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

    default property alias content: holder.data

    // Sized by its one child's implicit size; give the child a width bound
    // to the Kindle (not the other way round) when it must fill a column.
    implicitWidth: holder.children.length ? holder.children[0].implicitWidth : 0
    implicitHeight: holder.children.length ? holder.children[0].implicitHeight : 0

    property real glowAmount: 1
    // Stays visible at opacity 0 so layouts keep their size while the
    // blocks are still waiting for their turn.
    opacity: 0
    transform: Translate { id: shift; y: 5 }
    scale: 0.98

    Item {
        id: holder
        anchors.fill: parent
    }

    layer.enabled: kindleIn.running
    layer.effect: MultiEffect {
        blurEnabled: true
        blurMax: 16
        blur: 0.5 * kindle.glowAmount
        brightness: 0.5 * kindle.glowAmount
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
        PauseAnimation { duration: Theme.kindleDelay + kindle.index * Theme.kindleStagger }
        ParallelAnimation {
            NumberAnimation { target: kindle; property: "opacity"; to: 1; duration: Theme.motionKindle; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curveKindle }
            NumberAnimation { target: kindle; property: "glowAmount"; to: 0; duration: Theme.motionKindle; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curveKindle }
            NumberAnimation { target: kindle; property: "scale"; to: 1; duration: Theme.motionKindle; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curveKindle }
            NumberAnimation { target: shift; property: "y"; to: 0; duration: Theme.motionKindle; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curveKindle }
        }
    }

    SequentialAnimation {
        id: kindleOut
        NumberAnimation { target: kindle; property: "opacity"; to: 0; duration: Theme.motionFast; easing.type: Easing.OutCubic }
        PropertyAction { target: kindle; property: "scale"; value: 0.98 }
        PropertyAction { target: shift; property: "y"; value: 5 }
    }
}
