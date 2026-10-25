import QtQuick
import QtQuick.Shapes
import "../../core"

// A flat surface with at most two kinds of light: `topLight` puts a 1 px
// crescent of light on the top edge (one light from above, nothing down the
// sides), and `lit` lights the surface from inside by the ember at
// lightX/lightY, fading to the plain fill towards the far end. Gradients only:
// no offscreen effects, so many can be on screen.
Item {
    id: root

    property color base: Theme.ash
    property real radius: Theme.radiusTile
    property bool topLight: false
    property bool lit: false
    // Where the ember sits for `lit`, in this item's coordinates.
    property real lightX: width / 2
    property real lightY: height / 2
    property real lightRadius: width * 0.6

    property color fill: lit ? Qt.tint(base, Qt.alpha(Theme.ember, Theme.litFill)) : base
    Behavior on fill { ColorAnimation { duration: Theme.motionFast } }

    // The crescent: this rectangle shows through a 1 px step above the fill and
    // fades out within the first radius, so it thins out round the corners.
    Rectangle {
        anchors.fill: parent
        visible: root.topLight
        radius: root.radius
        gradient: Gradient {
            GradientStop { position: 0; color: Theme.edgeLight }
            GradientStop { position: Math.min(1, (root.radius + 2) / Math.max(1, root.height)); color: "transparent" }
            GradientStop { position: 1; color: "transparent" }
        }
    }

    Rectangle {
        id: body
        anchors.fill: parent
        anchors.topMargin: root.topLight ? 1 : 0
        radius: root.radius
        color: root.fill
    }

    // The ember's light inside the surface, drawn in its rounded shape.
    Shape {
        anchors.fill: body
        visible: opacity > 0
        opacity: root.lit ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.motionFast; easing.type: Easing.OutCubic } }
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeWidth: -1
            fillGradient: RadialGradient {
                centerX: root.lightX - body.x; centerY: root.lightY - body.y
                focalX: root.lightX - body.x; focalY: root.lightY - body.y
                centerRadius: root.lightRadius
                GradientStop { position: 0; color: Qt.alpha(Theme.ember, Theme.litHalo * Theme.glow) }
                GradientStop { position: 1; color: "transparent" }
            }
            PathRectangle {
                width: body.width
                height: body.height
                radius: body.radius
            }
        }
    }
}
