import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import "../core"

// One status-notifier icon. Left click activates (primary action), right
// click opens its DBus menu via the platform-native QsMenuAnchor — no
// hand-rolled menu widget needed, Quickshell renders it itself.
// `root.QsWindow.window` is Quickshell's attached property for "the window
// this Item currently lives in" — used instead of threading a window
// reference down from shell.qml, since ExpandedDashboard.qml (where this is
// used) is a separate Component/file and can't see shell.qml's `floatingPill`
// id across that boundary.
MouseArea {
    id: root
    required property SystemTrayItem trayItem

    width: 28
    height: 28
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor

    onClicked: mouse => {
        // onlyMenu items (per Quickshell's own doc comment: "activation will
        // do nothing") must open the menu on left click too, not just right —
        // otherwise the primary click on those items is a silent no-op.
        if (trayItem.hasMenu && (mouse.button === Qt.RightButton || trayItem.onlyMenu))
            menuAnchor.open();
        else
            trayItem.activate();
    }

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: root.containsMouse ? Theme.surface0 : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.animFast } }
    }

    IconImage {
        anchors.centerIn: parent
        width: 18
        height: 18
        source: root.trayItem.icon
    }

    QsMenuAnchor {
        id: menuAnchor
        menu: root.trayItem.menu
        anchor.window: root.QsWindow.window
        anchor.item: root
    }
}
