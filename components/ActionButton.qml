import QtQuick
import "../core"

// Icon + text label pill button — the settings-app counterpart to IconButton
// (which is icon-only). Sized to its content so it drops straight into a
// RowLayout without extra Layout.preferredWidth bookkeeping at call sites.
Rectangle {
    id: root
    property string icon: ""
    property string text: ""
    signal clicked()

    implicitWidth: row.implicitWidth + 28
    implicitHeight: 36
    radius: 12
    // Borderless: a button reads as a button from its fill and its hover
    // reaction. The outline this used to carry was the "grey box around
    // everything" tell, and it made a row of these look like a row of cards
    // rather than a row of controls. Hover steps up the tonal ramp instead.
    color: mouse.pressed ? Theme.surface0
        : (mouse.containsMouse ? Qt.lighter(Theme.surface, 1.35) : Theme.surface)
    Behavior on color { ColorAnimation { duration: Theme.animFast } }

    scale: mouse.pressed ? 0.96 : 1.0
    Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easeSpring } }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 7
        Text {
            text: root.icon
            visible: root.icon !== ""
            font.family: Theme.fontIcon
            font.pixelSize: 13
            color: Theme.primary
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            font.family: Theme.fontFamily;
            text: root.text
            font.pixelSize: 12
            font.bold: true
            color: Theme.text
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }
}
