import QtQuick
import QtQuick.Layouts
import "../core"

// Label + [−  value  +] stepper row. Modeled on ii-dots ConfigSpinBox.
// Hold an arrow to auto-repeat.
RowLayout {
    id: root
    property string icon: ""
    property string text: ""
    property int value: 0
    property int from: 0
    property int to: 100
    property int stepSize: 1
    signal edited(int v)

    Layout.fillWidth: true
    Layout.leftMargin: 12
    Layout.rightMargin: 12
    spacing: 10

    function bump(dir) {
        const v = Math.max(root.from, Math.min(root.to, root.value + dir * root.stepSize));
        if (v !== root.value) root.edited(v);
    }

    Text {
        text: root.icon
        font.family: Theme.fontIcon
        font.pixelSize: 15
        color: root.enabled ? Theme.text : Theme.subtext0
        visible: root.icon !== ""
    }
    Text {
        font.family: Theme.fontFamily;
        Layout.fillWidth: true
        text: root.text
        font.pixelSize: 13
        color: root.enabled ? Theme.text : Theme.subtext0
    }

    Rectangle {
        Layout.preferredWidth: 108
        Layout.preferredHeight: 30
        radius: 15
        color: Theme.surface0

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 4
            anchors.rightMargin: 4
            spacing: 0

            Item {
                Layout.preferredWidth: 26; Layout.fillHeight: true
                Text {
                    anchors.centerIn: parent
                    text: "󰍴"
                    font.family: Theme.fontIcon; font.pixelSize: 13
                    color: minusMa.containsMouse ? Theme.primary : Theme.subtext0
                    scale: minusMa.pressed ? 0.8 : 1.0
                    Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easeSpring } }
                }
                MouseArea {
                    id: minusMa
                    anchors.fill: parent
                    hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: root.bump(-1)
                    Timer { running: minusMa.pressed; interval: 120; repeat: true; triggeredOnStart: false; onTriggered: root.bump(-1) }
                }
            }

            Text {
                font.family: Theme.fontFamily;
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: root.value
                font.pixelSize: 13; font.bold: true
                color: Theme.text
            }

            Item {
                Layout.preferredWidth: 26; Layout.fillHeight: true
                Text {
                    anchors.centerIn: parent
                    text: "󰐕"
                    font.family: Theme.fontIcon; font.pixelSize: 13
                    color: plusMa.containsMouse ? Theme.primary : Theme.subtext0
                    scale: plusMa.pressed ? 0.8 : 1.0
                    Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easeSpring } }
                }
                MouseArea {
                    id: plusMa
                    anchors.fill: parent
                    hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: root.bump(1)
                    Timer { running: plusMa.pressed; interval: 120; repeat: true; triggeredOnStart: false; onTriggered: root.bump(1) }
                }
            }
        }
    }
}
