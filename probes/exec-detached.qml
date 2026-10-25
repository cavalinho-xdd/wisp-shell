import QtQuick
import Quickshell

ShellRoot {
    Component.onCompleted: {
        Quickshell.execDetached(["bash", "-c", "touch /tmp/qs-test"])
        Qt.quit()
    }
}
