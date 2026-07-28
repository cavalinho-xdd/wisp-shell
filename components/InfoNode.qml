import QtQuick
import "../core"

// Floating node orbiting the Wi-Fi / Bluetooth detail views' central object,
// positioned by centerX/centerY relative to its parent.
//
// Two kinds, and they must not look alike: a *readout* (signal strength,
// security, MAC address) and an *action* (Scan Networks, View Devices). They
// previously rendered identically — same fill, same size, same weight — so the
// only clue that one of them did anything was the cursor changing on hover.
// Actions now carry a primary-tinted fill, a primary label, a filled glyph
// chip, and a trailing chevron; readouts stay flat and quiet.
Item {
    id: root

    property real centerX: 0
    property real centerY: 0
    property string icon: ""
    property string label: ""
    property string subtitle: ""
    property bool isAction: false

    signal actionClicked()

    x: centerX - width / 2
    y: centerY - height / 2

    width: nodeContent.implicitWidth + (root.isAction ? 34 : 32)
    height: nodeContent.implicitHeight + 18

    opacity: 0.0
    scale: 0.8

    Component.onCompleted: {
        opacity = 1.0
        scale = 1.0
    }

    Behavior on opacity { NumberAnimation { duration: Theme.animSlow; easing.type: Easing.OutQuint } }
    Behavior on scale { NumberAnimation { duration: Theme.animSlow; easing.type: Theme.easeSpring } }

    // Press feedback, actions only — a readout that squished on click would be
    // claiming an interaction it doesn't have.
    readonly property bool pressing: root.isAction && nodeMa.pressed
    transform: Scale {
        origin.x: root.width / 2
        origin.y: root.height / 2
        xScale: root.pressing ? 0.96 : 1
        yScale: root.pressing ? 0.96 : 1
        Behavior on xScale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easeSpring } }
        Behavior on yScale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easeSpring } }
    }

    Rectangle {
        anchors.fill: parent
        radius: 14
        // Fill carries surface, kind and hover state at once — no outline. An
        // action is primary-tinted even at rest, which is what makes it read as
        // clickable before the cursor gets there.
        color: {
            if (root.isAction)
                return nodeMa.containsMouse ? Qt.alpha(Theme.primary, 0.30)
                                            : Qt.alpha(Theme.primary, 0.16);
            return nodeMa.containsMouse ? Qt.lighter(Theme.surface, 1.15) : Theme.surface;
        }
        Behavior on color { ColorAnimation { duration: Theme.animFast } }
    }

    Row {
        id: nodeContent
        anchors.centerIn: parent
        spacing: 10

        // Actions get the glyph on a filled chip; readouts get a bare glyph.
        Item {
            anchors.verticalCenter: parent.verticalCenter
            width: root.isAction ? 26 : 18
            height: root.isAction ? 26 : 18

            Rectangle {
                anchors.fill: parent
                radius: 9
                visible: root.isAction
                color: Qt.alpha(Theme.primary, 0.22)
            }
            Text {
                anchors.centerIn: parent
                text: root.icon
                font.family: Theme.fontIcon
                font.pixelSize: root.isAction ? 13 : 16
                color: root.isAction ? Theme.primary : Theme.subtext0
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1
            Text {
                font.family: Theme.fontFamily
                text: root.label
                font.pixelSize: 13
                font.bold: true
                color: root.isAction ? Theme.primary : Theme.text
            }
            Text {
                font.family: Theme.fontFamily
                text: root.subtitle
                font.pixelSize: 10
                color: Theme.subtext0
                visible: text.length > 0
            }
        }

        // Trailing chevron — the affordance that says "this goes somewhere",
        // and it nudges on hover so the node answers the pointer.
        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.isAction
            text: "󰅂"
            font.family: Theme.fontIcon
            font.pixelSize: 12
            color: Theme.primary
            opacity: nodeMa.containsMouse ? 1 : 0.55
            x: nodeMa.containsMouse ? 3 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
            Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutQuint } }
        }
    }

    MouseArea {
        id: nodeMa
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.isAction ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: if (root.isAction) root.actionClicked()
    }
}
