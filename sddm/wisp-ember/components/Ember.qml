import QtQuick
import QtQuick.Effects
import QtQuick.Shapes

// The ember: the one light on the screen. Breathes slowly; its glow grows
// with `heat` (the password length); flare() is the login moment.
Item {
    id: dot

    required property var tokens
    property real heat: 0

    implicitWidth: tokens.emberSize
    implicitHeight: tokens.emberSize
    Accessible.ignored: true

    Item {
        id: light
        anchors.fill: parent

        RectangularShadow {
            anchors.fill: core
            radius: core.radius
            color: Qt.alpha(dot.tokens.ember, 0.85)
            blur: dot.tokens.glow * (22 + dot.heat * 26)
            spread: 0
            Behavior on blur { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
        }
        RectangularShadow {
            anchors.fill: core
            radius: core.radius
            color: dot.tokens.ember
            blur: 6
        }

        Rectangle {
            id: core
            anchors.fill: parent
            radius: width / 2
            color: dot.tokens.ember
        }

        // A soft hot spot, so it reads as a light and not a disc.
        Shape {
            anchors.fill: core
            anchors.margins: 4
            opacity: 0.55
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeWidth: -1
                fillGradient: RadialGradient {
                    centerX: 4; centerY: 3.5; centerRadius: 7
                    focalX: 4; focalY: 3.5
                    GradientStop { position: 0; color: "white" }
                    GradientStop { position: 0.7; color: "transparent" }
                }
                PathAngleArc { centerX: 5; centerY: 5; radiusX: 5; radiusY: 5; sweepAngle: 360 }
            }
        }
    }

    // opacity .78 <-> 1, scale .9 <-> 1 over one breath.
    SequentialAnimation {
        running: !dot.tokens.reduceMotion && !flareAnim.running
        loops: Animation.Infinite
        ParallelAnimation {
            NumberAnimation { target: light; property: "opacity"; from: 0.78; to: 1; duration: dot.tokens.emberBreathe / 2; easing.type: Easing.InOutSine }
            NumberAnimation { target: light; property: "scale"; from: 0.9; to: 1; duration: dot.tokens.emberBreathe / 2; easing.type: Easing.InOutSine }
        }
        ParallelAnimation {
            NumberAnimation { target: light; property: "opacity"; to: 0.78; duration: dot.tokens.emberBreathe / 2; easing.type: Easing.InOutSine }
            NumberAnimation { target: light; property: "scale"; to: 0.9; duration: dot.tokens.emberBreathe / 2; easing.type: Easing.InOutSine }
        }
    }

    function flare() {
        flareAnim.restart();
    }

    SequentialAnimation {
        id: flareAnim
        PropertyAction { target: light; property: "opacity"; value: 1 }
        NumberAnimation { target: light; property: "scale"; to: dot.tokens.reduceMotion ? 1 : 2.2; duration: 275; easing.type: Easing.OutCubic }
        NumberAnimation { target: light; property: "scale"; to: 1; duration: 825; easing.type: Easing.BezierSpline; easing.bezierCurve: dot.tokens.curveKindle }
    }
}
