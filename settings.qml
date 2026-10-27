//@ pragma UseQApplication
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "core"
import "components"

// Standalone settings app — third entry point next to shell.qml / wallpaper.qml.
// Launch with `qs -p settings.qml` (the dashboard gear does exactly that).
// Layout (variant D of docs/decisions/Wisp — směry nastavení.html): one
// surface, a sidebar with the pages and About at its foot, and on the right a
// header with the page title over the scrollable page.
ShellRoot {
    FloatingWindow {
        id: win
        title: "Wisp Settings"
        implicitWidth: 860
        implicitHeight: 600
        color: Theme.smoke

        property int currentPage: 0

        Component.onCompleted: {
            // Float future Wisp toplevels (settings is the only one). Pushed at
            // runtime so the very first open may still tile; every open after floats.
            Quickshell.execDetached(["hyprctl", "eval",
                'hl.window_rule({ match = { class = "^org\\\\.quickshell$" }, float = true, size = {860, 600} })'])
        }
        // The last page (About) sits apart at the foot of the sidebar.
        readonly property var pages: [
            { name: "Hyprland", icon: "󰉼", component: "SettingsPageHypr.qml",
              sub: "Written to general.lua and animations.lua; Hyprland reloads straight away." },
            { name: "Colors", icon: "󰸌", component: "SettingsPageColors.qml",
              sub: "Colours taken from the wallpaper, and the wallpaper itself." },
            { name: "Monitors", icon: "󰹑", component: "SettingsPageMonitors.qml",
              sub: "Where the shell shows, refresh rate and scale." },
            { name: "Keybinds", icon: "󰌌", component: "SettingsPageKeybinds.qml",
              sub: "Your own shortcuts on top of the defaults." },
            { name: "Shell", icon: "󰍜", component: "SettingsPageShell.qml",
              sub: "The islands at the top of every screen." },
            { name: "Notifications", icon: "󰂚", component: "SettingsPageNotifications.qml",
              sub: "History keeps the last 7 days, up to 200." },
            { name: "Advanced", icon: "󰒓", component: "SettingsPageAdvanced.qml",
              sub: "The config file, the welcome wizard and Hyprland sync." },
            { name: "About", icon: "󰋽", component: "SettingsPageAbout.qml",
              sub: "Version and system." }
        ]

        component NavItem: Rectangle {
            id: item
            required property int page
            readonly property bool active: win.currentPage === page

            Layout.fillWidth: true
            Layout.preferredHeight: Theme.settingsNavRow
            radius: Theme.radiusRow
            color: navMa.containsMouse && !active ? Theme.hover : "transparent"
            Behavior on color { ColorAnimation { duration: Theme.animFast } }
            scale: navMa.pressed ? Theme.pressScale : 1
            Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easeSpring } }

            // The selected page is lit by the ember from its left edge.
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                opacity: item.active ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: Qt.tint(Theme.ashHi, Qt.alpha(Theme.ember, 0.12)) }
                    GradientStop { position: 1; color: Theme.ash }
                }
            }

            Row {
                anchors.left: parent.left
                anchors.leftMargin: Theme.spaceSm + 2
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.spaceSm + 2
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: win.pages[item.page].icon
                    font.family: Theme.fontIcon
                    font.pixelSize: Theme.textBody
                    color: item.active ? Theme.ember : Theme.islandMuted
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: win.pages[item.page].name
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.textCaption
                    font.weight: item.active ? Font.Medium : Font.Normal
                    color: item.active || navMa.containsMouse ? Theme.islandText : Theme.islandMuted
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                }
            }

            MouseArea {
                id: navMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: win.currentPage = item.page
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: Theme.spaceSm + 2
            spacing: Theme.spaceMd

            // ── Sidebar ──
            ColumnLayout {
                Layout.preferredWidth: Theme.settingsNavWidth
                Layout.fillHeight: true
                spacing: 2

                Row {
                    Layout.leftMargin: Theme.spaceSm + 2
                    Layout.topMargin: Theme.spaceXs
                    Layout.bottomMargin: Theme.spaceMd
                    spacing: Theme.spaceSm
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: Theme.emberSize
                        height: Theme.emberSize
                        radius: Theme.emberSize / 2
                        color: Theme.ember
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Wisp"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.textTitle
                        font.weight: Font.DemiBold
                        color: Theme.islandText
                    }
                }

                Repeater {
                    model: win.pages.length - 1
                    delegate: NavItem {
                        required property int index
                        page: index
                    }
                }

                Item { Layout.fillHeight: true }

                NavItem { page: win.pages.length - 1 }
            }

            // ── Page ──
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Theme.spaceSm

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: Theme.spaceXs
                    spacing: Theme.spaceMd

                    Column {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            width: parent.width
                            text: win.pages[win.currentPage].name
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.textHeading
                            font.weight: Font.DemiBold
                            color: Theme.islandText
                            elide: Text.ElideRight
                        }
                        Text {
                            width: parent.width
                            text: win.pages[win.currentPage].sub
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.textCaption
                            color: Theme.islandMuted
                            elide: Text.ElideRight
                        }
                    }

                    Rectangle {
                        Layout.alignment: Qt.AlignTop
                        Layout.preferredWidth: Theme.controlSize - 6
                        Layout.preferredHeight: Theme.controlSize - 6
                        radius: height / 2
                        color: closeMa.containsMouse ? Theme.hover : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                        scale: closeMa.pressed ? 0.9 : 1.0
                        Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easeSpring } }
                        Text {
                            anchors.centerIn: parent
                            text: "󰅖"
                            font.family: Theme.fontIcon
                            font.pixelSize: Theme.textBody
                            color: closeMa.containsMouse ? Theme.islandText : Theme.islandMuted
                            Behavior on color { ColorAnimation { duration: Theme.animFast } }
                        }
                        MouseArea {
                            id: closeMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Qt.quit()
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

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
