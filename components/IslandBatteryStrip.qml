import QtQuick
import Quickshell
import "../core"

Item {
    id: root

    readonly property bool active: Island.current === "battery"
    readonly property string reason: Island.batFlashReason

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
            text: reason === "low" || reason === "critical" ? "󰂎" 
                : reason === "charging" ? "󰂄"
                : reason === "full" ? "󰁹" : "󰁾"
            color: reason === "critical" ? Theme.red
                : reason === "low" ? Theme.yellow
                : reason === "charging" ? Theme.green
                : reason === "full" ? Theme.green : Theme.text
            font.family: Theme.fontIcon
            font.pixelSize: 18
        }

        // Text
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: reason === "critical" ? "Battery Critical"
                : reason === "low" ? "Battery Low"
                : reason === "charging" ? "Charging"
                : reason === "full" ? "Fully Charged"
                : "Discharging"
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: 14
            font.bold: true
        }

        // Percentage
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round(Battery.percentage * 100) + "%"
            color: Theme.subtext0
            font.family: Theme.fontFamily
            font.pixelSize: 14
        }
    }
}
