import QtQuick
import "../../core"

// On/off switch for open islands; the knob is ember while on.
Item {
    id: root

    property bool checked: false
    property string label: ""

    signal toggled(bool checked)

    implicitWidth: Theme.controlSizeBig - Theme.spaceXs / 2
    implicitHeight: Theme.spaceLg + Theme.spaceXs / 2
    activeFocusOnTab: true

    Accessible.role: Accessible.CheckBox
    Accessible.name: label
    Accessible.checked: checked
    Accessible.onPressAction: root.toggled(!root.checked)
    Keys.onReturnPressed: root.toggled(!root.checked)
    Keys.onSpacePressed: root.toggled(!root.checked)

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? Qt.tint(Theme.ashHi, Qt.alpha(Theme.ember, 0.22)) : Theme.ashHi
        border.width: root.activeFocus ? 1.5 : 0
        border.color: Theme.ember
        Behavior on color { ColorAnimation { duration: Theme.motionFast } }
    }
    Rectangle {
        y: Theme.spaceXs / 2
        x: root.checked ? parent.width - width - Theme.spaceXs / 2 : Theme.spaceXs / 2
        width: parent.height - Theme.spaceXs
        height: width
        radius: width / 2
        color: root.checked ? Theme.ember : Theme.islandMuted
        Behavior on x { NumberAnimation { duration: Theme.motionFast; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: Theme.motionFast } }
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }
}
