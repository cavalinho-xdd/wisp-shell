pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "beat.js" as BeatJs

// The music under the ember: cava's spectrum while a player plays, so the
// islands' glow and the ember can pulse to the bass and the media card can
// draw bars. cava runs only while `active`; nothing is spawned otherwise.
Singleton {
    id: root

    readonly property int barCount: 16
    readonly property bool active: Settings.conf.shell.musicPulse && Island.playing && !Theme.reduceMotion

    // Raw levels 0..1, smoothed per bar; kept when cava stops so `fade` can
    // take them down instead of cutting to dark.
    property var bars: []
    property real level: 0
    // 1 while active, eases to 0 over a pause.
    property real fade: active ? 1 : 0
    Behavior on fade { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }

    // What views read.
    readonly property real pulse: level * fade

    function feed(line) {
        const frame = BeatJs.parseFrame(line, barCount);
        if (!frame) return;
        const prev = bars.length === barCount ? bars : frame.map(() => 0);
        bars = frame.map((v, i) => BeatJs.follow(prev[i], v));
        level = BeatJs.follow(level, BeatJs.bass(frame));
    }

    Process {
        running: root.active
        // The config goes to a runtime file: cava reads its config only from
        // a path. Missing cava is not an error, the light just stays still.
        command: ["sh", "-c", `
            command -v cava >/dev/null || exit 0
            f="\${XDG_RUNTIME_DIR:-/tmp}/wisp-cava.conf"
            printf '[general]\\nbars = %s\\nframerate = 30\\n[output]\\nmethod = raw\\nraw_target = /dev/stdout\\ndata_format = ascii\\nascii_max_range = 1000\\nbar_delimiter = 59\\nframe_delimiter = 10\\nchannels = mono\\n' "$1" > "$f"
            exec cava -p "$f"`, "sh", String(root.barCount)]
        stdout: SplitParser { onRead: data => root.feed(data) }
    }
}
