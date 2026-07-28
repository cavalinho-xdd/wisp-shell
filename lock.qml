import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import "core"
import "components"

// Standalone lock-screen app (third entry point next to shell.qml /
// wallpaper.qml): `qs -p lock.qml` locks the session immediately —
// hypridle's lock_cmd and the dashboard power menu both launch it this
// way, and a successful unlock quits the process.
//
// PAM goes through the same stack hyprlock uses on this system:
// /etc/pam.d/hyprlock just includes "login", which is PamContext's
// default config — no custom pam.d shipped.
ShellRoot {
    id: root

    property bool authenticating: false
    property bool failed: false
    property string statusText: ""

    // PAM prompts first (responseRequired flips true), the UI answers via
    // respond(). Start is deferred through a Timer — starting synchronously
    // from Component.onCompleted crashes (nixos-configuration's Lock.qml
    // hit the same and documents it).
    Timer {
        id: pamRestart
        interval: 50
        running: true
        onTriggered: pam.start()
    }

    PamContext {
        id: pam

        onCompleted: result => {
            root.authenticating = false;
            if (result === PamResult.Success) {
                sessionLock.locked = false;
                Qt.quit();
            } else {
                root.failed = true;
                root.statusText = result === PamResult.MaxTries
                    ? "Too many attempts" : "Access denied";
                pamRestart.restart();
            }
        }
        onError: {
            root.authenticating = false;
            root.failed = true;
            root.statusText = "Authentication unavailable";
        }
    }

    WlSessionLock {
        id: sessionLock
        locked: true

        WlSessionLockSurface {
            color: Theme.background

            LockContent {
                anchors.fill: parent
                authenticating: root.authenticating
                failed: root.failed
                statusText: root.statusText
                canSubmit: pam.responseRequired

                onSubmit: password => {
                    root.authenticating = true;
                    root.failed = false;
                    root.statusText = "";
                    pam.respond(password);
                }
            }
        }
    }
}
