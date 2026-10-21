//@ pragma UseQApplication
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "core"
import "components"

// Standalone settings app — third entry point next to shell.qml / wallpaper.qml.
// Launch with `qs -p settings.qml` (the dashboard gear does exactly that).
// Layout: left navigation rail (pages, "Open config file" at its foot),
// scrollable content pages on the right.
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
            { name: "Notifications", icon: "󰂚", component: "SettingsPageNotifications.qml" },
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
                    font.family: Theme.fontFamily
                    Layout.leftMargin: 12
                    Layout.topMargin: 10
                    Layout.bottomMargin: 14
                    text: "Settings"
                    font.pixelSize: 18
                    font.bold: true
                    color: Theme.text
                }

                // Nav buttons with a sliding highlight pill
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Rectangle {
                        id: navIndicator
                        width: parent.width
                        height: 36
                        radius: 10
                        color: Theme.surface0
                        y: win.currentPage * 38
                        Behavior on y { NumberAnimation { duration: 320; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
                    }

                    Column {
                        width: parent.width
                        spacing: 2

                        Repeater {
                            model: win.pages
                            delegate: Item {
                                width: parent.width
                                height: 36

                                readonly property bool active: win.currentPage === index

                                Row {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 12
                                    Text {
                                        text: modelData.icon
                                        font.family: Theme.fontIcon
                                        font.pixelSize: 15
                                        color: active ? Theme.text : Theme.subtext0
                                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Text {
                                        font.family: Theme.fontFamily
                                        text: modelData.name
                                        font.pixelSize: 13
                                        font.weight: active ? Font.Medium : Font.Normal
                                        color: active || navMa.containsMouse ? Theme.text : Theme.subtext0
                                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }

                                MouseArea {
                                    id: navMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: win.currentPage = index
                                }
                            }
                        }
                    }
                }

                // Open settings.json directly — a secondary action, so it sits
                // at the foot of the rail instead of as a filled button on top
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 12
                        Text {
                            text: "󰈔"
                            font.family: Theme.fontIcon; font.pixelSize: 15
                            color: fabMa.containsMouse ? Theme.text : Theme.subtext0
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            font.family: Theme.fontFamily
                            text: "Open config file"
                            font.pixelSize: 13
                            color: fabMa.containsMouse ? Theme.text : Theme.subtext0
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    MouseArea {
                        id: fabMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Quickshell.execDetached(["xdg-open", Settings.configPath])
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
                    anchors.margins: 12
                    width: 30; height: 30; radius: 15
                    z: 10
                    color: closeMa.containsMouse ? Theme.surface0 : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    scale: closeMa.pressed ? 0.9 : 1.0
                    Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easeSpring } }
                    Text {
                        anchors.centerIn: parent
                        text: "󰅖"
                        font.family: Theme.fontIcon
                        font.pixelSize: 14
                        color: closeMa.containsMouse ? Theme.text : Theme.subtext0
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    }
                    MouseArea {
                        id: closeMa
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: Qt.quit()
                    }
                }

                // Page title, shared by every page
                Text {
                    id: pageTitle
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.topMargin: 22
                    anchors.leftMargin: 36
                    text: win.pages[win.currentPage].name
                    font.family: Theme.fontFamily
                    font.pixelSize: 20
                    font.bold: true
                    color: Theme.text
                }

                Item {
                    anchors.top: pageTitle.bottom
                    anchors.topMargin: 2
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom

                    Loader {
                        id: pageLoader
                        width: parent.width
                        height: parent.height
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
}
