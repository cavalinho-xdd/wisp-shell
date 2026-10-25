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

    // `qs ipc -p shell.qml call ember-eDP-1 toggle center` — opens islands
    // without a mouse, for checking changes and taking screenshots.
    IpcHandler {
        target: "ember-" + root.screen.name
        function toggle(island: string): void { controller.toggle(island); }
        function close(): void { controller.close(); }
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
        implicitHeight: Theme.islandMargin + Math.max(center.openHeight, right.openHeight) + Theme.glowBlurOpen * Theme.glow

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "wisp-ember"
        // Focus only while open, for Esc; collapsed islands never take keys.
        WlrLayershell.keyboardFocus: controller.anyOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

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
                collapsedWidth: 124
            }

            EmberIsland {
                id: center
                anchors.horizontalCenter: parent.horizontalCenter
                y: Theme.islandMargin
                collapsedWidth: activity.implicitWidth
                openWidth: 440
                openHeight: 172
                open: controller.openIsland === "center"
                lightX: activity.emberCentre.x
                lightY: activity.emberCentre.y
                onClicked: controller.toggle("center")

                ActivityCollapsed {
                    id: activity
                    running: !root.fullscreen
                    opacity: center.open ? 0 : 1
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: Theme.motionFast; easing.type: Easing.OutCubic } }
                }
            }

            EmberIsland {
                id: right
                anchors.right: parent.right
                anchors.rightMargin: Theme.islandMargin
                y: Theme.islandMargin
                transformOrigin: Item.TopRight
                collapsedWidth: 118
                openWidth: 380
                openHeight: 318
                open: controller.openIsland === "right"
                onClicked: controller.toggle("right")
            }
        }
    }
}
