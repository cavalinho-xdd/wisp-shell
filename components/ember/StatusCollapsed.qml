import QtQuick
import "../../core"

// Collapsed right island: Wi-Fi and Bluetooth state, the battery when the
// machine has one, and a count of notifications that are still live. Muted
// means off or not connected; the island takes its width from implicitWidth.
Item {
    id: root

    readonly property int unread: Notifs.liveRecords.length

    implicitWidth: row.implicitWidth + Theme.spaceMd * 2
    implicitHeight: Theme.islandHeight

    Accessible.ignored: true

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        x: Theme.spaceMd
        spacing: Theme.spaceSm

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Connectivity.wifiEnabled ? "󰤨" : "󰖪"
            color: Connectivity.wifiConnected ? Theme.islandText : Theme.islandMuted
            font.family: Theme.fontIcon
            font.pixelSize: Theme.textBody
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: !Connectivity.btEnabled ? "󰂲" : (Connectivity.btConnected.length > 0 ? "󰂱" : "󰂯")
            color: Connectivity.btConnected.length > 0 ? Theme.islandText : Theme.islandMuted
            font.family: Theme.fontIcon
            font.pixelSize: Theme.textBody
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: Battery.available
            text: Math.round(Battery.percentage * 100) + "%"
            color: Battery.low ? Theme.ember : Theme.islandMuted
            font.family: Theme.fontMono
            font.pixelSize: Theme.textMonoSmall
        }
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.unread > 0
            width: Math.max(height, count.implicitWidth + Theme.spaceXs)
            height: Theme.textLabel + Theme.spaceXs
            radius: height / 2
            color: Theme.ember
            Text {
                id: count
                anchors.centerIn: parent
                text: root.unread
                color: Theme.smoke
                font.family: Theme.fontMono
                font.pixelSize: Theme.textLabel
                font.weight: Font.DemiBold
            }
        }
    }
}
