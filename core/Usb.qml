pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string lastEvent: ""

    Process {
        running: true
        command: ["bash", Quickshell.shellPath("scripts/usb_watch.sh")]

        stdout: SplitParser {
            onRead: line => {
                let data;
                try {
                    data = JSON.parse(line);
                } catch (e) {
                    return;
                }

                if (data.event) {
                    root.lastEvent = data.event;
                    Island.triggerUsbFlash(data.event);
                }
            }
        }
    }
}
