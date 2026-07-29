import QtQuick
import "../core"

// Compact "dynamic island" Discord voice presence for the collapsed bar,
// fed by the Discord singleton (core/Discord.qml -> Pipewire capture node).
// Lowest-priority lane: Island.current only ever resolves to "discord" once
// notifications, osu and media are all quiet, so this is the strip you see
// when nothing else is happening but you're sitting in a call.
//
// Deliberately minimal — server/channel name is not obtainable from a Vesktop
// client (see core/Discord.qml for why), so it shows what is actually known:
// connected, for how long, and the mic state.
Item {
    id: root

    readonly property bool active: Island.current === "discord"

    implicitWidth: active ? strip.implicitWidth : 0
    implicitHeight: 48

    opacity: active ? 1 : 0
    // Whole-capsule hover invite, same as the media strip
    scale: active ? (hover.hovered ? 1.035 : 1.0) : 0.7
    visible: opacity > 0.01
    Behavior on opacity { NumberAnimation { duration: 250 } }
    Behavior on scale { NumberAnimation { duration: 220; easing.type: Theme.easeSpring; easing.overshoot: 1.3 } }
    Behavior on implicitWidth { NumberAnimation { duration: 420; easing.type: Easing.OutBack; easing.overshoot: 1.05 } }

    HoverHandler { id: hover }

    Row {
        id: strip
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        // ── Brand badge ──
        Rectangle {
            width: 30
            height: 30
            radius: 15
            anchors.verticalCenter: parent.verticalCenter
            color: Qt.rgba(Theme.blurple.r, Theme.blurple.g, Theme.blurple.b, 0.18)
            border.color: Theme.blurple
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "󰙯"
                font.family: Theme.fontIcon
                font.pixelSize: 16
                color: Theme.blurple
            }
        }

        // ── Label + elapsed, crossfading to controls on hover ──
        // Fixed width so the pill does not resize under the cursor: the
        // controls row is narrower than the label, and letting the strip
        // breathe on hover would make the whole pill twitch.
        Item {
            width: 124
            height: 34
            anchors.verticalCenter: parent.verticalCenter

            Column {
                anchors.centerIn: parent
                width: parent.width
                spacing: 1
                opacity: hover.hovered ? 0 : 1
                visible: opacity > 0.01
                Behavior on opacity { NumberAnimation { duration: 180 } }

                Row {
                    spacing: 6

                    // Live dot — slow breathing pulse, the only motion in the strip
                    Rectangle {
                        id: liveDot
                        width: 6
                        height: 6
                        radius: 3
                        color: Theme.green
                        anchors.verticalCenter: parent.verticalCenter

                        SequentialAnimation on opacity {
                            running: root.active
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.3; duration: 900; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 1.0; duration: 900; easing.type: Easing.InOutSine }
                        }
                    }

                    Text {
                        font.family: Theme.fontFamily
                        text: "Voice connected"
                        color: Theme.text
                        font.pixelSize: 12
                        font.bold: true
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Text {
                    font.family: Theme.fontFamily
                    text: Discord.elapsedText
                    color: Theme.subtext0
                    font.pixelSize: 10
                }
            }

            // Hover controls — same pseudo-staggered spring pop as the media
            // strip's transport row.
            Row {
                anchors.centerIn: parent
                spacing: 16
                opacity: hover.hovered ? 1 : 0
                visible: opacity > 0.01
                Behavior on opacity { NumberAnimation { duration: 180 } }

                Repeater {
                    // `enabled` is whether a shortcut is configured at all —
                    // Discord ships defaults for mute and deafen but none for
                    // disconnect, so an unbound leave button dims rather than
                    // silently doing nothing (Settings.conf.discord).
                    model: [
                        { on: Discord.selfMuted,
                          glyphOn: "󰍭", glyphOff: "󰍬",
                          spec: Settings.conf.discord.muteKey,
                          action: () => Discord.toggleMute() },
                        { on: Discord.selfDeafened,
                          glyphOn: "󰟎", glyphOff: "󰋋",
                          spec: Settings.conf.discord.deafenKey,
                          action: () => Discord.toggleDeafen() },
                        { on: false,
                          glyphOn: "󰏵", glyphOff: "󰏵",
                          spec: Settings.conf.discord.leaveKey,
                          action: () => Discord.leave() }
                    ]
                    delegate: Text {
                        required property var modelData
                        required property int index
                        readonly property bool isLeave: index === 2
                        readonly property bool usable: !!modelData.spec

                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.on ? modelData.glyphOn : modelData.glyphOff
                        font.family: Theme.fontIcon
                        font.pixelSize: 15
                        opacity: usable ? 1 : 0.32
                        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                        // Leave is the destructive one — red on hover, not the
                        // accent every other control uses.
                        color: (ctlMouse.containsMouse && usable)
                                 ? (isLeave ? Theme.red : Theme.primary)
                             : modelData.on ? Theme.red
                             : Theme.text
                        Behavior on color { ColorAnimation { duration: 120 } }

                        scale: hover.hovered ? (ctlMouse.pressed && usable ? 0.85 : 1) : 0.3
                        Behavior on scale {
                            NumberAnimation {
                                duration: 280 + index * 70
                                easing.type: Theme.easeSpring
                                easing.overshoot: 1.6
                            }
                        }

                        MouseArea {
                            id: ctlMouse
                            anchors.centerIn: parent
                            width: parent.width + 14
                            height: 34
                            hoverEnabled: true
                            enabled: parent.usable
                            cursorShape: Qt.PointingHandCursor
                            onClicked: modelData.action()
                        }
                    }
                }
            }
        }

        // ── Status icon — mic, or headphones once deafened ──
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Discord.selfDeafened ? "󰟎" : (Discord.selfMuted || Discord.micMuted) ? "󰍭" : "󰍬"
            font.family: Theme.fontIcon
            font.pixelSize: 15
            color: (Discord.selfDeafened || Discord.selfMuted || Discord.micMuted) ? Theme.red : Theme.subtext0
            Behavior on color { ColorAnimation { duration: Theme.animFast } }
        }
    }
}
