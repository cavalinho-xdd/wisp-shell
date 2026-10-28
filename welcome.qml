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
import "components/ember"

// First-run setup wizard (6th entry point): `qs -p welcome.qml`.
// Launched automatically once by core/FirstRun.qml the first time wisp starts
// on a machine, and on demand from Settings → Advanced → "Show welcome again".
//
// Shape borrowed from iNiR's welcome.qml (5-step wizard on a fullscreen
// layer-shell overlay with a blurred-wallpaper scrim and exclusive keyboard
// focus) rather than ii-dots' (one long scrolling ApplicationWindow of settings
// sections). The wizard reads as an event rather than as "the settings app
// again", which is the whole point of a first-run flow — and wisp already owns
// every piece it needs: lock.qml's blurred-wallpaper backdrop, an
// exclusive-focus overlay, and the settings app's Cfg* controls, which are
// reused verbatim here so a setting can never drift between the two surfaces.
// Drawn as an open Ember island: smoke card, ember-lit, workspace-dot steps.
ShellRoot {
    id: root

    property int step: 0
    readonly property var steps: ["Welcome", "Colour", "Wallpaper", "Islands", "Tour", "Login screen", "Ready"]
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

    // Current wallpaper, for the scrim and the island previews in the steps.
    property string iiWallpaper: ""
    FileView {
        path: Quickshell.env("HOME") + "/.local/state/quickshell/user/generated/wallpaper/path.txt"
        onLoaded: root.iiWallpaper = text().trim()
    }
    readonly property string wallpaper: {
        const p = Theme.dynWallpaper || Settings.conf.colors.lastWallpaper || iiWallpaper;
        return p ? "file://" + p.replace("file://", "") : "";
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

            Rectangle { anchors.fill: parent; color: Theme.smoke }
            Image {
                id: wp
                anchors.fill: parent
                source: root.wallpaper
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
        // An open island: one real shadow under it, the ember's glow round
        // it, a crescent of light on the top edge and the ember lighting it
        // from the step dots. No outline.
        Item {
            id: card
            anchors.centerIn: parent
            width: 820
            height: 640

            opacity: root.cardReady ? 1 : 0
            scale: root.cardReady ? 1 : Theme.kindleScale
            Behavior on opacity { NumberAnimation { duration: Theme.motionKindle; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curveKindle } }
            Behavior on scale { SpringAnimation { spring: Theme.springMorph; damping: Theme.dampingMorph } }

            RectangularShadow {
                anchors.fill: parent
                anchors.topMargin: Theme.cardShadowOffset
                radius: Theme.radiusIslandOpen
                blur: Theme.cardShadowBlur
                color: Theme.cardShadow
            }
            RectangularShadow {
                anchors.fill: parent
                radius: Theme.radiusIslandOpen
                blur: Theme.glowBlurOpen * Theme.glow
                color: Qt.alpha(Theme.ember, Theme.glowAlphaOpen * Theme.glow)
            }
            EmberSurface {
                anchors.fill: parent
                radius: Theme.radiusIslandOpen
                base: Theme.islandFillOpen
                topLight: true
                edge: Theme.edgeLightOpen
                lit: true
                lightX: width / 2
                lightY: Theme.spaceLg
                lightRadius: width * 0.5
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
                anchors.margins: Theme.radiusIslandOpen
                spacing: Theme.spaceMd

                // ── Header: step dots + title ──
                // The dots are the workspaces island's: the current step
                // stretched and glowing, done steps lit dimly.
                ColumnLayout {
                    // preferredWidth, not fillWidth — fillWidth is silently
                    // ignored on a ColumnLayout nested in a ColumnLayout.
                    Layout.preferredWidth: parent.width
                    spacing: Theme.spaceSm

                    Row {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: Theme.workspaceGap
                        Repeater {
                            model: root.steps.length
                            delegate: Item {
                                id: pip
                                required property int index
                                readonly property bool done: index < root.step
                                readonly property bool active: index === root.step
                                width: active ? Theme.workspaceActiveWidth : Theme.workspaceDot
                                height: Theme.workspaceDot
                                Behavior on width { SpringAnimation { spring: Theme.springQuick; damping: Theme.dampingQuick } }

                                RectangularShadow {
                                    anchors.fill: parent
                                    radius: height / 2
                                    blur: Theme.glowBlur * 0.5 * Theme.glow
                                    color: Theme.ember
                                    opacity: pip.active ? 1 : 0
                                    Behavior on opacity { NumberAnimation { duration: Theme.motionFast } }
                                }
                                Rectangle {
                                    anchors.fill: parent
                                    radius: height / 2
                                    color: pip.active ? Theme.ember : (pip.done ? Qt.alpha(Theme.ember, 0.45) : Theme.ashHi)
                                    Behavior on color { ColorAnimation { duration: Theme.motionFast } }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -Theme.spaceXs / 2
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.step = pip.index
                                }
                            }
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.steps[root.step]
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.textTitle
                        font.weight: Font.DemiBold
                        color: Theme.islandText
                        visible: root.step > 0
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
                            stepShift.x = (currentIndex > prev ? 1 : -1) * (Theme.reduceMotion ? 0 : Theme.spaceLg * 2);
                            prev = currentIndex;
                            stepIn.restart();
                        }
                        transform: Translate { id: stepShift }
                        ParallelAnimation {
                            id: stepIn
                            NumberAnimation { target: stepShift; property: "x"; to: 0; duration: Theme.motionKindle; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curveKindle }
                            NumberAnimation { target: stepStack; property: "opacity"; from: 0; to: 1; duration: Theme.motionKindle; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curveKindle }
                        }

                        WelcomeStepIntro {}
                        WelcomeStepAppearance { wallpaper: root.wallpaper }
                        WelcomeStepWallpaper {}
                        WelcomeStepIslands { wallpaper: root.wallpaper }
                        WelcomeStepTour { wallpaper: root.wallpaper }
                        WelcomeStepSddm {}
                        WelcomeStepReady { onOpenSettings: root.finish() }
                    }
                }

                // ── Footer nav ──
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spaceSm

                    // Quiet on purpose: leaving is always possible, never the
                    // thing the card asks you to do.
                    Text {
                        visible: !root.lastStep
                        text: "Skip setup"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.textCaption
                        color: skipMa.containsMouse ? Theme.islandText : Theme.islandMuted
                        Behavior on color { ColorAnimation { duration: Theme.motionFast } }
                        Accessible.role: Accessible.Button
                        Accessible.name: text
                        Accessible.onPressAction: root.finish()
                        MouseArea {
                            id: skipMa
                            anchors.fill: parent
                            anchors.margins: -Theme.spaceXs
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.finish()
                        }
                    }

                    Item { Layout.fillWidth: true }

                    ActionButton {
                        visible: root.step > 0
                        icon: "󰁍"
                        text: "Back"
                        onClicked: root.back()
                    }

                    // Primary action: the ember itself, glowing.
                    Item {
                        id: nextBtn
                        Layout.preferredWidth: nextRow.implicitWidth + 2 * Theme.spaceLg
                        Layout.preferredHeight: Theme.controlSize + Theme.spaceXs / 2
                        scale: nextMa.pressed ? Theme.pressScale : 1
                        Behavior on scale { NumberAnimation { duration: Theme.motionFast; easing.type: Easing.OutCubic } }
                        Accessible.role: Accessible.Button
                        Accessible.name: nextLabel.text
                        Accessible.onPressAction: root.next()

                        RectangularShadow {
                            anchors.fill: parent
                            radius: height / 2
                            blur: Theme.glowBlur * Theme.glow * (nextMa.containsMouse ? 1.4 : 1)
                            color: Qt.alpha(Theme.ember, 0.45)
                            Behavior on blur { NumberAnimation { duration: Theme.motionFast } }
                        }
                        Rectangle {
                            anchors.fill: parent
                            radius: height / 2
                            color: nextMa.containsMouse ? Qt.lighter(Theme.ember, 1.08) : Theme.ember
                            Behavior on color { ColorAnimation { duration: Theme.motionFast } }
                        }
                        Row {
                            id: nextRow
                            anchors.centerIn: parent
                            spacing: Theme.spaceXs
                            Text {
                                id: nextLabel
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.lastStep ? "Finish" : (root.step === 0 ? "Let's go" : "Next")
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.textBody
                                font.weight: Font.DemiBold
                                color: Theme.smoke
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.lastStep ? "󰄬" : "󰁔"
                                font.family: Theme.fontIcon
                                font.pixelSize: Theme.textBody
                                color: Theme.smoke
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
