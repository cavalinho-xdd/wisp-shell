pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Weather for the shell: scripts/weather.sh (open-meteo, cached 15 min on
// disk). Fetches only while a view asks for it (`wanted`) and the data is
// older than the cache, so the shell makes no requests while idle.
Singleton {
    id: root

    // Set by a view while it is on screen.
    property bool wanted: false
    // Parsed script output: { city, current, days[] }, null until the first read.
    property var wx: null
    property double fetchedAt: 0

    onWantedChanged: if (wanted && Date.now() - fetchedAt > 900000) proc.running = true

    Process {
        id: proc
        command: ["bash", Quickshell.shellPath("scripts/weather.sh"), "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                const t = this.text.trim();
                if (t === "") return;
                try {
                    root.wx = JSON.parse(t);
                    root.fetchedAt = Date.now();
                } catch (e) {
                    console.warn("Weather: unreadable output from weather.sh");
                }
            }
        }
    }
}
