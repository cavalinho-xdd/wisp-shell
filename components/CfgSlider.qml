import QtQuick
import QtQuick.Layouts
import "../core"
import "ember"

// Label + slider + value readout row for the settings pages.
RowLayout {
    id: root
    property string icon: ""
    property string text: ""
    property int value: 0
    property int maxValue: 30
    // Narrower in a half-width card (CfgGrid).
    property int labelWidth: 140
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
        color: root.enabled ? Theme.islandText : Theme.islandMuted
        Layout.preferredWidth: root.labelWidth
    }
    EmberSlider {
        Layout.fillWidth: true
        label: root.text
        value: root.maxValue > 0 ? root.value / root.maxValue : 0
        onMoved: v => root.edited(Math.round(v * root.maxValue))
    }
    Text {
        font.family: Theme.fontFamily
        font.features: { "tnum": 1 }
        text: root.value
        font.pixelSize: 13
        color: Theme.islandText
        Layout.preferredWidth: 24
        horizontalAlignment: Text.AlignRight
    }
}
