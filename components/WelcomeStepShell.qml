import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../core"

// Welcome wizard step 4 — the handful of shell.* settings a new user actually
// wants on day one. Same fields and controls as SettingsPageShell.qml plus the
// monitor restriction from SettingsPageMonitors.qml, which matters more here
// than anywhere else: a multi-monitor machine shows a pill on every screen by
// default, and this is the moment to say "just this one".
ColumnLayout {
    id: step
    // Sized against the StackLayout explicitly — see WelcomeStepIntro for why
    // Layout.fillWidth cannot be used here.
    Layout.preferredWidth: parent.width
    Layout.preferredHeight: parent.height
    spacing: 10

    property var monitors: []
    Process {
        id: monProc
        command: ["hyprctl", "monitors", "-j"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try { step.monitors = JSON.parse(this.text.trim()); } catch (e) {}
            }
        }
    }

    CfgSection {
        title: "Collapsed bar"
        icon: "󰍜"

        CfgSwitch {
            icon: "󰥔"
            text: "12-hour clock"
            hint: "Off = 24-hour"
            checked: Settings.conf.shell.clock12h
            onToggled: value => Settings.conf.shell.clock12h = value
        }
        CfgSpin {
            icon: "󱂬"
            text: "Workspace dots"
            value: Settings.conf.shell.workspaceCount
            from: 1
            to: 10
            onEdited: v => Settings.conf.shell.workspaceCount = v
        }
    }

    CfgSection {
        title: "Widgets"
        icon: "󰕮"

        CfgSwitch {
            icon: "󰖐"
            text: "Weather card"
            hint: "Auto-locates via IP, no API key needed"
            checked: Settings.conf.weather.enable
            onToggled: value => Settings.conf.weather.enable = value
        }
    }

    // ── Which monitor ──
    CfgSection {
        visible: step.monitors.length > 1
        title: "Show wisp on"
        icon: "󰍹"

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 12
            spacing: 8

            Rectangle {
                id: allChip
                readonly property bool active: Settings.conf.shell.pillMonitor === ""
                Layout.preferredHeight: 32
                Layout.preferredWidth: allRow.implicitWidth + 24
                radius: 12
                color: active ? Theme.primary : Theme.surface0
                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                Row {
                    id: allRow
                    anchors.centerIn: parent
                    spacing: 6
                    Text { text: "󰕮"; font.family: Theme.fontIcon; font.pixelSize: 12; color: allChip.active ? Theme.colorOnPrimary : Theme.subtext0; anchors.verticalCenter: parent.verticalCenter }
                    Text {
                        font.family: Theme.fontFamily; text: "All monitors"; font.pixelSize: 12; font.bold: allChip.active; color: allChip.active ? Theme.colorOnPrimary : Theme.text; anchors.verticalCenter: parent.verticalCenter }
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Settings.conf.shell.pillMonitor = "" }
            }

            Repeater {
                model: step.monitors
                delegate: Rectangle {
                    id: monChip
                    required property var modelData
                    readonly property bool active: Settings.conf.shell.pillMonitor === modelData.name
                    Layout.preferredHeight: 32
                    Layout.preferredWidth: monRow.implicitWidth + 24
                    radius: 12
                    color: active ? Theme.primary : Theme.surface0
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    Row {
                        id: monRow
                        anchors.centerIn: parent
                        spacing: 6
                        Text { text: "󰍹"; font.family: Theme.fontIcon; font.pixelSize: 12; color: monChip.active ? Theme.colorOnPrimary : Theme.subtext0; anchors.verticalCenter: parent.verticalCenter }
                        Text {
                            font.family: Theme.fontFamily; text: monChip.modelData.name; font.pixelSize: 12; font.bold: monChip.active; color: monChip.active ? Theme.colorOnPrimary : Theme.text; anchors.verticalCenter: parent.verticalCenter }
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Settings.conf.shell.pillMonitor = monChip.modelData.name }
                }
            }
            Item { Layout.fillWidth: true }
        }
    }

    Item { Layout.fillHeight: true }
}
