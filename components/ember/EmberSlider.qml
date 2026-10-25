import QtQuick
import QtQuick.Effects
import "../../core"

// Slider for open islands: a thin track whose head is the ember, as on the
// media progress. Drag or click to set, arrow keys step by 5 %.
Item {
    id: root

    property real value: 0
    property string label: ""

    signal moved(real value)

    readonly property real shown: drag.pressed ? drag.temp : value
    // Centre of the head, for the island's inner light.
    readonly property real headX: width * shown

    implicitWidth: 200
    implicitHeight: Theme.controlSize / 2
    activeFocusOnTab: true

    Accessible.role: Accessible.Slider
    Accessible.name: label
    Accessible.onIncreaseAction: root.moved(Math.min(1, root.value + 0.05))
    Accessible.onDecreaseAction: root.moved(Math.max(0, root.value - 0.05))

    Keys.onRightPressed: root.moved(Math.min(1, root.value + 0.05))
    Keys.onLeftPressed: root.moved(Math.max(0, root.value - 0.05))

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: Theme.progressHeight
        radius: height / 2
        color: Theme.ashHi

        Rectangle {
            width: root.headX
            height: parent.height
            radius: height / 2
            color: Theme.islandText
        }
    }

    Item {
        id: head
        x: root.headX - width / 2
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.emberSize + Theme.spaceXs / 2
        height: width
        scale: root.activeFocus || drag.pressed ? 1.25 : 1
        Behavior on scale { NumberAnimation { duration: Theme.motionFast; easing.type: Easing.OutCubic } }

        RectangularShadow {
            anchors.fill: parent
            radius: width / 2
            color: Theme.ember
            blur: Theme.glowBlur * 0.5 * Theme.glow
        }
        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: Theme.ember
        }
    }

    MouseArea {
        id: drag
        anchors.fill: parent
        property real temp: 0
        function setFrom(x: real): void {
            temp = Math.max(0, Math.min(1, x / width));
            root.moved(temp);
        }
        onPressed: mouse => setFrom(mouse.x)
        onPositionChanged: mouse => { if (pressed) setFrom(mouse.x); }
    }
}
