import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import "../core"

// Fullscreen lock-surface content: blurred wallpaper, clock, avatar,
// password pill. Purely presentational — PAM state comes in via
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
        color: Theme.background
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
        spacing: 26

        // Intro: fade + rise (Translate, not y — y fights centerIn)
        opacity: 0
        transform: Translate { id: rise; y: 24 }
        Component.onCompleted: intro.start()
        ParallelAnimation {
            id: intro
            NumberAnimation { target: content; property: "opacity"; to: 1; duration: 500; easing.type: Easing.OutCubic }
            NumberAnimation { target: rise; property: "y"; to: 0; duration: 600; easing.type: Easing.OutCubic }
        }

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 4

            Text {
                font.family: Theme.fontFamily;
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatTime(clock.date, Settings.conf.shell.clock12h ? "h:mm ap" : "HH:mm")
                color: Theme.text
                font.pixelSize: 96
                font.bold: true
            }
            Text {
                font.family: Theme.fontFamily;
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDate(clock.date, "dddd, d MMMM")
                color: Theme.subtext0
                font.pixelSize: 17
            }
        }

        Item { width: 1; height: 10 } // breathing room before the auth block

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 84; height: 84; radius: 42
            color: Theme.surface
            border.width: 2
            border.color: root.failed ? Theme.red : Theme.primary
            Behavior on border.color { ColorAnimation { duration: 300 } }

            Text {
                font.family: Theme.fontFamily;
                anchors.centerIn: parent
                text: (Quickshell.env("USER") || "?").charAt(0).toUpperCase()
                color: Theme.primary
                font.pixelSize: 36
                font.bold: true
            }
        }

        Text {
            font.family: Theme.fontFamily;
            anchors.horizontalCenter: parent.horizontalCenter
            text: Quickshell.env("USER") || ""
            color: Theme.text
            font.pixelSize: 16
            font.bold: true
        }

        // ── Password pill ──
        Rectangle {
            id: pill
            anchors.horizontalCenter: parent.horizontalCenter
            width: 300; height: 52; radius: 26
            color: Theme.surface
            border.width: 2
            border.color: root.failed ? Theme.red
                : (passInput.activeFocus ? Theme.primary : Theme.outline)
            Behavior on border.color { ColorAnimation { duration: 200 } }
            transform: Translate { id: shakeShift }

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
                color: root.authenticating ? Theme.primary : Theme.subtext0
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
                color: Theme.text
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
                    color: Theme.subtext0
                    font.pixelSize: 14
                }
            }

            Rectangle {
                id: submitBtn
                anchors.right: parent.right
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                width: 40; height: 40; radius: 20
                color: submitMouse.containsMouse ? Theme.primary : Theme.surface0
                scale: submitMouse.pressed ? 0.9 : 1
                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easeSpring } }

                Text {
                    anchors.centerIn: parent
                    text: "󰄾"
                    font.family: Theme.fontIcon
                    font.pixelSize: 16
                    color: submitMouse.containsMouse ? Theme.colorOnPrimary : Theme.text
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
            color: root.failed ? Theme.red : Theme.subtext0
            font.pixelSize: 13
            opacity: text.length > 0 ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }
    }
}
