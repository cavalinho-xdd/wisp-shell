import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import "../core"

// Transient notification flash for the collapsed bar — the island's
// second live activity. Appears when Island.flashNotif is set, preempting
// the media strip; auto-expires via Island's flash timer. Click expands
// the dashboard (notification centre lives on the Dashboard tab);
// middle-click dismisses just the flash.
Item {
    id: root

    signal expandRequested()

    readonly property var notif: Island.flashNotif
    // Keep the last notification around while animating out
    property var shown: null
    onNotifChanged: if (notif) shown = notif

    readonly property bool active: !!notif

    implicitWidth: active ? strip.implicitWidth : 0
    implicitHeight: 48

    opacity: active ? 1 : 0
    scale: active ? (hoverHandler.hovered ? 1.035 : 1.0) : 0.7
    visible: opacity > 0.01
    Behavior on opacity { NumberAnimation { duration: 250 } }
    Behavior on scale { NumberAnimation { duration: 220; easing.type: Theme.easeSpring; easing.overshoot: 1.3 } }
    Behavior on implicitWidth { NumberAnimation { duration: 420; easing.type: Easing.OutBack; easing.overshoot: 1.05 } }

    HoverHandler { id: hoverHandler }

    function urgencyColor() {
        if (shown && shown.urgency === NotificationUrgency.Critical) return Theme.red;
        return Theme.primary;
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: mouse => {
            if (mouse.button === Qt.MiddleButton)
                Island.dismissFlash();
            else
                root.expandRequested();
        }
    }

    Row {
        id: strip
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        // Bell badge with urgency tint; swings on arrival, breathes while shown
        Rectangle {
            id: badge
            anchors.verticalCenter: parent.verticalCenter
            width: 30; height: 30; radius: 15
            color: Theme.surface0
            border.color: root.urgencyColor()
            border.width: 2

            SequentialAnimation {
                running: root.active
                loops: Animation.Infinite
                NumberAnimation { target: badge; property: "border.width"; to: 3; duration: 900; easing.type: Easing.InOutSine }
                NumberAnimation { target: badge; property: "border.width"; to: 2; duration: 900; easing.type: Easing.InOutSine }
            }

            Text {
                id: bell
                anchors.centerIn: parent
                text: "󰂚"
                font.family: Theme.fontIcon
                font.pixelSize: 14
                color: root.urgencyColor()
                transformOrigin: Item.Top
            }
            SequentialAnimation {
                id: ring
                NumberAnimation { target: bell; property: "rotation"; to: -24; duration: 90; easing.type: Easing.OutQuad }
                NumberAnimation { target: bell; property: "rotation"; to: 18; duration: 110 }
                NumberAnimation { target: bell; property: "rotation"; to: -10; duration: 110 }
                NumberAnimation { target: bell; property: "rotation"; to: 0; duration: 160; easing.type: Easing.OutBack }
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1
            // Slide up on each new notification (Translate — y fights anchors)
            transform: Translate { id: shift }
            ParallelAnimation {
                id: slideIn
                NumberAnimation { target: shift; property: "y"; from: 10; to: 0; duration: 350; easing.type: Easing.OutQuint }
            }

            Text {
                font.family: Theme.fontFamily;
                text: root.shown ? (root.shown.summary || root.shown.appName || "Notification") : ""
                color: Theme.text
                font.pixelSize: 12
                font.bold: true
                width: Math.min(implicitWidth, 220)
                elide: Text.ElideRight
                onTextChanged: { ring.restart(); slideIn.restart(); }
            }
            Text {
                font.family: Theme.fontFamily;
                text: root.shown ? (root.shown.body || root.shown.appName || "") : ""
                color: Theme.subtext0
                font.pixelSize: 10
                width: Math.min(implicitWidth, 220)
                elide: Text.ElideRight
                visible: text.length > 0
                textFormat: Text.PlainText
            }
        }
    }
}
