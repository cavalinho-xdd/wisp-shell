import QtQuick
import Quickshell
import "../../core"

// Open right island: today's date, the four switches, volume and, where the
// machine has a backlight, brightness. Notifications, power and the Wi-Fi /
// Bluetooth / sound views come in the next steps of M7.
Item {
    id: root

    property bool lit: false
    // Centre of the volume head, for the island's inner light.
    readonly property point emberPoint: Qt.point(
        column.x + volumeRow.x + volumeSlider.x + volumeSlider.headX,
        column.y + volumeBlock.y + volumeRow.y + volumeSlider.y + volumeSlider.height / 2)

    readonly property real tileWidth: (column.width - Theme.spaceSm) / 2

    implicitWidth: Theme.ccWidth
    implicitHeight: column.implicitHeight + Theme.spaceMd * 2

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Column {
        id: column
        x: Theme.spaceMd
        y: Theme.spaceMd
        width: root.width - Theme.spaceMd * 2
        spacing: Theme.spaceSm

        Kindle {
            lit: root.lit
            index: 0
            width: column.width

            Text {
                width: column.width
                text: Qt.formatDate(clock.date, "dddd d. MMMM")
                elide: Text.ElideRight
                color: Theme.islandText
                font.family: Theme.fontFamily
                font.pixelSize: Theme.textTitle
                font.weight: Font.DemiBold
                topPadding: Theme.spaceXs / 2
                bottomPadding: Theme.spaceXs / 2
            }
        }

        Kindle {
            lit: root.lit
            index: 1
            width: column.width

            Grid {
                columns: 2
                spacing: Theme.spaceSm

                EmberTile {
                    width: root.tileWidth
                    icon: Connectivity.wifiEnabled ? "󰤨" : "󰖪"
                    title: "Wi‑Fi"
                    subtitle: !Connectivity.wifiEnabled ? "Off" : (Connectivity.network ? Connectivity.network.name : "Not connected")
                    checked: Connectivity.wifiEnabled
                    onClicked: Connectivity.toggleWifi()
                }
                EmberTile {
                    width: root.tileWidth
                    icon: !Connectivity.btEnabled ? "󰂲" : (Connectivity.btConnected.length > 0 ? "󰂱" : "󰂯")
                    title: "Bluetooth"
                    subtitle: !Connectivity.btEnabled ? "Off" : (Connectivity.btConnected.length > 0 ? Connectivity.btConnected[0].name : "On")
                    checked: Connectivity.btEnabled
                    onClicked: Connectivity.toggleBluetooth()
                }
                EmberTile {
                    width: root.tileWidth
                    icon: Notifs.dnd ? "󰂛" : "󰂚"
                    title: "Do not disturb"
                    subtitle: Notifs.dnd ? "On" : "Off"
                    checked: Notifs.dnd
                    onClicked: Notifs.setDnd(!Notifs.conf.dnd)
                }
                EmberTile {
                    width: root.tileWidth
                    icon: "󰊗"
                    title: "Game mode"
                    subtitle: QuickToggles.gameMode ? "On" : "Off"
                    checked: QuickToggles.gameMode
                    onClicked: QuickToggles.toggleGameMode()
                }
            }
        }

        Kindle {
            id: volumeBlock
            lit: root.lit
            index: 2
            width: column.width

            Row {
                id: volumeRow
                spacing: Theme.spaceSm

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Theme.spaceLg
                    horizontalAlignment: Text.AlignHCenter
                    text: Audio.muted ? "󰖁" : "󰕾"
                    color: Audio.muted ? Theme.islandMuted : Theme.islandText
                    font.family: Theme.fontIcon
                    font.pixelSize: Theme.textTitle

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -Theme.spaceXs
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Audio.toggleMute()
                    }
                }
                EmberSlider {
                    id: volumeSlider
                    width: column.width - Theme.spaceLg - Theme.spaceSm * 2 - volumeText.width
                    anchors.verticalCenter: parent.verticalCenter
                    label: "Volume"
                    value: Math.min(1, Audio.volume)
                    onMoved: v => Audio.setVolume(v)
                }
                Text {
                    id: volumeText
                    anchors.verticalCenter: parent.verticalCenter
                    width: Theme.spaceLg + Theme.spaceSm
                    horizontalAlignment: Text.AlignRight
                    text: Math.round(Audio.volume * 100)
                    color: Theme.islandMuted
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.textMonoSmall
                }
            }
        }

        Kindle {
            lit: root.lit
            index: 3
            width: column.width
            visible: Brightness.ready

            Row {
                spacing: Theme.spaceSm

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Theme.spaceLg
                    horizontalAlignment: Text.AlignHCenter
                    text: "󰃟"
                    color: Theme.islandText
                    font.family: Theme.fontIcon
                    font.pixelSize: Theme.textTitle
                }
                EmberSlider {
                    width: column.width - Theme.spaceLg - Theme.spaceSm * 2 - brightnessText.width
                    anchors.verticalCenter: parent.verticalCenter
                    label: "Brightness"
                    value: Brightness.value
                    onMoved: v => Brightness.set(v)
                }
                Text {
                    id: brightnessText
                    anchors.verticalCenter: parent.verticalCenter
                    width: Theme.spaceLg + Theme.spaceSm
                    horizontalAlignment: Text.AlignRight
                    text: Math.round(Brightness.value * 100)
                    color: Theme.islandMuted
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.textMonoSmall
                }
            }
        }
    }
}
