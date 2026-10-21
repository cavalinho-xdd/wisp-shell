import QtQuick
import Quickshell
import "../core"

Item {
    id: root

    readonly property bool active: Island.current === "network"
    readonly property bool isConnect: Island.netFlashIsConnect

    implicitWidth: active ? strip.implicitWidth : 0
    implicitHeight: 48

    opacity: active ? 1 : 0
    scale: active ? (hoverHandler.hovered ? 1.035 : 1.0) : 0.7
    visible: opacity > 0.01

    Behavior on opacity { NumberAnimation { duration: 250 } }
    Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
    Behavior on implicitWidth { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }

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
            text: "󰤨" // nf-md-wifi
            color: root.isConnect ? Theme.primary : Theme.subtext0
            font.family: Theme.fontIcon
            font.pixelSize: 18
        }

        // Device Name (SSID)
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Island.netFlashName
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
