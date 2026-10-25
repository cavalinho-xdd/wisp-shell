import QtQuick
import QtQuick.Effects
import "../../core"

// "Kindle": content lights up out of the ember's glow instead of sliding in
// (DESIGN.md). Wraps one block of an island's open content; blocks kindle in
// order of `index`. Going out is a quick fade with no stagger. The blur and
// brightness layer exists only while the animation runs.
Item {
    id: kindle

    property bool lit: false
    property int index: 0
    // Opened by keyboard, often: no stagger, no blur, a short fade.
    property bool quick: false

    default property alias content: holder.data

    // Sized by its one child's implicit size; give the child a width bound
    // to the Kindle (not the other way round) when it must fill a column.
    implicitWidth: holder.children.length ? holder.children[0].implicitWidth : 0
    implicitHeight: holder.children.length ? holder.children[0].implicitHeight : 0

    property real glowAmount: 1
    // Stays visible at opacity 0 so layouts keep their size while the
    // blocks are still waiting for their turn.
    opacity: 0
    transform: Translate { id: shift; y: Theme.kindleShift }
    scale: Theme.kindleScale

    Item {
        id: holder
        anchors.fill: parent
    }

    layer.enabled: kindleIn.running && !kindle.quick
    layer.effect: MultiEffect {
        blurEnabled: true
        blurMax: 16
        blur: Theme.kindleBlur * kindle.glowAmount
        brightness: Theme.kindleBlur * kindle.glowAmount
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
        PropertyAction { target: kindle; property: "glowAmount"; value: kindle.quick ? 0 : 1 }
        PauseAnimation { duration: kindle.quick ? 0 : Theme.kindleDelay + kindle.index * Theme.kindleStagger }
        ParallelAnimation {
            NumberAnimation { target: kindle; property: "opacity"; to: 1; duration: kindle.quick ? Theme.motionFast : Theme.motionKindle; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curveKindle }
            NumberAnimation { target: kindle; property: "glowAmount"; to: 0; duration: kindle.quick ? Theme.motionFast : Theme.motionKindle; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curveKindle }
            NumberAnimation { target: kindle; property: "scale"; to: 1; duration: kindle.quick ? Theme.motionFast : Theme.motionKindle; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curveKindle }
            NumberAnimation { target: shift; property: "y"; to: 0; duration: kindle.quick ? Theme.motionFast : Theme.motionKindle; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curveKindle }
        }
    }

    SequentialAnimation {
        id: kindleOut
        NumberAnimation { target: kindle; property: "opacity"; to: 0; duration: Theme.motionFast; easing.type: Easing.OutCubic }
        PropertyAction { target: kindle; property: "scale"; value: Theme.kindleScale }
        PropertyAction { target: shift; property: "y"; value: Theme.kindleShift }
    }
}
