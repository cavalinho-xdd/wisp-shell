import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import "../core"
import "ember"

// Fullscreen lock-surface content in Ember: blurred wallpaper, the ember,
// a mono clock and the password field as a lit island. Purely presentational — PAM state comes in via
// properties, the typed password leaves via submit(). Instantiated once
// per screen by WlSessionLock, so no per-screen state may live here
// beyond the input field itself.
Item {
    id: root

    property bool authenticating: false
    property bool failed: false
    property string statusText: ""
    property bool canSubmit: true

    signal submit(string password)

    onFailedChanged: if (failed) { passInput.text = ""; shake.restart(); }

    function trySubmit() {
        if (passInput.text.length === 0 || root.authenticating || !root.canSubmit)
            return;
        root.submit(passInput.text);
        passInput.text = "";
    }

    // Wallpaper source chain, same as apply_colors.sh: palette wallpaper
    // from colors.json → settings' lastWallpaper → ii's state file
    // (read-only fallback on this machine, wallpapers are set by ii)
    property string iiWallpaper: ""
    FileView {
        path: Quickshell.env("HOME") + "/.local/state/quickshell/user/generated/wallpaper/path.txt"
        onLoaded: root.iiWallpaper = text().trim()
    }
    readonly property string wallpaperPath: {
        const p = Theme.dynWallpaper || Settings.conf.colors.lastWallpaper || iiWallpaper;
        return p ? "file://" + p.replace("file://", "") : "";
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // ── Background: blurred wallpaper + darken so the type carries ──
    Rectangle {
        anchors.fill: parent
        color: Theme.smoke
    }
    Image {
        id: wp
        anchors.fill: parent
        source: root.wallpaperPath
        fillMode: Image.PreserveAspectCrop
        visible: false
        asynchronous: true
    }
    MultiEffect {
        anchors.fill: wp
        source: wp
        visible: wp.status === Image.Ready
        blurEnabled: true
        blur: 1.0
        blurMax: 64
    }
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.45)
    }

    // ── Center column ──
    Column {
        id: content
        anchors.centerIn: parent
        spacing: Theme.spaceLg

        // Intro: kindles in (Translate, not y — y fights centerIn)
        opacity: 0
        transform: Translate { id: rise; y: Theme.kindleShift * 4 }
        Component.onCompleted: intro.start()
        ParallelAnimation {
            id: intro
            NumberAnimation { target: content; property: "opacity"; to: 1; duration: Theme.motionKindle; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curveKindle }
            NumberAnimation { target: rise; property: "y"; to: 0; duration: Theme.motionKindle; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curveKindle }
        }

        EmberDot {
            anchors.horizontalCenter: parent.horizontalCenter
            width: Theme.emberSize * 2
            height: Theme.emberSize * 2
        }

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 4

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatTime(clock.date, Settings.conf.shell.clock12h ? "h:mm ap" : "HH:mm")
                color: Theme.islandText
                font.family: Theme.fontMono
                font.pixelSize: 96
                font.weight: Font.Light
            }
            Text {
                font.family: Theme.fontFamily;
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDate(clock.date, "dddd, d MMMM")
                color: Theme.islandMuted
                font.pixelSize: Theme.textTitle
            }
        }

        Item { width: 1; height: Theme.spaceLg } // breathing room before the auth block

        Text {
            font.family: Theme.fontFamily;
            anchors.horizontalCenter: parent.horizontalCenter
            text: Quickshell.env("USER") || ""
            color: Theme.islandText
            font.pixelSize: Theme.textBody
            font.weight: Font.Medium
        }

        // ── Password island ──
        // Lit by the ember while typing, by red after a failure. No outline.
        Item {
            id: pill
            anchors.horizontalCenter: parent.horizontalCenter
            width: 300; height: Theme.controlSizeBig + Theme.spaceXs
            transform: Translate { id: shakeShift }
            readonly property color light: root.failed ? Theme.red : Theme.ember

            RectangularShadow {
                anchors.fill: parent
                radius: height / 2
                blur: Theme.glowBlur * Theme.glow
                color: Qt.alpha(pill.light, Theme.glowAlphaOpen * Theme.glow * (passInput.text.length > 0 || root.failed ? 1.6 : 1))
                Behavior on color { ColorAnimation { duration: Theme.motionFast } }
            }
            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: Qt.tint(Theme.smoke, Qt.alpha(pill.light, Theme.litFill))
                Behavior on color { ColorAnimation { duration: Theme.motionFast } }
            }

            SequentialAnimation {
                id: shake
                NumberAnimation { target: shakeShift; property: "x"; to: -12; duration: 50 }
                NumberAnimation { target: shakeShift; property: "x"; to: 10; duration: 50 }
                NumberAnimation { target: shakeShift; property: "x"; to: -6; duration: 50 }
                NumberAnimation { target: shakeShift; property: "x"; to: 4; duration: 50 }
                NumberAnimation { target: shakeShift; property: "x"; to: 0; duration: 50 }
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 20
                anchors.verticalCenter: parent.verticalCenter
                text: root.authenticating ? "󰦖" : "󰌾"
                font.family: Theme.fontIcon
                font.pixelSize: 16
                color: root.authenticating ? Theme.ember : Theme.islandMuted
            }

            TextInput {
                font.family: Theme.fontFamily;
                id: passInput
                anchors.left: parent.left
                anchors.right: submitBtn.left
                anchors.leftMargin: 46
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                echoMode: TextInput.Password
                passwordCharacter: "●"
                color: Theme.islandText
                font.pixelSize: 15
                clip: true
                enabled: !root.authenticating
                onAccepted: root.trySubmit()
                Keys.onEscapePressed: text = ""

                // Session-lock surface owns the keyboard exclusively —
                // keep focus pinned so typing always lands here
                Component.onCompleted: forceActiveFocus()
                onActiveFocusChanged: if (!activeFocus) forceActiveFocus()

                Text {
                    font.family: Theme.fontFamily;
                    anchors.verticalCenter: parent.verticalCenter
                    visible: passInput.text.length === 0 && !root.authenticating
                    text: "Enter password"
                    color: Theme.islandMuted
                    font.pixelSize: 14
                }
            }

            Rectangle {
                id: submitBtn
                anchors.right: parent.right
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                width: Theme.controlSize; height: width; radius: width / 2
                color: submitMouse.containsMouse ? Theme.ember : Theme.ash
                scale: submitMouse.pressed ? 0.9 : 1
                Behavior on color { ColorAnimation { duration: Theme.motionFast } }
                Behavior on scale { NumberAnimation { duration: Theme.motionFast; easing.type: Easing.OutCubic } }

                Text {
                    anchors.centerIn: parent
                    text: "󰄾"
                    font.family: Theme.fontIcon
                    font.pixelSize: 16
                    color: submitMouse.containsMouse ? Theme.smoke : Theme.islandText
                }
                MouseArea {
                    id: submitMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.trySubmit()
                }
            }
        }

        Text {
            font.family: Theme.fontFamily;
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.authenticating ? "Authenticating…" : root.statusText
            color: root.failed ? Theme.red : Theme.islandMuted
            font.pixelSize: 13
            opacity: text.length > 0 ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }
    }
}
