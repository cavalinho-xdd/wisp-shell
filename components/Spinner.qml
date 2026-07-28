import QtQuick
import QtQuick.Shapes
import "../core"

// Indeterminate progress ring, for "this is happening now, wait" moments —
// connecting to a network, pairing a device, applying a setting.
//
// Two things that make an indeterminate spinner read as *alive* rather than as
// a spinning decoration, both borrowed from Material's circular progress:
//   1. the arc's length breathes as it spins, so it never looks like a static
//      ring that merely rotates;
//   2. it fades/scales in rather than popping, so a fast operation that
//      finishes in <200ms never produces a visible flash of spinner.
Item {
    id: root

    property bool running: false
    property color color: Theme.primary
    property real thickness: 2

    implicitWidth: 16
    implicitHeight: 16

    // Never animate while invisible: a spinner left running behind a collapsed
    // panel is a permanent repaint at the compositor's refresh rate for nothing
    // (this shell targets a 165Hz display — see plan.md's 165Hz pass).
    readonly property bool active: running && visible && opacity > 0.01

    opacity: running ? 1 : 0
    scale: running ? 1 : 0.6
    Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { duration: 260; easing.type: Theme.easeSpring; easing.overshoot: 1.4 } }

    Shape {
        id: shape
        anchors.fill: parent
        asynchronous: true
        preferredRendererType: Shape.CurveRenderer

        // Continuous rotation…
        NumberAnimation on rotation {
            running: root.active
            from: 0; to: 360
            duration: 1100
            loops: Animation.Infinite
        }

        ShapePath {
            strokeColor: root.color
            strokeWidth: root.thickness
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                id: arc
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: (root.width - root.thickness) / 2
                radiusY: (root.height - root.thickness) / 2
                startAngle: 0
                // …plus a breathing sweep, so the gap chases the head.
                sweepAngle: 90
                SequentialAnimation on sweepAngle {
                    running: root.active
                    loops: Animation.Infinite
                    NumberAnimation { from: 40; to: 300; duration: 900; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 300; to: 40; duration: 900; easing.type: Easing.InOutSine }
                }
            }
        }
    }
}
