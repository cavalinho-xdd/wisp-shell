import QtQuick
import Quickshell
import Quickshell.Widgets
import "../core"

// Presentational polkit auth prompt. Owns no PolkitAgent itself — all state
// arrives via properties and the typed password leaves via submit(), exactly
// like LockContent.qml. That split is what makes it testable in isolation
// (test_polkitui.qml) without needing a real privilege-escalation request,
// which matters a lot here since this host can't even register an agent
// while ii is running (see plan.md).
Item {
    id: root

    // ── Inputs ──
    property string message: ""
    property string actionId: ""
    property string iconName: ""
    property string inputPrompt: ""
    property string supplementaryMessage: ""
    property bool supplementaryIsError: false
    property bool responseRequired: false
    property bool responseVisible: false
    property bool failed: false
    property var identities: []
    property int selectedIdentityIndex: 0

    signal submit(string response)
    signal cancel()
    signal identityPicked(int index)

    onFailedChanged: if (failed) { passInput.text = ""; shake.restart(); }
    // A fresh prompt turn (new request, or a retry after a failure) always
    // starts from an empty field with focus — never leave a stale response
    // sitting in the box across conversation turns.
    onResponseRequiredChanged: {
        passInput.text = "";
        if (responseRequired) passInput.forceActiveFocus();
    }

    function trySubmit() {
        if (!root.responseRequired) return;
        root.submit(passInput.text);
        passInput.text = "";
    }

    // ── Dim backdrop; click outside cancels (same affordance as the pill's
    // click-catcher, and cancelling is always the safe default here) ──
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: 0.55
        MouseArea { anchors.fill: parent; onClicked: root.cancel() }
    }

    // ── Card ──
    Rectangle {
        id: card
        anchors.centerIn: parent
        width: 420
        height: cardCol.implicitHeight + 48
        radius: 26
        color: Theme.panelBackground
        // Border only while failed — that is real state worth outlining. The
        // idle grey outline it used to always wear was decoration (DESIGN.md §16).
        border.color: Theme.red
        border.width: root.failed ? 1 : 0
        Behavior on border.width { NumberAnimation { duration: 250 } }
        Behavior on height { NumberAnimation { duration: 320; easing.type: Easing.OutQuint } }

        // Swallow clicks so the backdrop's cancel doesn't fire through the card
        MouseArea { anchors.fill: parent }

        transform: Translate { id: shakeShift }
        SequentialAnimation {
            id: shake
            NumberAnimation { target: shakeShift; property: "x"; to: -12; duration: 50 }
            NumberAnimation { target: shakeShift; property: "x"; to: 10; duration: 50 }
            NumberAnimation { target: shakeShift; property: "x"; to: -6; duration: 50 }
            NumberAnimation { target: shakeShift; property: "x"; to: 4; duration: 50 }
            NumberAnimation { target: shakeShift; property: "x"; to: 0; duration: 50 }
        }

        // Intro: spring bloom, matching the pill's own grow curve
        opacity: 0
        scale: 0.9
        Component.onCompleted: intro.start()
        ParallelAnimation {
            id: intro
            NumberAnimation { target: card; property: "opacity"; to: 1; duration: 260; easing.type: Easing.OutCubic }
            NumberAnimation { target: card; property: "scale"; to: 1; duration: 460; easing.type: Easing.OutBack; easing.overshoot: 1.15 }
        }

        Column {
            id: cardCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: 24
            spacing: 16

            // Shield badge — breathes while waiting for input, so a prompt
            // sitting idle still reads as live rather than frozen
            Rectangle {
                id: badge
                anchors.horizontalCenter: parent.horizontalCenter
                width: 56; height: 56; radius: 28
                color: Theme.surface0
                border.width: 2
                border.color: root.failed ? Theme.red : Theme.primary
                Behavior on border.color { ColorAnimation { duration: 250 } }

                SequentialAnimation {
                    running: root.responseRequired && !root.failed
                    loops: Animation.Infinite
                    NumberAnimation { target: badge; property: "border.width"; to: 3; duration: 1100; easing.type: Easing.InOutSine }
                    NumberAnimation { target: badge; property: "border.width"; to: 2; duration: 1100; easing.type: Easing.InOutSine }
                    onStopped: badge.border.width = 2
                }

                // Prefer the requesting action's own icon; fall back to a
                // shield glyph when polkit gives no iconName (common).
                IconImage {
                    anchors.centerIn: parent
                    width: 26; height: 26
                    visible: root.iconName.length > 0 && status === Image.Ready
                    source: root.iconName.length > 0 ? Quickshell.iconPath(root.iconName, true) : ""
                }
                Text {
                    anchors.centerIn: parent
                    visible: root.iconName.length === 0
                    text: "󰒃"
                    font.family: Theme.fontIcon
                    font.pixelSize: 24
                    color: root.failed ? Theme.red : Theme.primary
                    Behavior on color { ColorAnimation { duration: 250 } }
                }
            }

            Text {
                font.family: Theme.fontFamily;
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: "Authentication Required"
                color: Theme.text
                font.pixelSize: 17
                font.bold: true
            }

            Text {
                font.family: Theme.fontFamily;
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: root.message
                color: Theme.subtext0
                font.pixelSize: 13
                wrapMode: Text.Wrap
                // Polkit messages are attacker-influencable in the sense that
                // any app can trigger a request — never let markup through.
                textFormat: Text.PlainText
                visible: text.length > 0
            }

            // The machine-readable action id, deliberately shown: it is the
            // only part of this prompt an application can't dress up, so it's
            // what actually tells the user WHAT they're authorizing.
            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: root.actionId
                color: Theme.subtext0
                font.pixelSize: 10
                font.family: Theme.fontIcon
                opacity: 0.65
                elide: Text.ElideMiddle
                textFormat: Text.PlainText
                visible: text.length > 0
            }

            // Identity chips — only when there's an actual choice to make
            Flow {
                width: parent.width
                spacing: 8
                visible: root.identities.length > 1
                Repeater {
                    model: root.identities.length
                    delegate: Rectangle {
                        required property int index
                        readonly property bool isSel: index === root.selectedIdentityIndex
                        height: 28
                        width: idLabel.implicitWidth + 24
                        radius: 14
                        color: isSel ? Theme.primary : Theme.surface0
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                        scale: idMa.pressed ? 0.94 : (idMa.containsMouse ? 1.05 : 1.0)
                        Behavior on scale { NumberAnimation { duration: 260; easing.type: Theme.easeSpring; easing.overshoot: 1.6 } }

                        Text {
                            font.family: Theme.fontFamily;
                            id: idLabel
                            anchors.centerIn: parent
                            text: root.identities[parent.index] ? (root.identities[parent.index].displayName || root.identities[parent.index].string) : ""
                            color: parent.isSel ? Theme.colorOnPrimary : Theme.text
                            font.pixelSize: 11
                            textFormat: Text.PlainText
                            Behavior on color { ColorAnimation { duration: Theme.animFast } }
                        }
                        MouseArea {
                            id: idMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.identityPicked(parent.index)
                        }
                    }
                }
            }

            // ── Password pill (same shape as the lock screen's) ──
            Rectangle {
                id: pill
                width: parent.width
                height: 50
                radius: 25
                color: Theme.surface
                border.width: 2
                border.color: root.failed ? Theme.red
                    : (passInput.activeFocus ? Theme.primary : Theme.outline)
                Behavior on border.color { ColorAnimation { duration: 200 } }
                opacity: root.responseRequired ? 1 : 0.5
                Behavior on opacity { NumberAnimation { duration: 200 } }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 20
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰌾"
                    font.family: Theme.fontIcon
                    font.pixelSize: 15
                    color: Theme.subtext0
                }

                TextInput {
                    font.family: Theme.fontFamily;
                    id: passInput
                    anchors.left: parent.left
                    anchors.right: submitBtn.left
                    anchors.leftMargin: 46
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    // Polkit tells us per-turn whether the response should be
                    // visible (it isn't always a password — could be an OTP
                    // prompt that echoes), so this must not be hardcoded.
                    echoMode: root.responseVisible ? TextInput.Normal : TextInput.Password
                    passwordCharacter: "●"
                    color: Theme.text
                    font.pixelSize: 15
                    clip: true
                    enabled: root.responseRequired
                    onAccepted: root.trySubmit()
                    Keys.onEscapePressed: root.cancel()

                    // Focus must be claimed on construction, not only from
                    // onResponseRequiredChanged: when responseRequired arrives
                    // as an initial property binding, that signal fires during
                    // component init, before the window is mapped, and the
                    // forceActiveFocus() there is silently lost. Observed as
                    // nondeterministic "typing does nothing" in the isolation
                    // probe. Re-asserting on focus loss matches what
                    // LockContent.qml already does for the same reason — this
                    // window holds the keyboard exclusively, so there is
                    // nothing else here that should ever hold focus.
                    Component.onCompleted: forceActiveFocus()
                    onActiveFocusChanged: if (!activeFocus && root.responseRequired) forceActiveFocus()

                    Text {
                        font.family: Theme.fontFamily;
                        anchors.verticalCenter: parent.verticalCenter
                        visible: passInput.text.length === 0
                        text: root.inputPrompt || "Password"
                        color: Theme.subtext0
                        font.pixelSize: 14
                        textFormat: Text.PlainText
                        elide: Text.ElideRight
                        width: passInput.width
                    }
                }

                Rectangle {
                    id: submitBtn
                    anchors.right: parent.right
                    anchors.rightMargin: 5
                    anchors.verticalCenter: parent.verticalCenter
                    width: 40; height: 40; radius: 20
                    color: submitMa.containsMouse ? Theme.primary : Theme.surface0
                    scale: submitMa.pressed ? 0.9 : 1
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easeSpring } }

                    Text {
                        anchors.centerIn: parent
                        text: "󰄾"
                        font.family: Theme.fontIcon
                        font.pixelSize: 16
                        color: submitMa.containsMouse ? Theme.colorOnPrimary : Theme.text
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    }
                    MouseArea {
                        id: submitMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.trySubmit()
                    }
                }
            }

            // Status line: polkit's supplementary message, or our own failure text
            Text {
                font.family: Theme.fontFamily;
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: root.supplementaryMessage || (root.failed ? "Authentication failed — try again" : "")
                color: (root.supplementaryIsError || root.failed) ? Theme.red : Theme.subtext0
                font.pixelSize: 12
                wrapMode: Text.Wrap
                textFormat: Text.PlainText
                opacity: text.length > 0 ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: cancelLabel.implicitWidth + 40
                height: 34
                radius: 17
                color: cancelMa.containsMouse ? Theme.surface0 : Theme.surface
                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                scale: cancelMa.pressed ? 0.95 : 1
                Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easeSpring } }

                Text {
                    font.family: Theme.fontFamily;
                    id: cancelLabel
                    anchors.centerIn: parent
                    text: "Cancel"
                    color: Theme.subtext0
                    font.pixelSize: 12
                }
                MouseArea {
                    id: cancelMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.cancel()
                }
            }
        }
    }
}
