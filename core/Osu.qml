pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// osu!lazer live state, fed by scripts/osu_connect.js — a reconnecting
// websocket client against tosu's local v2 API (127.0.0.1:24050). tosu
// pushes one JSON message per game tick; the script re-emits a trimmed
// subset as one JSON line per stdout write, parsed here like
// PerformanceCard.qml parses sysmon_snapshot.sh, except this Process runs
// unconditionally (cheap, event-driven) rather than gated on tab visibility
// — Island needs `active` even while the dashboard is collapsed.
Singleton {
    id: root

    property bool connected: false
    property int state: -1
    property string username: ""
    property int userId: 0
    property int globalRank: 0
    property real profilePp: 0
    property real livePp: 0
    property int combo: 0
    property int maxCombo: 0
    property real accuracy: 0
    property int hits300: 0
    property int hits100: 0
    property int hits50: 0
    property int hitsMiss: 0

    // tosu/gosumemory GameState numbering — 2 is the actual gameplay state
    // (see ppeek's osu/telemetry.py GameState enum, same source API).
    readonly property bool inGameplay: connected && state === 2
    // osu!lazer + tosu are up and reporting a logged-in profile — what
    // Island.qml gates the "osu" activity lane on.
    readonly property bool active: connected && username.length > 0
    readonly property string avatarUrl: userId > 0 ? ("https://a.ppy.sh/" + userId) : ""

    Process {
        running: true
        command: ["node", Quickshell.shellPath("scripts/osu_connect.js")]
        stdout: SplitParser {
            onRead: message => {
                let data;
                try {
                    data = JSON.parse(message);
                } catch (e) {
                    return;
                }
                root.connected = !!data.connected;
                if (!root.connected) return;
                root.state = data.state ?? -1;
                root.username = data.username ?? "";
                root.userId = data.userId ?? 0;
                root.globalRank = data.globalRank ?? 0;
                root.profilePp = data.profilePp ?? 0;
                root.livePp = data.livePp ?? 0;
                root.combo = data.combo ?? 0;
                root.maxCombo = data.maxCombo ?? 0;
                root.accuracy = data.accuracy ?? 0;
                root.hits300 = data.hits300 ?? 0;
                root.hits100 = data.hits100 ?? 0;
                root.hits50 = data.hits50 ?? 0;
                root.hitsMiss = data.hitsMiss ?? 0;
            }
        }
    }
}
