import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../core"

// Weather + 5-day forecast card. Data comes from scripts/weather.sh (open-meteo,
// cached 15 min, stale-while-revalidate). Several interaction principles are
// borrowed from illyamiro's CalendarPopup: the animated temperature counter that
// tints by direction while ticking, the direction-aware content swap, and the
// circular metric gauges.
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

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10

        // ── Header: city + refresh ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Text {
                font.family: Theme.fontFamily;
                text: root.wx ? root.wx.city : "Weather"
                font.pixelSize: 14; font.bold: true; color: Theme.text
            }
            Text {
                font.family: Theme.fontFamily;
                text: root.shownDay === 0 ? "now" : (root.dayData ? root.dayData.date : "")
                font.pixelSize: 11; color: Theme.subtext0
                anchors.baseline: undefined
            }
            Item { Layout.fillWidth: true }
            Text {
                id: refreshIcon
                text: "󰑐"
                font.family: Theme.fontIcon; font.pixelSize: 14
                color: refreshMa.containsMouse ? Theme.primary : Theme.subtext0
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

        // ── Hero: big icon + ticking temperature ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 14
            opacity: root.contentOpacity
            transform: Translate { x: root.contentShift }

            Text {
                text: root.shownDay === 0 && root.wx && root.wx.current ? root.wx.current.icon
                    : (root.dayData ? root.dayData.icon : "󰖐")
                font.family: Theme.fontIcon
                font.pixelSize: 46
                color: {
                    const hex = root.shownDay === 0 && root.wx && root.wx.current ? root.wx.current.hex
                        : (root.dayData ? root.dayData.hex : "");
                    return hex !== "" ? hex : Theme.primary;
                }
                Behavior on color { ColorAnimation { duration: 400 } }
            }

            Text {
                font.family: Theme.fontFamily;
                text: Math.round(root.displayedTemp) + "°"
                font.pixelSize: 42
                font.weight: Font.Black
                color: root.tempColor
                Behavior on color { ColorAnimation { duration: 250 } }
            }

            Item { Layout.fillWidth: true }

            ColumnLayout {
                spacing: 2
                Layout.alignment: Qt.AlignVCenter
                Text {
                    font.family: Theme.fontFamily;
                    Layout.alignment: Qt.AlignRight
                    text: root.shownDay === 0 && root.wx && root.wx.current ? root.wx.current.desc
                        : (root.dayData ? root.dayData.desc : "Loading…")
                    font.pixelSize: 13; font.bold: true; color: Theme.text
                }
                Text {
                    Layout.alignment: Qt.AlignRight
                    text: root.dayData ? ("󰁝 " + Math.round(root.dayData.max) + "°  󰁅 " + Math.round(root.dayData.min) + "°") : ""
                    font.family: Theme.fontIcon
                    font.pixelSize: 11; color: Theme.subtext0
                }
            }
        }

        // ── Day selector chips ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            Repeater {
                model: root.wx && root.wx.days ? root.wx.days : []
                delegate: Rectangle {
                    required property var modelData
                    readonly property bool active: index === root.selectedDay
                    Layout.fillWidth: true
                    Layout.preferredHeight: 50
                    radius: 12
                    color: active ? Theme.surface0 : (chipMa.containsMouse ? Qt.alpha(Theme.surface0, 0.5) : "transparent")
                    border.color: active ? Theme.primary : "transparent"
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    scale: chipMa.pressed ? 0.94 : 1.0
                    Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easeSpring } }

                    Column {
                        anchors.centerIn: parent
                        spacing: 2
                        Text {
                            font.family: Theme.fontFamily;
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: index === 0 ? "Now" : modelData.day
                            font.pixelSize: 10
                            font.bold: active
                            color: active ? Theme.text : Theme.subtext0
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.icon
                            font.family: Theme.fontIcon
                            font.pixelSize: 13
                            color: modelData.hex
                        }
                        Text {
                            font.family: Theme.fontFamily;
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Math.round(modelData.max) + "°"
                            font.pixelSize: 10
                            font.bold: true
                            color: active ? Theme.text : Theme.subtext0
                        }
                    }

                    MouseArea {
                        id: chipMa
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.selectDay(index)
                    }
                }
            }
        }

        // ── Hourly strip ──
        Flickable {
            Layout.fillWidth: true
            Layout.preferredHeight: 64
            contentWidth: hourRow.width
            clip: true
            interactive: contentWidth > width
            opacity: root.contentOpacity
            transform: Translate { x: root.contentShift * 1.5 }

            Row {
                id: hourRow
                spacing: 5
                Repeater {
                    model: root.dayData ? root.dayData.hourly : []
                    delegate: Rectangle {
                        required property var modelData
                        // On today, highlight the slot nearest the current hour
                        readonly property bool nowSlot: root.shownDay === 0
                            && index === Math.min(7, Math.round(new Date().getHours() / 3))
                        width: 34; height: 64; radius: 12
                        color: nowSlot ? Theme.primary : Theme.surface0
                        Column {
                            anchors.centerIn: parent
                            spacing: 3
                            Text {
                                font.family: Theme.fontFamily;
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.time.substring(0, 2)
                                font.pixelSize: 9
                                color: nowSlot ? Theme.background : Theme.subtext0
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.icon
                                font.family: Theme.fontIcon
                                font.pixelSize: 13
                                color: nowSlot ? Theme.background : modelData.hex
                            }
                            Text {
                                font.family: Theme.fontFamily;
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: Math.round(modelData.temp) + "°"
                                font.pixelSize: 10; font.bold: true
                                color: nowSlot ? Theme.background : Theme.text
                            }
                        }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }

        // ── Metric gauges: WIND / HUM / RAIN / FEEL ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 4
            opacity: root.contentOpacity

            Repeater {
                model: 4
                delegate: Item {
                    id: gaugeWrap
                    Layout.fillWidth: true
                    Layout.preferredHeight: 72

                    readonly property var d: root.dayData
                    readonly property string lbl: ["WIND", "HUM", "RAIN", "FEEL"][index]
                    readonly property string val: d ? (
                        index === 0 ? Math.round(d.wind) + "" :
                        index === 1 ? d.humidity + "%" :
                        index === 2 ? Math.round(d.pop) + "%" :
                        Math.round(d.feels) + "°") : ""
                    readonly property real fill: d ? (
                        index === 0 ? Math.min(1, d.wind / 60.0) :
                        index === 1 ? d.humidity / 100.0 :
                        index === 2 ? d.pop / 100.0 :
                        Math.max(0, Math.min(1, (d.feels + 15) / 55.0))) : 0

                    scale: gaugeMa.containsMouse ? 1.12 : 1.0
                    Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easeSpring } }

                    Column {
                        anchors.centerIn: parent
                        spacing: 4

                        Item {
                            width: 48; height: 48
                            anchors.horizontalCenter: parent.horizontalCenter

                            Canvas {
                                id: gaugeCanvas
                                anchors.fill: parent
                                rotation: -90
                                property real p: gaugeWrap.fill
                                Behavior on p { NumberAnimation { duration: 1000; easing.type: Easing.OutExpo } }
                                onPChanged: requestPaint()
                                onWidthChanged: requestPaint()
                                onPaint: {
                                    const ctx = getContext("2d");
                                    ctx.reset();
                                    const r = width / 2;
                                    ctx.beginPath();
                                    ctx.arc(r, r, r - 3, 0, 2 * Math.PI);
                                    ctx.strokeStyle = Qt.alpha(Theme.text, 0.08);
                                    ctx.lineWidth = 3;
                                    ctx.stroke();
                                    if (p > 0.01) {
                                        ctx.beginPath();
                                        ctx.arc(r, r, r - 3, 0, p * 2 * Math.PI);
                                        ctx.strokeStyle = Theme.primary;
                                        ctx.lineWidth = 3;
                                        ctx.lineCap = "round";
                                        ctx.stroke();
                                    }
                                }
                            }

                            Text {
                                font.family: Theme.fontFamily;
                                anchors.centerIn: parent
                                text: gaugeWrap.val
                                font.pixelSize: 11; font.bold: true
                                color: Theme.text
                            }
                        }

                        Text {
                            font.family: Theme.fontFamily;
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: gaugeWrap.lbl
                            font.pixelSize: 9
                            color: gaugeMa.containsMouse ? Theme.primary : Theme.subtext0
                            Behavior on color { ColorAnimation { duration: Theme.animFast } }
                        }
                    }

                    MouseArea { id: gaugeMa; anchors.fill: parent; hoverEnabled: true }
                }
            }
        }
    }
}
