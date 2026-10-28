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
    // Set once the island has settled; switching views then skips the stagger.
    property bool quick: false

    // Asks the island to show a detail view: "wifi", "bluetooth", "sound", "power" or "calendar".
    signal showView(string view)
    // Asks the island to close (an app was launched from here).
    signal done()
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

    // Notifs.records is a plain array, and a ListView given a new array
    // rebuilds every row with no add/remove transitions. This model follows
    // it row by row (by key), so a dismissed notification can leave and its
    // neighbours slide up. A row keeps its record as JSON, so it still has
    // something to draw while it fades out.
    ListModel { id: notifModel }
    function syncNotifs(): void {
        const recs = Notifs.records;
        const keys = new Set(recs.map(r => r.key));
        for (let i = notifModel.count - 1; i >= 0; i--)
            if (!keys.has(notifModel.get(i).key)) notifModel.remove(i);
        for (let i = 0; i < recs.length; i++) {
            const json = JSON.stringify(recs[i]);
            let at = -1;
            for (let j = i; j < notifModel.count; j++)
                if (notifModel.get(j).key === recs[i].key) { at = j; break; }
            if (at < 0) {
                notifModel.insert(i, { key: recs[i].key, json: json });
                continue;
            }
            if (at !== i) notifModel.move(at, i, 1);
            if (notifModel.get(i).json !== json) notifModel.setProperty(i, "json", json);
        }
    }
    Connections {
        target: Notifs
        function onRecordsChanged() { root.syncNotifs(); }
    }
    Component.onCompleted: syncNotifs()

    Column {
        id: column
        x: Theme.spaceMd
        y: Theme.spaceMd
        width: root.width - Theme.spaceMd * 2
        spacing: Theme.spaceSm

        Kindle {
            quick: root.quick
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
            quick: root.quick
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
            quick: root.quick
            id: volumeBlock
            lit: root.lit
            index: 2
            width: column.width

            Row {
                id: volumeRow
                spacing: Theme.spaceSm

                Text {
                    // Volume 0 is as silent as mute, so it shows the same glyph.
                    readonly property bool silent: Audio.muted || Math.round(Audio.volume * 100) === 0
                    anchors.verticalCenter: parent.verticalCenter
                    width: Theme.spaceLg
                    horizontalAlignment: Text.AlignHCenter
                    text: silent ? "󰖁" : "󰕾"
                    color: muteMouse.containsMouse ? Theme.ember : (silent ? Theme.islandMuted : Theme.islandText)
                    Behavior on color { ColorAnimation { duration: Theme.motionFast } }
                    font.family: Theme.fontIcon
                    font.pixelSize: Theme.textTitle
                    Accessible.role: Accessible.Button
                    Accessible.name: Audio.muted ? "Unmute" : "Mute"

                    MouseArea {
                        id: muteMouse
                        anchors.fill: parent
                        anchors.margins: -Theme.spaceXs
                        hoverEnabled: true
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
            quick: root.quick
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
            quick: root.quick
            lit: root.lit
            index: 4
            width: column.width

            // The list sits quietly on the card: a fill barely lighter than it.
            EmberSurface {
                width: column.width
                implicitHeight: Theme.spaceSm * 2 + headerRow.implicitHeight + Theme.spaceXs + notifList.height
                radius: Theme.radiusTile
                base: Theme.panel

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
                    // Grows with the rows up to the cap, then scrolls; empty keeps one row for "Nothing new".
                    height: Math.max(Theme.notifRow, Math.min(contentHeight, Theme.notifRow * Theme.ccNotifRows))
                    Behavior on height { NumberAnimation { duration: Theme.motionQuick; easing.type: Easing.OutCubic } }
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: notifModel

                    // Leaving: fades and slides out to the right; the rest
                    // close the gap. Arriving: fades in where it lands.
                    add: Transition {
                        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.motionQuick; easing.type: Easing.OutCubic }
                    }
                    remove: Transition {
                        NumberAnimation { property: "opacity"; to: 0; duration: Theme.motionQuick; easing.type: Easing.OutCubic }
                        NumberAnimation { property: "x"; to: Theme.spaceLg; duration: Theme.motionQuick; easing.type: Easing.OutCubic }
                    }
                    displaced: Transition {
                        NumberAnimation { property: "y"; duration: Theme.motionQuick; easing.type: Easing.OutCubic }
                        // A row caught mid-add or mid-remove ends whole.
                        NumberAnimation { property: "opacity"; to: 1; duration: Theme.motionQuick }
                    }
                    move: Transition {
                        NumberAnimation { property: "y"; duration: Theme.motionQuick; easing.type: Easing.OutCubic }
                    }

                    delegate: NotifRow {
                        required property string json
                        width: ListView.view.width
                        rec: JSON.parse(json)
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
            quick: root.quick
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
                    id: trayRow
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.spaceXs / 2
                    Repeater {
                        model: SystemTray.items.values.length
                        TrayIcon {
                            required property int index
                            trayItem: SystemTray.items.values[index]
                            readonly property string hint: trayItem.tooltipTitle || trayItem.title || trayItem.id
                            // Leaving one icon must not wipe the name the next one just set.
                            onContainsMouseChanged: {
                                if (containsMouse) trayHint.text = hint;
                                else if (trayHint.text === hint) trayHint.text = "";
                            }
                        }
                    }
                }
                // Names the hovered tray icon; icons alone rarely say whose they are.
                Text {
                    id: trayHint
                    anchors.verticalCenter: parent.verticalCenter
                    x: trayRow.width + Theme.spaceSm
                    width: footerButtons.x - x - Theme.spaceSm
                    elide: Text.ElideRight
                    opacity: text !== "" ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: Theme.motionFast } }
                    color: Theme.islandMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.textCaption
                }
                Row {
                    id: footerButtons
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.spaceXs / 2

                    // The standalone settings app; the island closes so a
                    // second click cannot start a second copy.
                    EmberButton {
                        icon: "󰒓"
                        label: "Settings"
                        onClicked: {
                            Quickshell.execDetached(["/usr/bin/qs", "-p", Settings.settingsAppPath]);
                            root.done();
                        }
                    }
                    EmberButton {
                        icon: "󰐥"
                        label: "Power"
                        onClicked: root.showView("power")
                    }
                }
            }
        }
    }
}
