import QtQuick

// One top-edge island: the Ember material around a row of content. Leans in
// a little on hover and gives on press; its width springs when the content
// grows (the power island asking to confirm).
Item {
    id: island

    required property var tokens
    property real padding: 16
    property alias spacing: row.spacing
    property bool pressed: false
    default property alias content: row.data

    implicitWidth: row.implicitWidth + 2 * padding
    implicitHeight: tokens.islandHeight
    width: implicitWidth
    height: implicitHeight
    Behavior on width { SpringAnimation { spring: 3.5; damping: 0.32; epsilon: 0.25 } }

    scale: pressed ? 0.98 : hover.hovered ? 1.03 : 1
    Behavior on scale { SpringAnimation { spring: 4; damping: 0.3; epsilon: 0.002 } }

    HoverHandler { id: hover }

    Surface {
        anchors.fill: parent
        tokens: island.tokens
        radius: island.tokens.radiusIsland
    }

    Row {
        id: row
        x: island.padding
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10
    }
}
