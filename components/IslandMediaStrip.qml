import QtQuick
import QtQuick.Effects
import Quickshell.Services.Mpris
import "../core"

// Compact "dynamic island" media presentation for the collapsed bar:
// spinning album art + marquee title/artist + EQ bars, controls on hover,
// frame-synced progress hairline underneath. Purely presentational —
// all state comes from the Island singleton.
Item {
    id: root

    signal expandRequested()

    readonly property var player: Island.player
    readonly property bool playing: Island.playing
    // Island.current arbitrates against transient activities (notif flash)
    readonly property bool active: Island.current === "media"
    readonly property string artUrl: player && player.trackArtUrl
        ? (player.trackArtUrl.startsWith("/") ? "file://" + player.trackArtUrl : player.trackArtUrl)
        : ""

    implicitWidth: active ? strip.implicitWidth : 0
    implicitHeight: 48

    opacity: active ? 1 : 0
    // Whole-capsule hover invite (small embiggen) layered onto the active/inactive pop
    scale: active ? (hover.hovered ? 1.035 : 1.0) : 0.7
    visible: opacity > 0.01
    Behavior on opacity { NumberAnimation { duration: 250 } }
    Behavior on scale { NumberAnimation { duration: 220; easing.type: Theme.easeSpring; easing.overshoot: 1.3 } }
    Behavior on implicitWidth { NumberAnimation { duration: 420; easing.type: Easing.OutBack; easing.overshoot: 1.05 } }

    // iOS-style squish on track change: quick inhale, springy settle
    SequentialAnimation {
        id: trackPop
        NumberAnimation { target: strip; property: "scale"; to: 1.1; duration: 90; easing.type: Easing.OutQuad }
        NumberAnimation { target: strip; property: "scale"; to: 1.0; duration: 380; easing.type: Easing.OutBack; easing.overshoot: 2.2 }
    }
    Connections {
        target: root.player
        function onTrackTitleChanged() { if (root.active) trackPop.restart() }
    }

    // Mpris only emits position on demand — poke it every render frame, so
    // the progress hairline advances at the compositor's full refresh rate.
    // Gated on the hairline actually being visible (livestreams hide it).
    FrameAnimation {
        running: root.playing && root.visible && progressTrack.visible
        onTriggered: root.player.positionChanged()
    }

    HoverHandler { id: hover }

    // Whole-strip click opens the dashboard on the Media tab; sits under
    // the control buttons so those still win on hover.
    MouseArea {
        anchors.fill: parent
        onClicked: root.expandRequested()
    }

    Row {
        id: strip
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10
        transformOrigin: Item.Center

        // ── Spinning album art ──
        Item {
            width: 30
            height: 30
            anchors.verticalCenter: parent.verticalCenter

            // Accent ring, breathes with playback state
            Rectangle {
                anchors.fill: parent
                anchors.margins: -3
                radius: width / 2
                color: "transparent"
                border.color: root.playing ? Theme.primary : Theme.surface0
                border.width: root.playing ? 2 : 1
                Behavior on border.color { ColorAnimation { duration: 400 } }
            }

            Image {
                id: art
                anchors.fill: parent
                source: root.artUrl
                fillMode: Image.PreserveAspectCrop
                visible: false
                asynchronous: true
            }

            MultiEffect {
                id: artMasked
                anchors.fill: art
                source: art
                maskEnabled: true
                visible: art.status === Image.Ready
                // NOTE: do NOT add shadowEnabled/shadow* here — confirmed via
                // isolated probe that MultiEffect's mask silently breaks (art
                // renders square, not circular) the moment shadowEnabled is
                // true alongside maskEnabled, on this Qt/Quickshell build.
                // Tried it for a "subtle depth" look; reverted — not worth a
                // second unmasked MultiEffect layer just for a drop shadow.
                maskSource: ShaderEffectSource {
                    sourceItem: Rectangle { width: 30; height: 30; radius: 15 }
                }
                // Vinyl spin — pauses in place instead of resetting
                RotationAnimation on rotation {
                    from: 0; to: 360
                    duration: 9000
                    loops: Animation.Infinite
                    running: true
                    paused: !root.playing || !root.visible
                }
            }

            // Fallback: own-drawn disc + plain note. The disc-in-glyph icon
            // (󰎆) draws off-center inside its em box and can't be centered
            // reliably; a Rectangle we control centers exactly. The note's
            // 1px ink offset is compensated by hand (verified via
            // test_glyph.qml crosshair probe).
            Rectangle {
                anchors.centerIn: parent
                width: 30
                height: 30
                radius: 15
                color: Theme.surface0
                visible: art.status !== Image.Ready

                Text {
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: -0.5
                    anchors.verticalCenterOffset: -1
                    text: "󰎈"
                    font.family: Theme.fontIcon
                    font.pixelSize: 13
                    color: Theme.text
                }
            }
        }

        // ── Title/artist marquee ⟷ hover controls (crossfade) ──
        Item {
            id: centerArea
            width: 150
            height: 34
            anchors.verticalCenter: parent.verticalCenter

            Item {
                id: titleClip
                anchors.fill: parent
                clip: true
                opacity: hover.hovered ? 0 : 1
                scale: hover.hovered ? 0.9 : 1
                Behavior on opacity { NumberAnimation { duration: 180 } }
                Behavior on scale { NumberAnimation { duration: 250; easing.type: Theme.easeSpring } }

                Column {
                    id: titleCol
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1
                    // Slide-in animates this, not y — a y animation fights the anchor
                    transform: Translate { id: titleShift }

                    Text {
                        font.family: Theme.fontFamily;
                        id: titleText
                        text: root.player ? (root.player.trackTitle || "Unknown") : ""
                        color: Theme.text
                        font.pixelSize: 12
                        font.bold: true

                        // New track: slide up into place
                        onTextChanged: { x = 0; slideIn.restart() }
                        ParallelAnimation {
                            id: slideIn
                            NumberAnimation { target: titleShift; property: "y"; from: 10; to: 0; duration: 350; easing.type: Easing.OutQuint }
                            NumberAnimation { target: titleCol; property: "opacity"; from: 0; to: 1; duration: 300 }
                        }

                        // Marquee only when the title actually overflows
                        SequentialAnimation {
                            running: titleText.implicitWidth > titleClip.width && !hover.hovered && root.active
                            loops: Animation.Infinite
                            onStopped: titleText.x = 0
                            PauseAnimation { duration: 1800 }
                            NumberAnimation {
                                target: titleText; property: "x"
                                to: titleClip.width - titleText.implicitWidth
                                duration: Math.max(600, (titleText.implicitWidth - titleClip.width) * 30)
                                easing.type: Easing.InOutSine
                            }
                            PauseAnimation { duration: 1200 }
                            NumberAnimation { target: titleText; property: "x"; to: 0; duration: 600; easing.type: Easing.InOutQuad }
                        }
                    }

                    Text {
                        font.family: Theme.fontFamily;
                        text: root.player ? (root.player.trackArtist || "") : ""
                        color: Theme.subtext0
                        font.pixelSize: 10
                        width: titleClip.width
                        elide: Text.ElideRight
                        // Empty artist (browser streams) still occupies a line
                        // height and pushes the title off-center — drop it
                        visible: text.length > 0
                    }
                }
            }

            // Hover controls — pseudo-staggered spring pop via per-button durations
            Row {
                anchors.centerIn: parent
                spacing: 14
                opacity: hover.hovered ? 1 : 0
                visible: opacity > 0.01
                Behavior on opacity { NumberAnimation { duration: 180 } }

                Repeater {
                    // `enabled` mirrors the player's own capability flags.
                    // Browsers routinely publish a player with canGoPrevious
                    // false (a single YouTube tab has nothing to go back to),
                    // and calling it anyway logs
                    // `Cannot call previous() ... because canGoPrevious is false`
                    // on every click — a dead button that also spams the log.
                    model: [
                        { glyph: "󰒮",
                          enabled: !!root.player && root.player.canGoPrevious,
                          action: () => root.player && root.player.canGoPrevious && root.player.previous() },
                        { glyph: "",
                          enabled: !!root.player && root.player.canTogglePlaying,
                          action: () => root.player && root.player.canTogglePlaying && root.player.togglePlaying() },
                        { glyph: "󰒭",
                          enabled: !!root.player && root.player.canGoNext,
                          action: () => root.player && root.player.canGoNext && root.player.next() }
                    ]
                    delegate: Text {
                        required property var modelData
                        required property int index
                        anchors.verticalCenter: parent.verticalCenter
                        // Middle button shows live play/pause state
                        text: index === 1 ? (root.playing ? "󰏤" : "󰐊") : modelData.glyph
                        font.family: Theme.fontIcon
                        font.pixelSize: index === 1 ? 18 : 14
                        // Unavailable actions dim rather than vanish — the row
                        // keeps its shape, and the control still reads as one.
                        opacity: modelData.enabled ? 1 : 0.32
                        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                        color: (ctlMouse.containsMouse && modelData.enabled) ? Theme.primary : Theme.text
                        scale: hover.hovered ? (ctlMouse.pressed && modelData.enabled ? 0.85 : 1) : 0.3
                        Behavior on scale {
                            NumberAnimation {
                                duration: 280 + index * 70
                                easing.type: Theme.easeSpring
                                easing.overshoot: 1.6
                            }
                        }
                        Behavior on color { ColorAnimation { duration: 120 } }

                        MouseArea {
                            id: ctlMouse
                            anchors.centerIn: parent
                            width: parent.width + 14
                            height: 34
                            hoverEnabled: true
                            enabled: modelData.enabled
                            cursorShape: Qt.PointingHandCursor
                            onClicked: modelData.action()
                        }
                    }
                }
            }
        }

        // ── EQ bars ──
        Row {
            spacing: 3
            height: 20
            anchors.verticalCenter: parent.verticalCenter

            Repeater {
                model: 4
                delegate: Item {
                    required property int index
                    width: 3
                    height: 20

                    Rectangle {
                        id: eqBar
                        anchors.verticalCenter: parent.verticalCenter
                        width: 3
                        radius: 1.5
                        color: root.playing ? Theme.primary : Theme.surface0
                        height: 3
                        Behavior on color { ColorAnimation { duration: 400 } }

                        SequentialAnimation on height {
                            running: root.playing && root.visible
                            loops: Animation.Infinite
                            onStopped: eqBar.height = 3
                            NumberAnimation { to: [14, 18, 10, 16][index]; duration: 260 + index * 70; easing.type: Easing.InOutQuad }
                            NumberAnimation { to: [6, 4, 8, 5][index]; duration: 300 + index * 50; easing.type: Easing.InOutQuad }
                            NumberAnimation { to: [11, 15, 17, 9][index]; duration: 240 + index * 90; easing.type: Easing.InOutQuad }
                            NumberAnimation { to: [5, 7, 4, 6][index]; duration: 280 + index * 60; easing.type: Easing.InOutQuad }
                        }
                    }
                }
            }
        }
    }

    // ── Frame-synced progress hairline ──
    Rectangle {
        id: progressTrack
        anchors.left: strip.left
        anchors.right: strip.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 4
        height: 2
        radius: 1
        color: Theme.surface0
        // Livestreams report length as int64-max microseconds — treat
        // anything over 24 h as "no meaningful duration" and hide.
        visible: !!root.player && root.player.length > 0 && root.player.length < 86400

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            radius: 1
            color: Theme.primary
            width: parent.width * (root.player && root.player.length > 0
                ? Math.min(1, root.player.position / root.player.length) : 0)
        }
    }
}
