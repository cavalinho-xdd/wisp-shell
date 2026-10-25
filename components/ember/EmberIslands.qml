import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../core"

// The Ember UI for one screen (ADR 0002): three islands at the top edge plus
// a click catcher that closes the open one. shell.qml loads it instead of the
// pill while Settings.conf.shell.ember is on.
Scope {
    id: root

    required property ShellScreen screen

    // Per monitor, like the pill: Hyprland.focusedWorkspace is global and
    // would hide the islands on every screen at once.
    readonly property var hyprMonitor: Hyprland.monitorFor(screen)
    readonly property bool fullscreen: !!hyprMonitor && !!hyprMonitor.activeWorkspace && hyprMonitor.activeWorkspace.hasFullscreen
    onFullscreenChanged: if (fullscreen) controller.close()

    IslandController { id: controller }

    // A notification flares the centre island only while nothing is open
    // and nothing is fullscreen; opening an island takes the flare away.
    readonly property bool flaring: !!Island.flashNotif && !controller.anyOpen && !fullscreen
    Connections {
        target: controller
        function onAnyOpenChanged() { if (controller.anyOpen) Island.dismissFlash(); }
    }

    // The launcher belongs to the output that was focused when it was
    // toggled (`wisp launcher`, ShellState); closing it here switches it off.
    readonly property bool launcherWanted: ShellState.launcherActive && ShellState.launcherScreen === screen.name
    onLauncherWantedChanged: {
        if (launcherWanted) controller.openLauncher();
        else if (controller.launcherOpen) controller.close();
    }
    Connections {
        target: controller
        function onLauncherOpenChanged() { if (!controller.launcherOpen && root.launcherWanted) ShellState.launcherActive = false; }
    }

    // `qs ipc -p shell.qml call ember-eDP-1 toggle center` — opens islands
    // without a mouse, for checking changes and taking screenshots.
    IpcHandler {
        target: "ember-" + root.screen.name
        function toggle(island: string): void { controller.toggle(island); }
        function close(): void { controller.close(); }
        // Shows a detail view of the open right island: cc, wifi, bluetooth.
        function view(name: string): void { controller.rightView = name; }
        function launcher(): void { controller.toggleLauncher(); }
        // Fills the notification list with n made-up records (the first two
        // live) without touching the saved history; 0 empties it.
        function notifs(n: int): void {
            const apps = [["Discord", "Večer hrajem?", "Mám nový beatmap, koukni na to"], ["Signal", "Marek", "Posílám ti fotky z výletu, jsou hodně povedené a je jich dvanáct"],
                ["System", "Aktualizace hotové", "12 balíčků, restart doporučen"], ["Zen", "Stahování dokončeno", "linux-6.12.iso"], ["Steam", "Kamarád je online", "Adam hraje Dota 2"]];
            Notifs.records = Array.from({ length: n }, (_, i) => ({ key: "fake" + i, appName: apps[i % 5][0], appIcon: "", desktopEntry: "", summary: apps[i % 5][1], body: apps[i % 5][2],
                image: "", urgency: 1, time: Date.now() - i * 240000, live: i < 2, transient: false, expiresAt: 0, redacted: false }));
        }
        // Same step as the mouse wheel over the left island: 1 next, -1 previous.
        function workspace(delta: int): void { workspaces.step(delta); }
        // Fake notification for checking the flare (the real server can be
        // taken by another shell). urgency: 0 low, 1 normal, 2 critical.
        function flash(summary: string, body: string, app: string, urgency: int): void {
            Island.flashNotif = { summary: summary, body: body, appName: app, appIcon: "", image: "", urgency: urgency };
        }
    }

    PanelWindow {
        screen: root.screen
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        visible: controller.anyOpen
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "wisp-ember-catcher"

        MouseArea {
            anchors.fill: parent
            onClicked: controller.close()
        }
    }

    PanelWindow {
        id: window
        screen: root.screen
        anchors { top: true; left: true; right: true }
        color: "transparent"

        // Fixed at the tallest open island plus room for its glow: resizing
        // the surface per frame flashes grey (references/gotchas.md). Only the
        // islands inside animate; the mask keeps clicks on them.
        implicitHeight: Theme.islandMargin + Math.max(launcher.implicitHeight, cc.implicitHeight, wifiOrb.implicitHeight, btOrb.implicitHeight, wifiList.implicitHeight, btList.implicitHeight, sound.implicitHeight, power.implicitHeight, calendar.implicitHeight) + Theme.glowBlurOpen * Theme.glow

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "wisp-ember"
        // Focus only while open, for Esc; collapsed islands never take keys.
        // The launcher types, so it takes the keyboard outright.
        WlrLayershell.keyboardFocus: controller.launcherOpen ? WlrKeyboardFocus.Exclusive : (controller.anyOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None)

        // Hyprland adds gaps_out to the reserved strip, so subtract it to get
        // islandMargin of space under the collapsed islands. Must match
        // general:gaps_out in the Hyprland config.
        readonly property int hyprGapsOut: 11
        exclusionMode: ExclusionMode.Normal
        exclusiveZone: Theme.islandMargin * 2 + Theme.islandHeight - hyprGapsOut

        // Input only on the islands; nothing at all over a fullscreen window.
        mask: root.fullscreen ? emptyRegion : islandsRegion
        Region { id: emptyRegion }
        Region {
            id: islandsRegion
            Region { item: left }
            Region { item: center }
            Region { item: right }
        }

        Item {
            anchors.fill: parent
            focus: true
            Keys.onEscapePressed: controller.close()

            opacity: root.fullscreen ? 0 : 1
            Behavior on opacity { NumberAnimation { duration: Theme.motionFast; easing.type: Easing.OutCubic } }

            // Fixed sizes are the prototype's placeholders until each island
            // gets its content and takes its size from it (M4, M6, M7).
            EmberIsland {
                id: left
                x: Theme.islandMargin
                y: Theme.islandMargin
                transformOrigin: Item.TopLeft
                dimmed: controller.anyOpen
                collapsedWidth: workspaces.implicitWidth
                lit: workspaces.shown.length > 0
                lightX: workspaces.emberPoint.x
                lightY: workspaces.emberPoint.y

                WorkspacesView {
                    id: workspaces
                    monitor: root.hyprMonitor
                }
            }

            EmberIsland {
                id: center
                anchors.horizontalCenter: parent.horizontalCenter
                y: Theme.islandMargin
                collapsedWidth: activity.implicitWidth
                readonly property bool launcherOpen: controller.launcherOpen
                readonly property bool mediaOpen: controller.openIsland === "center" && !launcherOpen
                // Nothing playing: the open centre shows the system instead
                // of an empty player.
                readonly property bool perfOpen: mediaOpen && !media.hasPlayer
                openWidth: launcherOpen ? launcher.implicitWidth : (perfOpen ? perf.implicitWidth : (mediaOpen ? media.implicitWidth : notif.implicitWidth))
                openHeight: launcherOpen ? launcher.implicitHeight : (perfOpen ? perf.implicitHeight : (mediaOpen ? media.implicitHeight : notif.implicitHeight))
                open: launcherOpen || mediaOpen || root.flaring
                // The launcher is opened by keyboard, often: its morph is
                // short, and so is the close that follows. Anything else
                // opening the island brings the full morph back.
                quick: false
                onLauncherOpenChanged: if (launcherOpen) quick = true
                onMediaOpenChanged: if (mediaOpen) quick = false
                Connections {
                    target: root
                    function onFlaringChanged() { if (root.flaring) center.quick = false; }
                }
                dimmed: controller.anyOpen && !open
                // The light follows the ember: the dot when collapsed, the
                // one in the notification, the search glyph in the launcher, the
                // progress head in the media view.
                lit: mediaOpen ? (!perfOpen && media.emberVisible) : true
                lightX: launcherOpen ? launcher.emberPoint.x : (mediaOpen ? media.emberPoint.x : (root.flaring ? notif.emberPoint.x : activity.emberCentre.x))
                lightY: launcherOpen ? launcher.emberPoint.y : (mediaOpen ? media.emberPoint.y : (root.flaring ? notif.emberPoint.y : activity.emberCentre.y))
                onClicked: controller.toggle("center")

                Connections {
                    target: Island
                    function onFlashNotifChanged() { if (Island.flashNotif && !controller.anyOpen && !root.fullscreen) center.flare(); }
                }

                ActivityCollapsed {
                    id: activity
                    running: !root.fullscreen
                    opacity: center.open ? 0 : 1
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: Theme.motionFast; easing.type: Easing.OutCubic } }
                }

                NotifView {
                    id: notif
                    lit: root.flaring
                    enabled: root.flaring
                }

                LauncherView {
                    id: launcher
                    lit: center.launcherOpen
                    enabled: center.launcherOpen
                    onDismiss: controller.close()
                }

                PerformanceView {
                    id: perf
                    lit: center.perfOpen
                    enabled: center.perfOpen
                }

                MediaView {
                    id: media
                    lit: center.mediaOpen && media.hasPlayer
                    enabled: center.mediaOpen && media.hasPlayer
                }
            }

            EmberIsland {
                id: right
                anchors.right: parent.right
                anchors.rightMargin: Theme.islandMargin
                y: Theme.islandMargin
                transformOrigin: Item.TopRight
                dimmed: controller.anyOpen && !open
                collapsedWidth: status.implicitWidth
                readonly property string view: controller.rightView
                openWidth: view === "calendar" ? calendar.implicitWidth : cc.implicitWidth
                openHeight: view === "wifi" ? wifiOrb.implicitHeight : (view === "bluetooth" ? btOrb.implicitHeight
                    : (view === "wifi-list" ? wifiList.implicitHeight : (view === "bluetooth-list" ? btList.implicitHeight : (view === "sound" ? sound.implicitHeight : (view === "power" ? power.implicitHeight : (view === "calendar" ? calendar.implicitHeight : cc.implicitHeight))))))
                open: controller.openIsland === "right"
                lit: open && view === "cc"
                lightX: cc.emberPoint.x
                lightY: cc.emberPoint.y
                onClicked: controller.toggle("right")

                // After the first reveal, moving between views only fades.
                property bool settled: false
                onOpenChanged: if (!open) settled = false
                Timer {
                    interval: 1000
                    running: right.open
                    onTriggered: right.settled = true
                }

                ControlCentre {
                    id: cc
                    quick: right.settled
                    lit: right.open && right.view === "cc"
                    enabled: lit
                    onShowView: view => controller.rightView = view
                }

                CalendarView {
                    id: calendar
                    quick: right.settled
                    lit: right.open && right.view === "calendar"
                    enabled: lit
                    onBack: controller.rightView = "cc"
                }

                PowerView {
                    id: power
                    quick: right.settled
                    lit: right.open && right.view === "power"
                    enabled: lit
                    onBack: controller.rightView = "cc"
                    onDone: controller.close()
                }

                SoundView {
                    id: sound
                    quick: right.settled
                    lit: right.open && right.view === "sound"
                    enabled: lit
                    onBack: controller.rightView = "cc"
                }

                WifiOrb {
                    id: wifiOrb
                    quick: right.settled
                    lit: right.open && right.view === "wifi"
                    enabled: lit
                    onBack: controller.rightView = "cc"
                    onMore: controller.rightView = "wifi-list"
                }

                BluetoothOrb {
                    id: btOrb
                    quick: right.settled
                    lit: right.open && right.view === "bluetooth"
                    enabled: lit
                    onBack: controller.rightView = "cc"
                    onMore: controller.rightView = "bluetooth-list"
                }

                WifiList {
                    id: wifiList
                    quick: right.settled
                    lit: right.open && right.view === "wifi-list"
                    enabled: lit
                    onBack: controller.rightView = "wifi"
                }

                BluetoothList {
                    id: btList
                    quick: right.settled
                    lit: right.open && right.view === "bluetooth-list"
                    enabled: lit
                    onBack: controller.rightView = "bluetooth"
                }

                StatusCollapsed {
                    id: status
                    opacity: right.open ? 0 : 1
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: Theme.motionFast; easing.type: Easing.OutCubic } }
                }
            }
        }
    }
}
