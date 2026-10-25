import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import "../../core"

// Notification flare in the centre island: app icon, the ember with the app
// name, summary and body. Click runs the notification's default action (or
// focuses the app); middle click dismisses the flare. Island.flashNotif
// decides what shows and for how long.
Item {
    id: root

    property bool lit: false
    readonly property var notif: Island.flashNotif
    // Last notification stays while the island closes around it.
    property var shown: null
    onNotifChanged: if (notif) shown = notif

    readonly property bool critical: !!shown && shown.urgency === NotificationUrgency.Critical
    readonly property string image: shown ? (shown.image || "") : ""
    readonly property string appIcon: shown ? (shown.appIcon || "") : ""
    // Centre of the ember, for the island's inner light.
    readonly property point emberPoint: Qt.point(
        textBlock.x + header.x + dot.x + dot.width / 2,
        textBlock.y + header.y + header.height / 2)

    implicitWidth: Theme.flareWidth
    implicitHeight: Theme.spaceMd * 2 + Math.max(Theme.flareIcon, textBlock.implicitHeight)

    Accessible.role: Accessible.Button
    Accessible.name: shown ? (shown.summary || shown.appName || "Notification") : ""
    Accessible.onPressAction: root.open()

    function open(): void {
        Notifs.activateLive(root.shown);
        Island.dismissFlash();
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            if (mouse.button === Qt.MiddleButton)
                Island.dismissFlash();
            else
                root.open();
        }
    }

    Kindle {
        lit: root.lit
        index: 0
        x: Theme.spaceMd
        y: Theme.spaceMd
        width: Theme.flareIcon
        height: Theme.flareIcon

        ClippingRectangle {
            width: Theme.flareIcon
            height: Theme.flareIcon
            radius: Theme.radiusRow
            color: Theme.ashHi

            Image {
                anchors.fill: parent
                visible: root.image !== ""
                source: root.image
                sourceSize: Qt.size(Theme.flareIcon * 2, Theme.flareIcon * 2)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
            IconImage {
                anchors.centerIn: parent
                implicitSize: Theme.flareIcon * 0.6
                visible: root.image === "" && root.appIcon !== ""
                source: visible ? Quickshell.iconPath(root.appIcon) : ""
                asynchronous: true
            }
            Text {
                anchors.centerIn: parent
                visible: root.image === "" && root.appIcon === ""
                text: "󰂚"
                color: Theme.islandMuted
                font.family: Theme.fontIcon
                font.pixelSize: Theme.textTitle
            }
        }
    }

    Kindle {
        id: textBlock
        lit: root.lit
        index: 1
        x: Theme.spaceMd + Theme.flareIcon + Theme.spaceSm
        y: Theme.spaceMd
        width: root.width - x - Theme.spaceMd

        Column {
            width: textBlock.width
            spacing: 2

            Row {
                id: header
                spacing: Theme.spaceXs

                EmberDot {
                    id: dot
                    anchors.verticalCenter: parent.verticalCenter
                    playing: root.critical
                    running: root.lit
                }
                Text {
                    width: Math.min(implicitWidth, textBlock.width - dot.width - urgent.width - header.spacing * (urgent.visible ? 2 : 1))
                    text: root.shown ? (root.shown.appName || "") : ""
                    elide: Text.ElideRight
                    opacity: 0.7
                    color: Theme.islandMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.textLabel
                    font.weight: Font.Medium
                    font.letterSpacing: Theme.textLabel * 0.08
                    font.capitalization: Font.AllUppercase
                }
                Text {
                    id: urgent
                    visible: root.critical
                    text: "Urgent"
                    color: Theme.ember
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.textLabel
                    font.weight: Font.Medium
                    font.letterSpacing: Theme.textLabel * 0.08
                    font.capitalization: Font.AllUppercase
                }
            }

            Text {
                width: textBlock.width
                text: root.shown ? (root.shown.summary || root.shown.appName || "") : ""
                elide: Text.ElideRight
                textFormat: Text.PlainText
                color: Theme.islandText
                font.family: Theme.fontFamily
                font.pixelSize: Theme.textBody
                font.weight: Font.DemiBold
            }

            Text {
                width: textBlock.width
                visible: text !== ""
                text: root.shown ? (root.shown.body || "") : ""
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                textFormat: Text.PlainText
                color: Theme.islandMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.textCaption
            }
        }
    }
}
