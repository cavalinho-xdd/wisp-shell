import QtQuick
import QtQuick.Effects

// The Ember island material: a smoke body with light on its top edge, a
// contact and an ambient shadow, and the ember's glow around it. Shared by
// the top islands, the session menu and the password field.
Item {
    id: surface

    required property var tokens
    property real radius: tokens.radiusIsland
    property color fill: tokens.smoke
    property color glowColor: tokens.ember
    property real glowBlur: 22
    property real glowAlpha: 0.16
    property real ambientY: 12
    property real ambientBlur: 32
    property real ambientAlpha: 0.42

    RectangularShadow {
        anchors.fill: body
        radius: surface.radius
        offset.y: surface.ambientY
        blur: surface.ambientBlur
        color: Qt.rgba(0, 0, 0, surface.ambientAlpha)
    }
    RectangularShadow {
        anchors.fill: body
        radius: surface.radius
        offset.y: 1
        blur: 2
        color: Qt.rgba(0, 0, 0, 0.5)
    }
    RectangularShadow {
        anchors.fill: body
        radius: surface.radius
        blur: surface.tokens.glow * surface.glowBlur
        color: Qt.alpha(surface.glowColor, Math.min(1, surface.glowAlpha * surface.tokens.glow))
        visible: surface.tokens.glow > 0
    }

    // Top light: the edge strip shows above the body's 1 px inset.
    Rectangle {
        anchors.fill: parent
        radius: surface.radius
        gradient: Gradient {
            GradientStop { position: 0; color: surface.tokens.topLight }
            GradientStop { position: Math.min(1, (surface.radius + 2) / Math.max(1, surface.height)); color: "transparent" }
            GradientStop { position: 1; color: "transparent" }
        }
    }
    Rectangle {
        id: body
        anchors.fill: parent
        anchors.topMargin: 1
        radius: surface.radius
        color: surface.fill
    }
}
