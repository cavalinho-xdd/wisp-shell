import QtQuick
import QtQuick.Layouts
import "../core"

CfgPage {
    ColumnLayout {
        Layout.fillWidth: true
        Layout.topMargin: 40
        spacing: 12

        // Mini collapsed-pill logo
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 140; height: 36; radius: 18
            color: Theme.surface
            Row {
                anchors.centerIn: parent
                spacing: 6
                Repeater {
                    model: 3
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: index === 0 ? 20 : 7
                        height: 7; radius: 4
                        color: index === 0 ? Theme.primary : Theme.subtext0
                    }
                }
            }
        }

        Text {
            font.family: Theme.fontFamily;
            Layout.alignment: Qt.AlignHCenter
            text: "Wisp"
            font.pixelSize: 24; font.bold: true
            color: Theme.text
        }
        Text {
            font.family: Theme.fontFamily;
            Layout.alignment: Qt.AlignHCenter
            text: "A dynamic-island desktop shell for Hyprland,\nbuilt with Quickshell."
            font.pixelSize: 13
            color: Theme.subtext0
            horizontalAlignment: Text.AlignHCenter
        }
        Text {
            font.family: Theme.fontFamily;
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 12
            text: "Inspired by illogical-impulse, caelestia-dots\nand illyamiro's quickshell widgets."
            font.pixelSize: 12
            color: Theme.subtext0
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
