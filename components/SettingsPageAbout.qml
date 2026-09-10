import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../core"

Item {
    id: root
    
    property string hyprVer: "..."
    property string osName: "..."

    Process {
        command: ["bash", "-c", "hyprctl version | grep -i '^version' | awk '{print $2}'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.hyprVer = this.text.trim()
        }
    }

    Process {
        command: ["bash", "-c", "grep PRETTY_NAME /etc/os-release | cut -d'\"' -f2"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.osName = this.text.trim()
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 16

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
            text: "Wisp Shell"
            font.pixelSize: 28; font.bold: true
            color: Theme.text
        }

        Text {
            font.family: Theme.fontFamily;
            Layout.alignment: Qt.AlignHCenter
            text: "A dynamic-island desktop shell for Hyprland"
            font.pixelSize: 14
            color: Theme.subtext0
            horizontalAlignment: Text.AlignHCenter
        }

        // Info Cards
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 16
            spacing: 16

            Rectangle {
                Layout.preferredWidth: 160
                Layout.preferredHeight: 80
                radius: 12
                color: Theme.surface
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 4
                    Text {
                        text: "󰄛"
                        font.family: Theme.fontIcon
                        font.pixelSize: 20
                        color: Theme.primary
                        Layout.alignment: Qt.AlignHCenter
                    }
                    Text {
                        text: "Quickshell"
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        font.bold: true
                        color: Theme.text
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }

            Rectangle {
                Layout.preferredWidth: 160
                Layout.preferredHeight: 80
                radius: 12
                color: Theme.surface
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 4
                    Text {
                        text: "󰉼"
                        font.family: Theme.fontIcon
                        font.pixelSize: 20
                        color: Theme.primary
                        Layout.alignment: Qt.AlignHCenter
                    }
                    Text {
                        text: "Hyprland " + root.hyprVer
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        font.bold: true
                        color: Theme.text
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }

            Rectangle {
                Layout.preferredWidth: 160
                Layout.preferredHeight: 80
                radius: 12
                color: Theme.surface
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 4
                    Text {
                        text: "󰣇"
                        font.family: Theme.fontIcon
                        font.pixelSize: 20
                        color: Theme.primary
                        Layout.alignment: Qt.AlignHCenter
                    }
                    Text {
                        text: root.osName
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        font.bold: true
                        color: Theme.text
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }
        }

        Text {
            font.family: Theme.fontFamily;
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 24
            text: "Maintained by Jakub Muzik (cavalinho-xdd)"
            font.pixelSize: 13
            color: Theme.text
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            font.family: Theme.fontFamily;
            Layout.alignment: Qt.AlignHCenter
            text: "Inspired by illogical-impulse, caelestia-dots & illyamiro"
            font.pixelSize: 12
            color: Theme.subtext0
            horizontalAlignment: Text.AlignHCenter
        }
        
        // Link Buttons
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 16
            spacing: 12
            
            Rectangle {
                Layout.preferredWidth: 120
                Layout.preferredHeight: 36
                radius: 10
                color: ghMa.containsMouse ? Theme.surface0 : Theme.surface
                border.color: Theme.primary
                border.width: 1
                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                
                Row {
                    anchors.centerIn: parent
                    spacing: 8
                    Text {
                        text: "󰊤"
                        font.family: Theme.fontIcon; font.pixelSize: 14; color: Theme.text
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: "GitHub"
                        font.family: Theme.fontFamily; font.pixelSize: 13; font.bold: true; color: Theme.text
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                MouseArea {
                    id: ghMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Quickshell.execDetached(["xdg-open", "https://github.com/cavalinho-xdd/wisp-shell"])
                }
            }
        }
    }
}
