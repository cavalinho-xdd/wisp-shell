import QtQuick
import "../../core"

// One app's volume in the mixer: name on top, slider with percentage below.
Item {
    id: row

    property string name: ""
    property real value: 0
    property bool muted: false

    signal moved(real value)
    signal muteClicked()

    implicitHeight: Theme.listRow

    Text {
        x: Theme.spaceXs
        width: parent.width - Theme.spaceXs * 2
        text: row.name
        elide: Text.ElideRight
        textFormat: Text.PlainText
        color: Theme.islandText
        font.family: Theme.fontFamily
        font.pixelSize: Theme.textCaption
    }
    Row {
        y: parent.height - height
        x: Theme.spaceXs
        spacing: Theme.spaceSm
        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: Theme.spaceLg
            horizontalAlignment: Text.AlignHCenter
            text: row.muted ? "󰖁" : "󰕾"
            color: row.muted ? Theme.islandMuted : Theme.islandText
            font.family: Theme.fontIcon
            font.pixelSize: Theme.textBody
            MouseArea {
                anchors.fill: parent
                anchors.margins: -Theme.spaceXs
                cursorShape: Qt.PointingHandCursor
                onClicked: row.muteClicked()
            }
        }
        EmberSlider {
            id: slider
            width: row.width - Theme.spaceXs * 2 - Theme.spaceLg - Theme.spaceSm * 2 - pct.width
            anchors.verticalCenter: parent.verticalCenter
            label: row.name
            value: Math.min(1, row.value)
            onMoved: v => row.moved(v)
        }
        Text {
            id: pct
            anchors.verticalCenter: parent.verticalCenter
            width: Theme.spaceLg + Theme.spaceSm
            horizontalAlignment: Text.AlignRight
            text: Math.round(row.value * 100)
            color: Theme.islandMuted
            font.family: Theme.fontMono
            font.pixelSize: Theme.textMonoSmall
        }
    }
}
