import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import "../core"

// One status-notifier icon. Left click activates (primary action), right
// click opens its DBus menu via the platform-native QsMenuAnchor — no
// hand-rolled menu widget needed, Quickshell renders it itself.
//
// Only `anchor.item` is set below — deliberately no `anchor.window`. Setting
// `window` unconditionally unsets `item` first (PopupAnchor::setWindow() ->
// setItem(nullptr) in Quickshell's popupanchor.cpp), and that null-item path
// (onItemWindowChanged()) dereferences the item pointer with no null check —
// a real crash in Quickshell itself. A previous version of this file bound
// `anchor.window: root.QsWindow.window` (root's live "current window"
// attached property) to work around item/window not crossing the
// ExpandedDashboard.qml/shell.qml file boundary; that binding re-fires every
// time root's window changes — which StackView teardown on dashboard
// collapse does — hitting the crash on every collapse. `anchor.item` alone
// already derives the window automatically through a null-safe internal
// path, so it's the only anchor property this needs.
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
        anchor.item: root
    }
}
