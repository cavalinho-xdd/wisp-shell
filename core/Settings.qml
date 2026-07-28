pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Sandboxed shell + Hyprland settings.
//
// The sandbox contract (this machine runs illogical-impulse dotfiles — they
// must never be touched):
//   1. Values live in settings.json next to shell.qml, NOT in any dotfile.
//   2. Hyprland changes are applied at runtime only, via
//      `hyprctl eval 'hl.config(...)'` (incremental — updates only keys passed).
//   3. `hyprctl reload` re-reads the user's own config files and wipes every
//      runtime override — that is the guaranteed escape hatch.
//   4. On shell startup the overrides are re-injected only if left enabled.
// Syntax verified against ~/.hyprwiki (hl.config / hl.bind / hl.unbind / hl.monitor).
Singleton {
    id: root

    property alias conf: adapter
    property bool ready: false

    function lua(code) {
        Quickshell.execDetached(["hyprctl", "eval", code]);
    }

    function applyLook() {
        if (!adapter.hypr.overridesEnabled) return;
        lua("hl.config({ general = { gaps_in = " + adapter.hypr.gapsIn
            + ", gaps_out = " + adapter.hypr.gapsOut
            + ", border_size = " + adapter.hypr.borderSize
            + " }, decoration = { rounding = " + adapter.hypr.rounding
            + ", blur = { enabled = " + adapter.hypr.blurEnabled
            + ", size = " + adapter.hypr.blurSize
            + ", passes = " + adapter.hypr.blurPasses
            + " } }, animations = { enabled = " + adapter.hypr.animationsEnabled + " } })");
    }

    // ── Keybind overrides ──
    // Each entry: { orig: "SUPER + Q", key: "SUPER + W", rest: "hl.dsp....(...)" }.
    // Runtime only: hl.unbind(orig) + hl.bind(new, rest). Any hyprctl reload
    // restores the user's own binds; we re-inject stored overrides on startup.

    function overrideKeybind(orig, newKey, rest) {
        lua('hl.unbind("' + orig + '") hl.bind("' + newKey + '", ' + rest + ")");
        let list = (adapter.keybindOverrides || []).filter(o => !(o.orig === orig && o.rest === rest));
        list.push({ orig: orig, key: newKey, rest: rest });
        adapter.keybindOverrides = list;
    }

    function resetKeybind(orig, rest) {
        const ov = (adapter.keybindOverrides || []).find(o => o.orig === orig && o.rest === rest);
        if (!ov) return;
        lua('hl.unbind("' + ov.key + '") hl.bind("' + orig + '", ' + rest + ")");
        adapter.keybindOverrides = adapter.keybindOverrides.filter(o => !(o.orig === orig && o.rest === rest));
    }

    function clearKeybindOverrides() {
        for (const ov of (adapter.keybindOverrides || []))
            lua('hl.unbind("' + ov.key + '") hl.bind("' + ov.orig + '", ' + ov.rest + ")");
        adapter.keybindOverrides = [];
    }

    function applyKeybinds() {
        for (const ov of (adapter.keybindOverrides || []))
            lua('hl.unbind("' + ov.orig + '") hl.bind("' + ov.key + '", ' + ov.rest + ")");
    }

    function applyAll() {
        applyLook();
        applyKeybinds();
    }

    // Synchronous write for callers that quit right after changing a value
    // (the debounced writeTimer would be killed with the app)
    function flush() {
        fileView.writeAdapter();
    }

    // ── Dynamic colors (matugen) ──
    // scripts/apply_colors.sh generates colors.json (project-local) from a
    // wallpaper; Theme.qml watches that file. The user's own matugen config
    // (has sudo post_hooks) is never executed — the script uses an empty one.

    function applyColors(img) {
        const script = Paths.shell("scripts/apply_colors.sh");
        let fanout = [];
        if (adapter.colors.applyTerminal) fanout.push("kitty");
        if (adapter.colors.applyTerminalOSC) fanout.push("osc");
        Quickshell.execDetached(["bash", script, img || adapter.colors.lastWallpaper || "-",
            adapter.colors.scheme, adapter.colors.mode, fanout.join(",")]);
    }

    // Absolute path to generated/terminal-osc.sh — shown in Settings as the
    // line the user adds to their own shell init (fish/bash/zsh); we never
    // write shell dotfiles ourselves, same sandbox contract as everywhere else.
    readonly property string terminalOscPath: Paths.terminalOscFile

    // Re-reads the user's config files — every runtime override disappears
    function restoreUserConfig() {
        Quickshell.execDetached(["hyprctl", "reload"]);
    }

    // Seeds hypr values from the live compositor state so enabling overrides
    // starts from what the user already sees instead of arbitrary defaults.
    function syncFromSystem() {
        syncProc.running = true;
    }

    // ── Absolute paths to project files ──
    //
    // ALL of these use Quickshell.shellPath(), NOT Qt.resolvedUrl(). Do not
    // "simplify" them back.
    //
    // Qt.resolvedUrl() cannot resolve a path to a .qml file here at all. It
    // returns Quickshell's internal virtual module URL — "qs:@/qs/lock.qml" —
    // which the `.replace("file://","")` that used to follow it silently left
    // untouched, because there is no file:// prefix to strip. Every one of
    // these then became `qs -p qs:@/qs/<name>.qml`: a path that does not
    // exist, launched inside a *detached* process whose stderr goes nowhere,
    // so the failure was invisible at every level.
    //
    // This was previously diagnosed as a difference between resolving inside a
    // dynamically-instantiated component versus inside a singleton, and
    // "fixed" by moving the calls here. That diagnosis was wrong, and the fix
    // did not work: verified with a probe printing all of them from this
    // singleton, `configPath` (.json) resolved to a real absolute path while
    // settingsAppPath / lockAppPath / wallpaperAppPath (.qml) all still came
    // back as "qs:@/qs/...". The real split is by file type — Quickshell maps
    // .qml files into its own module scheme wherever they are resolved from —
    // so the settings gear and, worse, the power-menu Lock button had remained
    // silently non-functional the whole time.
    //
    // Quickshell.shellPath() is the intended API for this (both ii-dots and
    // iNiR use it for exactly this purpose) and returns a real absolute path
    // with no scheme prefix to strip. It is used for the .json/.sh paths too,
    // which Qt.resolvedUrl did happen to handle, simply so there is one way of
    // doing this in the file rather than two subtly different ones.
    readonly property string configPath: Paths.settingsFile
    readonly property string settingsAppPath: Quickshell.shellPath("settings.qml")
    readonly property string lockAppPath: Quickshell.shellPath("lock.qml")
    readonly property string wallpaperAppPath: Quickshell.shellPath("wallpaper.qml")
    readonly property string welcomeAppPath: Quickshell.shellPath("welcome.qml")
    readonly property string nightmodeScriptPath: Quickshell.shellPath("core/fade_nightmode.sh")

    // ── Wallpaper folder ──
    // Was hardcoded to "$HOME/Obrázky/Wallpapers" (Czech-localized Pictures) in
    // both wallpaper.qml and the now-removed WallpaperView.qml — worked for
    // exactly one user. Real default comes from `xdg-user-dir PICTURES`
    // (locale-correct on any machine), resolved once at startup; the user can
    // still override it via the Colors settings page folder picker.
    property string xdgPicturesDir: ""
    Process {
        id: xdgPicturesProc
        command: ["xdg-user-dir", "PICTURES"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.xdgPicturesDir = this.text.trim()
        }
    }
    readonly property string defaultWallpaperFolder:
        (root.xdgPicturesDir || (Quickshell.env("HOME") + "/Pictures")) + "/Wallpapers"
    readonly property string wallpaperFolder: adapter.colors.wallpaperFolder || root.defaultWallpaperFolder

    Process {
        id: syncProc
        command: ["bash", "-c",
            "echo \"{" +
            "\\\"gapsIn\\\": $(hyprctl getoption general:gaps_in -j | jq '(.int // ((.custom // \"0\") | split(\" \")[0] | tonumber))'), " +
            "\\\"gapsOut\\\": $(hyprctl getoption general:gaps_out -j | jq '(.int // ((.custom // \"0\") | split(\" \")[0] | tonumber))'), " +
            "\\\"borderSize\\\": $(hyprctl getoption general:border_size -j | jq '.int // 0'), " +
            "\\\"rounding\\\": $(hyprctl getoption decoration:rounding -j | jq '.int // 0'), " +
            "\\\"blurEnabled\\\": $(hyprctl getoption decoration:blur:enabled -j | jq 'if (.int // 0) == 1 then true else false end'), " +
            "\\\"blurSize\\\": $(hyprctl getoption decoration:blur:size -j | jq '.int // 8'), " +
            "\\\"blurPasses\\\": $(hyprctl getoption decoration:blur:passes -j | jq '.int // 1'), " +
            "\\\"animationsEnabled\\\": $(hyprctl getoption animations:enabled -j | jq 'if (.int // 1) == 1 then true else false end')" +
            "}\""]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const v = JSON.parse(this.text.trim());
                    adapter.hypr.gapsIn = v.gapsIn;
                    adapter.hypr.gapsOut = v.gapsOut;
                    adapter.hypr.borderSize = v.borderSize;
                    adapter.hypr.rounding = v.rounding;
                    adapter.hypr.blurEnabled = v.blurEnabled;
                    adapter.hypr.blurSize = v.blurSize;
                    adapter.hypr.blurPasses = v.blurPasses;
                    adapter.hypr.animationsEnabled = v.animationsEnabled;
                } catch (e) {}
            }
        }
    }

    FileView {
        id: fileView
        path: root.configPath
        watchChanges: true
        onFileChanged: reloadTimer.restart()
        onAdapterUpdated: writeTimer.restart()
        onLoaded: {
            root.ready = true;
            root.applyAll();   // startup re-injection (no-op unless overrides are on)
        }
        onLoadFailed: error => {
            if (error == FileViewError.FileNotFound) {
                root.syncFromSystem();   // first run: seed from live values
                writeTimer.restart();
                // `ready` means "settings state is settled", not "a file was
                // read" — a missing file settles to the defaults just as
                // definitively. It was previously left false forever on this
                // path, which is exactly the first-run case core/FirstRun.qml
                // has to wait for (gating on it is what stops the welcome
                // wizard firing off the pre-load default value on every start).
                root.ready = true;
            }
        }

        adapter: JsonAdapter {
            id: adapter

            property JsonObject hypr: JsonObject {
                property bool overridesEnabled: false
                property int gapsIn: 5
                property int gapsOut: 20
                property int borderSize: 2
                property int rounding: 10
                property bool blurEnabled: true
                property int blurSize: 8
                property int blurPasses: 1
                property bool animationsEnabled: true
            }

            property var keybindOverrides: []

            property JsonObject shell: JsonObject {
                property int workspaceCount: 5
                property bool clock12h: true
                // Empty = show the pill/click-catcher/OSD trio on every connected
                // monitor (Multi-Monitor Support, plan.md); a monitor's `.name`
                // (e.g. "DP-1") restricts that whole per-monitor surface group to
                // just that one screen. Matches iNiR's "restrict to primary
                // monitor" settings pattern.
                property string pillMonitor: ""
                // First-run gate. False (the default, and therefore what a
                // machine with no settings.json at all reads) launches
                // welcome.qml once at shell startup — see core/FirstRun.qml.
                // Deliberately a settings.json field rather than the separate
                // state sentinel file both ii-dots and iNiR use
                // (`~/.local/state/.../first_run.txt`, checked via FileView /
                // `test -f`): wisp already keeps all its state in this one
                // project-local file with a FileView watching it, so a second
                // file plus a second existence-check mechanism would be strictly
                // more machinery for the same one bit.
                property bool welcomeSeen: false
            }

            property JsonObject weather: JsonObject {
                property bool enable: true
            }

            property JsonObject colors: JsonObject {
                property bool dynamicEnabled: false
                property string scheme: "tonal-spot"
                property string mode: "dark"
                property string lastWallpaper: ""
                // Empty = auto (Settings.defaultWallpaperFolder, xdg-user-dir PICTURES);
                // set once the user picks a folder via the Colors settings page.
                property string wallpaperFolder: ""
                // Fan the same palette out to kitty (apply_colors.sh 4th arg)
                property bool applyTerminal: false
                // Terminal-agnostic recolor via OSC escapes (apply_colors.sh
                // "osc" fanout) — see Settings.terminalOscPath
                property bool applyTerminalOSC: false
                // Panel background alpha, 0.0-1.0 — see Theme.panelBackground
                property real panelAlpha: 1.0
            }
        }
    }

    Timer { id: writeTimer; interval: 200; onTriggered: fileView.writeAdapter() }
    Timer { id: reloadTimer; interval: 100; onTriggered: fileView.reload() }
}
