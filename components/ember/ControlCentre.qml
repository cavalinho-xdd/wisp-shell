import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import "../../core"

// Open right island: today's date, the four switches, volume and, where the
// machine has a backlight, brightness. Notifications, power and the Wi-Fi /
// Bluetooth / sound views come in the next steps of M7.
Item {
    id: root

    property bool lit: false

    // Asks the island to show a detail view: "wifi", "bluetooth", "sound", "power" or "calendar".
    signal showView(string view)
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

            Item {
                width: column.width
                implicitHeight: dateText.implicitHeight
                Text {
                    id: dateText
                    width: parent.width
                    text: Qt.formatDate(clock.date, "dddd d. MMMM")
                    elide: Text.ElideRight
                    color: dateMouse.containsMouse ? Theme.ember : Theme.islandText
                    Behavior on color { ColorAnimation { duration: Theme.motionFast } }
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.textTitle
                    font.weight: Font.DemiBold
                    topPadding: Theme.spaceXs / 2
                    bottomPadding: Theme.spaceXs / 2
                }
                Accessible.role: Accessible.Button
                Accessible.name: "Calendar and weather"
                MouseArea {
                    id: dateMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.showView("calendar")
                }
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
                    hasMore: true
                    onClicked: Connectivity.toggleWifi()
                    onMoreClicked: root.showView("wifi")
                }
                EmberTile {
                    width: root.tileWidth
                    icon: !Connectivity.btEnabled ? "󰂲" : (Connectivity.btConnected.length > 0 ? "󰂱" : "󰂯")
                    title: "Bluetooth"
                    subtitle: !Connectivity.btEnabled ? "Off" : (Connectivity.btConnected.length > 0 ? Connectivity.btConnected[0].name : "On")
                    checked: Connectivity.btEnabled
                    hasMore: true
                    onClicked: Connectivity.toggleBluetooth()
                    onMoreClicked: root.showView("bluetooth")
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
                    width: column.width - Theme.spaceLg - Theme.spaceSm * 3 - volumeText.width - volumeMore.width
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
                EmberButton {
                    id: volumeMore
                    anchors.verticalCenter: parent.verticalCenter
                    icon: "󰅂"
                    label: "Sound settings"
                    onClicked: root.showView("sound")
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

        Kindle {
            lit: root.lit
            index: 4
            width: column.width

            Rectangle {
                width: column.width
                implicitHeight: Theme.spaceSm * 2 + headerRow.implicitHeight + Theme.spaceXs + Theme.notifRow * Theme.ccNotifRows
                radius: Theme.radiusTile
                color: Theme.ash

                Item {
                    id: headerRow
                    x: Theme.spaceSm
                    y: Theme.spaceSm
                    width: parent.width - Theme.spaceSm * 2
                    implicitHeight: Theme.controlSize - Theme.spaceXs

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        x: Theme.spaceXs
                        text: "Notifications"
                        color: Theme.islandMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.textCaption
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: clearText.left
                        anchors.rightMargin: Theme.spaceSm
                        visible: Notifs.records.length > 0
                        text: Notifs.liveRecords.length > 0 ? Notifs.liveRecords.length + " new" : ""
                        color: Theme.ember
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.textMonoSmall
                    }
                    Text {
                        id: clearText
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.spaceXs
                        visible: Notifs.records.length > 0
                        text: "Clear"
                        color: clearMouse.containsMouse ? Theme.islandText : Theme.islandMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.textCaption
                        Behavior on color { ColorAnimation { duration: Theme.motionFast } }
                        Accessible.role: Accessible.Button
                        Accessible.name: "Clear notifications"
                        MouseArea {
                            id: clearMouse
                            anchors.fill: parent
                            anchors.margins: -Theme.spaceXs
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Notifs.dismissAll();
                                Notifs.clearHistory();
                            }
                        }
                    }
                }

                ListView {
                    id: notifList
                    x: Theme.spaceXs
                    y: headerRow.y + headerRow.height + Theme.spaceXs
                    width: parent.width - Theme.spaceXs * 2
                    height: Theme.notifRow * Theme.ccNotifRows
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: Notifs.records

                    delegate: NotifRow {
                        required property var modelData
                        width: ListView.view.width
                        rec: modelData
                        onActivated: Notifs.activate(rec.key)
                        onDismissed: Notifs.dismiss(rec.key)
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: notifList.count === 0
                        text: "Nothing new"
                        color: Theme.islandMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.textBody
                    }
                }
            }
        }

        Kindle {
            lit: root.lit
            index: 5
            width: column.width
            height: Theme.controlSize

            Item {
                width: column.width
                height: Theme.controlSize

                // Tray icons; the count is index-based because modelData
                // would resolve to the screen inside the per-screen Variants.
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.spaceXs / 2
                    Repeater {
                        model: SystemTray.items.values.length
                        TrayIcon {
                            required property int index
                            trayItem: SystemTray.items.values[index]
                        }
                    }
                }
                EmberButton {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    icon: "󰐥"
                    label: "Power"
                    onClicked: root.showView("power")
                }
            }
        }
    }
}
