import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import "../core"

// Main on/off switch of a settings page, as a tile: an icon well, a label and
// its state. Put two to four side by side in a RowLayout; they share the
// width equally. On, the tile takes a tint of the ember and the well glows.
Rectangle {
    id: root
    property string icon: ""
    property string text: ""
    property string hint: checked ? "On" : "Off"
    property bool checked: false
    signal toggled(bool value)

    Layout.fillWidth: true
    Layout.preferredWidth: 1
    implicitHeight: Theme.controlSizeBig + Theme.spaceSm
    radius: Theme.radiusCard
    color: tileMa.containsMouse ? Theme.ashHi
         : checked ? Qt.tint(Theme.ash, Qt.alpha(Theme.ember, Theme.litFill * 1.5))
         : Theme.ash
    Behavior on color { ColorAnimation { duration: Theme.animFast } }
    scale: tileMa.pressed ? Theme.pressScale : 1
    Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easeSpring } }
    opacity: enabled ? 1 : 0.5

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.spaceSm + 2
        anchors.rightMargin: Theme.spaceSm + 2
        spacing: Theme.spaceSm

        Item {
            Layout.preferredWidth: Theme.controlSize - 4
            Layout.preferredHeight: Theme.controlSize - 4

            RectangularShadow {
                anchors.fill: well
                radius: well.radius
                blur: Theme.wellGlowBlur
                color: Qt.alpha(Theme.ember, Theme.wellGlowAlpha)
                opacity: root.checked ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
            }
            Rectangle {
                id: well
                anchors.fill: parent
                radius: width / 2
                color: Theme.smoke
                Text {
                    anchors.centerIn: parent
                    text: root.icon
                    font.family: Theme.fontIcon
                    font.pixelSize: Theme.textBody
                    color: root.checked ? Theme.ember : Theme.islandMuted
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                }
            }
        }

        Column {
            Layout.fillWidth: true
            spacing: 0
            Text {
                width: parent.width
                text: root.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.textCaption
                font.weight: Font.Medium
                color: Theme.islandText
                elide: Text.ElideRight
            }
            Text {
                width: parent.width
                text: root.hint
                font.family: Theme.fontFamily
                font.pixelSize: Theme.textMonoSmall
                color: Theme.islandMuted
                elide: Text.ElideRight
            }
        }
    }

    MouseArea {
        id: tileMa
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }
}
