import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import "../../core"

// One status-notifier icon in the control centre footer. Left click
// activates, right click (or a menu-only item) opens its menu. Only
// `anchor.item` is set on the menu anchor, never `anchor.window`: setting
// the window unsets the item and crashes Quickshell (see TrayItem.qml).
MouseArea {
    id: root

    required property SystemTrayItem trayItem

    implicitWidth: Theme.controlSize
    implicitHeight: Theme.controlSize
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor

    Accessible.role: Accessible.Button
    Accessible.name: trayItem.title || trayItem.id

    onClicked: mouse => {
        if (trayItem.hasMenu && (mouse.button === Qt.RightButton || trayItem.onlyMenu)) menuAnchor.open();
        else trayItem.activate();
    }

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: root.containsMouse ? Theme.ashHi : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.motionFast } }
    }
    IconImage {
        anchors.centerIn: parent
        implicitSize: Theme.textTitle
        source: root.trayItem.icon
    }
    QsMenuAnchor {
        id: menuAnchor
        menu: root.trayItem.menu
        anchor.item: root
    }
}
