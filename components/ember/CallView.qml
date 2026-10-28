import QtQuick
import "../../core"

// Open Discord call: how long, then mute, deafen and leave. Discord takes
// them as its own shortcuts (core/Discord.qml); a button without a shortcut
// in Settings.conf.discord is dimmed. Shown by the bubble and by the centre
// island while the call is its first activity.
Item {
    id: root

    property bool lit: false
    // Discord's own state: ours is a guess, the mic is the system's.
    readonly property bool muted: Discord.selfMuted || Discord.micMuted

    signal done()

    implicitWidth: row.implicitWidth + Theme.spaceMd * 2
    implicitHeight: Theme.controlSizeBig + Theme.spaceMd * 2

    Kindle {
        lit: root.lit
        index: 0
        x: Theme.spaceMd
        y: Theme.spaceMd

        Row {
            id: row
            spacing: Theme.spaceSm

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "󰙯"
                color: Theme.blurple
                font.family: Theme.fontIcon
                font.pixelSize: Theme.textTitle
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                rightPadding: Theme.spaceSm
                text: Discord.elapsedText
                color: Theme.islandMuted
                font.family: Theme.fontMono
                font.pixelSize: Theme.textMono
            }

            EmberButton {
                anchors.verticalCenter: parent.verticalCenter
                big: true
                icon: root.muted ? "󰍭" : "󰍬"
                label: root.muted ? "Unmute" : "Mute"
                enabled: !!Settings.conf.discord.muteKey
                onClicked: Discord.toggleMute()
            }

            EmberButton {
                anchors.verticalCenter: parent.verticalCenter
                big: true
                icon: Discord.selfDeafened ? "󰟎" : "󰋋"
                label: Discord.selfDeafened ? "Undeafen" : "Deafen"
                enabled: !!Settings.conf.discord.deafenKey
                onClicked: Discord.toggleDeafen()
            }

            EmberButton {
                anchors.verticalCenter: parent.verticalCenter
                big: true
                icon: "󰏵"
                label: "Leave call"
                enabled: !!Settings.conf.discord.leaveKey
                onClicked: {
                    Discord.leave();
                    root.done();
                }
            }
        }
    }
}
