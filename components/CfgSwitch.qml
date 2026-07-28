import QtQuick
import QtQuick.Layouts
import "../core"

// Full-width clickable row: icon, label, switch on the right.
// Modeled on ii-dots ConfigSwitch — the whole row toggles.
Rectangle {
    id: root
    property string icon: ""
    property string text: ""
    property string hint: ""
    property bool checked: false
    signal toggled(bool value)

    Layout.fillWidth: true
    implicitHeight: rowContent.implicitHeight + 20
    radius: 12
    color: rowMa.containsMouse ? Theme.surface0 : "transparent"
    Behavior on color { ColorAnimation { duration: Theme.animFast } }

    ColumnLayout {
        id: rowContent
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 2

        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Text {
                text: root.icon
                font.family: Theme.fontIcon
                font.pixelSize: 15
                color: root.enabled ? Theme.text : Theme.subtext0
                visible: root.icon !== ""
            }
            Text {
                font.family: Theme.fontFamily;
                Layout.fillWidth: true
                text: root.text
                font.pixelSize: 13
                color: root.enabled ? Theme.text : Theme.subtext0
            }
            ToggleSwitch {
                checked: root.checked
                onToggled: value => root.toggled(value)
            }
        }

        Text {
            font.family: Theme.fontFamily;
            Layout.fillWidth: true
            text: root.hint
            font.pixelSize: 11
            color: Theme.subtext0
            wrapMode: Text.WordWrap
            visible: root.hint !== ""
        }
    }

    MouseArea {
        id: rowMa
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.toggled(!root.checked)
        z: -1
    }
}
