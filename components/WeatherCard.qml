import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../core"

// Weather + 5-day forecast card. Data comes from scripts/weather.sh (open-meteo,
// cached 15 min, stale-while-revalidate). Several interaction principles are
// borrowed from illyamiro's CalendarPopup: the animated temperature counter that
// tints by direction while ticking and the direction-aware content swap.
Rectangle {
    id: root
    radius: 20
    color: Theme.surface
    clip: true

    property var wx: null
    property int selectedDay: 0
    property int shownDay: 0        // data on screen; lags selectedDay during the swap animation
    property real contentOpacity: 1
    property real contentShift: 0
    property int animDir: 1

    readonly property var dayData: (wx && wx.days && wx.days[shownDay]) ? wx.days[shownDay] : null

    // Temperature counter — peach while counting up, blue while counting down
    property real targetTemp: {
        if (!wx) return 0;
        if (shownDay === 0 && wx.current) return Number(wx.current.temp);
        return dayData ? Number(dayData.max) : 0;
    }
    property real displayedTemp: targetTemp
    Behavior on displayedTemp { NumberAnimation { id: tempAnim; duration: 800; easing.type: Easing.OutQuart } }
    readonly property color tempColor: !tempAnim.running ? Theme.text
        : (targetTemp > displayedTemp ? Theme.peach : Theme.blue)

    function selectDay(idx) {
        if (idx === selectedDay || !wx) return;
        animDir = idx > selectedDay ? 1 : -1;
        selectedDay = idx;
        swapAnim.restart();
    }

    // Content slides out one way, data swaps hidden, slides back in from the other side
    SequentialAnimation {
        id: swapAnim
        ParallelAnimation {
            NumberAnimation { target: root; property: "contentOpacity"; to: 0; duration: 160; easing.type: Easing.InSine }
            NumberAnimation { target: root; property: "contentShift"; to: -24 * root.animDir; duration: 160; easing.type: Easing.InSine }
        }
        ScriptAction { script: { root.shownDay = root.selectedDay; root.contentShift = 24 * root.animDir; } }
        ParallelAnimation {
            NumberAnimation { target: root; property: "contentOpacity"; to: 1; duration: 300; easing.type: Easing.OutQuart }
            NumberAnimation { target: root; property: "contentShift"; to: 0; duration: 300; easing.type: Easing.OutQuart }
        }
    }

    Process {
        id: wxProc
        command: ["bash", Quickshell.shellPath("scripts/weather.sh"), "--json"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const t = this.text.trim();
                if (t !== "") { try { root.wx = JSON.parse(t); } catch (e) {} }
            }
        }
    }
    Timer { interval: 900000; running: true; repeat: true; onTriggered: wxProc.running = true }

    // Week-wide temperature span, shared by every day's range bar
    readonly property real weekMin: {
        if (!wx || !wx.days || wx.days.length === 0) return 0;
        return Math.min.apply(null, wx.days.map(d => Number(d.min)));
    }
    readonly property real weekMax: {
        if (!wx || !wx.days || wx.days.length === 0) return 1;
        return Math.max.apply(null, wx.days.map(d => Number(d.max)));
    }

    // Today shows live conditions where open-meteo has them; other days their daily values
    readonly property var cur: shownDay === 0 && wx && wx.current ? wx.current : null

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 0

        // ── Header: city + refresh ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Text {
                font.family: Theme.fontFamily
                text: root.wx ? root.wx.city : "Weather"
                font.pixelSize: 15; font.weight: Font.Bold; color: Theme.text
            }
            Item { Layout.fillWidth: true }
            Text {
                id: refreshIcon
                text: "󰑐"
                font.family: Theme.fontIcon; font.pixelSize: 14
                color: refreshMa.containsMouse ? Theme.text : Theme.subtext0
                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                RotationAnimation on rotation {
                    running: wxProc.running
                    from: 0; to: 360; duration: 800
                    loops: Animation.Infinite
                }
                MouseArea {
                    id: refreshMa
                    anchors.fill: parent; anchors.margins: -8
                    hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        wxProc.command = ["bash", Quickshell.shellPath("scripts/weather.sh"), "--refresh"];
                        wxProc.running = true;
                    }
                }
            }
        }

        // ── Hero: ticking temperature, condition beside it ──
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 6
            spacing: 14
            opacity: root.contentOpacity
            transform: Translate { x: root.contentShift }

            Text {
                font.family: Theme.fontFamily
                font.features: { "tnum": 1 }
                text: Math.round(root.displayedTemp) + "°"
                font.pixelSize: 56
                font.weight: Font.Medium
                font.letterSpacing: -2
                color: root.tempColor
                Behavior on color { ColorAnimation { duration: 250 } }
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignVCenter
                spacing: 3
                RowLayout {
                    spacing: 6
                    Text {
                        text: root.cur ? root.cur.icon : (root.dayData ? root.dayData.icon : "󰖐")
                        font.family: Theme.fontIcon
                        font.pixelSize: 16
                        color: {
                            const hex = root.cur ? root.cur.hex : (root.dayData ? root.dayData.hex : "");
                            return hex !== "" ? hex : Theme.subtext0;
                        }
                        Behavior on color { ColorAnimation { duration: 400 } }
                    }
                    Text {
                        font.family: Theme.fontFamily
                        text: root.cur ? root.cur.desc : (root.dayData ? root.dayData.desc : "Loading…")
                        font.pixelSize: 14; font.weight: Font.Medium; color: Theme.text
                    }
                }
                Text {
                    font.family: Theme.fontFamily
                    font.features: { "tnum": 1 }
                    text: !root.dayData ? ""
                        : (root.shownDay === 0 ? "Today" : root.dayData.date) + "  ·  "
                          + Math.round(root.dayData.max) + "° / " + Math.round(root.dayData.min) + "°"
                    font.pixelSize: 12; color: Theme.subtext0
                }
            }

            Item { Layout.fillWidth: true }
        }

        // ── Hourly: temperature line with time underneath ──
        Item {
            id: hourly
            Layout.fillWidth: true
            Layout.topMargin: 10
            Layout.preferredHeight: 92
            opacity: root.contentOpacity
            transform: Translate { x: root.contentShift * 1.5 }

            readonly property var hours: root.dayData ? root.dayData.hourly : []
            readonly property real colW: hours.length > 0 ? width / hours.length : 0
            readonly property real tMin: hours.length ? Math.min.apply(null, hours.map(h => Number(h.temp))) : 0
            readonly property real tMax: hours.length ? Math.max.apply(null, hours.map(h => Number(h.temp))) : 1
            // On today, the slot nearest the current hour
            readonly property int nowIdx: root.shownDay === 0 ? Math.min(7, Math.round(new Date().getHours() / 3)) : -1
            function pointY(t) {
                const span = Math.max(1, tMax - tMin);
                return 18 + (1 - (t - tMin) / span) * 20;
            }

            Canvas {
                id: lineCanvas
                anchors.fill: parent
                property var pts: hourly.hours
                onPtsChanged: requestPaint()
                onWidthChanged: requestPaint()
                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();
                    if (!pts || pts.length < 2) return;
                    ctx.beginPath();
                    for (let i = 0; i < pts.length; i++) {
                        const x = hourly.colW * (i + 0.5);
                        const y = hourly.pointY(Number(pts[i].temp));
                        if (i === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y);
                    }
                    ctx.strokeStyle = Qt.alpha(Theme.text, 0.35);
                    ctx.lineWidth = 2;
                    ctx.lineJoin = "round";
                    ctx.stroke();
                }
            }

            Repeater {
                model: hourly.hours
                delegate: Item {
                    required property var modelData
                    required property int index
                    readonly property bool isNow: index === hourly.nowIdx
                    readonly property real py: hourly.pointY(Number(modelData.temp))
                    x: hourly.colW * index
                    width: hourly.colW
                    height: hourly.height

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: parent.py - 19
                        font.family: Theme.fontFamily
                        font.features: { "tnum": 1 }
                        text: Math.round(modelData.temp) + "°"
                        font.pixelSize: 12
                        font.weight: parent.isNow ? Font.Bold : Font.Normal
                        color: Theme.text
                    }
                    Rectangle {
                        visible: parent.isNow
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: parent.py - height / 2
                        width: 8; height: 8; radius: 4
                        color: Theme.primary
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 52
                        text: modelData.icon
                        font.family: Theme.fontIcon
                        font.pixelSize: 14
                        color: modelData.hex
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        font.family: Theme.fontFamily
                        font.features: { "tnum": 1 }
                        text: parent.isNow ? "Now" : modelData.time.substring(0, 2)
                        font.pixelSize: 11
                        font.weight: parent.isNow ? Font.Bold : Font.Normal
                        color: parent.isNow ? Theme.text : Theme.subtext0
                    }
                }
            }
        }

        // ── Days: one row each, range bar on the week's shared scale ──
        Column {
            id: dayList
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: 16
            spacing: 2

            Repeater {
                model: root.wx && root.wx.days ? root.wx.days : []
                delegate: Rectangle {
                    id: dayRow
                    required property var modelData
                    required property int index
                    readonly property bool active: index === root.selectedDay
                    width: parent.width
                    // Rows share the free height, within a comfortable pitch
                    height: Math.max(32, Math.min(42, (dayList.height - 8) / 5))
                    radius: 10
                    color: active ? Theme.surface0 : (dayMa.containsMouse ? Qt.alpha(Theme.surface0, 0.5) : "transparent")
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 10

                        Text {
                            Layout.preferredWidth: 44
                            font.family: Theme.fontFamily
                            text: dayRow.index === 0 ? "Today" : dayRow.modelData.day
                            font.pixelSize: 13
                            font.weight: dayRow.active ? Font.Bold : Font.Normal
                            color: Theme.text
                        }
                        Text {
                            Layout.preferredWidth: 18
                            horizontalAlignment: Text.AlignHCenter
                            text: dayRow.modelData.icon
                            font.family: Theme.fontIcon
                            font.pixelSize: 14
                            color: dayRow.modelData.hex
                        }
                        Text {
                            Layout.preferredWidth: 30
                            horizontalAlignment: Text.AlignRight
                            font.family: Theme.fontFamily
                            font.features: { "tnum": 1 }
                            text: Math.round(dayRow.modelData.pop) + "%"
                            font.pixelSize: 11
                            color: Theme.subtext0
                        }
                        Text {
                            Layout.preferredWidth: 26
                            horizontalAlignment: Text.AlignRight
                            font.family: Theme.fontFamily
                            font.features: { "tnum": 1 }
                            text: Math.round(dayRow.modelData.min) + "°"
                            font.pixelSize: 13
                            color: Theme.subtext0
                        }
                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 4
                            Rectangle {
                                anchors.fill: parent
                                radius: 2
                                color: Qt.alpha(Theme.text, 0.08)
                            }
                            Rectangle {
                                readonly property real span: Math.max(1, root.weekMax - root.weekMin)
                                x: parent.width * (dayRow.modelData.min - root.weekMin) / span
                                width: Math.max(4, parent.width * (dayRow.modelData.max - dayRow.modelData.min) / span)
                                height: parent.height
                                radius: 2
                                color: dayRow.active ? Theme.primary : Qt.alpha(Theme.text, 0.4)
                                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                            }
                        }
                        Text {
                            Layout.preferredWidth: 26
                            horizontalAlignment: Text.AlignRight
                            font.family: Theme.fontFamily
                            font.features: { "tnum": 1 }
                            text: Math.round(dayRow.modelData.max) + "°"
                            font.pixelSize: 13
                            color: Theme.text
                        }
                    }

                    MouseArea {
                        id: dayMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.selectDay(dayRow.index)
                    }
                }
            }
        }

        // ── Conditions: label over value ──
        Row {
            id: conditions
            Layout.fillWidth: true
            Layout.topMargin: 14
            opacity: root.contentOpacity

            Repeater {
                model: [
                    { lbl: "Wind", val: root.cur ? root.cur.wind : (root.dayData ? root.dayData.wind : null), unit: " km/h" },
                    { lbl: "Humidity", val: root.cur ? root.cur.humidity : (root.dayData ? root.dayData.humidity : null), unit: "%" },
                    { lbl: "Rain", val: root.dayData ? root.dayData.pop : null, unit: "%" },
                    { lbl: "Feels like", val: root.cur ? root.cur.feels : (root.dayData ? root.dayData.feels : null), unit: "°" }
                ]
                delegate: Column {
                    required property var modelData
                    width: conditions.width / 4
                    spacing: 2
                    Text {
                        font.family: Theme.fontFamily
                        text: modelData.lbl
                        font.pixelSize: 11
                        color: Theme.subtext0
                    }
                    Text {
                        font.family: Theme.fontFamily
                        font.features: { "tnum": 1 }
                        textFormat: Text.StyledText
                        text: modelData.val === null || modelData.val === undefined ? "–"
                            : Math.round(modelData.val) + "<font color=\"" + Theme.subtext0 + "\">" + modelData.unit + "</font>"
                        font.pixelSize: 15
                        font.weight: Font.Medium
                        color: Theme.text
                    }
                }
            }
        }
    }
}
