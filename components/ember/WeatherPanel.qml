import QtQuick
import "../../core"

// Weather for the day picked in the calendar: the current conditions for
// today, the day's high and low for later ones, the hours of that day and
// the five-day list. Clicking a day in the list picks it for the calendar too.
Item {
    id: root

    // Parsed weather.sh output (Weather.wx) and the picked day's index in
    // wx.days, -1 when the picked day has no forecast.
    property var wx: null
    property int dayIndex: -1

    signal dayPicked(int index)

    readonly property var day: wx && dayIndex >= 0 ? wx.days[dayIndex] : null
    // Later days show their forecast; today and days beyond it show now.
    readonly property bool forecast: !!day && dayIndex > 0
    readonly property var hours: day ? day.hourly : []
    readonly property real target: !wx ? 0 : (forecast ? day.max : wx.current.temp)
    property real shown: target

    Behavior on shown { NumberAnimation { duration: Theme.motionQuick; easing.type: Easing.OutCubic } }
    onDayIndexChanged: swap.restart()

    implicitWidth: 260
    implicitHeight: column.implicitHeight

    NumberAnimation {
        id: swap
        target: detail
        property: "opacity"
        from: 0.3
        to: 1
        duration: Theme.motionQuick
        easing.type: Easing.OutCubic
    }

    Column {
        id: column
        width: root.width
        spacing: Theme.spaceXs

        Item {
            id: detail
            width: column.width
            implicitHeight: head.implicitHeight + Theme.spaceSm + hourly.implicitHeight

            Column {
                id: head
                width: parent.width
                spacing: Theme.spaceXs / 2

                Text {
                    width: parent.width
                    text: !root.wx ? "Weather" : root.wx.city + (root.forecast ? " · " + root.day.day + " " + root.day.date : " · now")
                    elide: Text.ElideRight
                    color: Theme.islandMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.textCaption
                }
                Row {
                    spacing: Theme.spaceSm
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: !root.wx ? "" : (root.forecast ? root.day.icon : root.wx.current.icon)
                        color: Theme.islandText
                        font.family: Theme.fontIcon
                        font.pixelSize: Theme.textTitle * 2
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        Text {
                            text: root.wx ? Math.round(root.shown) + "°" : "–"
                            color: Theme.islandText
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.textTitle * 1.6
                            font.weight: Font.DemiBold
                        }
                        Text {
                            text: !root.wx ? (Weather.wanted ? "Loading…" : "") : (root.forecast ? root.day.desc : root.wx.current.desc)
                            color: Theme.islandMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.textCaption
                        }
                    }
                }
                Text {
                    visible: !!root.wx
                    text: !root.wx ? "" : (root.forecast
                        ? "Low " + Math.round(root.day.min) + "° · rain " + root.day.pop + " % · " + Math.round(root.day.wind) + " km/h"
                        : "Feels " + Math.round(root.wx.current.feels) + "° · " + root.wx.current.humidity + " % · " + Math.round(root.wx.current.wind) + " km/h")
                    color: Theme.islandMuted
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.textMonoSmall
                }
            }

            // The hours of the picked day: a bar per three hours, taller
            // when warmer.
            Item {
                id: hourly
                y: head.implicitHeight + Theme.spaceSm
                width: parent.width
                readonly property real lo: root.hours.reduce((m, h) => Math.min(m, h.temp), 99)
                readonly property real hi: root.hours.reduce((m, h) => Math.max(m, h.temp), -99)
                implicitHeight: Theme.calCell * 1.5

                Repeater {
                    model: root.hours.length
                    Item {
                        id: hour
                        required property int index
                        readonly property var h: root.hours[index]
                        width: hourly.width / Math.max(1, root.hours.length)
                        x: index * width
                        height: hourly.implicitHeight

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: label.top
                            anchors.bottomMargin: Theme.spaceXs / 2
                            width: Theme.spaceXs
                            radius: width / 2
                            height: Theme.spaceXs + (hourly.hi > hourly.lo ? (hour.h.temp - hourly.lo) / (hourly.hi - hourly.lo) : 0.5) * Theme.spaceLg
                            color: Theme.ember
                            opacity: 0.8
                            Behavior on height { NumberAnimation { duration: Theme.motionQuick; easing.type: Easing.OutCubic } }
                        }
                        Text {
                            id: label
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            text: hour.h.time.substring(0, 2)
                            color: Theme.islandMuted
                            font.family: Theme.fontMono
                            font.pixelSize: Theme.textLabel
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: 0
                            text: Math.round(hour.h.temp)
                            color: Theme.islandText
                            font.family: Theme.fontMono
                            font.pixelSize: Theme.textLabel
                        }
                    }
                }
            }
        }

        Item { width: 1; height: Theme.spaceXs }

        // Five days; the picked one carries a soft highlight that slides.
        Item {
            id: days
            width: column.width
            readonly property real rowHeight: Theme.calCell * 0.8
            implicitHeight: rowHeight * (root.wx ? root.wx.days.length : 0)
            height: implicitHeight

            Rectangle {
                width: parent.width
                height: days.rowHeight
                radius: Theme.radiusRow
                color: Theme.ash
                y: Math.max(0, root.dayIndex) * days.rowHeight
                opacity: root.dayIndex >= 0 ? 1 : 0
                Behavior on y { NumberAnimation { duration: Theme.motionQuick; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: Theme.motionFast } }
            }

            Repeater {
                model: root.wx ? root.wx.days.length : 0
                Item {
                    id: dayRow
                    required property int index
                    readonly property var d: root.wx.days[index]
                    y: index * days.rowHeight
                    width: days.width
                    height: days.rowHeight

                    Text {
                        x: Theme.spaceSm
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
                        anchors.rightMargin: Theme.spaceSm
                        text: Math.round(dayRow.d.max) + "° / " + Math.round(dayRow.d.min) + "°"
                        color: Theme.islandMuted
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.textMonoSmall
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.dayPicked(dayRow.index)
                    }
                }
            }
        }
    }
}
