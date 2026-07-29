import QtQuick
import QtQuick.Effects
import "../core"

// Compact "dynamic island" game-session presence for the collapsed bar, fed by
// the Games singleton (core/Games.qml -> scripts/game_watch.sh).
//
// Sits directly under notifications in Island arbitration: a running game is
// the longest-lived thing the user is actually inside, so it holds the strip
// over osu, media and Discord for the whole session.
//
// Two faces, swapped on Games.flashing, exactly like IslandOsuStrip's
// idle/gameplay pair:
//   session     — cover art, title, elapsed time, achievement progress
//   achievement — icon, "Achievement unlocked", its name, new progress
// The achievement face is a face and not its own Island lane on purpose: an
// unlock is a moment *inside* the session, so it must not have to win
// arbitration against the game it belongs to.
//
// No hover controls. Every other strip's buttons drive something real
// (Discord's own shortcuts, MPRIS transport); a game exposes no local control
// surface worth pretending about, so this lane is deliberately read-only —
// clicking only dismisses an achievement flash early.
Item {
    id: root

    readonly property bool active: Island.current === "game"
    readonly property bool flashing: Games.flashing

    implicitWidth: active ? strip.implicitWidth : 0
    implicitHeight: 48

    opacity: active ? 1 : 0
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

        // ── Art badge ──
        // Portrait cover when one resolved (Steam's CDN serves 600x900 for
        // every app unauthenticated), falling back to the launcher glyph when
        // it hasn't loaded or the launcher has no art source at all.
        Item {
            width: 30
            height: 40
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                id: artFrame
                anchors.fill: parent
                radius: 7
                color: root.flashing
                    ? Qt.rgba(Theme.yellow.r, Theme.yellow.g, Theme.yellow.b, 0.18)
                    : Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.16)
                border.width: 1
                border.color: root.flashing ? Theme.yellow : Theme.primary
                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                Behavior on border.color { ColorAnimation { duration: Theme.animFast } }
                clip: true

                Image {
                    id: cover
                    anchors.fill: parent
                    // Remote https source, same as IslandOsuStrip's avatar —
                    // no download step, Qt's network stack handles it.
                    source: root.flashing ? (Games.flashAchievement?.icon ?? "") : Games.coverUrl
                    fillMode: root.flashing ? Image.PreserveAspectFit : Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    visible: status === Image.Ready
                    opacity: status === Image.Ready ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 220 } }
                }

                // Launcher glyph — also the permanent face for anything with
                // no art (Heroic without a SteamGridDB key, gamemode catches).
                Text {
                    anchors.centerIn: parent
                    visible: cover.status !== Image.Ready
                    text: root.flashing ? "󰔸"                       // md-trophy
                        : Games.source === "steam" ? "󰓓"            // md-steam
                        : "󰊗"                                       // md-gamepad_variant
                    font.family: Theme.fontIcon
                    font.pixelSize: 16
                    color: root.flashing ? Theme.yellow : Theme.primary
                }
            }
        }

        // ── Label column ──
        // Fixed width so neither face resizes the strip under the cursor and
        // the two crossfade in place; the pill's own growth for the wider
        // achievement face is Island.activeWidth's job.
        Item {
            width: root.flashing ? 300 : 200
            height: 38
            anchors.verticalCenter: parent.verticalCenter
            Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

            // ── Face 1: the session ──
            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                spacing: 2
                opacity: root.flashing ? 0 : 1
                visible: opacity > 0.01
                Behavior on opacity { NumberAnimation { duration: 200 } }

                Text {
                    width: parent.width
                    font.family: Theme.fontFamily
                    text: Games.name
                    color: Theme.text
                    font.pixelSize: 12
                    font.bold: true
                    elide: Text.ElideRight
                }

                Row {
                    spacing: 8

                    // Playing dot — slow breathing pulse, the only motion in
                    // the session face.
                    Rectangle {
                        width: 6
                        height: 6
                        radius: 3
                        color: Theme.green
                        anchors.verticalCenter: parent.verticalCenter

                        SequentialAnimation on opacity {
                            running: root.active && !root.flashing
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.3; duration: 1100; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 1.0; duration: 1100; easing.type: Easing.InOutSine }
                        }
                    }

                    Text {
                        font.family: Theme.fontFamily
                        text: Games.elapsedText
                        color: Theme.subtext0
                        font.pixelSize: 10
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    // Achievement progress. Absent rather than zeroed when
                    // there is no key or the game has no achievements — a
                    // permanent "0/0" is the same lie as the GPU ring's
                    // permanent 0% on non-Nvidia hardware.
                    Row {
                        spacing: 4
                        visible: Games.hasAchievements
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            text: "󰔸"
                            font.family: Theme.fontIcon
                            font.pixelSize: 10
                            color: Theme.yellow
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            font.family: Theme.fontFamily
                            text: Games.unlocked + "/" + Games.total
                            color: Theme.subtext0
                            font.pixelSize: 10
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }

            // ── Face 2: achievement unlocked ──
            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                // Tighter than the session face's 2: this face stacks three
                // lines into the same 48px capsule, and at spacing 2 the
                // description crowded the pill's bottom edge.
                spacing: 1
                opacity: root.flashing ? 1 : 0
                visible: opacity > 0.01
                Behavior on opacity { NumberAnimation { duration: 200 } }
                // Rises into place rather than appearing — the unlock is the
                // one genuinely eventful thing this lane ever shows.
                transform: Translate {
                    y: root.flashing ? 0 : 6
                    Behavior on y { NumberAnimation { duration: 320; easing.type: Theme.easeSpring; easing.overshoot: 1.4 } }
                }

                Row {
                    spacing: 6

                    Text {
                        font.family: Theme.fontFamily
                        text: "ACHIEVEMENT UNLOCKED"
                        color: Theme.yellow
                        font.pixelSize: 9
                        font.bold: true
                        font.letterSpacing: 0.8
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        font.family: Theme.fontFamily
                        text: Games.unlocked + "/" + Games.total
                        color: Theme.subtext0
                        font.pixelSize: 9
                        visible: Games.hasAchievements
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Text {
                    width: parent.width
                    font.family: Theme.fontFamily
                    text: Games.flashAchievement?.name ?? ""
                    color: Theme.text
                    font.pixelSize: 12
                    font.bold: true
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    font.family: Theme.fontFamily
                    text: Games.flashAchievement?.description ?? ""
                    color: Theme.subtext0
                    font.pixelSize: 9
                    elide: Text.ElideRight
                    visible: text.length > 0
                }
            }

            // Click anywhere on the label column dismisses an achievement
            // early; disabled otherwise so the session face stays inert and
            // clicks fall through to the pill's own expand handler.
            MouseArea {
                anchors.fill: parent
                enabled: root.flashing
                cursorShape: root.flashing ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: Games.dismissFlash()
            }
        }

        // ── Launcher badge ──
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Games.sourceLabel
            font.family: Theme.fontFamily
            font.pixelSize: 9
            font.bold: true
            color: Theme.subtext0
            opacity: root.flashing ? 0 : 0.8
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }
    }
}
