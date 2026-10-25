import QtQuick
import QtQuick.Effects
import "../../core"

// The ember: the one light in the shell (DESIGN.md). Breathes slowly while
// idle and beats while media plays. `running` lets the owner stop it while
// the islands are hidden.
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

    // Idle: opacity 0.55 <-> 1, scale 0.85 <-> 1 over one breath. Playing:
    // always bright, scale 0.9 <-> 1.15 over two beats. Stepped at 20 fps
    // instead of animated per frame: each frame redraws the whole island
    // window, and the motion is too slow to show the steps.
    property real phase: 0
    readonly property real wave: Math.cos(phase * 2 * Math.PI)

    Timer {
        interval: 50
        repeat: true
        running: dot.running && !Theme.reduceMotion
        onTriggered: dot.phase = (dot.phase + interval / (dot.playing ? Theme.emberBeat * 2 : Theme.emberBreathe)) % 1
        onRunningChanged: if (!running) dot.phase = 0
    }
    Binding {
        target: light
        property: "opacity"
        value: dot.playing ? 1 : 0.775 + 0.225 * dot.wave
        when: !Theme.reduceMotion
    }
    Binding {
        target: light
        property: "scale"
        value: dot.playing ? 1.025 - 0.125 * dot.wave : 0.925 + 0.075 * dot.wave
        when: !Theme.reduceMotion
    }
}
