import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import "components"

// Wisp Ember login screen (docs/superpowers/specs/2026-10-28-sddm-ember-design.md).
// Laid out in a 1080-px-tall frame scaled to the screen; the frame's width
// follows the screen's aspect, so the islands stay on the edges.
Rectangle {
    id: root
    width: 1920
    height: 1080
    color: tokens.smoke

    Tokens { id: tokens }

    // Content kindles in once the greeter is up.
    property bool lit: false
    Component.onCompleted: lit = true

    property int userIndex: Math.max(0, userModel.lastIndex)
    property int sessionIndex: Math.max(0, sessionModel.lastIndex)
    property bool capsLock: keyboard ? keyboard.capsLock : false
    property alias password: field.text
    property bool needsPassword: users.needsPassword
    property string status: ""
    property bool busy: false

    // A user without a password logs in with an empty field.
    function login() {
        if (busy) return;
        if (needsPassword && field.text.length === 0) return;
        busy = true;
        status = "";
        sddm.login(users.userName, field.text, sessionIndex);
    }

    function loginFailed() {
        busy = false;
        field.text = "";
        field.failed = true;
        field.shake();
        status = "Heslo nesedí";
    }
    function loginSucceeded() {
        ember.flare();
        leaving.start();
        lit = false;
    }

    Connections {
        target: sddm
        function onLoginFailed() { root.loginFailed(); }
        function onLoginSucceeded() { root.loginSucceeded(); }
        function onInformationMessage(message) {
            root.status = message;
        }
    }

    // Logging in: content kindles out into the ember, then the room goes dark.
    SequentialAnimation {
        id: leaving
        PauseAnimation { duration: 350 }
        ParallelAnimation {
            NumberAnimation { target: room; property: "opacity"; to: 0; duration: 1100; easing.type: Easing.BezierSpline; easing.bezierCurve: tokens.curveKindle }
            NumberAnimation { target: cast; property: "opacity"; to: 0; duration: 1100; easing.type: Easing.BezierSpline; easing.bezierCurve: tokens.curveKindle }
        }
    }

    // ── The room: the wallpaper, blurred and darkened, slowly drifting ──
    Item {
        id: room
        anchors.fill: parent

        Image {
            id: wall
            anchors.fill: parent
            anchors.margins: -60 * frame.scale
            source: config.background || ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: false
            sourceSize.width: 1280 // blurred to 40 px anyway; keeps the blur cheap
        }
        MultiEffect {
            id: wallFx
            anchors.fill: wall
            source: wall
            visible: wall.status === Image.Ready
            blurEnabled: true
            blurMax: 64
            blur: 1.0
            brightness: -0.5
            saturation: -0.1

            SequentialAnimation on scale {
                running: !tokens.reduceMotion
                loops: Animation.Infinite
                NumberAnimation { from: 1.02; to: 1.07; duration: tokens.driftDuration; easing.type: Easing.InOutSine }
                NumberAnimation { from: 1.07; to: 1.02; duration: tokens.driftDuration; easing.type: Easing.InOutSine }
            }
        }

        // Vignette: the edges fall off into the dark.
        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeWidth: -1
                fillGradient: RadialGradient {
                    centerX: room.width / 2; centerY: room.height * 0.45
                    focalX: centerX; focalY: centerY
                    centerRadius: Math.hypot(room.width, room.height) * 0.6
                    GradientStop { position: 0.35; color: "transparent" }
                    GradientStop { position: 1; color: Qt.rgba(0, 0, 0, 0.55) }
                }
                PathRectangle { width: room.width; height: room.height }
            }
        }
    }

    // ── The 1080-tall frame everything else lives in ──
    Item {
        id: frame
        scale: root.height / 1080
        transformOrigin: Item.TopLeft
        width: root.width / scale
        height: 1080

        // The ember's light cast on the room, behind the clock.
        Item {
            id: cast
            width: 1100
            height: 760
            x: (frame.width - width) / 2
            y: 360 - height / 2
            opacity: 0.75 + centre.heat * 0.25
            Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }

            Shape {
                width: cast.width
                height: cast.width
                transform: Scale { yScale: cast.height / cast.width }
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeWidth: -1
                    fillGradient: RadialGradient {
                        centerX: cast.width / 2; centerY: cast.width / 2
                        focalX: centerX; focalY: centerY
                        centerRadius: cast.width / 2
                        GradientStop { position: 0; color: Qt.alpha(tokens.ember, Math.min(1, 0.09 * tokens.glow)) }
                        GradientStop { position: 1; color: "transparent" }
                    }
                    PathAngleArc { centerX: cast.width / 2; centerY: cast.width / 2; radiusX: cast.width / 2; radiusY: cast.width / 2; sweepAngle: 360 }
                }
            }
        }

        // ── Centre column ──
        Column {
            id: centre
            readonly property real heat: field.heat
            width: 520
            x: (frame.width - width) / 2
            y: frame.height / 2 - height * 0.54

            Kindle {
                tokens: tokens
                // The ember stays while everything else kindles out into it.
                lit: root.lit || leaving.running
                index: 0
                anchors.horizontalCenter: parent.horizontalCenter
                Ember {
                    id: ember
                    tokens: tokens
                    heat: centre.heat
                }
            }

            Item { width: 1; height: 30 }

            Kindle {
                tokens: tokens
                lit: root.lit
                index: 1
                anchors.horizontalCenter: parent.horizontalCenter
                Clock { tokens: tokens }
            }

            Item { width: 1; height: 64 }

            Kindle {
                tokens: tokens
                lit: root.lit
                index: 2
                anchors.horizontalCenter: parent.horizontalCenter
                Text {
                    id: nameText
                    text: users.displayName
                    font.family: tokens.fontFamily
                    font.pixelSize: 17
                    font.weight: 560
                    font.letterSpacing: -0.005 * 17
                    color: tokens.text
                    // A short fade when another user is picked.
                    onTextChanged: if (root.lit) nameIn.restart()
                    NumberAnimation on opacity { id: nameIn; running: false; from: 0; to: 1; duration: 300; easing.type: Easing.OutCubic }
                }
            }

            Item { width: 1; height: 12; visible: users.count > 1 }

            Kindle {
                tokens: tokens
                lit: root.lit
                index: 3
                visible: users.count > 1
                anchors.horizontalCenter: parent.horizontalCenter
                UserDots {
                    id: users
                    tokens: tokens
                    model: userModel
                    currentIndex: root.userIndex
                    onPicked: index => root.userIndex = index
                }
            }

            Item { width: 1; height: 26 }

            Kindle {
                tokens: tokens
                lit: root.lit
                index: 4
                anchors.horizontalCenter: parent.horizontalCenter
                PasswordIsland {
                    id: field
                    tokens: tokens
                    caps: root.capsLock
                    onAccepted: root.login()
                    onStepUser: delta => root.userIndex = (root.userIndex + delta + users.count) % Math.max(1, users.count)
                }
            }

            Item { width: 1; height: 16 }

            Kindle {
                tokens: tokens
                lit: root.lit
                index: 5
                anchors.horizontalCenter: parent.horizontalCenter
                Text {
                    height: 18
                    text: root.status
                    font.family: tokens.fontFamily
                    font.pixelSize: 13
                    font.letterSpacing: 0.065
                    color: field.failed ? tokens.red : tokens.muted
                    Behavior on color { ColorAnimation { duration: 250 } }
                }
            }
        }
    }
}
