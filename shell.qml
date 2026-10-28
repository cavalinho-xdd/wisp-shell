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
import Quickshell.Io
import "core"
import "components"
import "components/ember"

ShellRoot {
    // One-time, compositor-global init — must run exactly once regardless of
    // monitor count. Previously lived in floatingPill's Component.onCompleted;
    // moved here when the pill became a per-screen Variants delegate below,
    // since that block now instantiates once per monitor and would otherwise
    // re-inject the same hyprctl layer_rule/keybind N times.
    Component.onCompleted: {
        // Touching the singleton instantiates it; it re-injects saved overrides
        // itself once settings.json finishes loading (see Settings.onLoaded).
        void Settings.ready
        // Same trick for the first-run gate: touching it constructs the
        // singleton, which then waits for Settings.ready before deciding
        // whether to launch welcome.qml (see core/FirstRun.qml).
        FirstRun.enableAutoLaunch()
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

    IpcHandler {
        target: "shell"
        function toggleLauncher(): void {
            if (!ShellState.launcherActive) ShellState.launcherScreen = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "";
            ShellState.launcherActive = !ShellState.launcherActive;
        }
    }

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
    // group (islands + OSD) to one named output instead of every
    // connected screen — falls back to "all monitors" if the saved name isn't
    // currently connected (e.g. an external monitor unplugged), so a stale
    // setting can never silently zero out every shell surface with no visible
    // way back into Settings.
    readonly property var pillScreens: {
        if (Settings.conf.shell.pillMonitor === "") return Quickshell.screens;
        const match = Quickshell.screens.filter(s => s.name === Settings.conf.shell.pillMonitor);
        return match.length > 0 ? match : Quickshell.screens;
    }

    // Islands + OSD per connected monitor (Quickshell.screens, filtered by
    // pillScreens above), recreated on hotplug since Variants tracks the model
    // live. Each screen opens and closes its own islands; the content
    // (core/Island.qml) is one global singleton.
    Variants {
        model: pillScreens

        delegate: Component {
            QtObject {
                id: screenRoot
                required property var modelData

                // Volume/mic OSD — its own tiny surface per monitor, separate
                // from the islands so it never takes part in their morphs. Purely reactive
                // (core/Osd.qml watches core/Audio.qml), no keybind wiring needed.
                property PanelWindow osd: PanelWindow {
                    screen: screenRoot.modelData
                    color: "transparent"
                    // Suppressed during fullscreen on THIS monitor — without this, an
                    // OSD popup from adjusting volume mid-video would draw an
                    // input-eating 220x64 dead zone over the fullscreen surface's own
                    // controls. The OSD has no fade/mask choreography to
                    // preserve, so just not mapping the
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
                    // The window holds the pill and its glow; the margin keeps
                    // the pill where it always was (140 px above the edge).
                    margins { bottom: 140 - Theme.osdGlowRoom }
                    implicitWidth: Theme.osdWidth + Theme.osdGlowRoom * 2
                    implicitHeight: Theme.islandHeight + Theme.osdGlowRoom * 2

                    OsdPopup {}
                }

                property EmberIslands islands: EmberIslands { screen: screenRoot.modelData }
            }
        }
    }
}
