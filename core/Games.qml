pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Running-game session state, fed by scripts/game_watch.sh — one JSON line per
// event, parsed here the same way Osu.qml consumes osu_connect.js.
//
// Why a script and not a native service: nothing in Quickshell knows about
// games, and the two facts the island needs come from places QML cannot reach.
// The running app id is in the launcher's process cmdline (Steam runs
// everything through `reaper SteamLaunch AppId=<id>`), and achievements are not
// on disk at all — userdata/<id>/<appid>/ holds only remotecache.vdf, and
// logs/stats_log.txt records stat *syncs* without ever naming an achievement,
// so the Steam Web API is the only source for what actually unlocked. Both live
// in the script; this singleton is a plain state holder.
Singleton {
    id: root

    // ── Session ──
    property bool active: false
    property string source: ""      // "steam" | "heroic" | "gamemode"
    property string appId: ""
    property string name: ""
    property string coverUrl: ""
    property double startedAt: 0    // epoch seconds, from the game process's
                                    // own start time — a shell restarted
                                    // mid-session shows the true elapsed time
                                    // rather than restarting the clock at zero.
    property int unlocked: 0
    property int total: 0

    readonly property bool hasAchievements: total > 0

    readonly property string sourceLabel: source === "steam" ? "Steam"
        : source === "heroic" ? "Heroic"
        : source === "gamemode" ? "Game" : ""

    // ── Transient: achievement flash ──
    // Deliberately NOT a separate Island lane. An unlock is a moment inside a
    // session, not a competing activity, so the game strip swaps its own face
    // for a few seconds and falls back — Island arbitration never sees it, the
    // same way Osu.inGameplay swaps the osu strip's two faces.
    property var flashAchievement: null
    readonly property bool flashing: flashAchievement !== null

    Timer {
        id: flashTimer
        interval: 6000
        onTriggered: root.flashAchievement = null
    }

    function dismissFlash() {
        flashTimer.stop();
        flashAchievement = null;
    }

    // Seconds elapsed. Ticks only while a game is running — no idle cost.
    property int elapsed: 0
    Timer {
        running: root.active
        interval: 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.elapsed = root.startedAt > 0
            ? Math.max(0, Math.floor(Date.now() / 1000 - root.startedAt)) : 0
    }

    readonly property string elapsedText: {
        const s = Math.max(0, elapsed);
        const h = Math.floor(s / 3600);
        const m = Math.floor((s % 3600) / 60);
        const sec = s % 60;
        const pad = v => (v < 10 ? "0" + v : "" + v);
        return h > 0 ? h + ":" + pad(m) + ":" + pad(sec) : m + ":" + pad(sec);
    }

    Process {
        // Gated on the setting rather than always-on: the script polls every
        // few seconds, and someone who does not game should not pay for it.
        // The script re-reads settings.json itself for the API keys, so a key
        // pasted in later needs no restart — only this on/off switch does.
        running: Settings.conf.games.enable
        command: ["bash", Quickshell.shellPath("scripts/game_watch.sh")]

        stdout: SplitParser {
            onRead: line => {
                let data;
                try {
                    data = JSON.parse(line);
                } catch (e) {
                    return;
                }

                if (data.type === "session") {
                    if (!data.active) {
                        root.active = false;
                        root.source = "";
                        root.appId = "";
                        root.name = "";
                        root.coverUrl = "";
                        root.startedAt = 0;
                        root.elapsed = 0;
                        root.unlocked = 0;
                        root.total = 0;
                        root.dismissFlash();
                        return;
                    }
                    root.source = data.source ?? "";
                    root.appId = data.appid ?? "";
                    root.name = data.name ?? "";
                    root.coverUrl = data.cover ?? "";
                    root.startedAt = data.startedAt ?? 0;
                    root.unlocked = data.unlocked ?? 0;
                    root.total = data.total ?? 0;
                    root.active = true;
                } else if (data.type === "achievement") {
                    root.unlocked = data.unlocked ?? root.unlocked;
                    root.total = data.total ?? root.total;
                    root.flashAchievement = {
                        name: data.name ?? "",
                        description: data.description ?? "",
                        icon: data.icon ?? ""
                    };
                    flashTimer.restart();
                }
            }
        }
    }
}
