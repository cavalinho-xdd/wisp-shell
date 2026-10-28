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
        spacing: 6
        Repeater {
            model: root.options
            delegate: Rectangle {
                id: chip
                required property var modelData
                readonly property bool active: root.value === chip.modelData.value
                width: chipLabel.implicitWidth + 24
                height: 30
                radius: 10
                color: active ? Theme.ember : Theme.ashHi
                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                Accessible.role: Accessible.RadioButton
                Accessible.name: modelData.label
                Accessible.checked: active
                Text {
                    id: chipLabel
                    anchors.centerIn: parent
                    font.family: Theme.fontFamily
                    text: chip.modelData.label
                    font.pixelSize: 12
                    font.bold: chip.active
                    color: chip.active ? Theme.smoke : Theme.islandText
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (!chip.active) root.edited(chip.modelData.value);
                }
            }
        }
    }
}
