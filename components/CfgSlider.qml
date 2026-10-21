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
    Layout.preferredHeight: 40
    spacing: 16

    Text {
        font.family: Theme.fontFamily
        text: root.text
        font.pixelSize: 13
        color: root.enabled ? Theme.text : Theme.subtext0
        Layout.preferredWidth: 140
    }
    Slider {
        Layout.fillWidth: true
        value: root.maxValue > 0 ? root.value / root.maxValue : 0
        onMoved: function(v) { root.edited(Math.round(v * root.maxValue)) }
    }
    Text {
        font.family: Theme.fontFamily
        font.features: { "tnum": 1 }
        text: root.value
        font.pixelSize: 13
        color: Theme.text
        Layout.preferredWidth: 24
        horizontalAlignment: Text.AlignRight
    }
}
