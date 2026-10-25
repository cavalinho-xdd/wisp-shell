import QtQuick
import QtQuick.Effects
import Quickshell.Services.Mpris
import Quickshell.Widgets
import "../../core"

// Open activity island while media is around: art, title, artist, source,
// progress with the ember as its head, and controls. Each block kindles in
// when `lit` turns on. Sized by its content; the island morphs to it.
Item {
    id: root

    property bool lit: false
    // Player comes from core/Island.qml, which picks the best of several.
    readonly property var player: Island.player
    readonly property bool hasPlayer: !!player
    readonly property bool playing: Island.playing
    // The progress (and so the ember head) only exists when the player
    // reports a length; live streams have none.
    readonly property bool emberVisible: hasPlayer && barBlock.visible
    // Centre of the progress head, for the island's inner light.
    readonly property point emberPoint: Qt.point(
        info.x + progress.x + head.x + head.width / 2,
        info.y + barBlock.y + progress.y + progress.height / 2)

    readonly property string artUrl: player && player.trackArtUrl
        ? (player.trackArtUrl.startsWith("/") ? "file://" + player.trackArtUrl : player.trackArtUrl) : ""

    function time(seconds) {
        const s = Math.max(0, Math.floor(seconds));
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
    }

    implicitWidth: Theme.mediaWidth
    implicitHeight: hasPlayer
        ? Theme.spaceLg * 2 + Math.max(Theme.artSize, info.implicitHeight)
        : Theme.spaceLg * 2 + empty.implicitHeight

    // Mpris only reports position when asked; ask every frame while the
    // progress is on screen and moving.
    FrameAnimation {
        running: root.lit && root.playing && progress.visible
        onTriggered: root.player.positionChanged()
    }

    Kindle {
        id: empty
        lit: root.lit && !root.hasPlayer
        anchors.centerIn: parent
        Text {
            text: "Nothing playing"
            color: Theme.islandMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.textBody
        }
    }

    Kindle {
        id: art
        lit: root.lit && root.hasPlayer
        index: 0
        x: Theme.spaceLg
        y: Theme.spaceLg
        width: Theme.artSize
        height: Theme.artSize

        ClippingRectangle {
            width: Theme.artSize
            height: Theme.artSize
            radius: Theme.radiusArt
            color: Theme.ashHi

            Text {
                anchors.centerIn: parent
                visible: cover.status !== Image.Ready
                text: "󰎆"
                color: Theme.islandMuted
                font.family: Theme.fontIcon
                font.pixelSize: Theme.textTitle * 2
            }

            Image {
                id: cover
                anchors.fill: parent
                source: root.artUrl
                sourceSize: Qt.size(Theme.artSize * 2, Theme.artSize * 2)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
        }
    }

    Column {
        id: info
        x: Theme.spaceLg + Theme.artSize + Theme.spaceMd
        y: Theme.spaceLg
        width: root.width - x - Theme.spaceLg
        visible: root.hasPlayer

        Kindle {
            lit: root.lit && root.hasPlayer
            index: 1
            width: info.width
            Text {
                width: info.width
                text: root.player ? (root.player.trackTitle || "Unknown title") : ""
                elide: Text.ElideRight
                color: Theme.islandText
                font.family: Theme.fontFamily
                font.pixelSize: Theme.textTitle
                font.weight: Font.DemiBold
            }
        }

        Kindle {
            lit: root.lit && root.hasPlayer
            index: 2
            width: info.width
            Text {
                width: info.width
                text: root.player ? (root.player.trackArtist || "") : ""
                elide: Text.ElideRight
                color: Theme.islandMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.textBody
            }
        }

        Item { width: 1; height: Theme.spaceXs }

        Kindle {
            lit: root.lit && root.hasPlayer
            index: 3
            width: info.width
            Text {
                width: info.width
                text: root.player ? (root.player.identity || "") : ""
                elide: Text.ElideRight
                opacity: 0.7
                color: Theme.islandMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.textLabel
                font.weight: Font.Medium
                font.letterSpacing: Theme.textLabel * 0.08
                font.capitalization: Font.AllUppercase
            }
        }

        Item { width: 1; height: Theme.spaceSm }

        Kindle {
            id: barBlock
            lit: root.lit && root.hasPlayer
            index: 4
            width: info.width
            visible: !!root.player && root.player.lengthSupported

            Column {
                width: info.width
                spacing: Theme.spaceXs

                Item {
                    id: progress
                    width: parent.width
                    height: Theme.progressHeight
                    readonly property real ratio: root.player && root.player.length > 0
                        ? Math.min(1, root.player.position / root.player.length) : 0

                    Rectangle {
                        anchors.fill: parent
                        radius: height / 2
                        color: Theme.ashHi
                    }
                    Rectangle {
                        width: parent.width * progress.ratio
                        height: parent.height
                        radius: height / 2
                        color: Theme.islandText
                    }
                    Item {
                        id: head
                        x: parent.width * progress.ratio - width / 2
                        anchors.verticalCenter: parent.verticalCenter
                        width: Theme.emberSize
                        height: Theme.emberSize
                        RectangularShadow {
                            anchors.fill: parent
                            radius: width / 2
                            color: Theme.ember
                            blur: Theme.glowBlur * 0.5 * Theme.glow
                        }
                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: Theme.ember
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: elapsed.implicitHeight
                    Text {
                        id: elapsed
                        text: root.player ? root.time(root.player.position) : ""
                        color: Theme.islandMuted
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.textLabel
                    }
                    Text {
                        anchors.right: parent.right
                        text: root.player ? root.time(root.player.length) : ""
                        color: Theme.islandMuted
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.textLabel
                    }
                }
            }
        }

        Kindle {
            lit: root.lit && root.hasPlayer
            index: 5
            width: info.width

            Item {
                width: info.width
                implicitHeight: controls.implicitHeight
                Row {
                    id: controls
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Theme.spaceXs

                    // Each control follows the player's own capability flag;
                    // browsers often can't go back, and calling it anyway
                    // logs an error.
                    EmberButton {
                        anchors.verticalCenter: parent.verticalCenter
                        icon: "󰒮"
                        label: "Previous"
                        enabled: !!root.player && root.player.canGoPrevious
                        onClicked: root.player.previous()
                    }
                    EmberButton {
                        anchors.verticalCenter: parent.verticalCenter
                        big: true
                        icon: root.playing ? "󰏤" : "󰐊"
                        label: root.playing ? "Pause" : "Play"
                        enabled: !!root.player && root.player.canTogglePlaying
                        onClicked: root.player.togglePlaying()
                    }
                    EmberButton {
                        anchors.verticalCenter: parent.verticalCenter
                        icon: "󰒭"
                        label: "Next"
                        enabled: !!root.player && root.player.canGoNext
                        onClicked: root.player.next()
                    }
                }
            }
        }
    }
}
