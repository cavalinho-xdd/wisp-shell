import QtQuick
import "../../core"

// Calendar and weather, side by side. One picked day drives both: its
// weather (and hours) on the left, a month with a sliding ring and its
// events on the right.
Item {
    id: root

    property bool lit: false
    // Set once the island has settled; switching views then skips the stagger.
    property bool quick: false

    readonly property var wx: Weather.wx
    property var today: startOfDay(new Date())
    property var selected: today
    property int viewYear: today.getFullYear()
    property int viewMonth: today.getMonth()
    readonly property int firstOffset: (new Date(viewYear, viewMonth, 1).getDay() + 6) % 7
    readonly property var weekdays: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
    // Index of the picked day in the forecast, -1 outside it.
    readonly property int dayIndex: {
        const n = Math.round((selected - today) / 86400000);
        return wx && n >= 0 && n < wx.days.length ? n : -1;
    }
    // Slot of the picked day in the month grid, -1 when another month is shown.
    readonly property int selectedSlot: selected.getFullYear() === viewYear && selected.getMonth() === viewMonth
        ? firstOffset + selected.getDate() - 1 : -1

    signal back()

    function startOfDay(d) {
        return new Date(d.getFullYear(), d.getMonth(), d.getDate());
    }
    function shiftMonth(delta) {
        const d = new Date(viewYear, viewMonth + delta, 1);
        viewYear = d.getFullYear();
        viewMonth = d.getMonth();
    }
    function cellDate(i) {
        return new Date(viewYear, viewMonth, i - firstOffset + 1);
    }
    function pick(d) {
        selected = startOfDay(d);
        viewYear = selected.getFullYear();
        viewMonth = selected.getMonth();
    }

    onLitChanged: {
        Weather.wanted = lit;
        if (lit) {
            today = startOfDay(new Date());
            pick(today);
        }
    }

    implicitWidth: Theme.ccWideWidth
    implicitHeight: Theme.spaceMd * 2 + Theme.controlSize + Theme.spaceSm + Theme.calCell * 10

    Kindle {
        id: head
        quick: root.quick
        lit: root.lit
        index: 0
        x: Theme.spaceMd
        y: Theme.spaceMd
        width: root.width - Theme.spaceMd * 2
        height: Theme.controlSize
        Item {
            width: head.width
            height: Theme.controlSize
            EmberButton {
                anchors.verticalCenter: parent.verticalCenter
                icon: "󰁍"
                label: "Back"
                onClicked: root.back()
            }
            Text {
                anchors.centerIn: parent
                text: "Calendar and weather"
                color: Theme.islandText
                font.family: Theme.fontFamily
                font.pixelSize: Theme.textBody
                font.weight: Font.DemiBold
            }
        }
    }

    Item {
        id: body
        x: Theme.spaceMd
        y: head.y + head.height + Theme.spaceSm
        width: head.width
        height: Theme.calCell * 10

        Kindle {
            id: weather
            quick: root.quick
            lit: root.lit
            index: 1
            width: body.width * 0.42
            height: body.height

            WeatherPanel {
                width: weather.width - Theme.spaceSm
                wx: root.wx
                dayIndex: root.dayIndex
                onDayPicked: index => root.pick(new Date(root.today.getFullYear(), root.today.getMonth(), root.today.getDate() + index))
            }
        }

        Kindle {
            id: month
            quick: root.quick
            lit: root.lit
            index: 2
            x: weather.width
            width: body.width - weather.width
            height: body.height

            Rectangle {
                width: month.width
                height: month.height
                radius: Theme.radiusTile
                color: Theme.ash

                Item {
                    id: monthHead
                    x: Theme.spaceXs
                    y: Theme.spaceXs
                    width: parent.width - Theme.spaceXs * 2
                    height: Theme.calCell
                    EmberButton {
                        anchors.verticalCenter: parent.verticalCenter
                        icon: "󰅁"
                        label: "Previous month"
                        onClicked: root.shiftMonth(-1)
                    }
                    Text {
                        anchors.centerIn: parent
                        text: Qt.formatDate(new Date(root.viewYear, root.viewMonth, 1), "MMMM yyyy")
                        color: Theme.islandText
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.textBody
                        font.weight: Font.DemiBold
                    }
                    EmberButton {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        icon: "󰅂"
                        label: "Next month"
                        onClicked: root.shiftMonth(1)
                    }
                }

                Item {
                    id: grid
                    x: Theme.spaceXs
                    y: monthHead.y + monthHead.height
                    width: parent.width - Theme.spaceXs * 2
                    readonly property real cell: width / 7
                    readonly property real rowHeight: Theme.calCell * 0.8
                    readonly property real weekdayHeight: Theme.calCell * 0.7
                    height: weekdayHeight + rowHeight * 6

                    // The picked day: a ring that slides to it.
                    Rectangle {
                        readonly property int slot: Math.max(0, root.selectedSlot)
                        x: (slot % 7) * grid.cell + (grid.cell - width) / 2
                        y: grid.weekdayHeight + Math.floor(slot / 7) * grid.rowHeight + (grid.rowHeight - height) / 2
                        width: Math.min(grid.cell, grid.rowHeight)
                        height: width
                        radius: width / 2
                        color: "transparent"
                        border.width: 1.5
                        border.color: Theme.islandText
                        opacity: root.selectedSlot >= 0 ? 1 : 0
                        Behavior on x { NumberAnimation { duration: Theme.motionQuick; easing.type: Easing.OutCubic } }
                        Behavior on y { NumberAnimation { duration: Theme.motionQuick; easing.type: Easing.OutCubic } }
                        Behavior on opacity { NumberAnimation { duration: Theme.motionFast } }
                    }

                    Repeater {
                        model: root.weekdays
                        Text {
                            required property string modelData
                            required property int index
                            x: index * grid.cell
                            width: grid.cell
                            height: grid.weekdayHeight
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            text: modelData
                            color: Theme.islandMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.textLabel
                        }
                    }
                    Repeater {
                        model: 42
                        Item {
                            id: cell
                            required property int modelData
                            readonly property var date: root.cellDate(modelData)
                            readonly property bool inMonth: date.getMonth() === root.viewMonth
                            readonly property bool isToday: date.getTime() === root.today.getTime()
                            readonly property bool hasEvents: EventStore.days && EventStore.eventsFor(EventStore.keyFor(date)).length > 0
                            x: (modelData % 7) * grid.cell
                            y: grid.weekdayHeight + Math.floor(modelData / 7) * grid.rowHeight
                            width: grid.cell
                            height: grid.rowHeight

                            Rectangle {
                                anchors.centerIn: parent
                                width: Math.min(parent.width, parent.height)
                                height: width
                                radius: width / 2
                                color: cell.isToday ? Theme.ember : (dayMouse.containsMouse ? Theme.hover : "transparent")
                                Behavior on color { ColorAnimation { duration: Theme.motionFast } }
                            }
                            Text {
                                anchors.centerIn: parent
                                text: cell.date.getDate()
                                color: cell.isToday ? Theme.smoke : (cell.inMonth ? Theme.islandText : Theme.islandMuted)
                                opacity: cell.inMonth ? 1 : 0.4
                                font.family: Theme.fontMono
                                font.pixelSize: Theme.textMonoSmall
                            }
                            Rectangle {
                                visible: cell.hasEvents && !cell.isToday
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.bottom
                                width: Theme.spaceXs / 2
                                height: width
                                radius: width / 2
                                color: Theme.ember
                            }
                            Accessible.role: Accessible.Button
                            Accessible.name: Qt.formatDate(cell.date, "d. MMMM")
                            MouseArea {
                                id: dayMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.pick(cell.date)
                            }
                        }
                    }

                    // A wheel notch is 120; a trackpad sends many small deltas.
                    property real wheelSum: 0
                    WheelHandler {
                        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                        onWheel: event => {
                            grid.wheelSum += event.angleDelta.y;
                            const notches = Math.trunc(grid.wheelSum / 120);
                            if (notches !== 0) {
                                grid.wheelSum -= notches * 120;
                                root.shiftMonth(-notches);
                            }
                        }
                    }
                }

                AgendaPanel {
                    x: Theme.spaceSm
                    y: grid.y + grid.height + Theme.spaceXs
                    width: parent.width - Theme.spaceSm * 2
                    height: parent.height - y - Theme.spaceSm
                    date: root.selected
                    lit: root.lit
                }
            }
        }
    }
}
