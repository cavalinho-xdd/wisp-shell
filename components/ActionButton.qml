import QtQuick
import "../core"

// Icon + text label button for the settings app and the welcome wizard.
// Sized to its content so it drops straight into a
// RowLayout without extra Layout.preferredWidth bookkeeping at call sites.
Rectangle {
    id: root
    property string icon: ""
    property string text: ""
    signal clicked()

    implicitWidth: row.implicitWidth + 2 * Theme.spaceMd
    implicitHeight: Theme.controlSize
    radius: height / 2
    // Borderless: a button reads as a button from its fill and its hover
    // reaction. The outline this used to carry was the "grey box around
    // everything" tell, and it made a row of these look like a row of cards
    // rather than a row of controls. Hover steps up the tonal ramp instead.
    color: mouse.containsMouse ? Theme.hover : Theme.ashHi
    Behavior on color { ColorAnimation { duration: Theme.motionFast } }

    scale: mouse.pressed ? Theme.pressScale : 1.0
    Behavior on scale { NumberAnimation { duration: Theme.motionFast; easing.type: Easing.OutCubic } }
    Accessible.role: Accessible.Button
    Accessible.name: text
    Accessible.onPressAction: root.clicked()

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Theme.spaceXs
        Text {
            text: root.icon
            visible: root.icon !== ""
            font.family: Theme.fontIcon
            font.pixelSize: Theme.textCaption
            color: Theme.islandMuted
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            font.family: Theme.fontFamily;
            text: root.text
            font.pixelSize: Theme.textCaption
            font.weight: Font.Medium
            color: Theme.islandText
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
