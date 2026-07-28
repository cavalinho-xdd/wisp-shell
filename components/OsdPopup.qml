import QtQuick
import "../core"

// Fills its own small per-monitor PanelWindow (see shell.qml) — separate
// surface from the main pill so it never fights the pill's collapsed/media/
// expanded width state machine. Purely reactive to core/Osd.qml; no click
// handling, nothing to interact with, just a glance-and-gone indicator.
Item {
    id: root
    anchors.fill: parent

    readonly property bool isMic: Osd.reason === "mic"
    readonly property string glyph: isMic
        ? (Osd.muted ? "󰍭" : "󰍬")
        : (Osd.muted ? "󰝟" : "󰕾")
    readonly property color accent: Osd.muted ? Theme.red : Theme.primary

    Rectangle {
        id: pill
        anchors.centerIn: parent
        width: 220
        height: 64
        radius: 20
        color: Theme.panelBackground

        opacity: Osd.shown ? 1 : 0
        scale: Osd.shown ? 1.0 : 0.85
        visible: opacity > 0.01
        Behavior on opacity { NumberAnimation { duration: 180 } }
        Behavior on scale { NumberAnimation { duration: 260; easing.type: Theme.easeSpring; easing.overshoot: 1.3 } }

        Row {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.glyph
                font.family: Theme.fontIcon
                font.pixelSize: 22
                color: root.accent
                Behavior on color { ColorAnimation { duration: Theme.animFast } }
            }

            Rectangle {
                id: track
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 22 - 12 - 34 - 12
                height: 8
                radius: 4
                color: Theme.surface0

                Rectangle {
                    height: parent.height
                    radius: parent.radius
                    color: root.accent
                    width: parent.width * (Osd.muted ? 0 : Osd.value)
                    Behavior on width { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                }
            }

            Text {
                font.family: Theme.fontFamily;
                anchors.verticalCenter: parent.verticalCenter
                width: 34
                horizontalAlignment: Text.AlignRight
                text: Osd.muted ? "--" : Math.round(Osd.value * 100).toString()
                color: Theme.subtext0
                font.pixelSize: 12
                font.bold: true
            }
        }
    }
}
