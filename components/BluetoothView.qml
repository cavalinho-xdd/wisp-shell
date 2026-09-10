import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import "../core"

Item {
    id: root

    property var stack: null
    property bool showScanView: false
    property var adapter: Bluetooth.defaultAdapter

    property var connectedDevice: {
        if (!root.adapter || !root.adapter.enabled) return null;
        let devs = root.adapter.devices.values;
        for (let i = 0; i < devs.length; i++) {
            if (devs[i].connected) return devs[i];
        }
        return null;
    }

    property bool btEnabled: root.adapter ? root.adapter.enabled : false

    // ── Back Button ──
    Rectangle {
        anchors.left: parent.left
        anchors.leftMargin: 16
        anchors.top: parent.top
        anchors.topMargin: 16
        width: 40; height: 40; radius: 20
        color: backMa.containsMouse ? Theme.surface : "transparent"
        z: 10
        Behavior on color { ColorAnimation { duration: Theme.animFast } }
        Text {
            anchors.centerIn: parent
            text: "󰁍"
            font.family: Theme.fontIcon
            font.pixelSize: 20
            color: Theme.text
        }
        MouseArea {
            id: backMa
            anchors.fill: parent
            hoverEnabled: true
            onClicked: { if (root.stack) root.stack.pop() }
        }
    }

    // ── Toggle switch ──
    Rectangle {
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.top: parent.top
        anchors.topMargin: 24
        width: 48; height: 24; radius: 12; z: 10
        color: root.btEnabled ? Theme.primary : Theme.surface
        Behavior on color { ColorAnimation { duration: Theme.animFast } }
        Rectangle {
            width: 20; height: 20; radius: 10
            color: Theme.background; y: 2
            x: root.btEnabled ? 26 : 2
            Behavior on x { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easeSpring } }
        }
        MouseArea { anchors.fill: parent; onClicked: { if (root.adapter) root.adapter.enabled = !root.adapter.enabled } }
    }

    // ── Title ──
    Text {
        font.family: Theme.fontFamily;
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 24
        text: "Bluetooth"
        font.pixelSize: 18; font.bold: true
        color: Theme.text; z: 10
    }

    // ══════════════════════════════════════════
    // INFO VIEW (connected device + orbital nodes)
    // ══════════════════════════════════════════
    Item {
        id: infoView
        anchors.fill: parent
        anchors.topMargin: 60
        anchors.bottomMargin: 16
        visible: !root.showScanView && root.connectedDevice !== null
        opacity: visible ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: Theme.animSlow } }

        // Concentric ring decorations (slightly different spacing from wifi)
        Repeater {
            model: 3
            Rectangle {
                anchors.centerIn: parent
                width: 170 + index * 45
                height: width
                radius: width / 2
                color: "transparent"
                border.color: Theme.surface
                border.width: 1
                opacity: 0.35 - index * 0.08
            }
        }

        // ── Central Circle ──
        Rectangle {
            id: centralCircle
            anchors.centerIn: parent
            width: 150; height: 150; radius: 75
            color: Theme.primary
            scale: root.connectedDevice ? 1.0 : 0.5
            Behavior on scale { NumberAnimation { duration: Theme.animSlow; easing.type: Theme.easeSpring } }

            // Pulse ring
            Rectangle {
                anchors.centerIn: parent
                width: parent.width + 20; height: width; radius: width / 2
                color: "transparent"
                border.color: Theme.primary; border.width: 2
                opacity: 0.25
                SequentialAnimation on scale {
                    loops: Animation.Infinite; running: true
                    NumberAnimation { to: 1.08; duration: 2000; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0; duration: 2000; easing.type: Easing.InOutSine }
                }
            }

            Column {
                anchors.centerIn: parent
                spacing: 4
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "󰂱"
                    font.family: Theme.fontIcon
                    font.pixelSize: 44
                    color: Theme.colorOnPrimary
                }
                Text {
                    font.family: Theme.fontFamily;
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.connectedDevice ? (root.connectedDevice.name || root.connectedDevice.address) : ""
                    font.pixelSize: 14; font.bold: true
                    color: Theme.colorOnPrimary
                    width: 130; horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }
                Text {
                    font.family: Theme.fontFamily;
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Connected"
                    font.pixelSize: 10
                    color: Theme.colorOnPrimary; opacity: 0.7
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: if (root.connectedDevice) root.connectedDevice.disconnect()
            }
        }

        // ── Info nodes ──
        // MAC Address (left)
        InfoNode {
            centerX: parent.width / 2 - 245
            centerY: parent.height / 2
            icon: "󰒋"
            label: root.connectedDevice ? root.connectedDevice.address : ""
            subtitle: "MAC Address"
            visible: root.connectedDevice !== null
        }

        // Battery (top-right)
        InfoNode {
            centerX: parent.width / 2 + 245
            centerY: parent.height / 2 - 60
            icon: "󰥉"
            label: root.connectedDevice && root.connectedDevice.batteryAvailable ? Math.round(root.connectedDevice.battery * 100) + "%" : "N/A"
            subtitle: "Battery"
            visible: root.connectedDevice !== null
        }

        // Paired status (bottom)
        InfoNode {
            centerX: parent.width / 2
            centerY: parent.height / 2 + 165
            icon: "󰌾"
            label: root.connectedDevice && root.connectedDevice.paired ? "Paired" : "Not Paired"
            subtitle: "Status"
            visible: root.connectedDevice !== null
        }

        // Scan Devices button (top)
        InfoNode {
            centerX: parent.width / 2
            centerY: parent.height / 2 - 165
            icon: "󰍉"
            label: "Scan Devices"
            subtitle: "Switch View"
            isAction: true
            visible: root.connectedDevice !== null
            onActionClicked: root.showScanView = true
        }
    }

    // ══════════════════════════════════════════
    // SCANNING / EMPTY STATE (no connected device, not in scan list)
    // ══════════════════════════════════════════
    Item {
        id: scanningState
        anchors.fill: parent
        anchors.topMargin: 60
        anchors.bottomMargin: 16
        visible: !root.showScanView && root.connectedDevice === null && root.btEnabled
        opacity: visible ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: Theme.animSlow } }

        // Concentric rings
        Repeater {
            model: 3
            Rectangle {
                anchors.centerIn: parent
                width: 140 + index * 110
                height: width
                radius: width / 2
                color: "transparent"
                border.color: Theme.surface
                border.width: 1
                opacity: 0.35 - index * 0.08
            }
        }

        // Central scanning circle
        Rectangle {
            anchors.centerIn: parent
            width: 150; height: 150; radius: 75
            color: Theme.surface

            // Scanning pulse rings
            Repeater {
                model: 3
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width * 0.5; height: width; radius: width / 2
                    color: "transparent"
                    border.color: Theme.primary; border.width: 2
                    SequentialAnimation on scale {
                        running: scanningState.visible; loops: Animation.Infinite
                        PauseAnimation { duration: index * 400 }
                        NumberAnimation { from: 1.0; to: 2.5; duration: 2000; easing.type: Easing.OutSine }
                    }
                    SequentialAnimation on opacity {
                        running: scanningState.visible; loops: Animation.Infinite
                        PauseAnimation { duration: index * 400 }
                        NumberAnimation { from: 0.6; to: 0.0; duration: 2000; easing.type: Easing.OutSine }
                    }
                }
            }

            Column {
                anchors.centerIn: parent
                spacing: 2

                // The glyph sits in a fixed-height Item rather than laying out
                // on its own text metrics. At 40px this Nerd Font glyph's ink
                // overflows its line box, so a plain Column put the label
                // underneath *inside* the glyph — visibly overlapping (caught
                // from a screenshot). A fixed box makes ink and layout agree.
                Item {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 46; height: 46
                    Text {
                        anchors.centerIn: parent
                        text: "󰂯"
                        font.family: Theme.fontIcon
                        font.pixelSize: 38
                        color: Theme.primary
                        SequentialAnimation on opacity {
                            running: scanningState.visible; loops: Animation.Infinite
                            NumberAnimation { to: 0.45; duration: 1000; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 1.0; duration: 1000; easing.type: Easing.InOutSine }
                        }
                    }
                }
                Text {
                    font.family: Theme.fontFamily
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Scanning"
                    font.pixelSize: 12; font.bold: true
                    color: Theme.text
                }
                // Live count instead of a static label — the screen previously
                // said "Scanning..." forever with no evidence anything was
                // happening. This is the one number that proves it is.
                Text {
                    font.family: Theme.fontFamily
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: {
                        const n = (root.adapter && root.adapter.devices) ? root.adapter.devices.values.length : 0;
                        return n === 0 ? "no devices yet" : n + (n === 1 ? " device" : " devices");
                    }
                    font.pixelSize: 10
                    color: Theme.subtext0
                }
            }
        }

        // Scan Devices button. Pulled in from +140 to +120: the rings sweep out
        // to 2.5x of a 75px circle (~187px), so at +140 the button sat inside
        // their path and got visually crossed by every pulse.
        InfoNode {
            centerX: parent.width / 2
            centerY: parent.height / 2 + 120
            icon: "󰍉"
            label: "View Devices"
            subtitle: "Switch View"
            isAction: true
            onActionClicked: root.showScanView = true
        }
    }

    // ── Disabled state ──
    Item {
        anchors.fill: parent
        anchors.topMargin: 60
        visible: !root.btEnabled
        opacity: visible ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: Theme.animSlow } }

        Column {
            anchors.centerIn: parent
            spacing: 12
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "󰂲"
                font.family: Theme.fontIcon
                font.pixelSize: 48
                color: Theme.subtext0
            }
            Text {
                font.family: Theme.fontFamily;
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Bluetooth is Off"
                font.pixelSize: 14
                color: Theme.subtext0
            }
        }
    }

    // ══════════════════════════════════════════
    // SCAN / LIST VIEW
    // ══════════════════════════════════════════
    Item {
        id: scanView
        anchors.fill: parent
        anchors.topMargin: 60
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 24
        visible: root.showScanView && root.btEnabled
        opacity: visible ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: Theme.animSlow } }

        // Back to info view
        Rectangle {
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.top: parent.top
            width: infoBackRow.implicitWidth + 24
            height: 36; radius: 18
            color: infoBackMa.containsMouse ? Theme.surface : Theme.surface0
            z: 5
            Behavior on color { ColorAnimation { duration: Theme.animFast } }

            Row {
                id: infoBackRow
                anchors.centerIn: parent
                spacing: 8
                Text { text: "󰒓"; font.family: Theme.fontIcon; font.pixelSize: 14; color: Theme.text; anchors.verticalCenter: parent.verticalCenter }
                Text {
                    font.family: Theme.fontFamily; text: "View Info"; font.pixelSize: 12; font.bold: true; color: Theme.text; anchors.verticalCenter: parent.verticalCenter }
            }
            MouseArea {
                id: infoBackMa
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.showScanView = false
            }
        }

        ListView {
            id: scanList
            anchors.fill: parent
            anchors.topMargin: 44
            clip: true
            spacing: 4
            topMargin: 8
            bottomMargin: 28

            model: (root.adapter && root.btEnabled) ? root.adapter.devices.values : null

            delegate: Item {
                required property var modelData
                width: scanList.width
                height: 56

                Rectangle {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    radius: 14
                    color: btDelegateMa.containsMouse ? Theme.surface : "transparent"
                    border.color: modelData.connected ? Theme.primary : (btDelegateMa.containsMouse ? Theme.surface0 : "transparent")
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    height: 56
                    spacing: 12

                    // Icon ↔ spinner, same treatment as the Wi-Fi rows: pairing
                    // and connecting are slow, failure-prone operations, and
                    // previously only `pairing` surfaced at all (and only as
                    // static text, below the row title). BluetoothDeviceState's
                    // Connecting/Disconnecting and `pairing` are both live
                    // bindables (quickshell/src/bluetooth/device.hpp).
                    Item {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 22; height: 22

                        readonly property bool busy: modelData.pairing
                            || modelData.state === BluetoothDeviceState.Connecting
                            || modelData.state === BluetoothDeviceState.Disconnecting

                        Text {
                            anchors.centerIn: parent
                            text: modelData.connected ? "󰂱" : (modelData.paired ? "󰂯" : "󰂲")
                            font.family: Theme.fontIcon
                            font.pixelSize: 20
                            color: modelData.connected ? Theme.primary : Theme.subtext0
                            Behavior on color { ColorAnimation { duration: Theme.animFast } }
                            opacity: parent.busy ? 0 : 1
                            scale: parent.busy ? 0.7 : 1
                            Behavior on opacity { NumberAnimation { duration: 160 } }
                            Behavior on scale { NumberAnimation { duration: 220; easing.type: Theme.easeSpring } }
                        }

                        Spinner {
                            anchors.centerIn: parent
                            width: 18; height: 18
                            running: parent.busy
                            color: Theme.primary
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        Text {
                            font.family: Theme.fontFamily;
                            text: modelData.name || modelData.address || "Unknown"
                            font.pixelSize: 13; font.bold: modelData.connected
                            color: modelData.connected ? Theme.primary : Theme.text
                            elide: Text.ElideRight
                            width: scanList.width - 100
                        }
                        Text {
                            font.family: Theme.fontFamily;
                            // In-flight states are checked FIRST. Previously
                            // `paired` was tested before `pairing`, so a saved
                            // device being connected just read "Paired" — the
                            // one moment the user most needs to know something
                            // is happening was the one moment nothing changed.
                            readonly property bool busy: modelData.pairing
                                || modelData.state === BluetoothDeviceState.Connecting
                                || modelData.state === BluetoothDeviceState.Disconnecting
                            text: {
                                if (modelData.pairing) return "Pairing…"
                                if (modelData.state === BluetoothDeviceState.Connecting) return "Connecting…"
                                if (modelData.state === BluetoothDeviceState.Disconnecting) return "Disconnecting…"
                                if (modelData.connected) return "Connected"
                                if (modelData.paired) return "Paired"
                                return "Available"
                            }
                            font.pixelSize: 10
                            color: busy ? Theme.primary : Theme.subtext0
                            Behavior on color { ColorAnimation { duration: Theme.animFast } }
                        }
                    }
                }

                MouseArea {
                    id: btDelegateMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        if (modelData.connected) {
                            modelData.disconnect()
                        } else if (modelData.paired) {
                            modelData.connect()
                        } else {
                            modelData.pair()
                        }
                    }
                }
            }
        }

            // Overflow affordance — same treatment as the Wi-Fi scan list, so
            // a paired-device list that continues past the fold says so.
            ScrollFade {
                anchors.fill: scanList
                target: scanList
            }

            // Empty state in list view
            Column {
                anchors.centerIn: parent
                spacing: 8
                visible: scanList.count === 0
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "󰂯"
                    font.family: Theme.fontIcon
                    font.pixelSize: 32
                    color: Theme.subtext0
                }
                Text {
                    font.family: Theme.fontFamily;
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Scanning for devices..."
                    font.pixelSize: 13
                    color: Theme.subtext0
                }
            }
        }
    }

    // Only discovers while a scan screen (the device list, or the "looking
    // for something" placeholder that says "Scanning...") is actually on
    // screen — looking at an already-connected device's info view shouldn't
    // keep the radio scanning (real battery cost, was running unconditionally
    // any time Bluetooth was on, regardless of which screen was shown).
    readonly property bool scanActive: root.btEnabled && (root.showScanView || root.connectedDevice === null)

    // Write only on an actual change. The three entry points below (state
    // change, adapter arriving, component completing) all fired at startup and
    // each re-issued the same `discovering = true`, which BlueZ answers with
    // `Failed to start discovery ... "Operation already in progress"` — a
    // warning per redundant write, visible in the shell's log on every launch.
    function setDiscovering(on) {
        if (!root.adapter) return;
        if (root.adapter.discovering === on) return;
        root.adapter.discovering = on;
    }

    onScanActiveChanged: root.setDiscovering(scanActive)
    onAdapterChanged: root.setDiscovering(scanActive)
    Component.onCompleted: root.setDiscovering(scanActive)
    Component.onDestruction: root.setDiscovering(false)
}
