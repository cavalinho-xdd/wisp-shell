import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "../core"

Item {
    id: root

    // Bubbles up from the media island strip: expand straight onto the Media tab
    signal expandMedia()
    // From the notification flash: expand onto the Dashboard tab (notif centre)
    signal expandNotifs()

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        spacing: 12

        // Workspaces — live Hyprland state
        Row {
            spacing: 8
            Layout.alignment: Qt.AlignVCenter

            Repeater {
                model: Settings.conf.shell.workspaceCount
                delegate: Rectangle {
                    id: dot
                    readonly property int wsId: index + 1
                    readonly property bool isActive: (Hyprland.focusedWorkspace?.id ?? 1) === wsId
                    readonly property bool occupied: Hyprland.workspaces.values.some(w => w.id === wsId)
                    readonly property bool urgent: Hyprland.workspaces.values.some(w => w.id === wsId && w.urgent)

                    anchors.verticalCenter: parent.verticalCenter
                    width: isActive ? 24 : (urgent ? 16 : 8)
                    height: 8
                    radius: 4
                    color: urgent ? Theme.red
                         : isActive ? Theme.primary
                         : occupied ? Theme.subtext0
                         : Theme.surface0

                    Behavior on width { NumberAnimation { duration: Theme.animSlow; easing.type: Theme.easeSpring } }
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    // Staggered pop-in each time the bar appears
                    opacity: 0
                    scale: 0
                    SequentialAnimation {
                        running: true
                        PauseAnimation { duration: 60 + index * 45 }
                        ParallelAnimation {
                            NumberAnimation { target: dot; property: "scale"; to: 1; duration: 300; easing.type: Theme.easeSpring }
                            NumberAnimation { target: dot; property: "opacity"; to: 1; duration: 180 }
                        }
                    }

                    // Oversized hit area — the dot itself is only 8px
                    MouseArea {
                        anchors.centerIn: parent
                        width: parent.width + 10
                        height: 28
                        // Lua-parser Hyprland: dispatch args are wrapped into hl.dispatch(...),
                        // so the old "workspace N" string form fails silently-ish.
                        onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + dot.wsId + " })")
                    }
                }
            }
        }

        Item { Layout.fillWidth: true } // Spacer

        // Dynamic-island activities — zero-width when idle, twin spacers
        // keep them centered between dots and clock. Island.current
        // arbitrates: the notif flash preempts the media strip.
        IslandMediaStrip {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredHeight: 48
            Layout.preferredWidth: implicitWidth
            onExpandRequested: root.expandMedia()
        }

        IslandOsuStrip {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredHeight: 48
            Layout.preferredWidth: implicitWidth
        }

        IslandDiscordStrip {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredHeight: 48
            Layout.preferredWidth: implicitWidth
        }

        IslandGameStrip {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredHeight: 48
            Layout.preferredWidth: implicitWidth
        }

        IslandNotifFlash {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredHeight: 48
            Layout.preferredWidth: implicitWidth
            onExpandRequested: root.expandNotifs()
        }

        Item { Layout.fillWidth: true } // Spacer

        // Battery — hidden entirely on hardware with no laptop battery
        // (core/Battery.qml gates on isLaptopBattery, not just isPresent),
        // rather than showing a permanent fake 0% like the GPU ring did
        // pre-fix on non-Nvidia machines (see plan.md Scaling Notes).
        Row {
            spacing: 6
            Layout.alignment: Qt.AlignVCenter
            visible: opacity > 0.01
            opacity: Battery.available ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.animFast } }

            Text {
                text: Battery.icon()
                font.family: Theme.fontIcon
                font.pixelSize: 15
                color: Battery.critical ? Theme.red : (Battery.charging ? Theme.green : Theme.subtext0)
                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                anchors.baseline: battPct.baseline
            }
            Text {
                font.family: Theme.fontFamily;
                id: battPct
                text: Math.round(Battery.percentage * 100) + "%"
                color: Theme.text
                font.pixelSize: 13
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // Clock — native SystemClock, no Timer polling
        Row {
            id: clockRow
            spacing: 8
            Layout.alignment: Qt.AlignVCenter

            opacity: 0
            SequentialAnimation {
                running: true
                PauseAnimation { duration: 150 }
                NumberAnimation { target: clockRow; property: "opacity"; to: 1; duration: 250 }
            }

            Text {
                text: "󰥔"
                font.family: Theme.fontIcon
                font.pixelSize: 16
                color: Theme.primary
                // Baseline-align to the time — vertical centering drifts
                // because the glyph's em box differs from the text font's
                anchors.baseline: timeText.baseline
            }
            Text {
                font.family: Theme.fontFamily;
                id: timeText
                text: Qt.formatTime(clock.date, Settings.conf.shell.clock12h ? "hh:mm ap" : "HH:mm")
                color: Theme.text
                font.pixelSize: 15
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
