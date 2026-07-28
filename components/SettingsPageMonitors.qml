import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../core"

// Monitor configuration — visual style inspired by illyamiro's settings
// (monitor illustration + resolution preset chips + refresh-rate row), but
// applied through the lua parser: hl.monitor({ output, mode, position, scale }).
// Runtime only; a Hyprland reload restores the user's own monitor config.
CfgPage {
    id: page

    property var monitors: []
    property int selMonitor: 0
    property string pendingRes: ""
    property int pendingRate: 0
    property int pendingScale: 100   // scale × 100

    readonly property var mon: monitors.length > selMonitor ? monitors[selMonitor] : null

    // Unique resolutions from availableModes, highest first
    readonly property var resolutions: {
        if (!mon) return [];
        const seen = {};
        const out = [];
        for (const m of (mon.availableModes || [])) {
            const res = m.split("@")[0];
            if (!seen[res]) { seen[res] = true; out.push(res); }
        }
        return out;
    }

    // Unique refresh rates for the pending resolution
    readonly property var rates: {
        if (!mon) return [];
        const seen = {};
        const out = [];
        for (const m of (mon.availableModes || [])) {
            const parts = m.split("@");
            if (parts[0] !== page.pendingRes) continue;
            const r = Math.round(parseFloat(parts[1]));
            if (!seen[r]) { seen[r] = true; out.push(r); }
        }
        return out.sort((a, b) => a - b);
    }

    function resLabel(res) {
        const names = {
            "3840x2160": "4K", "2560x1440": "QHD", "1920x1080": "FHD",
            "1600x900": "HD+", "1366x768": "WXGA", "1280x720": "HD",
            "1024x768": "XGA", "800x600": "SVGA",
            "2560x1080": "UWFHD", "3440x1440": "UWQHD"
        };
        return names[res] || res.split("x")[0] + "p";
    }

    function seedFromMonitor() {
        if (!mon) return;
        pendingRes = mon.width + "x" + mon.height;
        pendingRate = Math.round(mon.refreshRate);
        pendingScale = Math.round(mon.scale * 100);
    }

    function apply() {
        if (!mon || pendingRes === "" || pendingRate === 0) return;
        Settings.lua('hl.monitor({ output = "' + mon.name
            + '", mode = "' + pendingRes + "@" + pendingRate
            + '", position = "' + mon.x + "x" + mon.y
            + '", scale = ' + (pendingScale / 100) + " })");
        refreshTimer.restart();
    }

    Process {
        id: monProc
        command: ["hyprctl", "monitors", "-j"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    page.monitors = JSON.parse(this.text.trim());
                    if (page.selMonitor >= page.monitors.length) page.selMonitor = 0;
                    page.seedFromMonitor();
                } catch (e) {}
            }
        }
    }
    Timer { id: refreshTimer; interval: 800; onTriggered: monProc.running = true }

    onSelMonitorChanged: seedFromMonitor()

    CfgNotice {
        text: "Applied at runtime via hl.monitor — your monitors.lua stays untouched. A Hyprland reload restores your own layout."
    }

    // ── Monitor selector (multi-monitor only) ──
    RowLayout {
        visible: page.monitors.length > 1
        Layout.fillWidth: true
        spacing: 8
        Repeater {
            model: page.monitors
            delegate: Rectangle {
                readonly property bool active: index === page.selMonitor
                Layout.preferredHeight: 32
                Layout.preferredWidth: selRow.implicitWidth + 24
                radius: 12
                color: active ? Qt.alpha(Theme.primary, 0.22) : Theme.surface
                Row {
                    id: selRow
                    anchors.centerIn: parent
                    spacing: 6
                    Text { text: "󰹑"; font.family: Theme.fontIcon; font.pixelSize: 12; color: active ? Theme.primary : Theme.subtext0; anchors.verticalCenter: parent.verticalCenter }
                    Text {
                        font.family: Theme.fontFamily; text: modelData.name; font.pixelSize: 12; font.bold: active; color: Theme.text; anchors.verticalCenter: parent.verticalCenter }
                }
                MouseArea { anchors.fill: parent; onClicked: page.selMonitor = index }
            }
        }
        Item { Layout.fillWidth: true }
    }

    // ── Illustration + resolution presets ──
    RowLayout {
        Layout.fillWidth: true
        spacing: 24

        // Monitor drawing
        ColumnLayout {
            Layout.alignment: Qt.AlignTop
            spacing: 0

            Rectangle {
                Layout.preferredWidth: 240
                Layout.preferredHeight: 155
                radius: 14
                color: Theme.surface0
                border.color: page.mon && (page.pendingRes !== page.mon.width + "x" + page.mon.height
                    || page.pendingRate !== Math.round(page.mon.refreshRate)
                    || page.pendingScale !== Math.round(page.mon.scale * 100))
                    ? Theme.primary : Theme.outline
                border.width: 2
                Behavior on border.color { ColorAnimation { duration: Theme.animSlow } }

                Column {
                    anchors.centerIn: parent
                    spacing: 6
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "󰍹"
                        font.family: Theme.fontIcon
                        font.pixelSize: 34
                        color: Theme.primary
                    }
                    Text {
                        font.family: Theme.fontFamily;
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: page.mon ? page.mon.name : "…"
                        font.pixelSize: 14; font.bold: true
                        color: Theme.text
                    }
                    Text {
                        font.family: Theme.fontFamily;
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: page.pendingRes + " @ " + page.pendingRate + "Hz"
                            + (page.pendingScale !== 100 ? "  ×" + (page.pendingScale / 100) : "")
                        font.pixelSize: 12
                        color: Theme.subtext0
                    }
                }
            }
            // Stand
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 22; height: 16
                color: Theme.surface0
            }
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 70; height: 6; radius: 3
                color: Theme.surface0
            }
        }

        // Resolution preset chips
        GridLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            columns: 2
            rowSpacing: 8
            columnSpacing: 8

            Repeater {
                model: page.resolutions
                delegate: Rectangle {
                    readonly property bool active: modelData === page.pendingRes
                    Layout.fillWidth: true
                    Layout.preferredHeight: 42
                    radius: 12
                    color: active ? Theme.surface0 : (resMa.containsMouse ? Qt.alpha(Theme.surface0, 0.5) : Qt.alpha(Theme.surface0, 0.25))
                    border.color: active ? Theme.primary : "transparent"
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    scale: resMa.pressed ? 0.96 : 1.0
                    Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easeSpring } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        Text {
                            font.family: Theme.fontFamily;
                            text: page.resLabel(modelData)
                            font.pixelSize: 13; font.bold: true
                            color: active ? Theme.primary : Theme.text
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            font.family: Theme.fontFamily;
                            text: modelData
                            font.pixelSize: 11
                            color: Theme.subtext0
                        }
                    }

                    MouseArea {
                        id: resMa
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            page.pendingRes = modelData;
                            // Keep the rate if available, else pick the highest
                            if (!page.rates.includes(page.pendingRate))
                                page.pendingRate = page.rates.length > 0 ? page.rates[page.rates.length - 1] : 60;
                        }
                    }
                }
            }
        }
    }

    // ── Shell visibility ──
    // Which monitor(s) get the pill/click-catcher/OSD trio. Falls back to "all"
    // if the saved monitor name isn't currently connected (Settings.pillScreens
    // in shell.qml) — never lets a stale pick hide every shell surface.
    CfgSection {
        title: "Shell visibility"
        icon: "󰍹"

        CfgNotice {
            text: "Restrict wisp's pill + click-catcher + OSD to one monitor instead of showing them everywhere. Applies live, no reload needed."
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 12
            spacing: 8

            Rectangle {
                id: allMonBtn
                readonly property bool active: Settings.conf.shell.pillMonitor === ""
                Layout.preferredHeight: 32
                Layout.preferredWidth: allRow.implicitWidth + 24
                radius: 12
                color: active ? Theme.primary : Theme.surface0
                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                Row {
                    id: allRow
                    anchors.centerIn: parent
                    spacing: 6
                    Text { text: "󰕮"; font.family: Theme.fontIcon; font.pixelSize: 12; color: allMonBtn.active ? Theme.background : Theme.subtext0; anchors.verticalCenter: parent.verticalCenter }
                    Text {
                        font.family: Theme.fontFamily; text: "All monitors"; font.pixelSize: 12; font.bold: allMonBtn.active; color: allMonBtn.active ? Theme.background : Theme.text; anchors.verticalCenter: parent.verticalCenter }
                }
                MouseArea { anchors.fill: parent; onClicked: Settings.conf.shell.pillMonitor = "" }
            }

            Repeater {
                model: page.monitors
                delegate: Rectangle {
                    id: monBtn
                    readonly property bool active: Settings.conf.shell.pillMonitor === modelData.name
                    Layout.preferredHeight: 32
                    Layout.preferredWidth: monRow.implicitWidth + 24
                    radius: 12
                    color: active ? Theme.primary : Theme.surface0
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    Row {
                        id: monRow
                        anchors.centerIn: parent
                        spacing: 6
                        Text { text: "󰍹"; font.family: Theme.fontIcon; font.pixelSize: 12; color: monBtn.active ? Theme.background : Theme.subtext0; anchors.verticalCenter: parent.verticalCenter }
                        Text {
                            font.family: Theme.fontFamily; text: modelData.name; font.pixelSize: 12; font.bold: monBtn.active; color: monBtn.active ? Theme.background : Theme.text; anchors.verticalCenter: parent.verticalCenter }
                    }
                    MouseArea { anchors.fill: parent; onClicked: Settings.conf.shell.pillMonitor = modelData.name }
                }
            }
            Item { Layout.fillWidth: true }
        }
    }

    // ── Refresh rate ──
    CfgSection {
        title: "Refresh rate"
        icon: "󰓅"

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 12
            spacing: 8
            Repeater {
                model: page.rates
                delegate: Rectangle {
                    readonly property bool active: modelData === page.pendingRate
                    Layout.preferredWidth: rateText.implicitWidth + 22
                    Layout.preferredHeight: 30
                    radius: 15
                    color: active ? Theme.primary : Theme.surface0
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    scale: rateMa.pressed ? 0.94 : 1.0
                    Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easeSpring } }
                    Text {
                        font.family: Theme.fontFamily;
                        id: rateText
                        anchors.centerIn: parent
                        text: modelData
                        font.pixelSize: 12
                        font.bold: true
                        color: active ? Theme.background : Theme.text
                    }
                    MouseArea {
                        id: rateMa
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: page.pendingRate = modelData
                    }
                }
            }
            Item { Layout.fillWidth: true }
        }
    }

    // ── Scale ──
    CfgSection {
        title: "Scale"
        icon: "󰍉"

        CfgSpin {
            icon: "󰆟"
            text: "Display scale (%)"
            value: page.pendingScale
            from: 75; to: 300
            stepSize: 25
            onEdited: v => page.pendingScale = v
        }
    }

    // ── Apply ──
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 44
        radius: 16
        color: applyMonMa.containsMouse ? Qt.lighter(Theme.primary, 1.1) : Theme.primary
        Behavior on color { ColorAnimation { duration: Theme.animFast } }
        scale: applyMonMa.pressed ? 0.97 : 1.0
        Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easeSpring } }

        Row {
            anchors.centerIn: parent
            spacing: 8
            Text { text: "󰸞"; font.family: Theme.fontIcon; font.pixelSize: 15; color: Theme.background; anchors.verticalCenter: parent.verticalCenter }
            Text {
                font.family: Theme.fontFamily; text: "Apply"; font.pixelSize: 14; font.bold: true; color: Theme.background; anchors.verticalCenter: parent.verticalCenter }
        }

        MouseArea {
            id: applyMonMa
            anchors.fill: parent
            hoverEnabled: true
            onClicked: page.apply()
        }
    }
}
