import QtQuick
import QtQuick.Effects
import Quickshell.Services.Mpris
import "../core"

// Compact "dynamic island" media presentation for the collapsed bar:
// rounded album art, title over "artist · player", a progress hairline
// under the text, and always-visible transport controls. Purely
// presentational — all state comes from the Island singleton.
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
    scale: active ? 1.0 : 0.85
    visible: opacity > 0.01
    Behavior on opacity { NumberAnimation { duration: 250 } }
    Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
    Behavior on implicitWidth { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }

    // Mpris only emits position on demand — poke it every render frame, so
    // the progress hairline advances at the compositor's full refresh rate.
    // Gated on the hairline actually being visible (livestreams hide it).
    FrameAnimation {
        running: root.playing && root.visible && progressTrack.visible
        onTriggered: root.player.positionChanged()
    }

    // Whole-strip click opens the dashboard on the Media tab; sits under
    // the control buttons so those still win.
    MouseArea {
        anchors.fill: parent
        onClicked: root.expandRequested()
    }

    Row {
        id: strip
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        // ── Album art ──
        Item {
            width: 32
            height: 32
            anchors.verticalCenter: parent.verticalCenter

            Image {
                id: art
                anchors.fill: parent
                source: root.artUrl
                fillMode: Image.PreserveAspectCrop
                visible: false
                asynchronous: true
            }

            // NOTE: do NOT add shadowEnabled/shadow* here — MultiEffect's mask
            // silently breaks (art renders unmasked) the moment shadowEnabled
            // is true alongside maskEnabled, on this Qt/Quickshell build.
            MultiEffect {
                anchors.fill: art
                source: art
                maskEnabled: true
                visible: art.status === Image.Ready
                maskSource: ShaderEffectSource {
                    sourceItem: Rectangle { width: 32; height: 32; radius: 8 }
                }
            }

            // Fallback tile. The note glyph's 1px ink offset is compensated by
            // hand (verified via test_glyph.qml crosshair probe).
            Rectangle {
                anchors.fill: parent
                radius: 8
                color: Theme.surface0
                visible: art.status !== Image.Ready

                Text {
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: -0.5
                    anchors.verticalCenterOffset: -1
                    text: "󰎈"
                    font.family: Theme.fontIcon
                    font.pixelSize: 14
                    color: Theme.subtext0
                }
            }
        }

        // ── Title, "artist · player", progress ──
        // Fixed width so the pill doesn't resize on every track change.
        Column {
            id: textCol
            width: 168
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1
            // Track change slides this, not y — a y animation fights the anchor
            transform: Translate { id: titleShift }

            Text {
                id: titleText
                width: parent.width
                text: root.player ? (root.player.trackTitle || "Unknown") : ""
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 12
                font.bold: true
                elide: Text.ElideRight

                onTextChanged: slideIn.restart()
                ParallelAnimation {
                    id: slideIn
                    NumberAnimation { target: titleShift; property: "y"; from: 6; to: 0; duration: 350; easing.type: Easing.OutQuint }
                    NumberAnimation { target: textCol; property: "opacity"; from: 0; to: 1; duration: 250 }
                }
            }

            Text {
                width: parent.width
                text: {
                    if (!root.player) return "";
                    const artist = root.player.trackArtist || "";
                    const app = root.player.identity || "";
                    return artist && app ? artist + " · " + app : (artist || app);
                }
                color: Theme.subtext0
                font.family: Theme.fontFamily
                font.pixelSize: 10
                elide: Text.ElideRight
                // An empty line would still take height and push the title off-centre
                visible: text.length > 0
            }

            Item { width: 1; height: 3; visible: progressTrack.visible }

            Rectangle {
                id: progressTrack
                width: parent.width
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

        // ── Transport controls ──
        Row {
            spacing: 4
            anchors.verticalCenter: parent.verticalCenter

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
                delegate: Rectangle {
                    id: ctl
                    required property var modelData
                    required property int index
                    readonly property bool isPlay: index === 1

                    anchors.verticalCenter: parent.verticalCenter
                    width: 28
                    height: 28
                    radius: 14
                    // Play/pause is the one filled control; the skips only
                    // get a tone step under the cursor.
                    color: isPlay ? Theme.text
                         : (ctlMouse.containsMouse && modelData.enabled ? Theme.surface0 : "transparent")
                    // Unavailable actions dim rather than vanish — the row
                    // keeps its shape, and the control still reads as one.
                    opacity: modelData.enabled ? 1 : 0.32
                    scale: ctlMouse.pressed && modelData.enabled ? 0.9 : 1
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                    Text {
                        anchors.centerIn: parent
                        text: ctl.isPlay ? (root.playing ? "󰏤" : "󰐊") : ctl.modelData.glyph
                        font.family: Theme.fontIcon
                        font.pixelSize: ctl.isPlay ? 15 : 14
                        color: ctl.isPlay ? Theme.background : Theme.text
                    }

                    MouseArea {
                        id: ctlMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: ctl.modelData.enabled
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ctl.modelData.action()
                    }
                }
            }
        }
    }
}
