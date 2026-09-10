//@ pragma UseQApplication
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "core"
import "components"

// First-run setup wizard (6th entry point): `qs -p welcome.qml`.
// Launched automatically once by core/FirstRun.qml the first time wisp starts
// on a machine, and on demand from Settings → Advanced → "Show welcome again".
//
// Shape borrowed from iNiR's welcome.qml (5-step wizard on a fullscreen
// layer-shell overlay with a blurred-wallpaper scrim and exclusive keyboard
// focus) rather than ii-dots' (one long scrolling ApplicationWindow of settings
// sections). The wizard reads as an event rather than as "the settings app
// again", which is the whole point of a first-run flow — and wisp already owns
// every piece it needs: lock.qml's blurred-wallpaper backdrop, launcher.qml's
// exclusive-focus overlay, and the settings app's Cfg* controls, which are
// reused verbatim here so a setting can never drift between the two surfaces.
ShellRoot {
    id: root

    property int step: 0
    readonly property var steps: [
        { icon: "󰄛", title: "Welcome" },
        { icon: "󰸌", title: "Appearance" },
        { icon: "󰸉", title: "Wallpaper" },
        { icon: "󰍜", title: "SDDM Theme" },
        { icon: "󰍜", title: "Shell" },
        { icon: "󰄬", title: "Ready" }
    ]
    readonly property bool lastStep: step === steps.length - 1

    // Staggered entry (scrim, then card) — the same gate pattern iNiR uses, so
    // the card doesn't pop in against an already-opaque background.
    property bool scrimReady: false
    property bool cardReady: false
    property bool closing: false

    Component.onCompleted: entryTimer.start()
    Timer { id: entryTimer; interval: 60; onTriggered: { root.scrimReady = true; cardTimer.start() } }
    Timer { id: cardTimer; interval: 140; onTriggered: root.cardReady = true }

    // Both "Finish" and "Skip setup" mark the wizard seen — a user who skipped
    // it chose not to be asked again, same as one who finished. Getting it back
    // is a button on the Advanced settings page, not a re-prompt on next boot.
    function finish() {
        if (root.closing) return;
        root.closing = true;
        FirstRun.markSeen();
        root.cardReady = false;
        root.scrimReady = false;
        exitTimer.start();
    }
    // Outlasts the exit animation below; Settings.flush() in markSeen() is
    // synchronous, so nothing is racing the quit here.
    Timer { id: exitTimer; interval: 320; onTriggered: Qt.quit() }

    function next() {
        if (root.lastStep) root.finish();
        else root.step++;
    }
    function back() {
        if (root.step > 0) root.step--;
    }

    // Land on whichever monitor the user is actually looking at. Without an
    // explicit `screen:` a PanelWindow goes to Quickshell's first screen, which
    // on this two-monitor host put the entire setup flow on the *secondary*
    // display (caught live — the wizard was on DP-2 while DP-1 had focus). A
    // modal, keyboard-grabbing surface appearing on a screen you aren't looking
    // at is the worst version of the App Launcher's already-documented
    // wrong-monitor caveat, so it's resolved properly here rather than
    // inherited. Null (no Hyprland monitor match) falls back to the default.
    readonly property var targetScreen: {
        const name = Hyprland.focusedMonitor?.name ?? "";
        const match = Quickshell.screens.filter(s => s.name === name);
        return match.length > 0 ? match[0] : null;
    }

    PanelWindow {
        id: win
        screen: root.targetScreen
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "wisp-welcome"
        // Exclusive: this is a modal setup flow, and Escape/arrow keys have to
        // reach it rather than whatever happened to be focused underneath.
        // Released while closing so focus returns cleanly as the surface fades.
        WlrLayershell.keyboardFocus: root.closing ? WlrKeyboardFocus.None : WlrKeyboardFocus.Exclusive
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"

        // ── Backdrop: blurred wallpaper + dim ──
        // Same source chain and MultiEffect treatment as components/LockContent.qml.
        Item {
            id: scrim
            anchors.fill: parent
            opacity: root.scrimReady ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

            property string iiWallpaper: ""
            FileView {
                path: Quickshell.env("HOME") + "/.local/state/quickshell/user/generated/wallpaper/path.txt"
                onLoaded: scrim.iiWallpaper = text().trim()
            }
            readonly property string wallpaperPath: {
                const p = Theme.dynWallpaper || Settings.conf.colors.lastWallpaper || iiWallpaper;
                return p ? "file://" + p.replace("file://", "") : "";
            }

            Rectangle { anchors.fill: parent; color: Theme.background }
            Image {
                id: wp
                anchors.fill: parent
                source: scrim.wallpaperPath
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
            Rectangle { anchors.fill: parent; color: Qt.rgba(0, 0, 0, 0.55) }
        }

        // ── Card ──
        Rectangle {
            id: card
            anchors.centerIn: parent
            width: 780
            height: 580
            radius: 28
            color: Theme.background
            // No border. The card already separates from the blurred wallpaper
            // behind it by fill + the 0.55 scrim; a 1px outline on top of that
            // is the "grey box around every card" tell and buys nothing here.
            // Everything inside separates by tonal step instead (background →
            // surface is a +9.4 L* shift, well past the 3–5% the separation
            // ladder asks for). See DESIGN.md finding A1.
            clip: true

            opacity: root.cardReady ? 1 : 0
            scale: root.cardReady ? 1 : 0.94
            Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
            Behavior on scale {
                NumberAnimation { duration: 420; easing.type: Easing.OutBack; easing.overshoot: 1.1 }
            }

            // Keyboard: Escape skips, arrows/Enter drive the wizard. Focus is
            // asserted from Component.onCompleted (not a property handler) —
            // per plan.md's polkit lesson, a handler firing during component
            // init runs before the window is mapped and the focus is lost.
            focus: true
            Component.onCompleted: forceActiveFocus()
            Keys.onEscapePressed: root.finish()
            Keys.onRightPressed: root.next()
            Keys.onLeftPressed: root.back()
            Keys.onReturnPressed: root.next()
            Keys.onEnterPressed: root.next()

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 28
                spacing: 16

                // ── Header: step pips + title ──
                ColumnLayout {
                    // preferredWidth, not fillWidth — fillWidth is silently
                    // ignored on a ColumnLayout nested in a ColumnLayout, which
                    // left this header collapsed to the width of the pip row and
                    // flush left. See the long note in WelcomeStepIntro.qml.
                    Layout.preferredWidth: parent.width
                    spacing: 10

                    Row {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 8
                        Repeater {
                            model: root.steps.length
                            delegate: Rectangle {
                                required property int index
                                readonly property bool done: index < root.step
                                readonly property bool active: index === root.step
                                anchors.verticalCenter: parent.verticalCenter
                                width: active ? 28 : 8
                                height: 8
                                radius: 4
                                color: active ? Theme.primary : (done ? Theme.subtext0 : Theme.surface0)
                                Behavior on width { NumberAnimation { duration: Theme.animSlow; easing.type: Theme.easeSpring } }
                                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                            }
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        font.family: Theme.fontFamily
                        text: "Step " + (root.step + 1) + " of " + root.steps.length
                        font.pixelSize: 11
                        color: Theme.subtext0
                    }
                }

                // ── Step content ──
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    StackLayout {
                        id: stepStack
                        anchors.fill: parent
                        currentIndex: root.step

                        // Direction-aware slide+fade, same language as the
                        // dashboard's tab crossfade (x offset by travel direction).
                        property int prev: 0
                        onCurrentIndexChanged: {
                            stepShift.x = currentIndex > prev ? 36 : -36;
                            prev = currentIndex;
                            stepIn.restart();
                        }
                        transform: Translate { id: stepShift }
                        ParallelAnimation {
                            id: stepIn
                            NumberAnimation { target: stepShift; property: "x"; to: 0; duration: 380; easing.type: Easing.OutQuint }
                            NumberAnimation { target: stepStack; property: "opacity"; from: 0; to: 1; duration: 260 }
                        }

                        WelcomeStepIntro {}
                        WelcomeStepAppearance {}
                        WelcomeStepWallpaper {}
                        WelcomeStepSddm {}
                        WelcomeStepShell {}
                        WelcomeStepReady { onOpenSettings: root.finish() }
                    }
                }

                // ── Footer nav ──
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    ActionButton {
                        visible: !root.lastStep
                        icon: "󰅖"
                        text: "Skip setup"
                        onClicked: root.finish()
                    }

                    Item { Layout.fillWidth: true }

                    ActionButton {
                        visible: root.step > 0
                        icon: "󰁍"
                        text: "Back"
                        onClicked: root.back()
                    }

                    // Primary action — filled, unlike the outlined ActionButtons
                    Rectangle {
                        Layout.preferredWidth: nextRow.implicitWidth + 40
                        Layout.preferredHeight: 40
                        radius: 14
                        color: nextMa.containsMouse ? Qt.lighter(Theme.primary, 1.1) : Theme.primary
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                        scale: nextMa.pressed ? 0.96 : 1.0
                        Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easeSpring } }

                        Row {
                            id: nextRow
                            anchors.centerIn: parent
                            spacing: 8
                            Text {
                                text: root.lastStep ? "󰄬" : "󰁔"
                                font.family: Theme.fontIcon; font.pixelSize: 14
                                color: Theme.colorOnPrimary
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                font.family: Theme.fontFamily
                                text: root.lastStep ? "Finish" : (root.step === 0 ? "Let's go" : "Next")
                                font.pixelSize: 13; font.bold: true
                                color: Theme.colorOnPrimary
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: nextMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.next()
                        }
                    }
                }
            }
        }
    }
}
