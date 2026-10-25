import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import "../../core"

// One island: opaque smoke fill lit by the ember glow around it and a soft
// light inside it, no outline (DESIGN.md). Collapsed it is islandHeight tall
// and collapsedWidth wide; open it morphs to openWidth x openHeight.
// Children go into the content area, which matches the island's shape.
Item {
    id: island

    property bool open: false
    property real collapsedWidth: Theme.islandHeight
    property real openWidth: collapsedWidth
    property real openHeight: Theme.islandHeight
    // The inner light is the ember lighting the island from inside, so it
    // is only on while the island shows the ember (or another ember-coloured
    // element) at lightX/lightY, in island coordinates.
    property bool lit: false
    // Another island is open: step back.
    property bool dimmed: false
    // Opened by keyboard (launcher): morph short and without overshoot.
    property bool quick: false
    property real lightX: width / 2
    Behavior on lightX { NumberAnimation { duration: Theme.motionFast; easing.type: Easing.OutCubic } }
    property real lightY: Theme.islandHeight / 2
    readonly property bool hovered: hover.hovered
    // Free to be dragged along the bar; the owner decides what a drop means.
    property bool draggable: false
    property bool dragging: false
    // Pointer offset while dragging (x 1:1, y resisted) added to the owner's x/y.
    property real dragDx: 0
    property real dragDy: 0
    // Where the open island ends up: the owner lays islands out by these.
    readonly property real targetWidth: open ? openWidth : collapsedWidth

    // The further past the edge, the less it follows; saturates at `limit`.
    function rubberBand(overshoot: real, limit: real): real {
        const k = 0.55;
        return overshoot * limit * k / (limit + k * Math.abs(overshoot));
    }
    // 1 right after flare(), falling to 0: extra glow for a moment.
    property real flareBoost: 0

    function flare(): void {
        flareAnim.restart();
    }

    NumberAnimation {
        id: flareAnim
        target: island
        property: "flareBoost"
        from: 1
        to: 0
        duration: Theme.emberFlare
        easing.type: Easing.OutCubic
    }

    default property alias content: contentArea.data

    signal clicked()
    // Let go after a drag: centre x in the owner's coordinates and release velocity (px/s).
    signal released(real centerX, real velocityX)

    width: open ? openWidth : collapsedWidth
    height: open ? openHeight : Theme.islandHeight
    Behavior on width { SpringAnimation { spring: island.quick ? Theme.springQuick : Theme.springMorph; damping: island.quick ? Theme.dampingQuick : Theme.dampingMorph; epsilon: 0.25 } }
    Behavior on height { SpringAnimation { spring: island.quick ? Theme.springQuick : Theme.springMorph; damping: island.quick ? Theme.dampingQuick : Theme.dampingMorph; epsilon: 0.25 } }

    // Grows from the screen edge it hangs on; the owner sets the corner.
    transformOrigin: Item.Top
    // Position follows the owner's layout on a spring, except while the
    // pointer holds the island.
    Behavior on x { enabled: !island.dragging; SpringAnimation { spring: Theme.springMove; damping: Theme.dampingMove; epsilon: 0.25 } }
    Behavior on y { enabled: !island.dragging; SpringAnimation { spring: Theme.springMove; damping: Theme.dampingMove; epsilon: 0.25 } }
    scale: dimmed ? Theme.dimScale : ((tap.pressed || dragging) && !open ? Theme.pressScale : (hovered && !open ? Theme.hoverScale : 1))
    Behavior on scale { NumberAnimation { duration: Theme.motionFast; easing.type: Easing.OutCubic } }
    opacity: dimmed ? Theme.dimOpacity : 1
    Behavior on opacity { NumberAnimation { duration: Theme.motionMorph; easing.type: Easing.OutCubic } }

    Accessible.role: Accessible.Button
    Accessible.name: "Wisp island"

    RectangularShadow {
        anchors.fill: fill
        radius: fill.radius
        color: Qt.alpha(Theme.ember, Math.min(1, (island.open ? Theme.glowAlphaOpen : Theme.glowAlpha) * Theme.glow * (1 + island.flareBoost * Theme.flareGlowBoost)))
        blur: (island.open ? Theme.glowBlurOpen : Theme.glowBlur) * Theme.glow * (1 + island.flareBoost * Theme.flareGlowBoost)
        Behavior on blur { NumberAnimation { duration: Theme.motionMorph; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: Theme.motionMorph } }
    }

    Rectangle {
        id: fill
        anchors.fill: parent
        color: Theme.smoke
        radius: island.open ? Theme.radiusIslandOpen : Theme.radiusIsland
        Behavior on radius { NumberAnimation { duration: Theme.motionMorph; easing.type: Easing.OutCubic } }
    }

    // The light living inside the island: a radial ember glow drawn in the
    // island's own rounded shape, so it never spills past the corners.
    Shape {
        anchors.fill: parent
        visible: opacity > 0
        opacity: island.lit ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.motionFast; easing.type: Easing.OutCubic } }
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeWidth: -1
            fillGradient: RadialGradient {
                centerX: island.lightX; centerY: island.lightY
                focalX: island.lightX; focalY: island.lightY
                centerRadius: Theme.islandHeight * 2
                GradientStop { position: 0; color: Qt.alpha(Theme.ember, Theme.innerLightAlpha * Theme.glow) }
                GradientStop { position: 1; color: "transparent" }
            }
            PathRectangle {
                width: island.width
                height: island.height
                radius: fill.radius
            }
        }
    }

    HoverHandler { id: hover }

    // An open island is a surface, not a button: clicks inside it stay
    // there. Click outside or Esc closes it. A press that turns into a drag
    // is no click (the tap is cancelled past the drag threshold).
    TapHandler {
        id: tap
        enabled: !island.open
        onTapped: island.clicked()
    }

    // Drag along x with the pointer; y only stretches like a rubber band.
    // The owner turns `released` into a layout; this item just follows the
    // pointer while it is down and springs to wherever its owner puts it.
    DragHandler {
        id: drag
        target: null
        enabled: island.draggable && !island.open && !island.dimmed
        property real lastX: 0
        property real lastT: 0
        property real velocityX: 0
        onActiveTranslationChanged: {
            if (!active) return;
            island.dragDx = activeTranslation.x;
            island.dragDy = island.rubberBand(activeTranslation.y, activeTranslation.y < 0 ? Theme.islandMargin : Theme.islandHeight);
            // Smoothed release velocity, px/s.
            const now = Date.now();
            if (lastT > 0 && now > lastT) {
                const v = (activeTranslation.x - lastX) / (now - lastT) * 1000;
                velocityX = velocityX * 0.5 + v * 0.5;
            }
            lastX = activeTranslation.x;
            lastT = now;
        }
        onActiveChanged: {
            if (active) {
                lastT = 0;
                velocityX = 0;
                island.dragging = true;
            } else {
                // Read where the island was let go, then hand it back to the
                // springs before the owner moves its slot: with the springs
                // still off, the new slot would be taken with a jump and the
                // spring would then run from the wrong side.
                const centerX = island.x + island.width / 2;
                const velocity = Date.now() - lastT < 100 ? velocityX : 0;
                island.dragging = false;
                island.dragDx = 0;
                island.dragDy = 0;
                island.released(centerX, velocity);
            }
        }
    }

    // Clipped so content bigger than the island mid-morph stays inside.
    Item {
        id: contentArea
        anchors.fill: parent
        clip: true
    }
}
