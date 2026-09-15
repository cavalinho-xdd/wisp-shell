pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "."

Singleton {
    id: root

    property real value: 0
    property bool ready: false

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
