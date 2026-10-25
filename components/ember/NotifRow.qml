import QtQuick
import Quickshell
import Quickshell.Widgets
import "../../core"

// One notification in the control centre list: app icon, summary, body and
// how long ago. Live ones carry an ember dot. Click runs the default action,
// the cross (or Delete) dismisses it.
Item {
    id: row

    // A record from core/Notifs.qml.
    property var rec: null

    signal activated()
    signal dismissed()

    readonly property bool live: !!rec && rec.live
    readonly property string image: rec ? (rec.image || "") : ""
    readonly property string appIcon: rec ? (rec.appIcon || "") : ""

    implicitHeight: Theme.notifRow

    Accessible.role: Accessible.Button
    Accessible.name: rec ? (rec.summary || rec.appName) : ""
    Accessible.onPressAction: row.activated()
    activeFocusOnTab: true
    Keys.onReturnPressed: row.activated()
    Keys.onDeletePressed: row.dismissed()

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusRow
        color: Theme.ashHi
        opacity: mouse.containsMouse || row.activeFocus ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.motionFast } }
    }

    ClippingRectangle {
        id: icon
        x: Theme.spaceSm
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.notifIcon
        height: width
        radius: Theme.spaceSm
        color: Theme.ashHi

        Image {
            anchors.fill: parent
            visible: row.image !== ""
            source: row.image
            sourceSize: Qt.size(width * 2, height * 2)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }
        IconImage {
            anchors.centerIn: parent
            implicitSize: Theme.notifIcon * 0.62
            visible: row.image === "" && row.appIcon !== ""
            source: visible ? Quickshell.iconPath(row.appIcon) : ""
            asynchronous: true
        }
        Text {
            anchors.centerIn: parent
            visible: row.image === "" && row.appIcon === ""
            text: "󰂚"
            color: Theme.islandMuted
            font.family: Theme.fontIcon
            font.pixelSize: Theme.textBody
        }
    }

    Column {
        anchors.verticalCenter: parent.verticalCenter
        x: icon.x + icon.width + Theme.spaceSm
        width: side.x - x - Theme.spaceXs

        Text {
            width: parent.width
            text: row.rec ? (row.rec.summary || row.rec.appName) : ""
            elide: Text.ElideRight
            textFormat: Text.PlainText
            color: Theme.islandText
            font.family: Theme.fontFamily
            font.pixelSize: Theme.textBody
            font.weight: row.live ? Font.DemiBold : Font.Medium
        }
        Text {
            width: parent.width
            visible: text !== ""
            text: row.rec ? (row.rec.body || "") : ""
            elide: Text.ElideRight
            textFormat: Text.PlainText
            maximumLineCount: 1
            color: Theme.islandMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.textCaption
        }
    }

    // Time ago, or the cross while the row is under the pointer.
    Item {
        id: side
        anchors.verticalCenter: parent.verticalCenter
        x: parent.width - width - Theme.spaceSm
        width: Theme.controlSize - Theme.spaceXs
        height: width

        Text {
            anchors.centerIn: parent
            text: row.rec ? Notifs.relTime(row.rec.time) : ""
            color: Theme.islandMuted
            font.family: Theme.fontMono
            font.pixelSize: Theme.textMonoSmall
            opacity: mouse.containsMouse || row.activeFocus ? 0 : 1
            Behavior on opacity { NumberAnimation { duration: Theme.motionFast } }
        }
        Rectangle {
            anchors.centerIn: parent
            width: Theme.spaceXs
            height: width
            radius: width / 2
            color: Theme.ember
            visible: row.live
            anchors.horizontalCenterOffset: -parent.width / 2 - Theme.spaceXs
        }
        EmberButton {
            anchors.centerIn: parent
            opacity: mouse.containsMouse || row.activeFocus ? 1 : 0
            enabled: opacity > 0
            icon: "󰅖"
            label: "Dismiss"
            onClicked: row.dismissed()
            Behavior on opacity { NumberAnimation { duration: Theme.motionFast } }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        z: -1
        cursorShape: Qt.PointingHandCursor
        onClicked: row.activated()
    }
}
