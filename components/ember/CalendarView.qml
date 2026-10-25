import QtQuick
import "../../core"

// Calendar and weather, side by side: the weather for today and the next
// days on the left, a month with a dot on days that have events on the right.
Item {
    id: root

    property bool lit: false

    readonly property var wx: Weather.wx
    property var today: new Date()
    property int viewYear: today.getFullYear()
    property int viewMonth: today.getMonth()
    readonly property int firstOffset: (new Date(viewYear, viewMonth, 1).getDay() + 6) % 7
    readonly property var weekdays: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

    signal back()

    function shiftMonth(delta) {
        const d = new Date(viewYear, viewMonth + delta, 1);
        viewYear = d.getFullYear();
        viewMonth = d.getMonth();
    }
    function cellDate(i) {
        return new Date(viewYear, viewMonth, i - firstOffset + 1);
    }

    onLitChanged: {
        Weather.wanted = lit;
        if (lit) {
            today = new Date();
            viewYear = today.getFullYear();
            viewMonth = today.getMonth();
        }
    }

    implicitWidth: Theme.ccWideWidth
    implicitHeight: Theme.spaceMd * 2 + Theme.controlSize + Theme.spaceSm + Theme.calCell * 8

    Kindle {
        id: head
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
        height: Theme.calCell * 8

        // Weather
        Kindle {
            id: weather
            lit: root.lit
            index: 1
            width: body.width * 0.44
            height: body.height

            Column {
                width: weather.width - Theme.spaceMd
                spacing: Theme.spaceXs

                Text {
                    width: parent.width
                    text: root.wx ? root.wx.city : "Weather"
                    elide: Text.ElideRight
                    color: Theme.islandMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.textCaption
                }
                Row {
                    spacing: Theme.spaceSm
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.wx ? root.wx.current.icon : ""
                        color: Theme.islandText
                        font.family: Theme.fontIcon
                        font.pixelSize: Theme.textTitle * 2
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        Text {
                            text: root.wx ? Math.round(root.wx.current.temp) + "°" : "–"
                            color: Theme.islandText
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.textTitle * 1.6
                            font.weight: Font.DemiBold
                        }
                        Text {
                            text: root.wx ? root.wx.current.desc : (Weather.wanted ? "Loading…" : "")
                            color: Theme.islandMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.textCaption
                        }
                    }
                }
                Text {
                    visible: !!root.wx
                    text: root.wx ? "Feels " + Math.round(root.wx.current.feels) + "° · " + root.wx.current.humidity + " % · " + Math.round(root.wx.current.wind) + " km/h" : ""
                    color: Theme.islandMuted
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.textMonoSmall
                }
                Item { width: 1; height: Theme.spaceXs }
                Repeater {
                    model: root.wx ? root.wx.days.length : 0
                    Item {
                        id: dayRow
                        required property int index
                        width: weather.width - Theme.spaceMd
                        height: Theme.calCell * 0.8
                        readonly property var d: root.wx.days[index]
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: Theme.spaceLg * 2
                            text: dayRow.index === 0 ? "Today" : dayRow.d.day
                            color: Theme.islandText
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.textCaption
                        }
                        Text {
                            anchors.centerIn: parent
                            text: dayRow.d.icon
                            color: Theme.islandMuted
                            font.family: Theme.fontIcon
                            font.pixelSize: Theme.textBody
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: parent.right
                            text: Math.round(dayRow.d.max) + "° / " + Math.round(dayRow.d.min) + "°"
                            color: Theme.islandMuted
                            font.family: Theme.fontMono
                            font.pixelSize: Theme.textMonoSmall
                        }
                    }
                }
            }
        }

        // Month
        Kindle {
            id: month
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

                Grid {
                    id: grid
                    x: Theme.spaceXs
                    y: monthHead.y + monthHead.height
                    columns: 7
                    readonly property real cell: (parent.width - Theme.spaceXs * 2) / 7

                    Repeater {
                        model: root.weekdays
                        Text {
                            required property string modelData
                            width: grid.cell
                            height: Theme.calCell * 0.7
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
                            readonly property bool isToday: date.toDateString() === root.today.toDateString()
                            readonly property bool hasEvents: EventStore.days && EventStore.eventsFor(EventStore.keyFor(date)).length > 0
                            width: grid.cell
                            height: Theme.calCell * 0.8

                            Rectangle {
                                anchors.centerIn: parent
                                width: Math.min(parent.width, parent.height)
                                height: width
                                radius: width / 2
                                color: cell.isToday ? Theme.ember : "transparent"
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
                        }
                    }
                }
            }
        }
    }
}
