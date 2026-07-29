import QtQuick
import QtQuick.Layouts
import Quickshell
import "../core"

CfgPage {
    id: page

    component ActionButton: Rectangle {
        id: btn
        property string icon: ""
        property string text: ""
        property bool danger: false
        signal clicked()

        Layout.fillWidth: true
        Layout.preferredHeight: 40
        radius: 14
        color: btnMa.containsMouse
            ? (btn.danger ? Qt.alpha(Theme.red, 0.15) : Theme.surface0)
            : Theme.surface
        // Danger keeps its outline — that is semantic. Ordinary buttons are
        // borderless, matching components/ActionButton.qml (DESIGN.md §16).
        border.color: Theme.red
        border.width: btn.danger ? 1 : 0
        Behavior on color { ColorAnimation { duration: Theme.animFast } }
        scale: btnMa.pressed ? 0.96 : 1.0
        Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easeSpring } }

        Row {
            anchors.centerIn: parent
            spacing: 8
            Text {
                text: btn.icon
                font.family: Theme.fontIcon; font.pixelSize: 14
                color: btn.danger ? Theme.red : Theme.text
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                font.family: Theme.fontFamily;
                text: btn.text
                font.pixelSize: 13; font.bold: true
                color: btn.danger ? Theme.red : Theme.text
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            id: btnMa
            anchors.fill: parent
            hoverEnabled: true
            onClicked: btn.clicked()
        }
    }

    CfgNotice {
        text: "All options live in " + Settings.configPath + " — edit it directly if you prefer; the shell reloads it on change."
    }

    CfgSection {
        title: "Config file"
        icon: "󰈔"

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 12
            Layout.rightMargin: 12
            spacing: 12

            ActionButton {
                icon: "󰈔"
                text: "Open settings.json"
                onClicked: Quickshell.execDetached(["xdg-open", Settings.configPath])
            }
            ActionButton {
                id: copyBtn
                property bool justCopied: false
                icon: justCopied ? "󰄬" : "󰆏"
                text: justCopied ? "Copied!" : "Copy path"
                onClicked: {
                    Quickshell.execDetached(["bash", "-c", "printf %s '" + Settings.configPath + "' | wl-copy"]);
                    justCopied = true;
                    copyRevert.restart();
                }
                Timer { id: copyRevert; interval: 1500; onTriggered: copyBtn.justCopied = false }
            }
        }
    }

    CfgSection {
        title: "Setup"
        icon: "󱐋"

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 12
            Layout.rightMargin: 12
            spacing: 12

            ActionButton {
                icon: "󱐋"
                text: "Show welcome again"
                onClicked: FirstRun.showAgain()
            }
            Item { Layout.fillWidth: true }
        }
    }

    CfgSection {
        title: "Hyprland config"
        icon: "󰒃"

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 12
            Layout.rightMargin: 12
            spacing: 12

            ActionButton {
                icon: "󰑓"
                text: "Sync sliders from system"
                onClicked: Settings.syncFromSystem()
            }
            ActionButton {
                icon: "󰜉"
                text: "Reload Hyprland"
                onClicked: Settings.reloadHyprland()
            }
        }
    }
}
