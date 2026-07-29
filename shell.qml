//@ pragma UseQApplication
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.Polkit
import Quickshell.Networking
import Quickshell.Bluetooth
import "core"
import "components"

ShellRoot {
    // One-time, compositor-global init — must run exactly once regardless of
    // monitor count. Previously lived in floatingPill's Component.onCompleted;
    // moved here when the pill became a per-screen Variants delegate below,
    // since that block now instantiates once per monitor and would otherwise
    // re-inject the same hyprctl layer_rule/keybind N times.
    Component.onCompleted: {
        // Hyprland >= 0.55 uses the lua parser; `hyprctl keyword` is a no-op there.
        // Namespace is an RE2 regex, so anchor it or `wisp-catcher` matches too.
        Quickshell.execDetached(["hyprctl", "eval",
            'hl.layer_rule({ match = { namespace = "^wisp$" }, animation = "fade" })'])
        // Touching the singleton instantiates it; it re-injects saved overrides
        // itself once settings.json finishes loading (see Settings.onLoaded).
        void Settings.ready
        // Same trick for the first-run gate: touching it constructs the
        // singleton, which then waits for Settings.ready before deciding
        // whether to launch welcome.qml (see core/FirstRun.qml).
        void FirstRun.checked
        // Super+Space is bound statically in keybinds.lua (`wisp launcher`,
        // which toggles/dismisses via pgrep) — do NOT also inject a runtime
        // bind here. Hyprland keeps both binds live simultaneously rather
        // than the later one overriding the earlier (verified via
        // `hyprctl binds -j`: two live "Space"/SUPER entries), so having
        // both fired one blind `qs -p launcher.qml` spawn per keypress on
        // top of keybinds.lua's toggle-aware one — two launcher windows
        // stacked on every press. Removed; keybinds.lua's bind is the only
        // one now.
    }

    // ── Polkit authentication agent ──
    // Deliberately NOT inside the per-monitor Variants below: a privilege-
    // escalation prompt is modal and singular. One dialog on the active screen
    // is correct; N dialogs across N monitors would mean N surfaces each
    // demanding exclusive keyboard focus, fighting each other for it.
    // Registers once, at startup, and is never destroyed until the shell exits.
    //
    // Quickshell's PolkitAgent registers exactly once in componentComplete and
    // does NOT retry on failure (verified in
    // ~/coding/quickshell/src/services/polkit/listener.cpp — a single
    // polkit_agent_listener_register call, one warning, done), unlike the
    // notification server which retries itself. Polkit allows only one agent
    // per session, so if something else already holds it at our startup (on
    // this dev host ii always does), wisp has no agent for that session.
    //
    // A retry was implemented for exactly that case — a Loader toggled by a
    // timer, so destroying and rebuilding the object would re-run registration
    // — and it had to be REMOVED: it segfaulted the entire shell. Destroying a
    // PolkitAgent deletes the process-wide PolkitAgentImpl singleton
    // (`onEndOfQmlAgent` -> `delete instance`, agentimpl.cpp), tearing down the
    // GLib/GDBus listener; doing that repeatedly, and especially while the app
    // is shutting down, hits "QEventLoop: Cannot be used without
    // QCoreApplication" and crashes (caught live — SIGSEGV, crash report under
    // ~/.cache/quickshell/crashes). Crashing the whole shell is far worse than
    // not having an agent in a session where another one is already running,
    // and the only situation the retry could recover from (a competing agent
    // exiting mid-session) is rare. Do not reintroduce it without an upstream
    // fix making PolkitAgent teardown safe to repeat.
    PolkitAgent {
        id: polkitAgent
    }

    PanelWindow {
        id: polkitWindow
        visible: polkitAgent.isActive
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "wisp-polkit"
        WlrLayershell.layer: WlrLayer.Overlay
        // A password prompt must own the keyboard outright — with OnDemand,
        // focus could sit elsewhere and the typed password would go to whatever
        // window had it instead of this field.
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        anchors { top: true; bottom: true; left: true; right: true }

        PolkitDialog {
            anchors.fill: parent
            readonly property var flow: polkitAgent.flow

            message: flow?.message ?? ""
            actionId: flow?.actionId ?? ""
            iconName: flow?.iconName ?? ""
            inputPrompt: flow?.inputPrompt ?? ""
            supplementaryMessage: flow?.supplementaryMessage ?? ""
            supplementaryIsError: flow?.supplementaryIsError ?? false
            responseRequired: flow?.isResponseRequired ?? false
            responseVisible: flow?.responseVisible ?? false
            failed: flow?.failed ?? false
            identities: flow?.identities ?? []
            selectedIdentityIndex: {
                if (!flow || !flow.identities) return 0;
                const i = flow.identities.indexOf(flow.selectedIdentity);
                return i < 0 ? 0 : i;
            }

            onSubmit: response => flow?.submit(response)
            onCancel: flow?.cancelAuthenticationRequest()
            onIdentityPicked: index => {
                if (flow && flow.identities[index])
                    flow.selectedIdentity = flow.identities[index];
            }
        }
    }

    // Settings.conf.shell.pillMonitor restricts the whole per-monitor surface
    // group (pill + click-catcher + OSD) to one named output instead of every
    // connected screen — falls back to "all monitors" if the saved name isn't
    // currently connected (e.g. an external monitor unplugged), so a stale
    // setting can never silently zero out every shell surface with no visible
    // way back into Settings.
    readonly property var pillScreens: {
        if (Settings.conf.shell.pillMonitor === "") return Quickshell.screens;
        const match = Quickshell.screens.filter(s => s.name === Settings.conf.shell.pillMonitor);
        return match.length > 0 ? match : Quickshell.screens;
    }

    // One pill + click-catcher pair per connected monitor (Quickshell.screens,
    // filtered by pillScreens above), recreated on hotplug since Variants
    // tracks the model live. Each instance owns fully independent expand/
    // collapse state — media/notification content (core/Island.qml) stays a
    // single global singleton, so the *content* is the same everywhere, only
    // open/closed is per-monitor local.
    Variants {
        model: pillScreens

        delegate: Component {
            QtObject {
                id: screenRoot
                required property var modelData

                property PanelWindow clickCatcher: PanelWindow {
                    screen: screenRoot.modelData
                    anchors {
                        top: true; bottom: true; left: true; right: true
                    }
                    color: "transparent"
                    visible: screenRoot.pill.isExpanded
                    exclusionMode: ExclusionMode.Ignore
                    WlrLayershell.namespace: "wisp-catcher"

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            // Background catcher clicked -> collapse the dashboard.
                            // pop(null) and replace() are both StackView transition-
                            // triggering ops (QQuickStackView, libQt6QuickTemplates2) —
                            // firing both synchronously in the same tick, while a
                            // subview is pushed, raced the first transition's own
                            // setup against the second and reproduced a SIGSEGV in
                            // QQuickTransitionManager::complete()/derefWindow (4/4
                            // crash reports today, ~/.cache/quickshell/crashes/,
                            // identical stacktrace each time). pop(null) is only
                            // meaningful when a subview is actually pushed (depth>1);
                            // deferring the replace to the next tick via Qt.callLater
                            // lets that pop's transition settle before StackView is
                            // asked to do anything else.
                            const stack = screenRoot.pill.contentStackRef;
                            screenRoot.pill.isExpanded = false
                            if (stack.depth > 1) {
                                stack.pop(null) // Pop to root
                                Qt.callLater(() => stack.replace(screenRoot.pill.collapsedViewRef))
                            } else {
                                stack.replace(screenRoot.pill.collapsedViewRef)
                            }
                        }
                    }
                }

                // Volume/mic OSD — its own tiny surface per monitor, deliberately
                // separate from the pill so it never interacts with the pill's
                // collapsed/media/expanded width state machine. Purely reactive
                // (core/Osd.qml watches core/Audio.qml), no keybind wiring needed.
                property PanelWindow osd: PanelWindow {
                    screen: screenRoot.modelData
                    color: "transparent"
                    // Suppressed during fullscreen on THIS monitor — without this, an
                    // OSD popup from adjusting volume mid-video would draw an
                    // input-eating 220x64 dead zone over the fullscreen surface's own
                    // controls (same class of bug the pill's own fullscreenOverride
                    // exists to prevent, see below). Unlike the pill, OSD has no
                    // fade/mask choreography to preserve, so just not mapping the
                    // surface at all is the simplest correct fix — no separate mask
                    // needed. Per-monitor, not Hyprland.focusedWorkspace (compositor-
                    // global — would wrongly suppress OSD on every monitor just
                    // because a DIFFERENT monitor's focused workspace is fullscreen).
                    readonly property var hyprMonitor: Hyprland.monitorFor(screenRoot.modelData)
                    readonly property bool fullscreenOverride: !!hyprMonitor && !!hyprMonitor.activeWorkspace && hyprMonitor.activeWorkspace.hasFullscreen
                    visible: Osd.shown && !fullscreenOverride
                    exclusionMode: ExclusionMode.Ignore
                    WlrLayershell.namespace: "wisp-osd"
                    WlrLayershell.layer: WlrLayer.Overlay

                    anchors { bottom: true }
                    margins { bottom: 140 }
                    implicitWidth: 220
                    implicitHeight: 64

                    OsdPopup {}
                }

                property PanelWindow pill: PanelWindow {
                    id: floatingPill
                    screen: screenRoot.modelData

                    property alias contentStackRef: contentStack
                    property alias collapsedViewRef: collapsedView
                    property alias expandedViewRef: expandedView

                    WlrLayershell.layer: WlrLayer.Overlay
                    // Keyboard reaches TextInputs (calendar event entry) only while expanded;
                    // collapsed pill must never steal focus from apps.
                    WlrLayershell.keyboardFocus: isExpanded ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

                    anchors {
                        top: true
                    }
                    margins {
                        top: 12
                    }

                    property bool isExpanded: false
                    // Which dashboard tab to land on when expanding (media island jumps to Media)
                    property int expandTab: 0

                    // Fullscreen apps (games, video players) take full precedence over the
                    // pill — hides it entirely and, via the empty mask below, releases its
                    // input region so clicks/keys reach the fullscreen window underneath
                    // instead of hitting an invisible-but-still-there layer-shell surface.
                    // Per-monitor: uses THIS screen's own Hyprland monitor/workspace, not
                    // Hyprland.focusedWorkspace (compositor-global — would wrongly hide the
                    // pill on every monitor just because a DIFFERENT monitor's focused
                    // workspace went fullscreen). HyprlandMonitor.activeWorkspace and
                    // HyprlandWorkspace.hasFullscreen are both live IPC-driven bindable
                    // properties (verified in ~/coding/quickshell/src/wayland/hyprland/ipc/{monitor,workspace}.hpp),
                    // Hyprland.monitorFor(screen) is the documented screen->monitor lookup
                    // (ipc/qml.hpp).
                    readonly property var hyprMonitor: Hyprland.monitorFor(screenRoot.modelData)
                    readonly property bool fullscreenOverride: !!hyprMonitor && !!hyprMonitor.activeWorkspace && hyprMonitor.activeWorkspace.hasFullscreen

                    // Fixed at max size on purpose: animating the actual wl_surface (implicitWidth/Height)
                    // causes a compositor-side resize each frame, which flashes an uninitialized grey
                    // backing-store rect for the newly-exposed region until the buffer catches up.
                    // Only `container` below animates now; the mask keeps clicks off the invisible margin.
                    implicitWidth: 750
                    implicitHeight: 550

                    color: "transparent"

                    // Reserves space for the *collapsed* bar height only (12px top margin +
                    // 48px collapsed pill), not the fixed 750x550 surface — tiled windows
                    // now stay clear of the bar's baseline row instead of being drawn behind
                    // it. exclusiveZone is independent of implicitHeight/anchored-edge size
                    // (that's what ExclusionMode.Auto would use, and it would reserve the
                    // full 550px expanded height, which is wrong), so expand/collapse and
                    // the media-island width bump never resize the reserved zone.
                    exclusionMode: ExclusionMode.Normal
                    exclusiveZone: 60

                    WlrLayershell.namespace: "wisp"

                    // Input hit-test region: with the surface now fixed at max size, this is what
                    // keeps clicks confined to the visually-shrunk pill instead of the whole surface.
                    // While a fullscreen window owns the workspace, swap to the empty region so this
                    // layer-shell surface stops eating clicks entirely (an invisible container would
                    // otherwise still block input to whatever's fullscreen underneath it).
                    mask: fullscreenOverride ? emptyRegion : containerRegion
                    Region { id: emptyRegion }
                    Region { id: containerRegion; item: container }

                    // Inner container for the actual visual pill. Sized/animated independently of
                    // the (now fixed) window surface, anchored to where the pill visually grows from.
                    Rectangle {
                        id: container
                        anchors.top: parent.top
                        anchors.horizontalCenter: parent.horizontalCenter
                        // Third size tier: media island widens the collapsed pill without expanding
                        readonly property real targetWidth: contentStack.depth > 1 ? 750
                            : (floatingPill.isExpanded ? 750 : (Island.current !== "none" ? Island.activeWidth : 320))
                        // Direction-aware easing needs to know grow vs shrink; compare against
                        // the previous *target*, not the animated width (which lags mid-flight)
                        property real lastTarget: 320
                        property bool widthGrowing: true
                        onTargetWidthChanged: {
                            widthGrowing = targetWidth > lastTarget;
                            lastTarget = targetWidth;
                        }
                        width: targetWidth
                        height: contentStack.depth > 1 ? 550 : (floatingPill.isExpanded ? 550 : 48)
                        color: Theme.panelBackground
                        radius: 24
                        // No outline. The pill is the shell's signature object and
                        // the most-seen surface in it; a grey hairline around it was
                        // the "box around everything" tell at its most visible.
                        // Separation from the desktop comes from the fill plus the
                        // compositor-level shadow Hyprland draws around the layer
                        // surface (DESIGN.md, Elevation & Depth).
                        clip: true

                        // Fullscreen apps take full precedence — fade out entirely rather
                        // than sit drawn-but-unclickable over the fullscreen content.
                        //
                        // One deliberate exception: an achievement unlock (core/Games.qml)
                        // fades the collapsed pill back in for the few seconds the flash
                        // lasts. Games are the main reason a workspace is fullscreen at
                        // all, so a lane that hides exactly while you play would never be
                        // seen. Only the *visual* suppression is lifted — `mask` above
                        // stays on emptyRegion while fullscreenOverride holds, so the
                        // surface still takes no input and clicks continue to reach the
                        // game underneath. Collapsed only: the expanded dashboard has no
                        // business appearing over a fullscreen window unprompted.
                        readonly property bool achievementPeek: floatingPill.fullscreenOverride
                            && Games.flashing && !floatingPill.isExpanded
                        opacity: (floatingPill.fullscreenOverride && !achievementPeek) ? 0 : 1
                        Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                        // Hover invite: collapsed pill swells slightly, hinting it opens
                        transformOrigin: Item.Top
                        scale: !floatingPill.isExpanded && bgMouse.containsMouse ? 1.04 : 1.0
                        Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easeSpring } }

                        // Asymmetric morph: any growth blooms with overshoot (expand AND island
                        // appear), any shrink slurps shut fast with no bounce — overshoot while
                        // shrinking reads as wobble.
                        Behavior on width {
                            NumberAnimation {
                                duration: container.widthGrowing ? 420 : 300
                                easing.type: container.widthGrowing ? Easing.OutBack : Easing.OutQuint
                                easing.overshoot: 1.08
                            }
                        }
                        Behavior on height {
                            NumberAnimation {
                                duration: floatingPill.isExpanded ? 500 : 260
                                easing.type: floatingPill.isExpanded ? Easing.OutBack : Easing.OutQuint
                                easing.overshoot: 1.04
                            }
                        }
                        Behavior on radius { NumberAnimation { duration: Theme.animSlow; easing.type: Theme.easeSpring } }

                        // Background click handler. Sits BEHIND widgets.
                        MouseArea {
                            id: bgMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                if (contentStack.depth > 1) return;

                                // Only expand if collapsed. If already expanded, empty space clicks do nothing.
                                if (!floatingPill.isExpanded) {
                                    floatingPill.expandTab = 0;
                                    floatingPill.isExpanded = true;
                                    contentStack.replace(expandedView);
                                }
                            }
                        }

                        // Inner content
                        StackView {
                            id: contentStack
                            anchors.fill: parent
                            initialItem: floatingPill.isExpanded ? expandedView : collapsedView

                            // Expand/collapse content swap: scale-pop in
                            replaceEnter: Transition {
                                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.animSlow }
                                NumberAnimation { property: "scale"; from: 0.92; to: 1; duration: 450; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
                            }
                            replaceExit: Transition {
                                NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.animFast }
                            }
                            // Subview enter: rises up into place
                            pushEnter: Transition {
                                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.animSlow }
                                NumberAnimation { property: "y"; from: 40; to: 0; duration: 420; easing.type: Easing.OutQuint }
                            }
                            pushExit: Transition {
                                NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.animFast }
                                NumberAnimation { property: "scale"; from: 1; to: 0.96; duration: Theme.animFast }
                            }
                            // Subview leave: dashboard scales back up, subview drops away
                            popEnter: Transition {
                                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.animSlow }
                                NumberAnimation { property: "scale"; from: 0.96; to: 1; duration: 420; easing.type: Easing.OutQuint }
                            }
                            popExit: Transition {
                                NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.animFast }
                                NumberAnimation { property: "y"; from: 0; to: 40; duration: Theme.animFast; easing.type: Easing.InQuad }
                            }
                        }
                    }

                    Component {
                        id: collapsedView
                        CollapsedBar {
                            onExpandMedia: {
                                floatingPill.expandTab = 2; // Media tab
                                floatingPill.isExpanded = true;
                                contentStack.replace(expandedView);
                            }
                            onExpandNotifs: {
                                Island.dismissFlash();
                                floatingPill.expandTab = 0; // Dashboard tab (notif centre)
                                floatingPill.isExpanded = true;
                                contentStack.replace(expandedView);
                            }
                        }
                    }

                    Component {
                        id: expandedView
                        ExpandedDashboard {
                            stack: contentStack
                            currentTab: floatingPill.expandTab
                        }
                    }
                }
            }
        }
    }
}
