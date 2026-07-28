import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Services.Mpris
import "../core"

Rectangle {
    id: root
    radius: 20
    color: Theme.surface
    clip: true

    // Shared with the collapsed-bar island strip (core/Island.qml) rather than
    // just grabbing Mpris.players.values[0] — browsers commonly publish the
    // same tab as two separate MPRIS players (one with no art), and picking
    // array-order-first could silently grab the art-less one.
    property var mprisPlayer: Island.player
    property bool isPlaying: mprisPlayer && mprisPlayer.playbackState === MprisPlaybackState.Playing
    property string artUrlStr: mprisPlayer && mprisPlayer.trackArtUrl ? (mprisPlayer.trackArtUrl.startsWith("/") ? "file://" + mprisPlayer.trackArtUrl : mprisPlayer.trackArtUrl) : ""

    // ── Blurred Background ──
    Image {
        id: bgArt
        anchors.fill: parent
        source: root.artUrlStr
        fillMode: Image.PreserveAspectCrop
        visible: false 
        asynchronous: true
    }
    
    MultiEffect {
        anchors.fill: parent
        source: bgArt
        blurEnabled: true
        blurMax: 64
        blur: 1.0
        opacity: bgArt.status === Image.Ready ? 0.6 : 0.0
        visible: bgArt.status === Image.Ready
        Behavior on opacity { NumberAnimation { duration: 800 } }
    }
    
    // Dim the blurred background so text remains legible
    Rectangle {
        anchors.fill: parent
        color: Theme.background
        opacity: 0.65
        visible: bgArt.status === Image.Ready
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 24
        
        // ── Left Side: Animated Circular Album Art ──
        Item {
            Layout.preferredWidth: 120
            Layout.preferredHeight: 120
            Layout.alignment: Qt.AlignVCenter
            
            scale: root.isPlaying ? 1.0 : 0.85
            Behavior on scale { NumberAnimation { duration: 800; easing.type: Easing.OutElastic; easing.overshoot: 1.2 } }
            
            // Glowing Aura when playing
            Rectangle {
                z: -1
                anchors.centerIn: parent
                width: parent.width + 16
                height: parent.height + 16
                radius: width / 2
                color: Theme.primary
                opacity: root.isPlaying && bgArt.status === Image.Ready ? 0.5 : 0.0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 500 } }
                
                layer.enabled: true
                layer.effect: MultiEffect {
                    blurEnabled: true
                    blurMax: 32
                    blur: 1.0
                }
            }
            
            // Outer subtle ring
            Rectangle {
                anchors.fill: parent
                anchors.margins: -4
                radius: width / 2
                color: "transparent"
                border.color: root.isPlaying ? Theme.primary : Theme.surface0
                border.width: root.isPlaying ? 3 : 2
                Behavior on border.color { ColorAnimation { duration: 500 } }
            }
            
            Image {
                id: albumArt
                anchors.fill: parent
                source: root.artUrlStr
                fillMode: Image.PreserveAspectCrop
                visible: false // Hidden because MultiEffect draws it
                asynchronous: true
            }
            
            // Round mask for image
            MultiEffect {
                anchors.fill: albumArt
                source: albumArt
                maskEnabled: true
                visible: albumArt.status === Image.Ready
                maskSource: ShaderEffectSource {
                    sourceItem: Rectangle {
                        width: albumArt.width
                        height: albumArt.height
                        radius: width / 2
                    }
                }
            }
            
            // Fallback icon if no art
            Text {
                anchors.centerIn: parent
                text: "󰎆"
                font.family: Theme.fontIcon
                font.pixelSize: 48
                color: Theme.subtext0
                visible: !albumArt.source || albumArt.source.toString() === ""
            }
        }
        
        // ── Right Side: Info & Controls ──
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8
            
            Item { Layout.fillHeight: true } // Spacer
            
            Text {
                font.family: Theme.fontFamily;
                text: root.mprisPlayer ? (root.mprisPlayer.trackTitle || "No title") : "Not Playing"
                font.pixelSize: 18
                font.bold: true
                color: Theme.text
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
            
            Text {
                font.family: Theme.fontFamily;
                text: root.mprisPlayer ? (root.mprisPlayer.trackArtist || "Unknown Artist") : "Waiting for media..."
                font.pixelSize: 14
                color: Theme.subtext0
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
            
            Item { Layout.preferredHeight: 8 } // Spacer
            
            RowLayout {
                Layout.fillWidth: true
                spacing: 20
                
                // Each control mirrors the player's own capability flag. A
                // browser tab commonly reports canGoPrevious false, and calling
                // it regardless logs "Cannot call previous() ... because
                // canGoPrevious is false" — same guard as IslandMediaStrip.
                IconButton {
                    text: "󰒮"
                    width: 32; height: 32
                    readonly property bool available: !!root.mprisPlayer && root.mprisPlayer.canGoPrevious
                    opacity: available ? 1 : 0.32
                    Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                    onClicked: if (available) root.mprisPlayer.previous()
                }

                IconButton {
                    text: root.isPlaying ? "󰏤" : "󰐊"
                    width: 56; height: 56
                    isChecked: true // Gives it the primary pill background
                    readonly property bool available: !!root.mprisPlayer && root.mprisPlayer.canTogglePlaying
                    opacity: available ? 1 : 0.32
                    Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                    onClicked: if (available) root.mprisPlayer.togglePlaying()
                }

                IconButton {
                    text: "󰒭"
                    width: 32; height: 32
                    readonly property bool available: !!root.mprisPlayer && root.mprisPlayer.canGoNext
                    opacity: available ? 1 : 0.32
                    Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                    onClicked: if (available) root.mprisPlayer.next()
                }
                
                Item { Layout.fillWidth: true } // Push controls to the left
            }
            
            Item { Layout.fillHeight: true } // Spacer
        }
    }
}
