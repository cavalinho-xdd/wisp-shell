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
    // In a voice call and nothing more important to show (Island lanes).
    readonly property bool voice: Island.current === "discord"

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

        // Discord call: how long, and the system mic state (Discord's own
        // mute is not readable, see core/Discord.qml).
        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.voice
            text: "󰙯"
            color: Theme.blurple
            font.family: Theme.fontIcon
            font.pixelSize: Theme.textMono
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.voice
            // Fixed width per length: the digits of the mono font are all
            // as wide as a zero, so the island does not twitch every second.
            width: voiceDigits.width
            text: Discord.elapsedText
            color: Theme.islandMuted
            font: voiceDigits.font
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.voice && Discord.micMuted
            text: "󰍭"
            color: Theme.red
            font.family: Theme.fontIcon
            font.pixelSize: Theme.textMono
        }
    }

    TextMetrics {
        id: voiceDigits
        text: Discord.elapsedText.replace(/\d/g, "0")
        font.family: Theme.fontMono
        font.pixelSize: Theme.textMonoSmall
    }
}
