import QtQuick
import Quickshell
import "../../core"

// Collapsed activity island: the ember, the clock and, while media plays,
// the track title. The island takes its width from implicitWidth.
Item {
    id: root

    property bool running: true
    // Centre of the ember, for the island's inner light.
    readonly property point emberCentre: Qt.point(row.x + dot.x + dot.width / 2, height / 2)

    readonly property var player: Island.mediaActive ? Island.player : null

    implicitWidth: row.implicitWidth + Theme.spaceMd * 2
    implicitHeight: Theme.islandHeight

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        x: Theme.spaceMd
        spacing: Theme.spaceSm

        EmberDot {
            id: dot
            anchors.verticalCenter: parent.verticalCenter
            playing: Island.playing
            running: root.running
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatTime(clock.date, Settings.conf.shell.clock12h ? "h:mm ap" : "HH:mm")
            color: Theme.islandText
            font.family: Theme.fontMono
            font.pixelSize: Theme.textMono
            font.weight: Font.Medium
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: !!root.player
            width: Math.min(implicitWidth, Theme.trackMaxWidth)
            text: root.player ? (root.player.trackTitle || root.player.identity || "") : ""
            elide: Text.ElideRight
            color: Theme.islandMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.textCaption
        }
    }
}
