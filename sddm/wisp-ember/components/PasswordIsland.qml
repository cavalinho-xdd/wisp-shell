import QtQuick
import QtQuick.Effects

// The password field: a lit island whose light rises as you type. Bullets pop
// in, a thin ember caret, a Caps chip, and a submit button that lights once
// there is something to send. A wrong password turns the light red.
Item {
    id: field

    required property var tokens
    property alias text: input.text
    property bool caps: false
    property bool failed: false
    signal accepted()
    // ←/→ while the field is empty pick another user.
    signal stepUser(int delta)
    // Esc: the owner closes what is open, or clears the field.
    signal escapePressed()

    readonly property real heat: Math.min(1, text.length / 10)
    readonly property color light: failed ? tokens.red : tokens.ember

    function shake() {
        shakeAnim.restart();
    }
    function focusInput() {
        input.forceActiveFocus();
    }

    implicitWidth: 340
    implicitHeight: 54
    transform: Translate { id: nudge }

    Surface {
        anchors.fill: parent
        tokens: field.tokens
        radius: field.tokens.radiusField
        fill: Qt.tint(field.tokens.smoke, Qt.alpha(field.light, 0.04 + field.heat * 0.04))
        glowColor: field.light
        glowBlur: 18 + field.heat * 22
        glowAlpha: 0.18 + field.heat * 0.2
        ambientY: 14
        ambientBlur: 36
        ambientAlpha: 0.45
        Behavior on glowBlur { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
        Behavior on glowAlpha { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
    }

    // The real input is invisible: the bullets and caret are drawn below.
    TextInput {
        id: input
        width: 0
        height: 0
        opacity: 0
        echoMode: TextInput.Password
        passwordMaskDelay: 0
        Accessible.name: "Heslo"
        Accessible.role: Accessible.EditableText
        Component.onCompleted: forceActiveFocus()
        // Keep focus pinned so typing always lands here (as LockContent).
        onActiveFocusChanged: if (!activeFocus) forceActiveFocus()
        onAccepted: field.accepted()
        onTextChanged: if (text.length > 0) field.failed = false
        Keys.onEscapePressed: field.escapePressed()
        Keys.onLeftPressed: event => {
            if (text.length === 0) field.stepUser(-1);
            else event.accepted = false;
        }
        Keys.onRightPressed: event => {
            if (text.length === 0) field.stepUser(1);
            else event.accepted = false;
        }
    }

    Text {
        x: 32
        anchors.verticalCenter: parent.verticalCenter
        text: "Heslo"
        font.family: field.tokens.fontFamily
        font.pixelSize: 15
        color: field.tokens.muted
        opacity: input.text.length === 0 ? 1 : 0
        transform: Translate { x: input.text.length === 0 ? 0 : 6; Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } } }
        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    }

    Row {
        id: bullets
        x: 22
        anchors.verticalCenter: parent.verticalCenter
        width: capsChip.x - x - 8
        clip: true
        spacing: 7

        Repeater {
            // shortcut: long passwords run past the chip and are clipped, like the mock.
            model: input.text.length
            Rectangle {
                id: bullet
                width: 7
                height: 7
                radius: 3.5
                anchors.verticalCenter: parent.verticalCenter
                color: field.tokens.text
                scale: 1
                Component.onCompleted: if (!field.tokens.reduceMotion) popIn.start()
                ParallelAnimation {
                    id: popIn
                    NumberAnimation { target: bullet; property: "scale"; from: 0.2; to: 1; duration: 380; easing.type: Easing.OutBack; easing.overshoot: 2 }
                    NumberAnimation { target: bullet; property: "opacity"; from: 0; to: 1; duration: 200 }
                }
            }
        }

        Rectangle {
            width: 1.5
            height: 18
            radius: 1
            anchors.verticalCenter: parent.verticalCenter
            color: field.light
            SequentialAnimation on opacity {
                running: !field.tokens.reduceMotion
                loops: Animation.Infinite
                PropertyAction { value: 1 }
                PauseAnimation { duration: 600 }
                PropertyAction { value: 0 }
                PauseAnimation { duration: 500 }
            }
        }
    }

    Rectangle {
        id: capsChip
        anchors.right: go.left
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        width: capsRow.implicitWidth + 16
        height: 24
        radius: 12
        color: Qt.alpha(field.light, 0.12)
        opacity: field.caps ? 1 : 0
        scale: field.caps ? 1 : 0.9
        Behavior on opacity { NumberAnimation { duration: 200 } }
        Behavior on scale { SpringAnimation { spring: 4; damping: 0.35; epsilon: 0.005 } }
        Accessible.name: "Caps Lock zapnutý"

        Row {
            id: capsRow
            anchors.centerIn: parent
            spacing: 5
            Icon {
                anchors.verticalCenter: parent.verticalCenter
                size: 12
                color: field.light
                path: "m12 4-7 8h4v6h6v-6h4z"
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Caps"
                font.family: field.tokens.fontFamily
                font.pixelSize: 12
                font.weight: Font.DemiBold
                font.letterSpacing: 0.23
                color: field.light
            }
        }
    }

    Item {
        id: go
        readonly property bool ready: input.text.length > 0
        anchors.right: parent.right
        anchors.rightMargin: 7
        anchors.verticalCenter: parent.verticalCenter
        width: 40
        height: 40
        scale: goHit.pressed ? 0.88 : 1
        Behavior on scale { SpringAnimation { spring: 5; damping: 0.4; epsilon: 0.005 } }
        Accessible.role: Accessible.Button
        Accessible.name: "Přihlásit"

        RectangularShadow {
            anchors.fill: goBody
            radius: 20
            blur: field.tokens.glow * 16
            color: Qt.alpha(field.light, 0.55)
            opacity: go.ready ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 300 } }
        }
        Rectangle {
            id: goBody
            anchors.fill: parent
            radius: 20
            color: go.ready ? field.light : field.tokens.ash
            Behavior on color { ColorAnimation { duration: 200; easing.type: Easing.OutCubic } }
        }
        Icon {
            anchors.centerIn: parent
            color: go.ready ? field.tokens.smoke : field.tokens.muted
            path: "M5 12h14M13 6l6 6-6 6"
        }
        MouseArea {
            id: goHit
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: field.accepted()
        }
    }

    SequentialAnimation {
        id: shakeAnim
        NumberAnimation { target: nudge; property: "x"; to: field.tokens.reduceMotion ? 0 : -10; duration: 63; easing.type: Easing.OutCubic }
        NumberAnimation { target: nudge; property: "x"; to: field.tokens.reduceMotion ? 0 : 8; duration: 84; easing.type: Easing.InOutCubic }
        NumberAnimation { target: nudge; property: "x"; to: field.tokens.reduceMotion ? 0 : -5; duration: 84; easing.type: Easing.InOutCubic }
        NumberAnimation { target: nudge; property: "x"; to: field.tokens.reduceMotion ? 0 : 2; duration: 84; easing.type: Easing.InOutCubic }
        NumberAnimation { target: nudge; property: "x"; to: 0; duration: 105; easing.type: Easing.OutCubic }
    }
}
