import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../core"
import "ember"

Item {
    id: root
    
    property string hyprVer: ""
    property string qsVer: ""
    property string osName: ""

    // `hyprctl version` opens with "Hyprland 0.56.2 built from branch …"
    Process {
        command: ["bash", "-c", "hyprctl version | head -1 | awk '{print $2}'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.hyprVer = this.text.trim()
        }
    }

    Process {
        command: ["bash", "-c", "qs --version | head -1 | awk '{print $2}'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.qsVer = this.text.trim()
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
        anchors.verticalCenterOffset: -16
        spacing: 0

        // The ember is the mark.
        EmberDot {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Theme.controlSize - Theme.spaceSm
            Layout.preferredHeight: Theme.controlSize - Theme.spaceSm
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 28
            font.family: Theme.fontFamily
            text: "Wisp Shell"
            font.pixelSize: 30
            font.bold: true
            font.letterSpacing: -0.5
            color: Theme.islandText
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 6
            font.family: Theme.fontFamily
            text: "A dynamic-island desktop shell for Hyprland"
            font.pixelSize: 14
            color: Theme.islandMuted
        }

        // What it runs on: one strip, split by hairlines, label over value
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 32
            Layout.preferredWidth: 480
            Layout.preferredHeight: 66
            radius: 16
            color: Theme.ash

            Row {
                anchors.fill: parent
                Repeater {
                    model: [
                        { lbl: "Toolkit", val: root.qsVer ? "Quickshell " + root.qsVer : "…" },
                        { lbl: "Compositor", val: root.hyprVer ? "Hyprland " + root.hyprVer : "…" },
                        { lbl: "System", val: root.osName || "…" }
                    ]
                    delegate: Item {
                        required property var modelData
                        required property int index
                        width: parent.width / 3
                        height: parent.height

                        Rectangle {
                            visible: parent.index > 0
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            width: 1; height: 30
                            color: Qt.alpha(Theme.islandText, 0.08)
                        }
                        Column {
                            anchors.centerIn: parent
                            spacing: 3
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.lbl
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                color: Theme.islandMuted
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.val
                                font.family: Theme.fontFamily
                                font.features: { "tnum": 1 }
                                font.pixelSize: 13
                                font.weight: Font.Medium
                                color: Theme.islandText
                            }
                        }
                    }
                }
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 32
            font.family: Theme.fontFamily
            text: "Made by Jakub Muzik"
            font.pixelSize: 13
            color: Theme.islandText
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 4
            font.family: Theme.fontFamily
            text: "Inspired by illogical-impulse, caelestia-dots & illyamiro"
            font.pixelSize: 12
            color: Theme.islandMuted
        }

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 20
            Layout.preferredWidth: ghRow.implicitWidth + 36
            Layout.preferredHeight: 36
            radius: 18
            color: ghMa.containsMouse ? Theme.hover : Theme.ashHi
            Behavior on color { ColorAnimation { duration: Theme.animFast } }
            scale: ghMa.pressed ? 0.96 : 1.0
            Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easeSpring } }

            Row {
                id: ghRow
                anchors.centerIn: parent
                spacing: 8
                Text {
                    text: "󰊤"
                    font.family: Theme.fontIcon; font.pixelSize: 14; color: Theme.islandText
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: "cavalinho-xdd/wisp-shell"
                    font.family: Theme.fontFamily; font.pixelSize: 13; font.weight: Font.Medium; color: Theme.islandText
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
