import QtQuick
import QtQuick.Effects
import "../../core"

// The ember: the one light in the shell (DESIGN.md). Breathes slowly while
// idle and beats while media plays. Animators run on the render thread, and
// `running` lets the owner stop them while the islands are hidden.
Item {
    id: dot

    property bool playing: false
    property bool running: true

    implicitWidth: Theme.emberSize
    implicitHeight: Theme.emberSize

    Accessible.ignored: true

    // Glow and core breathe together, so the animators drive their parent.
    Item {
        id: light
        anchors.fill: parent

        RectangularShadow {
            anchors.fill: core
            radius: core.radius
            color: Theme.ember
            blur: Theme.glowBlur * 0.7 * Theme.glow
        }

        Rectangle {
            id: core
            anchors.fill: parent
            radius: width / 2
            color: Theme.ember
        }
    }

    // Idle: opacity 0.55 <-> 1, scale 0.85 <-> 1 over one breath.
    ParallelAnimation {
        running: dot.running && !dot.playing
        loops: Animation.Infinite
        SequentialAnimation {
            OpacityAnimator { target: light; to: 0.55; duration: Theme.emberBreathe / 2; easing.type: Easing.InOutSine }
            OpacityAnimator { target: light; to: 1; duration: Theme.emberBreathe / 2; easing.type: Easing.InOutSine }
        }
        SequentialAnimation {
            ScaleAnimator { target: light; to: 0.85; duration: Theme.emberBreathe / 2; easing.type: Easing.InOutSine }
            ScaleAnimator { target: light; to: 1; duration: Theme.emberBreathe / 2; easing.type: Easing.InOutSine }
        }
    }

    // Playing: a quicker beat, always bright.
    SequentialAnimation {
        running: dot.running && dot.playing
        loops: Animation.Infinite
        ParallelAnimation {
            OpacityAnimator { target: light; to: 1; duration: Theme.emberBeat; easing.type: Easing.OutSine }
            ScaleAnimator { target: light; to: 1.15; duration: Theme.emberBeat; easing.type: Easing.OutSine }
        }
        ScaleAnimator { target: light; to: 0.9; duration: Theme.emberBeat; easing.type: Easing.InOutSine }
    }
}
