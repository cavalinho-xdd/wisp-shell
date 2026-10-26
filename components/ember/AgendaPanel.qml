import QtQuick
import "../../core"

// Events of one day (EventStore, shared with the old widget): tick one off,
// remove it, or type a new one and press Enter.
Item {
    id: root

    property var date: new Date()
    property bool lit: false

    readonly property string key: EventStore.keyFor(date)
    // Reading EventStore.days keeps this live across edits.
    readonly property var events: EventStore.days ? EventStore.eventsFor(key) : []

    implicitHeight: Theme.listRow * 2 + Theme.spaceSm * 2

    onLitChanged: if (!lit) {
        field.focus = false;
        field.text = "";
    }
    onKeyChanged: field.text = ""

    Text {
        id: heading
        width: parent.width
        text: Qt.formatDate(root.date, "dddd d. MMMM")
        elide: Text.ElideRight
        color: Theme.islandMuted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.textLabel
        font.letterSpacing: Theme.textLabel * 0.08
        font.capitalization: Font.AllUppercase
    }

    ListView {
        id: list
        y: heading.height + Theme.spaceXs / 2
        width: parent.width
        height: Theme.calCell * 0.8 * 2
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: root.events

        add: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.motionQuick; easing.type: Easing.OutCubic } }
        remove: Transition { NumberAnimation { property: "opacity"; to: 0; duration: Theme.motionFast; easing.type: Easing.OutCubic } }
        displaced: Transition { NumberAnimation { property: "y"; duration: Theme.motionQuick; easing.type: Easing.OutCubic } }

        delegate: Item {
            id: row
            required property int index
            required property var modelData
            width: list.width
            height: Theme.calCell * 0.8

            Rectangle {
                id: box
                x: Theme.spaceXs
                anchors.verticalCenter: parent.verticalCenter
                width: Theme.spaceMd
                height: width
                radius: width / 2
                color: row.modelData.done ? Theme.ember : "transparent"
                border.width: 1.5
                border.color: row.modelData.done ? Theme.ember : Theme.islandMuted
                Behavior on color { ColorAnimation { duration: Theme.motionFast } }
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -Theme.spaceXs
                    cursorShape: Qt.PointingHandCursor
                    onClicked: EventStore.toggleDone(root.key, row.index)
                }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                x: box.x + box.width + Theme.spaceSm
                width: parent.width - x - Theme.controlSize
                text: row.modelData.text
                elide: Text.ElideRight
                textFormat: Text.PlainText
                color: row.modelData.done ? Theme.islandMuted : Theme.islandText
                font.family: Theme.fontFamily
                font.pixelSize: Theme.textCaption
                font.strikeout: row.modelData.done
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: Theme.spaceXs
                text: "󰅖"
                color: removeMouse.containsMouse ? Theme.ember : Theme.islandMuted
                font.family: Theme.fontIcon
                font.pixelSize: Theme.textBody
                Behavior on color { ColorAnimation { duration: Theme.motionFast } }
                Accessible.role: Accessible.Button
                Accessible.name: "Remove event"
                MouseArea {
                    id: removeMouse
                    anchors.fill: parent
                    anchors.margins: -Theme.spaceXs
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: EventStore.removeEvent(root.key, row.index)
                }
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            x: Theme.spaceXs
            visible: list.count === 0
            text: "Nothing planned"
            color: Theme.islandMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.textCaption
        }
    }

    Rectangle {
        y: parent.height - height
        width: parent.width
        height: Theme.controlSize - Theme.spaceXs
        radius: height / 2
        color: field.activeFocus ? Theme.ashHi : Theme.well
        border.width: field.activeFocus ? 1 : 0
        border.color: Theme.ember
        Behavior on color { ColorAnimation { duration: Theme.motionFast } }

        TextInput {
            id: field
            anchors.fill: parent
            anchors.leftMargin: Theme.spaceMd
            anchors.rightMargin: Theme.spaceMd
            verticalAlignment: TextInput.AlignVCenter
            clip: true
            color: Theme.islandText
            selectionColor: Theme.ember
            selectedTextColor: Theme.smoke
            font.family: Theme.fontFamily
            font.pixelSize: Theme.textCaption
            Accessible.role: Accessible.EditableText
            Accessible.name: "New event"
            onAccepted: {
                EventStore.addEvent(root.key, text);
                text = "";
            }
            Text {
                anchors.fill: parent
                verticalAlignment: Text.AlignVCenter
                visible: field.text === "" && !field.activeFocus
                text: "Add an event"
                color: Theme.islandMuted
                font: field.font
            }
        }
    }
}
