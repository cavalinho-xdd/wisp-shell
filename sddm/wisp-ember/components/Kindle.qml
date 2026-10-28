import QtQuick
import QtQuick.Effects

// Content lights up out of the ember's glow instead of sliding in; a copy of
// the shell's components/ember/Kindle.qml with the theme's tokens. Blocks
// kindle in order of `index`; going out is a quick fade with no stagger.
Item {
    id: kindle

    required property var tokens
    property bool lit: false
    property int index: 0

    default property alias content: holder.data

    implicitWidth: holder.children.length ? holder.children[0].implicitWidth : 0
    implicitHeight: holder.children.length ? holder.children[0].implicitHeight : 0

    property real glowAmount: 1
    opacity: 0
    transform: Translate { id: shift; y: kindle.tokens.kindleShift }
    scale: tokens.kindleScale

    Item {
        id: holder
        anchors.fill: parent
    }

    layer.enabled: kindleIn.running || kindleOut.running
    layer.effect: MultiEffect {
        blurEnabled: true
        blurMax: 16
        blur: kindle.tokens.kindleBlur * kindle.glowAmount
        brightness: kindle.tokens.kindleBlur * kindle.glowAmount
    }

    onLitChanged: {
        if (lit) {
            kindleOut.stop();
            kindleIn.restart();
        } else {
            kindleIn.stop();
            kindleOut.restart();
        }
    }

    SequentialAnimation {
        id: kindleIn
        PropertyAction { target: kindle; property: "glowAmount"; value: 1 }
        PauseAnimation { duration: kindle.tokens.kindleDelay + kindle.index * kindle.tokens.kindleStagger }
        ParallelAnimation {
            NumberAnimation { target: kindle; property: "opacity"; to: 1; duration: kindle.tokens.motionKindle; easing.type: Easing.BezierSpline; easing.bezierCurve: kindle.tokens.curveKindle }
            NumberAnimation { target: kindle; property: "glowAmount"; to: 0; duration: kindle.tokens.motionKindle; easing.type: Easing.BezierSpline; easing.bezierCurve: kindle.tokens.curveKindle }
            NumberAnimation { target: kindle; property: "scale"; to: 1; duration: kindle.tokens.motionKindle; easing.type: Easing.BezierSpline; easing.bezierCurve: kindle.tokens.curveKindle }
            NumberAnimation { target: shift; property: "y"; to: 0; duration: kindle.tokens.motionKindle; easing.type: Easing.BezierSpline; easing.bezierCurve: kindle.tokens.curveKindle }
        }
    }

    // Logging in: blocks burn out into the light (brighter, blurred) rather
    // than just fading.
    ParallelAnimation {
        id: kindleOut
        NumberAnimation { target: kindle; property: "opacity"; to: 0; duration: 500; easing.type: Easing.BezierSpline; easing.bezierCurve: kindle.tokens.curveKindle }
        NumberAnimation { target: kindle; property: "glowAmount"; to: 1; duration: 500; easing.type: Easing.BezierSpline; easing.bezierCurve: kindle.tokens.curveKindle }
        NumberAnimation { target: kindle; property: "scale"; to: kindle.tokens.kindleScale; duration: 500; easing.type: Easing.BezierSpline; easing.bezierCurve: kindle.tokens.curveKindle }
    }
}
