import QtQuick
import QtQuick.Layouts
import "../core"

Item {
    id: root

    // Properties
    property real value: 0.0 // 0.0 to 1.0
    property string title: ""
    property string subtitle: ""
    property string icon: ""
    property color color: Theme.primary
    property color bgColor: Theme.surface0
    property int lineWidth: 10
    property int iconSize: 16

    // 270° gauge: starts bottom-left (135°), sweeps through top to bottom-right (45°).
    readonly property real _startAngle: Math.PI * 0.75
    readonly property real _spanAngle: Math.PI * 1.5

    // Internal value for animation to bind smoothly
    property real _animValue: 0.0

    Behavior on _animValue {
        NumberAnimation {
            duration: Theme.animSlow * 2
            easing.type: Easing.OutQuart
        }
    }

    // Shifts to red under heavy load
    property color _drawColor: root.value >= 0.9 ? Theme.red : root.color
    Behavior on _drawColor { ColorAnimation { duration: Theme.animSlow } }

    // Update internal animation target
    onValueChanged: _animValue = value

    // Redraw canvas on frame when animated value changes
    on_AnimValueChanged: canvas.requestPaint()
    on_DrawColorChanged: canvas.requestPaint()
    onBgColorChanged: canvas.requestPaint()

    // Alive hover effect
    scale: hoverMa.containsMouse ? 1.05 : 1.0
    Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easeSpring } }

    // Subtle glow — sized to the ring, not the (possibly wide) layout cell
    Rectangle {
        anchors.centerIn: parent
        width: Math.min(parent.width, parent.height) - root.lineWidth
        height: width
        radius: width / 2
        color: root._drawColor
        opacity: hoverMa.containsMouse ? 0.15 : 0.05
        Behavior on opacity { NumberAnimation { duration: Theme.animSlow } }
    }

    Canvas {
        id: canvas
        anchors.fill: parent
        anchors.margins: 4
        antialiasing: true

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();

            var centerX = width / 2;
            var centerY = height / 2;
            var radius = Math.max(0.001, Math.min(centerX, centerY) - (root.lineWidth / 2));

            // Track
            ctx.beginPath();
            ctx.arc(centerX, centerY, radius, root._startAngle, root._startAngle + root._spanAngle);
            ctx.lineWidth = root.lineWidth;
            ctx.strokeStyle = root.bgColor;
            ctx.lineCap = "round";
            ctx.stroke();

            // Value arc
            var endAngle = root._startAngle + (root._animValue * root._spanAngle);
            if (root._animValue > 0.001) {
                ctx.beginPath();
                ctx.arc(centerX, centerY, radius, root._startAngle, endAngle);
                ctx.lineWidth = root.lineWidth;
                ctx.strokeStyle = root._drawColor;
                ctx.lineCap = "round";
                ctx.stroke();

                // Bright head dot at the arc tip
                var hx = centerX + radius * Math.cos(endAngle);
                var hy = centerY + radius * Math.sin(endAngle);
                ctx.beginPath();
                ctx.arc(hx, hy, Math.max(1, root.lineWidth / 2 - 2), 0, 2 * Math.PI);
                ctx.fillStyle = Qt.lighter(root._drawColor, 1.35);
                ctx.fill();
            }
        }
    }

    // Central content
    Column {
        anchors.centerIn: parent
        spacing: 2

        Text {
            font.family: Theme.fontFamily;
            text: root.title
            font.pixelSize: 15
            font.bold: true
            color: Theme.text
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            font.family: Theme.fontFamily;
            text: root.subtitle
            font.pixelSize: 11
            color: Theme.subtext0
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    // Metric icon sits in the gauge's bottom gap
    Text {
        text: root.icon
        font.family: Theme.fontIcon
        font.pixelSize: root.iconSize
        color: root._drawColor
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        visible: root.icon !== ""
    }

    MouseArea {
        id: hoverMa
        anchors.fill: parent
        hoverEnabled: true
    }
}
