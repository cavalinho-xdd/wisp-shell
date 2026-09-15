import QtQuick
import Quickshell
import "../core"

Item {
    id: root

    readonly property bool active: Island.current === "bluetooth"
    readonly property bool isConnect: Island.btFlashIsConnect

    implicitWidth: active ? strip.implicitWidth : 0
    implicitHeight: 48

    opacity: active ? 1 : 0
    scale: active ? (hoverHandler.hovered ? 1.035 : 1.0) : 0.7
    visible: opacity > 0.01

    Behavior on opacity { NumberAnimation { duration: 250 } }
    Behavior on scale { NumberAnimation { duration: 220; easing.type: Theme.easeSpring; easing.overshoot: 1.3 } }
    Behavior on implicitWidth { NumberAnimation { duration: 420; easing.type: Easing.OutBack; easing.overshoot: 1.05 } }

    HoverHandler { id: hoverHandler }

    Row {
        id: strip
        height: parent.height
        anchors.centerIn: parent
        spacing: 12
        padding: 16

        // Icon
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "󰂯" // nf-md-bluetooth
            color: root.isConnect ? Theme.primary : Theme.subtext0
            font.family: Theme.fontIcon
            font.pixelSize: 18
        }

        // Device Name
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Island.btFlashName
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: 14
            font.bold: true
        }

        // Status
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.isConnect ? "Connected" : "Disconnected"
            color: root.isConnect ? Theme.green : Theme.subtext0
            font.family: Theme.fontFamily
            font.pixelSize: 14
        }
    }
}
