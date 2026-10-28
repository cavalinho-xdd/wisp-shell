import QtQuick
import QtQuick.Layouts
import "../core"

CfgPage {
    // Read-only line in a card: a label and its value on the right.
    component InfoRow: RowLayout {
        property string text: ""
        property string value: ""
        Layout.fillWidth: true
        Layout.preferredHeight: 40
        Layout.leftMargin: 12
        Layout.rightMargin: 12
        Text {
            Layout.fillWidth: true
            text: parent.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.textCaption
            color: Theme.islandText
        }
        Text {
            text: parent.value
            font.family: Theme.fontFamily
            font.pixelSize: Theme.textMonoSmall
            color: Theme.islandMuted
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.spaceSm

        CfgTile {
            icon: "󰜺"
            text: "Reduce motion"
            checked: Settings.conf.shell.reduceMotion
            onToggled: value => Settings.conf.shell.reduceMotion = value
        }
        CfgTile {
            icon: "󰖐"
            text: "Weather"
            checked: Settings.conf.weather.enable
            onToggled: value => Settings.conf.weather.enable = value
        }
    }

    CfgGrid {
        CfgSection {
            Layout.columnSpan: 2
            title: "Islands"

            CfgChoice {
                text: "Material"
                value: Settings.conf.shell.material
                options: [
                    { value: "solid", label: "Solid" },
                    { value: "tinted", label: "Tinted glass" },
                    { value: "smoked", label: "Smoked glass" }
                ]
                onEdited: v => Settings.conf.shell.material = v
            }
            CfgChoice {
                text: "Glow"
                value: Settings.conf.shell.glow
                options: [
                    { value: "soft", label: "Soft" },
                    { value: "medium", label: "Medium" },
                    { value: "strong", label: "Strong" }
                ]
                onEdited: v => Settings.conf.shell.glow = v
            }
            CfgChoice {
                text: "Layout"
                value: Settings.conf.shell.emberLayout
                options: [
                    { value: "spread", label: "Spread" },
                    { value: "cluster", label: "Cluster" },
                    { value: "quarters", label: "Quarters" }
                ]
                onEdited: v => Settings.conf.shell.emberLayout = v
            }
        }

        CfgSection {
            Layout.fillHeight: true
            title: "Bar"

            CfgSpin {
                text: "Workspace dots"
                value: Settings.conf.shell.workspaceCount
                from: 1
                to: 10
                onEdited: v => Settings.conf.shell.workspaceCount = v
            }
            CfgSwitch {
                text: "12-hour clock"
                checked: Settings.conf.shell.clock12h
                onToggled: value => Settings.conf.shell.clock12h = value
            }
        }

        CfgSection {
            Layout.fillHeight: true
            title: "Weather"
            enabled: Settings.conf.weather.enable

            InfoRow { text: "Source"; value: "open-meteo, located by IP" }
            InfoRow { text: "Refresh"; value: "every 15 min" }
        }
    }
}
