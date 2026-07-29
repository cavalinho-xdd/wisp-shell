pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Live shell + Hyprland settings.
//
// No sandbox: this app owns the user's real ~/.config/hypr dotfiles and
// writes them directly. There is no separate "runtime override" layer to
// wipe on reload/reboot — Settings pages edit general.lua/animations.lua/
// keybinds.lua in place via scripts/apply_hypr_*.py, then `hyprctl reload`
// re-reads that same file, so what you see in Settings IS the config.
// (Earlier revisions of this file ran everything through a throwaway
// `hyprctl eval` layer to avoid touching another shell's dotfiles on the
// dev machine — that constraint no longer applies, so it's gone.)
Singleton {
    id: root

    property alias conf: adapter
    property bool ready: false

    // Real ~/.config/hypr (respects XDG_CONFIG_HOME), same rule Paths.qml
    // uses for wisp's own config/state dirs.
    readonly property string hyprConfigDir:
        (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/hypr"

    function lua(code) {
        Quickshell.execDetached(["hyprctl", "eval", code]);
    }

    function reloadHyprland() {
        Quickshell.execDetached(["hyprctl", "reload"]);
    }

    function applyLook() {
        Quickshell.execDetached(["python3", Paths.shell("scripts/apply_hypr_look.py"),
            root.hyprConfigDir,
            String(adapter.hypr.gapsIn), String(adapter.hypr.gapsOut),
            String(adapter.hypr.borderSize), String(adapter.hypr.rounding),
            adapter.hypr.blurEnabled ? "1" : "0",
            String(adapter.hypr.blurSize), String(adapter.hypr.blurPasses),
            adapter.hypr.animationsEnabled ? "1" : "0"]);
        // The script edits the file directly; reload is what makes Hyprland
        // actually pick the new file up (no incremental eval path anymore).
        reloadTimer2.restart();
    }

    // ── Keybind overrides ──
    // Each entry: { orig: "SUPER + Q", key: "SUPER + W", rest: "hl.dsp....(...)" }.
    // Rewrites the matching hl.bind("<orig>", ...) line in whichever real
    // ~/.config/hypr/*.lua file declares it (scripts/apply_hypr_keybind.py),
    // then reloads. keybindOverrides is kept only so Settings can show which
    // binds have been changed and offer a per-row reset.

    function overrideKeybind(orig, newKey, rest) {
        Quickshell.execDetached(["python3", Paths.shell("scripts/apply_hypr_keybind.py"), orig, newKey]);
        let list = (adapter.keybindOverrides || []).filter(o => !(o.orig === orig && o.rest === rest));
        list.push({ orig: orig, key: newKey, rest: rest });
        adapter.keybindOverrides = list;
        reloadTimer2.restart();
    }

    function resetKeybind(orig, rest) {
        const ov = (adapter.keybindOverrides || []).find(o => o.orig === orig && o.rest === rest);
        if (!ov) return;
        Quickshell.execDetached(["python3", Paths.shell("scripts/apply_hypr_keybind.py"), ov.key, orig]);
        adapter.keybindOverrides = adapter.keybindOverrides.filter(o => !(o.orig === orig && o.rest === rest));
        reloadTimer2.restart();
    }

    function clearKeybindOverrides() {
        for (const ov of (adapter.keybindOverrides || []))
            Quickshell.execDetached(["python3", Paths.shell("scripts/apply_hypr_keybind.py"), ov.key, ov.orig]);
        adapter.keybindOverrides = [];
        reloadTimer2.restart();
    }

    // ── Custom keybinds (brand new binds, not rebinds of existing ones) ──
    // Each entry: { mods: ["SUPER"], key: "T", actionId: "exec", actionArg: "kitty",
    //               luaExpr: 'hl.dsp.exec_cmd("kitty")', description: "Open terminal" }.
    // keybinds_custom.lua (required from hyprland.lua, right after keybinds.lua)
    // is fully wisp-owned — every add/edit/remove regenerates it from scratch via
    // scripts/write_custom_keybinds.py, so there's no line-patching fragility.

    function writeCustomKeybinds() {
        const items = (adapter.customKeybinds || []).map(b => ({
            keyStr: (b.mods && b.mods.length ? b.mods.join(" + ") + " + " : "") + b.key,
            luaExpr: b.luaExpr,
            description: b.description || ""
        }));
        Quickshell.execDetached(["python3", Paths.shell("scripts/write_custom_keybinds.py"),
            root.hyprConfigDir, JSON.stringify(items)]);
        reloadTimer2.restart();
    }

    function addCustomKeybind(entry) {
        let list = (adapter.customKeybinds || []).slice();
        list.push(entry);
        adapter.customKeybinds = list;
        writeCustomKeybinds();
    }

    function removeCustomKeybind(index) {
        let list = (adapter.customKeybinds || []).slice();
        list.splice(index, 1);
        adapter.customKeybinds = list;
        writeCustomKeybinds();
    }

    // No-op now that keybind overrides are direct file edits rather than a
    // runtime hl.unbind/hl.bind layer — kept only so a fresh shell start
    // doesn't have to special-case "first apply".
    function applyKeybinds() {}

    function applyAll() {
        // Nothing to re-inject on startup any more: general.lua/animations.lua/
        // keybinds.lua already ARE the settings, on disk, before wisp even runs.
    }

    Timer { id: reloadTimer2; interval: 150; onTriggered: root.reloadHyprland() }

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
    // line the user adds to their own shell init (fish/bash/zsh). Shell rc
    // files are the one thing still left to the user to wire up by hand —
    // everything Hyprland-side is a direct write now (see hyprConfigDir above).
    readonly property string terminalOscPath: Paths.terminalOscFile

    // Seeds hypr values from the live compositor state — used to pull the
    // sliders back in sync with the real file if it was ever hand-edited
    // outside Settings.
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
            root.applyAll();   // no-op today; kept as the one startup hook if that changes
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
            property var customKeybinds: []

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

            // Discord voice island controls. There is no local API to drive a
            // Discord client with — arRPC's IPC socket carries rich presence
            // only, Vencord exposes nothing external — so the buttons deliver
            // Discord's own in-app shortcuts to its window via Hyprland's
            // send_shortcut dispatcher. Format is "MODS, KEY" (Hyprland's own
            // bind syntax, mods space-separated); empty disables that button.
            // Mute/deafen are Discord's factory defaults and work as shipped.
            // Disconnect has NO default shortcut in Discord — bind it yourself
            // under Settings > Keybinds > "Disconnect From Voice Channel".
            property JsonObject discord: JsonObject {
                property string windowMatch: "class:vesktop"
                property string muteKey: "CTRL SHIFT, M"
                property string deafenKey: "CTRL SHIFT, D"
                property string leaveKey: "CTRL SHIFT, L"
            }

            // Running-game island lane (core/Games.qml + scripts/game_watch.sh).
            //
            // Detection, the session timer and Steam cover art all work with no
            // key at all — Steam's public CDN serves library art unauthenticated
            // and the running app id comes from the launcher's own process
            // cmdline. The keys buy exactly two things:
            //   steamApiKey  — achievement popups. There is NO local source for
            //                  these (see core/Games.qml), so without a key the
            //                  lane simply shows game + timer and never flashes.
            //                  Free, from https://steamcommunity.com/dev/apikey.
            //                  The profile's "Game details" must be Public or
            //                  the API returns nothing for your own account.
            //   steamGridDbKey — cover art for launchers Steam's CDN does not
            //                  cover (Heroic: Epic/GOG/Amazon). Ignored for
            //                  Steam titles, which already have art.
            // steamId is auto-detected from Steam's own loginusers.vdf; set it
            // only to override.
            //
            // Both are stored here in plaintext, like every other value in this
            // file. They are local-only credentials — the Steam key is read-only
            // over public stats endpoints — but treat the file as secret-bearing
            // if you ever share it.
            property JsonObject games: JsonObject {
                property bool enable: true
                property string steamApiKey: ""
                property string steamId: ""
                property string steamGridDbKey: ""
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
