import QtQuick
import "../core"

// Small animated pill switch shared by the settings UI.
Item {
    id: sw
    property bool checked: false
    signal toggled(bool value)
    width: 36; height: 20

    Rectangle {
        anchors.fill: parent
        radius: 10
        // Track fill alone. Checked, the border matched its own fill; unchecked,
        // it outlined a track that the surface0 tonal step already defines.
        color: sw.checked ? Theme.primary : Theme.surface0
        Behavior on color { ColorAnimation { duration: Theme.animFast } }

        Rectangle {
            width: 14; height: 14; radius: 7
            anchors.verticalCenter: parent.verticalCenter
            x: sw.checked ? parent.width - width - 3 : 3
            color: sw.checked ? Theme.colorOnPrimary : Theme.subtext0
            Behavior on x { NumberAnimation { duration: Theme.animSlow; easing.type: Theme.easeSpring } }
            Behavior on color { ColorAnimation { duration: Theme.animFast } }
        }
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -6
        cursorShape: Qt.PointingHandCursor
        onClicked: sw.toggled(!sw.checked)
    }
}
