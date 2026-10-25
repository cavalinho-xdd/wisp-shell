pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "."

Singleton {
    id: root

    property real value: 0
    property bool ready: false

    // v is 0..1. The watcher script reports the change back, so `value`
    // follows without being set here.
    function set(v: real): void {
        Quickshell.execDetached(["brightnessctl", "set", Math.round(Math.max(0.01, Math.min(1, v)) * 100) + "%"]);
    }

    Process {
        running: true
        command: ["bash", Quickshell.shellPath("scripts/brightness_watch.sh")]

        stdout: SplitParser {
            onRead: line => {
                let data;
                try {
                    data = JSON.parse(line);
                } catch (e) {
                    return;
                }

                if (data.value !== undefined) {
                    let oldReady = root.ready;
                    root.value = data.value;
                    root.ready = true;
                    // Don't show OSD on the initial script print, only on subsequent changes
                    if (oldReady) {
                        Osd.show("brightness", root.value, false);
                    }
                }
            }
        }
    }
}
