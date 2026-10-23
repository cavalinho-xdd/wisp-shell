import QtQuick
import QtQuick.Layouts
import "../core"

// Month calendar with per-day events/todos persisted via EventStore (events.json).
// Interaction principles borrowed from caelestia's dashboard calendar: wheel
// scrolls months, clicking the title jumps back to today, month swaps slide
// directionally. Event storage and the editable day panel are our own.
Rectangle {
    id: root
    radius: 20
    color: Theme.surface
    clip: true

    readonly property date today: new Date()
    property int viewMonth: today.getMonth()
    property int viewYear: today.getFullYear()
    property date selectedDate: new Date()

    property real gridOpacity: 1
    property real gridShift: 0
    property int monthAnimDir: 1
    property var pendingMonth: null

    readonly property var monthNames: ["January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"]

    // 42 cells, Monday-first
    readonly property var cells: {
        const first = new Date(viewYear, viewMonth, 1);
        const startDow = (first.getDay() + 6) % 7;
        let arr = [];
        for (let i = 0; i < 42; i++)
            arr.push(new Date(viewYear, viewMonth, 1 - startDow + i));
        return arr;
    }

    readonly property string selectedKey: EventStore.keyFor(selectedDate)
    // Referencing EventStore.days keeps this binding live across mutations
    readonly property var selectedEvents: EventStore.days[selectedKey] || []

    function sameDay(a, b) {
        return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
    }

    function shiftMonth(delta) {
        monthAnimDir = delta > 0 ? 1 : -1;
        pendingMonth = new Date(viewYear, viewMonth + delta, 1);
        monthSwap.restart();
    }

    function goToday() {
        if (viewMonth === today.getMonth() && viewYear === today.getFullYear()) return;
        monthAnimDir = new Date(viewYear, viewMonth, 1) > today ? -1 : 1;
        pendingMonth = new Date(today.getFullYear(), today.getMonth(), 1);
        monthSwap.restart();
    }

    SequentialAnimation {
        id: monthSwap
        ParallelAnimation {
            NumberAnimation { target: root; property: "gridOpacity"; to: 0; duration: 140; easing.type: Easing.InSine }
            NumberAnimation { target: root; property: "gridShift"; to: -20 * root.monthAnimDir; duration: 140; easing.type: Easing.InSine }
        }
        ScriptAction {
            script: {
                if (root.pendingMonth) {
                    root.viewMonth = root.pendingMonth.getMonth();
                    root.viewYear = root.pendingMonth.getFullYear();
                    root.pendingMonth = null;
                }
                root.gridShift = 20 * root.monthAnimDir;
            }
        }
        ParallelAnimation {
            NumberAnimation { target: root; property: "gridOpacity"; to: 1; duration: 280; easing.type: Easing.OutQuart }
            NumberAnimation { target: root; property: "gridShift"; to: 0; duration: 280; easing.type: Easing.OutQuart }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 0

        // ── Month navigation: title left, arrows together on the right ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 14

            Text {
                id: monthTitle
                Layout.fillWidth: true
                font.family: Theme.fontFamily
                text: root.monthNames[root.viewMonth] + " " + root.viewYear
                font.pixelSize: 15; font.weight: Font.Bold
                color: Theme.text
                opacity: root.gridOpacity
                transform: Translate { x: root.gridShift }
                MouseArea {
                    width: monthTitle.contentWidth; height: parent.height
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.goToday()
                }
            }

            Text {
                text: "󰅁"
                font.family: Theme.fontIcon; font.pixelSize: 16
                color: prevMa.containsMouse ? Theme.text : Theme.subtext0
                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                MouseArea { id: prevMa; anchors.fill: parent; anchors.margins: -6; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.shiftMonth(-1) }
            }

            Text {
                text: "󰅂"
                font.family: Theme.fontIcon; font.pixelSize: 16
                color: nextMa.containsMouse ? Theme.text : Theme.subtext0
                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                MouseArea { id: nextMa; anchors.fill: parent; anchors.margins: -6; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.shiftMonth(1) }
            }
        }

        // ── Day-of-week header ──
        Row {
            id: dowRow
            Layout.fillWidth: true
            Layout.topMargin: 14
            Layout.bottomMargin: 4
            Repeater {
                model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                delegate: Text {
                    required property var modelData
                    width: dowRow.width / 7
                    font.family: Theme.fontFamily
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    font.pixelSize: 11
                    color: Theme.subtext0
                }
            }
        }

        // ── Month grid ──
        Item {
            id: gridWrap
            Layout.fillWidth: true
            Layout.preferredHeight: gridCol.implicitHeight
            opacity: root.gridOpacity
            transform: Translate { x: root.gridShift }

            MouseArea {
                anchors.fill: parent
                onWheel: wheel => root.shiftMonth(wheel.angleDelta.y > 0 ? -1 : 1)
                z: -1
            }

            Grid {
                id: gridCol
                width: parent.width
                columns: 7
                rowSpacing: 1

                Repeater {
                    model: root.cells
                    delegate: Item {
                        required property var modelData
                        width: gridCol.width / 7
                        height: 32

                        readonly property date d: modelData
                        readonly property bool inMonth: d.getMonth() === root.viewMonth
                        readonly property bool isToday: root.sameDay(d, root.today)
                        readonly property bool isSelected: root.sameDay(d, root.selectedDate)
                        readonly property int evCount: (EventStore.days[EventStore.keyFor(d)] || []).length

                        Rectangle {
                            anchors.centerIn: parent
                            width: 28; height: 28; radius: 14
                            color: isToday ? Theme.primary
                                : isSelected ? Theme.surface0
                                : cellMa.containsMouse ? Qt.alpha(Theme.surface0, 0.5) : "transparent"
                            Behavior on color { ColorAnimation { duration: Theme.animFast } }
                        }

                        Text {
                            font.family: Theme.fontFamily
                            font.features: { "tnum": 1 }
                            anchors.centerIn: parent
                            anchors.verticalCenterOffset: evCount > 0 ? -2 : 0
                            text: d.getDate()
                            font.pixelSize: 13
                            font.weight: isToday || isSelected ? Font.Bold : Font.Normal
                            color: isToday ? Theme.colorOnPrimary
                                : !inMonth ? Qt.alpha(Theme.subtext0, 0.4)
                                : Theme.text
                        }

                        // Event marker
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 5
                            width: 4; height: 4; radius: 2
                            color: isToday ? Theme.colorOnPrimary : Theme.primary
                            visible: evCount > 0
                        }

                        MouseArea {
                            id: cellMa
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.selectedDate = d
                        }
                    }
                }
            }
        }

        // ── Selected-day header ──
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 16
            Layout.bottomMargin: 6
            Text {
                font.family: Theme.fontFamily
                text: Qt.formatDate(root.selectedDate, "dddd d MMMM")
                font.pixelSize: 13; font.weight: Font.Bold; color: Theme.text
            }
            Item { Layout.fillWidth: true }
            Text {
                font.family: Theme.fontFamily
                readonly property int n: root.selectedEvents.length
                visible: n > 0
                text: n + (n === 1 ? " event" : " events")
                font.pixelSize: 12; color: Theme.subtext0
            }
        }

        Text {
            visible: root.selectedEvents.length === 0
            font.family: Theme.fontFamily
            text: root.sameDay(root.selectedDate, root.today) ? "Nothing planned today." : "Nothing planned."
            font.pixelSize: 12; color: Theme.subtext0
        }

        // ── Event list ──
        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: evCol.implicitHeight
            clip: true
            interactive: contentHeight > height

            Column {
                id: evCol
                width: parent.width
                spacing: 4

                Repeater {
                    model: root.selectedEvents
                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        width: evCol.width
                        height: 28
                        radius: 8
                        color: evMa.containsMouse ? Theme.surface0 : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 6
                            anchors.rightMargin: 6
                            spacing: 8

                            // Done checkbox
                            Rectangle {
                                width: 15; height: 15; radius: 5
                                color: modelData.done ? Theme.primary : "transparent"
                                border.color: modelData.done ? Theme.primary : Theme.subtext0
                                border.width: 1
                                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                                Text {
                                    anchors.centerIn: parent
                                    text: "󰄬"
                                    font.family: Theme.fontIcon; font.pixelSize: 9
                                    color: Theme.background
                                    visible: modelData.done
                                }
                                MouseArea {
                                    anchors.fill: parent; anchors.margins: -6
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: EventStore.toggleDone(root.selectedKey, index)
                                }
                            }

                            Text {
                                font.family: Theme.fontFamily;
                                Layout.fillWidth: true
                                text: modelData.text
                                font.pixelSize: 12
                                font.strikeout: modelData.done
                                color: modelData.done ? Theme.subtext0 : Theme.text
                                elide: Text.ElideRight
                                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                            }

                            // Delete — appears on row hover
                            Text {
                                text: "󰅖"
                                font.family: Theme.fontIcon; font.pixelSize: 12
                                color: delMa.containsMouse ? Theme.red : Theme.subtext0
                                opacity: evMa.containsMouse ? 1 : 0
                                Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                                MouseArea {
                                    id: delMa
                                    anchors.fill: parent; anchors.margins: -6
                                    hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: EventStore.removeEvent(root.selectedKey, index)
                                }
                            }
                        }

                        MouseArea {
                            id: evMa
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.NoButton
                        }
                    }
                }
            }
        }

        // ── Add-event input ──
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 34
            Layout.topMargin: 8
            radius: 10
            color: Theme.surface0
            border.color: evInput.activeFocus ? Theme.primary : "transparent"
            border.width: 1
            Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 8
                spacing: 6

                TextInput {
                    font.family: Theme.fontFamily;
                    id: evInput
                    Layout.fillWidth: true
                    font.pixelSize: 12
                    color: Theme.text
                    clip: true
                    selectByMouse: true
                    onAccepted: {
                        EventStore.addEvent(root.selectedKey, text);
                        text = "";
                    }
                    Text {
                        font.family: Theme.fontFamily;
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Add to " + Qt.formatDate(root.selectedDate, "d MMM") + "…"
                        font.pixelSize: 12
                        color: Theme.subtext0
                        visible: evInput.text === "" && !evInput.activeFocus
                    }
                }

                Text {
                    text: "󰐕"
                    font.family: Theme.fontIcon; font.pixelSize: 13
                    color: addMa.containsMouse ? Theme.text : Theme.subtext0
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    scale: addMa.pressed ? 0.85 : 1.0
                    Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easeSpring } }
                    MouseArea {
                        id: addMa
                        anchors.fill: parent; anchors.margins: -6
                        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            EventStore.addEvent(root.selectedKey, evInput.text);
                            evInput.text = "";
                        }
                    }
                }
            }
        }
    }
}
