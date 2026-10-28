import QtQuick
import QtQuick.Layouts
import "../core"

// Label + a row of chips, one of which is selected. `options` is a list of
// { value, label }; `edited` reports the picked value.
RowLayout {
    id: root
    property string icon: ""
    property string text: ""
    property string value: ""
    property var options: []
    signal edited(string v)

    Layout.fillWidth: true
    Layout.leftMargin: 12
    Layout.rightMargin: 12
    Layout.preferredHeight: 40
    spacing: 16

    Text {
        font.family: Theme.fontFamily
        Layout.fillWidth: true
        text: root.text
        font.pixelSize: 13
        color: root.enabled ? Theme.islandText : Theme.islandMuted
    }

    Row {
        spacing: Theme.spaceXs
        Repeater {
            model: root.options
            delegate: Rectangle {
                id: chip
                required property var modelData
                readonly property bool active: root.value === chip.modelData.value
                width: chipLabel.implicitWidth + 2 * Theme.spaceMd
                height: Theme.controlSize - Theme.spaceXs
                radius: height / 2
                color: active ? Qt.tint(Theme.ashHi, Qt.alpha(Theme.ember, 0.22))
                     : chipMa.containsMouse ? Theme.hover : Theme.ashHi
                Behavior on color { ColorAnimation { duration: Theme.motionFast } }
                Accessible.role: Accessible.RadioButton
                Accessible.name: modelData.label
                Accessible.checked: active
                Text {
                    id: chipLabel
                    anchors.centerIn: parent
                    font.family: Theme.fontFamily
                    text: chip.modelData.label
                    font.pixelSize: Theme.textCaption
                    font.weight: chip.active ? Font.DemiBold : Font.Normal
                    color: chip.active ? Theme.ember : Theme.islandText
                }
                MouseArea {
                    id: chipMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (!chip.active) root.edited(chip.modelData.value);
                }
            }
        }
    }
}
