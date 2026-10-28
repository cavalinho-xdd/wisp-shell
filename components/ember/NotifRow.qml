import QtQuick
import Quickshell
import Quickshell.Widgets
import "../../core"

// One notification in the control centre list: app icon, summary, body and
// how long ago. Live ones carry an ember dot. Click runs the default action,
// the cross (or Delete) dismisses it, the chevron (or Space) shows the whole
// body when one line cannot hold it.
Item {
    id: row

    // A record from core/Notifs.qml.
    property var rec: null

    signal activated()
    signal dismissed()

    readonly property bool live: !!rec && rec.live
    readonly property string image: rec ? (rec.image || "") : ""
    readonly property string appIcon: rec ? (rec.appIcon || "") : ""
    readonly property string body: rec ? (rec.body || "") : ""
    // Measured on the unwrapped text, so it does not depend on the row's own width.
    readonly property bool canExpand: bodyText.implicitWidth > side.x - textCol.x - Theme.spaceXs || body.indexOf("\n") >= 0
    property bool expanded: false

    implicitHeight: Math.max(Theme.notifRow, textCol.implicitHeight + Theme.spaceSm * 2)

    Accessible.role: Accessible.Button
    Accessible.name: rec ? (rec.summary || rec.appName) : ""
    Accessible.onPressAction: row.activated()
    activeFocusOnTab: true
    Keys.onReturnPressed: row.activated()
    Keys.onDeletePressed: row.dismissed()
    Keys.onSpacePressed: if (row.canExpand) row.expanded = !row.expanded

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
        // Icon and side stay level with the first line when the row grows.
        y: (Theme.notifRow - height) / 2
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
        id: textCol
        anchors.verticalCenter: parent.verticalCenter
        x: icon.x + icon.width + Theme.spaceSm
        width: (row.canExpand ? expandButton.x : side.x) - x - Theme.spaceXs

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
            id: bodyText
            width: parent.width
            visible: text !== ""
            text: row.body
            elide: Text.ElideRight
            textFormat: Text.PlainText
            wrapMode: row.expanded ? Text.Wrap : Text.NoWrap
            maximumLineCount: row.expanded ? Theme.notifBodyLines : 1
            color: Theme.islandMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.textCaption
        }
    }

    EmberButton {
        id: expandButton
        x: side.x - width
        y: (Theme.notifRow - height) / 2
        visible: row.canExpand
        icon: row.expanded ? "󰅃" : "󰅀"
        label: row.expanded ? "Show less" : "Show more"
        onClicked: row.expanded = !row.expanded
    }

    // Time ago, or the cross while the row is under the pointer.
    Item {
        id: side
        y: (Theme.notifRow - height) / 2
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
            anchors.horizontalCenterOffset: -parent.width / 2 - Theme.spaceXs - (row.canExpand ? expandButton.width : 0)
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
