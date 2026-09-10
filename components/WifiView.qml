import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking
import "../core"

Item {
    id: root

    property var stack: null
    property bool showScanView: false

    // `type` is a CONSTANT property (NetworkDevice, quickshell/src/network/device.hpp)
    // — reading it here creates no reactive dependency, unlike the previous
    // `scannerEnabled !== undefined` duck-type check, which did: scannerEnabled
    // is itself a live bindable this view writes to (see the scanning-indicator
    // block below), so reading it inside this same binding caused a real
    // "Binding loop detected for property wifiDevice" warning the moment
    // scanning state started reacting to view changes instead of being a
    // one-shot Component.onCompleted write.
    property QtObject wifiDevice: {
        let devs = Networking.devices ? Networking.devices.values : [];
        for (let i = 0; i < devs.length; i++) {
            if (devs[i].type === DeviceType.Wifi) return devs[i];
        }
        return null;
    }

    property var connectedNetwork: {
        if (!root.wifiDevice || !Networking.wifiEnabled) return null;
        let nets = root.wifiDevice.networks.values;
        for (let i = 0; i < nets.length; i++) {
            if (nets[i].connected) return nets[i];
        }
        return null;
    }

    // ── Back Button ──
    Rectangle {
        id: backBtn
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
        color: Networking.wifiEnabled ? Theme.primary : Theme.surface
        Behavior on color { ColorAnimation { duration: Theme.animFast } }
        Rectangle {
            width: 20; height: 20; radius: 10
            color: Theme.background; y: 2
            x: Networking.wifiEnabled ? 26 : 2
            Behavior on x { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easeSpring } }
        }
        MouseArea { anchors.fill: parent; onClicked: Networking.wifiEnabled = !Networking.wifiEnabled }
    }

    // ── Title ──
    Text {
        font.family: Theme.fontFamily;
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 24
        text: "Wi-Fi"
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
        visible: !root.showScanView && root.connectedNetwork !== null
        opacity: visible ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: Theme.animSlow } }

        // Concentric ring decorations
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
                opacity: 0.4 - index * 0.1
            }
        }

        // ── Central Circle ──
        Rectangle {
            id: centralCircle
            anchors.centerIn: parent
            width: 150; height: 150; radius: 75
            color: Theme.primary
            scale: connectedNetwork ? 1.0 : 0.5
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
                    text: "󰤨"
                    font.family: Theme.fontIcon
                    font.pixelSize: 44
                    color: Theme.colorOnPrimary
                }
                Text {
                    font.family: Theme.fontFamily;
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.connectedNetwork ? root.connectedNetwork.name : ""
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
                onClicked: if (root.connectedNetwork) root.connectedNetwork.disconnect()
            }
        }

        // ── Info nodes positioned around circle ──
        // Signal Strength (top-right)
        InfoNode {
            centerX: parent.width / 2 + 235
            centerY: parent.height / 2 - 70
            icon: "󰤨"
            label: root.connectedNetwork ? Math.round(root.connectedNetwork.signalStrength * 100) + "%" : ""
            subtitle: "Signal Strength"
            visible: root.connectedNetwork !== null
        }

        // Security (bottom)
        InfoNode {
            centerX: parent.width / 2
            centerY: parent.height / 2 + 165
            icon: "󰌾"
            label: {
                if (!root.connectedNetwork) return "";
                let s = root.connectedNetwork.security;
                if (s === 1) return "WEP";
                if (s === 2) return "WPA-PSK";
                if (s === 3) return "WPA-EAP";
                if (s === 4) return "SAE";
                return "Open";
            }
            subtitle: "Security"
            visible: root.connectedNetwork !== null
        }

        // Scan Devices button (top-left)
        InfoNode {
            centerX: parent.width / 2 - 235
            centerY: parent.height / 2 - 70
            icon: "󰍉"
            label: "Scan Networks"
            subtitle: "Switch View"
            isAction: true
            visible: root.connectedNetwork !== null
            onActionClicked: root.showScanView = true
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
        visible: root.showScanView || root.connectedNetwork === null
        opacity: visible ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: Theme.animSlow } }

        // Back to info if connected
        Rectangle {
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.top: parent.top
            width: infoBackRow.implicitWidth + 24
            height: 36; radius: 18
            color: infoBackMa.containsMouse ? Theme.surface : Theme.surface0
            visible: root.connectedNetwork !== null && root.showScanView
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
            anchors.topMargin: root.connectedNetwork !== null && root.showScanView ? 44 : 0
            clip: true
            spacing: 4
            topMargin: 8
            bottomMargin: 16

            model: (root.wifiDevice && Networking.wifiEnabled) ? root.wifiDevice.networks.values : null

            delegate: Item {
                id: delegateWrapper
                required property var modelData
                width: scanList.width
                height: isExpanded ? 100 : 52

                property bool isExpanded: false

                Behavior on height { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easeSpring } }

                Rectangle {
                    id: networkDelegate
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    radius: 14
                    color: delegateMa.containsMouse ? Theme.surface : "transparent"
                    border.color: modelData.connected ? Theme.primary : (delegateMa.containsMouse ? Theme.surface0 : "transparent")
                    border.width: 1
                    clip: true

                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    height: 52
                    spacing: 12

                    // Signal bars ↔ spinner. Clicking a network used to give no
                    // feedback whatsoever — connect() fired and the row sat
                    // unchanged until it either worked or didn't, so the only
                    // way to tell a click had registered was to wait. The
                    // signal icon now becomes a spinner for exactly as long as
                    // the operation is in flight. `stateChanging` is a live
                    // bindable on Network (quickshell/src/network/network.hpp),
                    // so this tracks the real operation, not a guessed timeout.
                    Item {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 20; height: 20

                        Text {
                            anchors.centerIn: parent
                            text: {
                                if (modelData.connected) return "󰤨"
                                if (modelData.signalStrength > 0.75) return "󰤨"
                                if (modelData.signalStrength > 0.5) return "󰤥"
                                if (modelData.signalStrength > 0.25) return "󰤢"
                                return "󰤟"
                            }
                            font.family: Theme.fontIcon
                            font.pixelSize: 18
                            color: modelData.connected ? Theme.primary : Theme.subtext0
                            Behavior on color { ColorAnimation { duration: Theme.animFast } }
                            // Cross-fade with the spinner rather than swapping,
                            // so a sub-200ms connect doesn't strobe.
                            opacity: modelData.stateChanging ? 0 : 1
                            scale: modelData.stateChanging ? 0.7 : 1
                            Behavior on opacity { NumberAnimation { duration: 160 } }
                            Behavior on scale { NumberAnimation { duration: 220; easing.type: Theme.easeSpring } }
                        }

                        Spinner {
                            anchors.centerIn: parent
                            width: 16; height: 16
                            running: modelData.stateChanging
                            color: Theme.primary
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        Text {
                            font.family: Theme.fontFamily;
                            text: modelData.name || "Hidden Network"
                            font.pixelSize: 13; font.bold: modelData.connected
                            color: modelData.connected ? Theme.primary : Theme.text
                            elide: Text.ElideRight
                            width: scanList.width - 120
                        }
                        Text {
                            font.family: Theme.fontFamily;
                            // Says what is actually happening while it happens,
                            // instead of showing a stale signal percentage.
                            text: {
                                if (modelData.stateChanging)
                                    return modelData.connected ? "Disconnecting…" : "Connecting…";
                                if (modelData.connected) return "Connected";
                                if (modelData.known) return "Saved";
                                return Math.round(modelData.signalStrength * 100) + "%";
                            }
                            font.pixelSize: 10
                            color: modelData.stateChanging ? Theme.primary : Theme.subtext0
                            Behavior on color { ColorAnimation { duration: Theme.animFast } }
                        }
                    }
                }

                // Lock icon
                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.top: parent.top
                    anchors.topMargin: 16
                    text: modelData.security !== 0 ? "󰌾" : ""
                    font.family: Theme.fontIcon
                    font.pixelSize: 14
                    color: Theme.subtext0
                    visible: modelData.security !== 0
                }

                // Password row
                RowLayout {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 8
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    height: 32
                    visible: delegateWrapper.isExpanded
                    opacity: delegateWrapper.isExpanded ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: Theme.animFast } }

                    Rectangle {
                        Layout.fillWidth: true; height: 32; radius: 8
                        color: Theme.background
                        border.color: Theme.surface0; border.width: 1
                        TextInput {
                            font.family: Theme.fontFamily;
                            id: pwdInput
                            anchors.fill: parent
                            anchors.leftMargin: 12; anchors.rightMargin: 12
                            verticalAlignment: TextInput.AlignVCenter
                            font.pixelSize: 13; color: Theme.text
                            echoMode: TextInput.Password; clip: true
                            onAccepted: {
                                modelData.connectWithPsk(pwdInput.text)
                                networkDelegate.isExpanded = false
                            }
                        }
                    }
                    Rectangle {
                        width: 32; height: 32; radius: 8
                        color: Theme.primary
                        Text { anchors.centerIn: parent; text: "󰒄"; font.family: Theme.fontIcon; font.pixelSize: 14; color: Theme.colorOnPrimary }
                        MouseArea { anchors.fill: parent; onClicked: { modelData.connectWithPsk(pwdInput.text); networkDelegate.isExpanded = false } }
                    }
                }

                MouseArea {
                    id: delegateMa
                    anchors.fill: parent
                    anchors.bottomMargin: networkDelegate.isExpanded ? 40 : 0
                    hoverEnabled: true
                    onClicked: {
                        if (modelData.connected) {
                            modelData.disconnect()
                        } else if (modelData.known || modelData.security === 0) {
                            modelData.connect()
                        } else {
                            delegateWrapper.isExpanded = !delegateWrapper.isExpanded
                            if (delegateWrapper.isExpanded) pwdInput.forceActiveFocus()
                        }
                    }
                }
            }
        }

            // Empty state. While scanning, the label used to sit perfectly
            // still — indistinguishable from a hung scan. It now breathes, so
            // "still looking" is visible without adding a second widget.
            Item {
                anchors.centerIn: parent
                width: emptyRow.implicitWidth
                height: 20
                visible: scanList.count === 0

                Row {
                    id: emptyRow
                    anchors.centerIn: parent
                    spacing: 8

                    Spinner {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 14; height: 14
                        running: Networking.wifiEnabled
                        color: Theme.subtext0
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        font.family: Theme.fontFamily
                        text: Networking.wifiEnabled ? "Scanning…" : "Wi-Fi is Off"
                        font.pixelSize: 14
                        color: Theme.subtext0

                        SequentialAnimation on opacity {
                            running: Networking.wifiEnabled && scanList.count === 0
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.45; duration: 900; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 1.0; duration: 900; easing.type: Easing.InOutSine }
                            onStopped: parent.opacity = 1
                        }
                    }
                }
            }
        }

        // Overflow affordance — only visible at an edge that actually has
        // more content past it. Sibling *after* the list so it draws on top.
        ScrollFade {
            anchors.fill: scanList
            target: scanList
        }
    }

    // ── Scanning indicator ──
    // Only scans while the scan list is actually the thing on screen — either
    // shown by default (nothing connected) or after switching to it. Opening
    // this view just to check an already-connected network's info shouldn't
    // spin up the radio (real battery cost, was running unconditionally).
    readonly property bool scanListVisible: root.showScanView || root.connectedNetwork === null
    onScanListVisibleChanged: if (root.wifiDevice) root.wifiDevice.scannerEnabled = scanListVisible
    onWifiDeviceChanged: if (root.wifiDevice) root.wifiDevice.scannerEnabled = scanListVisible
    Component.onCompleted: {
        if (root.wifiDevice) root.wifiDevice.scannerEnabled = scanListVisible;
    }
    Component.onDestruction: {
        if (root.wifiDevice) root.wifiDevice.scannerEnabled = false;
    }
}
