import QtQuick
import QtQuick.Effects
import "../core"

// Fills its own small per-monitor PanelWindow (see shell.qml) — separate
// surface from the main pill so it never fights the pill's collapsed/media/
// expanded width state machine. Purely reactive to core/Osd.qml; no click
// handling, nothing to interact with, just a glance-and-gone indicator.
// Drawn like an Ember island: smoke fill lit by the ember glow around it.
Item {
    id: root
    anchors.fill: parent

    // Force singleton init so script runs
    property bool _brightInit: Brightness.ready

    readonly property bool isMic: Osd.reason === "mic"
    readonly property bool isBright: Osd.reason === "brightness"
    readonly property string glyph: isBright ? "󰃠"
        : isMic ? (Osd.muted ? "󰍭" : "󰍬")
        : (Osd.muted ? "󰝟" : "󰕾")
    readonly property color accent: (Osd.muted && !isBright) ? Theme.red : (isBright ? Theme.yellow : Theme.ember)

    Item {
        id: pill
        anchors.centerIn: parent
        width: Theme.osdWidth
        height: Theme.islandHeight

        opacity: Osd.shown ? 1 : 0
        scale: Osd.shown ? 1 : Theme.osdScale
        visible: opacity > 0.01
        Behavior on opacity { NumberAnimation { duration: Theme.motionFast; easing.type: Easing.OutCubic } }
        Behavior on scale { SpringAnimation { spring: Theme.springQuick; damping: Theme.dampingQuick; epsilon: 0.001 } }

        RectangularShadow {
            anchors.fill: fill
            radius: fill.radius
            color: Qt.alpha(Theme.ember, Math.min(1, Theme.glowAlpha * Theme.glow))
            blur: Theme.glowBlur * Theme.glow
        }

        Rectangle {
            id: fill
            anchors.fill: parent
            radius: Theme.radiusIsland
            color: Theme.smoke
        }

        Row {
            anchors.fill: parent
            anchors.leftMargin: Theme.spaceMd
            anchors.rightMargin: Theme.spaceMd
            spacing: Theme.spaceSm

            Text {
                id: icon
                anchors.verticalCenter: parent.verticalCenter
                width: Theme.osdIconSize
                horizontalAlignment: Text.AlignHCenter
                text: root.glyph
                font.family: Theme.fontIcon
                font.pixelSize: Theme.osdIconSize
                color: root.accent
                Behavior on color { ColorAnimation { duration: Theme.motionFast } }
            }

            Rectangle {
                id: track
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - icon.width - readout.width - parent.spacing * 2
                height: Theme.osdTrackHeight
                radius: height / 2
                color: Qt.alpha(Theme.islandText, 0.12)

                Rectangle {
                    height: parent.height
                    radius: parent.radius
                    color: root.accent
                    width: parent.width * (Osd.muted ? 0 : Osd.value)
                    Behavior on width { NumberAnimation { duration: Theme.motionFast; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: Theme.motionFast } }
                }
            }

            Text {
                id: readout
                anchors.verticalCenter: parent.verticalCenter
                width: Theme.osdReadoutWidth
                horizontalAlignment: Text.AlignRight
                text: Osd.muted ? "--" : Math.round(Osd.value * 100).toString()
                color: Theme.islandMuted
                font.family: Theme.fontMono
                font.pixelSize: Theme.textMonoSmall
                font.weight: Font.Medium
            }
        }
    }
}
