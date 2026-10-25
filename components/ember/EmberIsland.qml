import QtQuick
import QtQuick.Effects
import "../../core"

// One island: opaque smoke fill lit by the ember glow around it, no outline
// (DESIGN.md). Collapsed it is islandHeight tall and collapsedWidth wide; open
// it morphs to openWidth x openHeight. Content arrives in M3+.
Item {
    id: island

    property bool open: false
    property real collapsedWidth: Theme.islandHeight
    property real openWidth: collapsedWidth
    property real openHeight: Theme.islandHeight

    signal clicked()

    width: open ? openWidth : collapsedWidth
    height: open ? openHeight : Theme.islandHeight
    Behavior on width { NumberAnimation { duration: Theme.motionMorph; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curveMorph } }
    Behavior on height { NumberAnimation { duration: Theme.motionMorph; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curveMorph } }

    Accessible.role: Accessible.Button
    Accessible.name: "Wisp island"

    RectangularShadow {
        anchors.fill: fill
        radius: fill.radius
        color: Qt.alpha(Theme.ember, (island.open ? Theme.glowAlphaOpen : Theme.glowAlpha) * Theme.glow)
        blur: (island.open ? Theme.glowBlurOpen : Theme.glowBlur) * Theme.glow
        Behavior on blur { NumberAnimation { duration: Theme.motionMorph; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: Theme.motionMorph } }
    }

    Rectangle {
        id: fill
        anchors.fill: parent
        color: Theme.smoke
        radius: island.open ? Theme.radiusIslandOpen : Theme.radiusIsland
        Behavior on radius { NumberAnimation { duration: Theme.motionMorph; easing.type: Easing.OutCubic } }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: island.clicked()
    }
}
