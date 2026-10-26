import QtQuick
import "../../core"

// One audio device in the sound view; the default one is marked with the ember.
Rectangle {
    id: row

    property string icon: ""
    property string name: ""
    property bool active: false

    signal clicked()

    implicitHeight: Theme.listRow - Theme.spaceXs
    radius: Theme.radiusRow
    color: mouse.containsMouse ? Theme.hover : (active ? Theme.ash : "transparent")
    Behavior on color { ColorAnimation { duration: Theme.motionFast } }

    Accessible.role: Accessible.RadioButton
    Accessible.name: name
    Accessible.checked: active

    Text {
        id: glyph
        x: Theme.spaceSm
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.controlSize
        horizontalAlignment: Text.AlignHCenter
        text: row.icon
        color: row.active ? Theme.ember : Theme.islandMuted
        font.family: Theme.fontIcon
        font.pixelSize: Theme.textTitle
    }
    Text {
        anchors.verticalCenter: parent.verticalCenter
        x: glyph.x + glyph.width + Theme.spaceSm
        width: parent.width - x - Theme.spaceSm
        text: row.name
        elide: Text.ElideRight
        textFormat: Text.PlainText
        color: Theme.islandText
        font.family: Theme.fontFamily
        font.pixelSize: Theme.textBody
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: row.clicked()
    }
}
