import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import "../../core"

// One island: opaque smoke fill lit by the ember glow around it and a soft
// light inside it, no outline (DESIGN.md). Collapsed it is islandHeight tall
// and collapsedWidth wide; open it morphs to openWidth x openHeight.
// Children go into the content area, which matches the island's shape.
Item {
    id: island

    property bool open: false
    property real collapsedWidth: Theme.islandHeight
    property real openWidth: collapsedWidth
    property real openHeight: Theme.islandHeight
    // The inner light is the ember lighting the island from inside, so it
    // is only on while the island shows the ember (or another ember-coloured
    // element) at lightX/lightY, in island coordinates.
    property bool lit: false
    property real lightX: width / 2
    property real lightY: Theme.islandHeight / 2
    readonly property bool hovered: mouse.containsMouse

    default property alias content: contentArea.data

    signal clicked()

    width: open ? openWidth : collapsedWidth
    height: open ? openHeight : Theme.islandHeight
    Behavior on width { NumberAnimation { duration: Theme.motionMorph; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curveMorph } }
    Behavior on height { NumberAnimation { duration: Theme.motionMorph; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curveMorph } }

    // Grows from the screen edge it hangs on; the owner sets the corner.
    transformOrigin: Item.Top
    scale: hovered && !open ? Theme.hoverScale : 1
    Behavior on scale { NumberAnimation { duration: Theme.motionFast; easing.type: Easing.OutCubic } }

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

    // The light living inside the island: a radial ember glow drawn in the
    // island's own rounded shape, so it never spills past the corners.
    Shape {
        anchors.fill: parent
        visible: opacity > 0
        opacity: island.lit ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.motionFast; easing.type: Easing.OutCubic } }
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeWidth: -1
            fillGradient: RadialGradient {
                centerX: island.lightX; centerY: island.lightY
                focalX: island.lightX; focalY: island.lightY
                centerRadius: Theme.islandHeight * 2
                GradientStop { position: 0; color: Qt.alpha(Theme.ember, Theme.innerLightAlpha * Theme.glow) }
                GradientStop { position: 1; color: "transparent" }
            }
            PathRectangle {
                width: island.width
                height: island.height
                radius: fill.radius
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: island.clicked()
    }

    Item {
        id: contentArea
        anchors.fill: parent
    }
}
