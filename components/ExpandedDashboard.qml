import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Networking
import Quickshell.Bluetooth
import "../core"

Item {
    id: root
    property var stack: null
    property int currentTab: 0

    Component { id: wifiViewComp; WifiView { stack: root.stack } }
    Component { id: btViewComp; BluetoothView { stack: root.stack } }
    Component { id: audioViewComp; AudioView { stack: root.stack } }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 16

        // ── Top Navigation Bar ──
        Item {
            id: tabBar
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            Layout.maximumHeight: 48
            Layout.minimumHeight: 48

            readonly property int tabSpacing: 16
            readonly property real cellWidth: (width - 3 * tabSpacing) / 4

            // Active-tab pill physically slides between tabs
            Rectangle {
                id: tabIndicator
                width: tabBar.cellWidth
                height: parent.height
                x: root.currentTab * (tabBar.cellWidth + tabBar.tabSpacing)
                radius: 12
                color: Theme.surface0
                Behavior on x { NumberAnimation { duration: 380; easing.type: Easing.OutBack; easing.overshoot: 1.15 } }
            }

            RowLayout {
                anchors.fill: parent
                spacing: tabBar.tabSpacing

                Repeater {
                    model: [
                        { name: "Dashboard", icon: "󰂚" },
                        { name: "Widgets", icon: "󰕮" },
                        { name: "Media", icon: "󰝚" },
                        { name: "Performance", icon: "󰓅" }
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 12

                        // Highlight tracks the sliding pill, not the click — the label
                        // lights up the moment the pill physically arrives under it.
                        readonly property real cellX: index * (tabBar.cellWidth + tabBar.tabSpacing)
                        readonly property bool highlighted: {
                            const c = tabIndicator.x + tabIndicator.width / 2;
                            return c >= cellX && c < cellX + tabBar.cellWidth;
                        }

                        color: tabMouse.containsMouse && !highlighted ? Theme.surface : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }

                        Row {
                            anchors.centerIn: parent
                            spacing: 8
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.icon
                                font.family: Theme.fontIcon
                                font.pixelSize: 16
                                color: highlighted ? Theme.primary : Theme.subtext0
                                scale: highlighted ? 1.15 : 1.0
                                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                                Behavior on scale { NumberAnimation { duration: 300; easing.type: Theme.easeSpring } }
                            }
                            Text {
                                font.family: Theme.fontFamily;
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.name
                                font.pixelSize: 14
                                font.bold: highlighted
                                color: highlighted ? Theme.text : Theme.subtext0
                                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                            }
                        }

                        MouseArea {
                            id: tabMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.currentTab = index
                        }
                    }
                }
            }
        }

        // ── Tab Content Area ──
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // ── 0. Dashboard (formerly Hub) ──
            Item {
                width: parent.width; height: parent.height
                x: root.currentTab === 0 ? 0 : (root.currentTab > 0 ? -28 : 28)
                opacity: root.currentTab === 0 ? 1 : 0
                visible: opacity > 0
                scale: root.currentTab === 0 ? 1 : 0.95
                Behavior on x { NumberAnimation { duration: Theme.animSlow; easing.type: Easing.OutQuint } }
                Behavior on opacity { NumberAnimation { duration: Theme.animSlow } }
                Behavior on scale { NumberAnimation { duration: Theme.animSlow; easing.type: Easing.OutQuart } }
                
                ColumnLayout {
                    id: dashboardTab
                    anchors.fill: parent
                    spacing: 16
                    
                    property bool nightModeEnabled: false
                    property bool gameModeEnabled: false
                    property bool caffeineEnabled: false
                    property bool powerMenuOpen: false
                    property string uptimeText: "…"

                    // Real uptime from /proc/uptime, refreshed every 30 s
                    Process {
                        id: uptimeProc
                        command: ["cat", "/proc/uptime"]
                        stdout: SplitParser {
                            onRead: line => {
                                const s = parseFloat(line.split(" ")[0]);
                                if (isNaN(s)) return;
                                const d = Math.floor(s / 86400);
                                const h = Math.floor((s % 86400) / 3600);
                                const m = Math.floor((s % 3600) / 60);
                                dashboardTab.uptimeText = "Up " + (d > 0 ? d + "d " : "") + h + "h " + m + "m";
                            }
                        }
                    }
                    Timer {
                        interval: 30000; running: true; repeat: true; triggeredOnStart: true
                        onTriggered: uptimeProc.running = true
                    }

                    // System Header
                    RowLayout {
                        id: dashboardHeader
                        Layout.fillWidth: true
                        spacing: 8
                        z: 100
                        // Borderless on purpose — the pill never tracked the text width well
                        Item {
                            width: uptimeRow.implicitWidth
                            height: 36
                            Row {
                                id: uptimeRow
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 10

                                // "System alive" heartbeat: green dot with an expanding ping ring
                                Item {
                                    width: 10; height: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                    Rectangle {
                                        id: pingRing
                                        anchors.centerIn: parent
                                        width: 8; height: 8; radius: 4
                                        color: "transparent"
                                        border.color: Theme.green
                                        border.width: 1
                                        opacity: 0
                                        SequentialAnimation {
                                            running: true; loops: Animation.Infinite
                                            ParallelAnimation {
                                                NumberAnimation { target: pingRing; property: "scale"; from: 1; to: 2.6; duration: 1100; easing.type: Easing.OutQuad }
                                                NumberAnimation { target: pingRing; property: "opacity"; from: 0.9; to: 0; duration: 1100 }
                                            }
                                            PauseAnimation { duration: 1900 }
                                        }
                                    }
                                    Rectangle {
                                        id: aliveDot
                                        anchors.centerIn: parent
                                        width: 8; height: 8; radius: 4
                                        color: Theme.green
                                        SequentialAnimation on scale {
                                            loops: Animation.Infinite
                                            NumberAnimation { to: 1.25; duration: 1500; easing.type: Easing.InOutSine }
                                            NumberAnimation { to: 1.0; duration: 1500; easing.type: Easing.InOutSine }
                                        }
                                    }
                                }

                                Text {
                                    font.family: Theme.fontFamily; text: dashboardTab.uptimeText; font.pixelSize: 13; font.bold: true; color: Theme.text; anchors.verticalCenter: parent.verticalCenter }
                            }
                        }
                        Item { Layout.fillWidth: true } // Spacer

                        // System tray — native Quickshell.Services.SystemTray, no
                        // separate polling/watcher needed. Right-click opens the
                        // item's own DBus menu via QsMenuAnchor (see TrayItem.qml).
                        //
                        // Was disabled 2026-07-29 for crash bisection: every reported
                        // SIGSEGV (~/.cache/quickshell/crashes/) shared one stacktrace —
                        // QQuickItem::window() called on a freed item during a StackView
                        // teardown cascade (dashboard collapse destroys this subtree).
                        // Root cause found in TrayItem.qml's QsMenuAnchor usage, fixed
                        // there — see that file's comment. Re-enabled.
                        Row {
                            spacing: 4
                            Layout.alignment: Qt.AlignVCenter
                            Repeater {
                                // Index into .values instead of binding the delegate's
                                // "modelData" directly — this Repeater sits deep inside the
                                // outer per-monitor Variants{model: Quickshell.screens} in
                                // shell.qml, which also injects a "modelData" (the
                                // QuickshellScreenInfo); nesting two same-named loop
                                // variables resolved to the wrong one here (verified via a
                                // live "Unable to assign QuickshellScreenInfo to
                                // StatusNotifierItem" QML warning) — index-based access
                                // sidesteps the ambiguity entirely.
                                model: SystemTray.items.values.length
                                delegate: TrayItem {
                                    required property int index
                                    trayItem: SystemTray.items.values[index]
                                }
                            }
                        }

                        // Reload shell — spins once, then Quickshell reloads the config
                        IconButton {
                            id: reloadBtn
                            width: 36; height: 36; text: "󰑐"
                            Behavior on rotation { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
                            onClicked: { rotation += 360; Quickshell.reload(false) }
                        }
                        // Launches the standalone settings app (settings.qml entry point).
                        // Path comes from Settings.settingsAppPath (core/Settings.qml), NOT a
                        // local Qt.resolvedUrl() here — see that property's comment for why:
                        // resolving it from this dynamically-instantiated component produced
                        // a Quickshell-internal "qs:@/qs/settings.qml" pseudo-path instead of
                        // a real file:// one, so the button silently launched a nonexistent path.
                        IconButton {
                            id: settingsBtn
                            width: 36; height: 36; text: "󰒓"
                            // execDetached has no running-instance guard (unlike shell.qml/
                            // launcher.qml, which the `wisp` CLI singleton-guards via
                            // running_pids) — a debounce here is the cheapest thing that
                            // stops a double-click (or a hitch mid-animation) from spawning
                            // N stacked settings.qml processes.
                            property bool launching: false
                            onClicked: {
                                if (launching) return;
                                launching = true;
                                Quickshell.execDetached(["/usr/bin/qs", "-p", Settings.settingsAppPath]);
                                launchCooldown.start();
                            }
                            Timer { id: launchCooldown; interval: 1000; onTriggered: settingsBtn.launching = false }
                        }

                        // Power button + dropdown menu
                        Item {
                            id: powerButtonWrap
                            width: 36; height: 36

                            IconButton {
                                id: powerBtn
                                anchors.fill: parent
                                text: "󰐥"
                                color: Theme.red
                                isChecked: dashboardTab.powerMenuOpen
                                onClicked: dashboardTab.powerMenuOpen = !dashboardTab.powerMenuOpen
                            }

                            Rectangle {
                                id: powerMenu
                                anchors.top: powerBtn.bottom
                                anchors.topMargin: 8
                                anchors.right: powerBtn.right
                                width: 196
                                height: powerMenuCol.implicitHeight + 16
                                radius: 14
                                color: Theme.surface
                                transformOrigin: Item.TopRight
                                visible: opacity > 0
                                opacity: dashboardTab.powerMenuOpen ? 1.0 : 0.0
                                scale: dashboardTab.powerMenuOpen ? 1.0 : 0.9
                                Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                                Behavior on scale { NumberAnimation { duration: Theme.animSlow; easing.type: Theme.easeSpring } }

                                Column {
                                    id: powerMenuCol
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 2

                                    Repeater {
                                        model: [
                                            // Own native lock screen (lock.qml entry point), not loginctl —
                                            // nothing on this host listens for the lock-session signal
                                            { label: "Lock", icon: "󰌾", danger: false, hold: false, cmd: ["/usr/bin/qs", "-p", Settings.lockAppPath] },
                                            { label: "Log Out", icon: "󰍃", danger: false, hold: true, cmd: ["hyprctl", "dispatch", "hl.dsp.exit()"] },
                                            { label: "Restart", icon: "󰑐", danger: false, hold: true, cmd: ["bash", "-c", "systemctl reboot || loginctl reboot"] },
                                            { label: "Shut Down", icon: "󰐥", danger: true, hold: true, cmd: ["bash", "-c", "systemctl poweroff || loginctl poweroff"] }
                                        ]
                                        delegate: Rectangle {
                                            id: powerRow
                                            required property var modelData
                                            width: powerMenuCol.width
                                            height: 38
                                            radius: 10
                                            clip: true
                                            color: itemMa.containsMouse ? Theme.surface0 : "transparent"
                                            Behavior on color { ColorAnimation { duration: Theme.animFast } }

                                            readonly property color accent: modelData.danger ? Theme.red : Theme.primary
                                            property real holdProgress: 0

                                            // Staggered cascade: each row slides in a beat after the previous
                                            opacity: dashboardTab.powerMenuOpen ? 1 : 0
                                            x: dashboardTab.powerMenuOpen ? 0 : 16
                                            Behavior on opacity {
                                                SequentialAnimation {
                                                    PauseAnimation { duration: index * 40 }
                                                    NumberAnimation { duration: 160 }
                                                }
                                            }
                                            Behavior on x {
                                                SequentialAnimation {
                                                    PauseAnimation { duration: index * 40 }
                                                    NumberAnimation { duration: 240; easing.type: Easing.OutQuint }
                                                }
                                            }

                                            // Hold-to-confirm fill sweeping left to right
                                            Rectangle {
                                                anchors.left: parent.left
                                                height: parent.height
                                                width: parent.width * powerRow.holdProgress
                                                radius: powerRow.radius
                                                color: powerRow.accent
                                                opacity: 0.3
                                                visible: powerRow.holdProgress > 0
                                            }

                                            NumberAnimation {
                                                id: holdAnim
                                                target: powerRow; property: "holdProgress"
                                                from: 0; to: 1; duration: 650
                                                onFinished: {
                                                    Quickshell.execDetached(modelData.cmd);
                                                    dashboardTab.powerMenuOpen = false;
                                                    powerRow.holdProgress = 0;
                                                }
                                            }
                                            NumberAnimation {
                                                id: holdCancel
                                                target: powerRow; property: "holdProgress"
                                                to: 0; duration: 160; easing.type: Easing.OutQuad
                                            }

                                            Row {
                                                anchors.left: parent.left
                                                anchors.leftMargin: 8
                                                anchors.verticalCenter: parent.verticalCenter
                                                spacing: 10

                                                // Icon chip — fills with the row accent on hover
                                                Rectangle {
                                                    width: 26; height: 26; radius: 8
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    color: itemMa.containsMouse ? powerRow.accent : Theme.surface0
                                                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: modelData.icon
                                                        font.family: Theme.fontIcon
                                                        font.pixelSize: 13
                                                        color: itemMa.containsMouse ? Theme.background : (modelData.danger ? Theme.red : Theme.text)
                                                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                                                    }
                                                }

                                                Text {
                                                    font.family: Theme.fontFamily;
                                                    text: modelData.label
                                                    font.pixelSize: 13
                                                    font.bold: itemMa.containsMouse
                                                    color: modelData.danger ? Theme.red : Theme.text
                                                    anchors.verticalCenter: parent.verticalCenter
                                                }
                                            }

                                            // Hover hint for hold-to-confirm rows
                                            Text {
                                                font.family: Theme.fontFamily;
                                                anchors.right: parent.right
                                                anchors.rightMargin: 10
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: "hold"
                                                font.pixelSize: 10
                                                color: Theme.subtext0
                                                opacity: modelData.hold && itemMa.containsMouse && powerRow.holdProgress === 0 ? 0.7 : 0
                                                Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                                            }

                                            MouseArea {
                                                id: itemMa
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                onPressed: if (modelData.hold) { holdCancel.stop(); holdAnim.restart() }
                                                onReleased: if (modelData.hold && powerRow.holdProgress < 1) { holdAnim.stop(); holdCancel.restart() }
                                                onExited: if (modelData.hold && holdAnim.running) { holdAnim.stop(); holdCancel.restart() }
                                                onClicked: {
                                                    if (!modelData.hold) {
                                                        Quickshell.execDetached(modelData.cmd);
                                                        dashboardTab.powerMenuOpen = false;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Sliders
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 88
                        radius: 20; color: Theme.surface
                        ColumnLayout {
                            anchors.fill: parent; anchors.margins: 16; spacing: 12
                            RowLayout {
                                Layout.fillWidth: true; spacing: 12
                                Slider { Layout.fillWidth: true; value: Audio.volume; onMoved: function(v) { Audio.setVolume(v) } }
                                Text {
                                    text: Audio.muted ? "󰝟" : "󰕾"
                                    font.family: Theme.fontIcon; font.pixelSize: 16
                                    color: Audio.muted ? Theme.red : Theme.subtext0
                                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                                    scale: volMuteMa.containsMouse ? 1.2 : 1.0
                                    Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easeSpring } }
                                    MouseArea { id: volMuteMa; anchors.fill: parent; anchors.margins: -6; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Audio.toggleMute() }
                                }
                                IconButton { width: 24; height: 24; text: "󰅂"; iconSize: 14; onClicked: if(root.stack) root.stack.push(audioViewComp) }
                            }
                            RowLayout {
                                Layout.fillWidth: true; spacing: 12
                                Slider { Layout.fillWidth: true; value: Audio.micVolume; onMoved: function(v) { Audio.setMicVolume(v) } }
                                Text {
                                    text: Audio.micMuted ? "󰍭" : "󰍬"
                                    font.family: Theme.fontIcon; font.pixelSize: 16
                                    color: Audio.micMuted ? Theme.red : Theme.subtext0
                                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                                    scale: micMuteMa.containsMouse ? 1.2 : 1.0
                                    Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easeSpring } }
                                    MouseArea { id: micMuteMa; anchors.fill: parent; anchors.margins: -6; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Audio.toggleMicMute() }
                                }
                                Item { width: 24; height: 1 } // Aligns the mic icon with the volume icon above
                            }
                        }
                    }

                    // Quick Toggles
                    RowLayout {
                        Layout.fillWidth: true; Layout.alignment: Qt.AlignHCenter; spacing: 12
                        IconButton { width: 44; height: 44; text: "󰤨"; isChecked: Networking.wifiEnabled; onClicked: if(root.stack) root.stack.push(wifiViewComp) }
                        IconButton { width: 44; height: 44; text: "󰂯"; property var adapter: Bluetooth.defaultAdapter; isChecked: adapter ? adapter.enabled : false; onClicked: if(root.stack) root.stack.push(btViewComp) }
                        
                        // Night Mode
                        IconButton { 
                            width: 44; height: 44; text: "󰖔"
                            isChecked: dashboardTab.nightModeEnabled
                            onClicked: {
                                dashboardTab.nightModeEnabled = !dashboardTab.nightModeEnabled;
                                let scriptPath = Settings.nightmodeScriptPath;
                                let cmd = dashboardTab.nightModeEnabled ? ("bash " + scriptPath + " 1 &") : ("bash " + scriptPath + " 0 &");
                                Quickshell.execDetached(["bash", "-c", cmd]);
                            }
                        }
                        // Game Mode
                        IconButton { 
                            width: 44; height: 44; text: "󰊴"
                            isChecked: dashboardTab.gameModeEnabled
                            onClicked: {
                                dashboardTab.gameModeEnabled = !dashboardTab.gameModeEnabled;
                                // Game mode strips eye candy, so effects are the inverse of the toggle.
                                let fx = !dashboardTab.gameModeEnabled;
                                Quickshell.execDetached(["hyprctl", "eval",
                                    `hl.config({ decoration = { blur = { enabled = ${fx} } }, animations = { enabled = ${fx} }, debug = { vfr = ${fx} } })`]);
                            }
                        }
                        // Caffeine
                        IconButton { 
                            width: 44; height: 44; text: "󰅶"
                            isChecked: dashboardTab.caffeineEnabled
                            onClicked: {
                                dashboardTab.caffeineEnabled = !dashboardTab.caffeineEnabled;
                                let cmd = dashboardTab.caffeineEnabled ? "killall -STOP hypridle" : "killall -CONT hypridle";
                                Quickshell.execDetached(["bash", "-c", cmd]);
                            }
                        }
                        // Wallpaper — launches the standalone fullscreen picker (wallpaper.qml)
                        // rather than pushing an in-widget browser; keeps exactly one wallpaper-
                        // apply codepath instead of two copies of the same swww/hyprpaper command.
                        IconButton { width: 44; height: 44; text: "󰸉"; isChecked: false; onClicked: Quickshell.execDetached(["/usr/bin/qs", "-p", Settings.wallpaperAppPath]) }
                    }

                    // Notifications — grouped by app, swipe-to-dismiss, per-notif actions.
                    NotificationCard {
                        Layout.fillWidth: true; Layout.fillHeight: true
                    }
                }

                // Closes the power menu on any click outside it
                MouseArea {
                    anchors.fill: dashboardTab
                    z: 99
                    visible: dashboardTab.powerMenuOpen
                    enabled: dashboardTab.powerMenuOpen
                    onClicked: dashboardTab.powerMenuOpen = false
                }
            }

            // ── 1. Widgets ──
            Item {
                width: parent.width; height: parent.height
                x: root.currentTab === 1 ? 0 : (root.currentTab > 1 ? -28 : 28)
                opacity: root.currentTab === 1 ? 1 : 0
                visible: opacity > 0
                scale: root.currentTab === 1 ? 1 : 0.95
                Behavior on x { NumberAnimation { duration: Theme.animSlow; easing.type: Easing.OutQuint } }
                Behavior on opacity { NumberAnimation { duration: Theme.animSlow } }
                Behavior on scale { NumberAnimation { duration: Theme.animSlow; easing.type: Easing.OutQuart } }
                
                RowLayout {
                    anchors.fill: parent
                    spacing: 16

                    WeatherCard {
                        visible: Settings.conf.weather.enable
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }

                    CalendarCard {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }
                }
            }

            // ── 2. Media ──
            Item {
                width: parent.width; height: parent.height
                x: root.currentTab === 2 ? 0 : (root.currentTab > 2 ? -28 : 28)
                opacity: root.currentTab === 2 ? 1 : 0
                visible: opacity > 0
                scale: root.currentTab === 2 ? 1 : 0.95
                Behavior on x { NumberAnimation { duration: Theme.animSlow; easing.type: Easing.OutQuint } }
                Behavior on opacity { NumberAnimation { duration: Theme.animSlow } }
                Behavior on scale { NumberAnimation { duration: Theme.animSlow; easing.type: Easing.OutQuart } }
                
                MediaCard {
                    anchors.fill: parent
                    anchors.margins: 12
                }
            }

            // ── 3. Performance ──
            Item {
                width: parent.width; height: parent.height
                x: root.currentTab === 3 ? 0 : 28
                opacity: root.currentTab === 3 ? 1 : 0
                visible: opacity > 0
                scale: root.currentTab === 3 ? 1 : 0.95
                Behavior on x { NumberAnimation { duration: Theme.animSlow; easing.type: Easing.OutQuint } }
                Behavior on opacity { NumberAnimation { duration: Theme.animSlow } }
                Behavior on scale { NumberAnimation { duration: Theme.animSlow; easing.type: Easing.OutQuart } }
                
                PerformanceCard {
                    anchors.fill: parent
                    anchors.margins: 12
                    active: root.currentTab === 3
                }
            }
        }
    }
}
