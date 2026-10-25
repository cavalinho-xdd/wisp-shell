import QtQuick
import QtQuick.Effects
import "../../core"

// Toggle tile of the control centre: a round icon well that lights up in ember
// while the thing is on, a title and a line of state.
Item {
    id: tile

    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property bool checked: false

    // A chevron that opens the detail view of this tile.
    property bool hasMore: false

    signal clicked()
    signal moreClicked()

    implicitHeight: Theme.controlSizeBig + Theme.spaceMd
    activeFocusOnTab: true

    Accessible.role: Accessible.CheckBox
    Accessible.name: title
    Accessible.checked: checked
    Accessible.onPressAction: tile.clicked()

    Keys.onReturnPressed: tile.clicked()
    Keys.onSpacePressed: tile.clicked()

    // Raised plate; while on, the whole tile is lit by the ember from the icon.
    EmberSurface {
        id: plate
        anchors.fill: parent
        lit: tile.checked
        base: mouse.containsMouse ? Theme.ashHi : Theme.ash
        radius: Theme.radiusTile
        lightX: well.x + well.width / 2
        lightY: height / 2
        scale: mouse.pressed ? Theme.pressScale : 1
        Behavior on base { ColorAnimation { duration: Theme.motionFast } }
        Behavior on scale { NumberAnimation { duration: Theme.motionFast; easing.type: Easing.OutCubic } }
    }

    // Keyboard focus ring, outside the plate so it never reads as depth.
    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusTile
        color: "transparent"
        visible: tile.activeFocus
        border.width: 1.5
        border.color: Theme.ember
    }

    // The well: dark, the icon is the ember when on.
    EmberSurface {
        id: well
        x: Theme.spaceSm
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.controlSize
        height: width
        radius: width / 2
        base: tile.checked ? Theme.smoke : Theme.ashHi
        scale: plate.scale
        Behavior on base { ColorAnimation { duration: Theme.motionFast } }

        Text {
            anchors.centerIn: parent
            text: tile.icon
            color: tile.checked ? Theme.ember : Theme.islandMuted
            font.family: Theme.fontIcon
            font.pixelSize: Theme.textTitle
            Behavior on color { ColorAnimation { duration: Theme.motionFast } }
        }
    }

    Column {
        anchors.verticalCenter: parent.verticalCenter
        x: well.x + well.width + Theme.spaceSm
        width: parent.width - x - Theme.spaceSm - (tile.hasMore ? more.width : 0)

        Text {
            width: parent.width
            text: tile.title
            elide: Text.ElideRight
            color: Theme.islandText
            font.family: Theme.fontFamily
            font.pixelSize: Theme.textBody
            font.weight: Font.Medium
        }
        Text {
            width: parent.width
            text: tile.subtitle
            elide: Text.ElideRight
            color: Theme.islandMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.textCaption
        }
    }

    Item {
        id: more
        visible: tile.hasMore
        anchors.verticalCenter: parent.verticalCenter
        x: parent.width - width - Theme.spaceXs
        width: Theme.controlSize - Theme.spaceXs
        height: width
        Accessible.role: Accessible.Button
        Accessible.name: tile.title + " details"
        activeFocusOnTab: tile.hasMore
        Keys.onReturnPressed: tile.moreClicked()

        Text {
            anchors.centerIn: parent
            text: "󰅂"
            color: moreMouse.containsMouse ? Theme.islandText : Theme.islandMuted
            font.family: Theme.fontIcon
            font.pixelSize: Theme.textBody
            Behavior on color { ColorAnimation { duration: Theme.motionFast } }
        }
        MouseArea {
            id: moreMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: tile.moreClicked()
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        z: -1
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: tile.clicked()
    }
}
