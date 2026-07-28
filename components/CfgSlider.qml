import QtQuick
import QtQuick.Layouts
import "../core"

// Label + slider + value readout row for the settings pages.
RowLayout {
    id: root
    property string icon: ""
    property string text: ""
    property int value: 0
    property int maxValue: 30
    signal edited(int v)

    Layout.fillWidth: true
    Layout.leftMargin: 12
    Layout.rightMargin: 12
    spacing: 10

    Text {
        text: root.icon
        font.family: Theme.fontIcon
        font.pixelSize: 15
        color: root.enabled ? Theme.text : Theme.subtext0
        visible: root.icon !== ""
    }
    Text {
        font.family: Theme.fontFamily;
        text: root.text
        font.pixelSize: 13
        color: root.enabled ? Theme.text : Theme.subtext0
        Layout.preferredWidth: 110
    }
    Slider {
        Layout.fillWidth: true
        value: root.maxValue > 0 ? root.value / root.maxValue : 0
        onMoved: function(v) { root.edited(Math.round(v * root.maxValue)) }
    }
    Text {
        font.family: Theme.fontFamily;
        text: root.value
        font.pixelSize: 13
        font.bold: true
        color: Theme.primary
        Layout.preferredWidth: 28
        horizontalAlignment: Text.AlignRight
    }
}
