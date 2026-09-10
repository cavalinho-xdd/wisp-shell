//@ pragma UseQApplication
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "core"
import "components"

// Standalone settings app — third entry point next to shell.qml / wallpaper.qml.
// Launch with `qs -p settings.qml` (the dashboard gear does exactly that).
// Layout modeled on the ii-dots settings app: left navigation rail with a
// "Config file" action on top, scrollable content pages on the right.
ShellRoot {
    FloatingWindow {
        id: win
        title: "Wisp Settings"
        implicitWidth: 860
        implicitHeight: 600
        color: Theme.background

        property int currentPage: 0

        Component.onCompleted: {
            // Float future Wisp toplevels (settings is the only one). Pushed at
            // runtime so the very first open may still tile; every open after floats.
            Quickshell.execDetached(["hyprctl", "eval",
                'hl.window_rule({ match = { class = "^org\\\\.quickshell$" }, float = true, size = {860, 600} })'])
        }
        readonly property var pages: [
            { name: "Hyprland", icon: "󰉼", component: "SettingsPageHypr.qml" },
            { name: "Colors", icon: "󰸌", component: "SettingsPageColors.qml" },
            { name: "Monitors", icon: "󰹑", component: "SettingsPageMonitors.qml" },
            { name: "Keybinds", icon: "󰌌", component: "SettingsPageKeybinds.qml" },
            { name: "Shell", icon: "󰍜", component: "SettingsPageShell.qml" },
            { name: "Advanced", icon: "󰒓", component: "SettingsPageAdvanced.qml" },
            { name: "About", icon: "󰋽", component: "SettingsPageAbout.qml" }
        ]

        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 12

            // ── Navigation rail ──
            ColumnLayout {
                Layout.preferredWidth: 170
                Layout.minimumWidth: 170
                Layout.maximumWidth: 170
                Layout.fillHeight: true
                spacing: 6

                Text {
                    font.family: Theme.fontFamily;
                    Layout.leftMargin: 12
                    Layout.topMargin: 6
                    Layout.bottomMargin: 8
                    text: "Settings"
                    font.pixelSize: 20
                    font.bold: true
                    color: Theme.text
                }

                // "Config file" FAB — open settings.json directly (ii-dots pattern)
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 44
                    radius: 16
                    color: fabMa.containsMouse ? Qt.lighter(Theme.primary, 1.1) : Theme.primary
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    scale: fabMa.pressed ? 0.96 : 1.0
                    Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easeSpring } }

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10
                        Text {
                            text: "󰈔"
                            font.family: Theme.fontIcon; font.pixelSize: 15
                            color: Theme.background
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            font.family: Theme.fontFamily;
                            text: "Config file"
                            font.pixelSize: 13; font.bold: true
                            color: Theme.background
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    MouseArea {
                        id: fabMa
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: Quickshell.execDetached(["xdg-open", Settings.configPath])
                    }
                }

                Item { Layout.preferredHeight: 8 }

                // Nav buttons with a sliding highlight pill
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Rectangle {
                        id: navIndicator
                        width: parent.width
                        height: 40
                        radius: 14
                        color: Theme.surface0
                        y: win.currentPage * 46
                        Behavior on y { NumberAnimation { duration: 320; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
                    }

                    Column {
                        width: parent.width
                        spacing: 6

                        Repeater {
                            model: win.pages
                            delegate: Item {
                                width: parent.width
                                height: 40

                                readonly property bool active: win.currentPage === index

                                Row {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 14
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 10
                                    Text {
                                        text: modelData.icon
                                        font.family: Theme.fontIcon
                                        font.pixelSize: 15
                                        color: active ? Theme.primary : Theme.subtext0
                                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Text {
                                        font.family: Theme.fontFamily;
                                        text: modelData.name
                                        font.pixelSize: 13
                                        font.bold: active
                                        color: active ? Theme.text : Theme.subtext0
                                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: win.currentPage = index
                                }
                            }
                        }
                    }
                }
            }

            // ── Content pane ──
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 20
                color: Theme.surface
                clip: true

                // Close button — floats over the page content, top-right
                Rectangle {
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 10
                    width: 30; height: 30; radius: 15
                    z: 10
                    color: closeMa.containsMouse ? Qt.alpha(Theme.red, 0.2) : Theme.surface0
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    scale: closeMa.pressed ? 0.9 : 1.0
                    Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easeSpring } }
                    Text {
                        anchors.centerIn: parent
                        text: "󰅖"
                        font.family: Theme.fontIcon
                        font.pixelSize: 14
                        color: closeMa.containsMouse ? Theme.red : Theme.subtext0
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    }
                    MouseArea {
                        id: closeMa
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: Qt.quit()
                    }
                }

                Loader {
                    id: pageLoader
                    anchors.fill: parent
                    source: "components/" + win.pages[win.currentPage].component

                    // Fade + rise on page switch
                    opacity: 0
                    onLoaded: pageIn.restart()
                    ParallelAnimation {
                        id: pageIn
                        NumberAnimation { target: pageLoader; property: "opacity"; from: 0; to: 1; duration: 250 }
                        NumberAnimation { target: pageLoader; property: "y"; from: 14; to: 0; duration: 320; easing.type: Easing.OutQuint }
                    }
                }
            }
        }
    }
}
