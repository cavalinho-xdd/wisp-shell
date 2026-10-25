import QtQuick
import "../../core"

// Round icon button inside an open island. `big` gets a raised ash fill
// (the primary action); others show the fill only on hover.
Item {
    id: button

    property string icon: ""
    property string label: ""
    property bool big: false

    signal clicked()

    implicitWidth: big ? Theme.controlSizeBig : Theme.controlSize
    implicitHeight: implicitWidth
    opacity: enabled ? 1 : 0.32
    Behavior on opacity { NumberAnimation { duration: Theme.motionFast } }

    Accessible.role: Accessible.Button
    Accessible.name: label
    Accessible.onPressAction: if (enabled) button.clicked()

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: mouse.containsMouse && button.enabled ? Theme.ashHi : (button.big ? Theme.ash : "transparent")
        Behavior on color { ColorAnimation { duration: Theme.motionFast } }
        scale: mouse.pressed ? 0.9 : 1
        Behavior on scale { NumberAnimation { duration: Theme.motionFast; easing.type: Easing.OutCubic } }

        Text {
            anchors.centerIn: parent
            text: button.icon
            color: Theme.islandText
            font.family: Theme.fontIcon
            font.pixelSize: button.big ? Theme.textTitle : Theme.textBody
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: button.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: if (button.enabled) button.clicked()
    }
}
