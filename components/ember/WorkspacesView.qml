import QtQuick
import Quickshell.Hyprland
import "../../core"

// Content of the left island: the workspaces that live on this monitor, in
// order, the active one stretched and glowing. Hyprland only lists workspaces
// that exist (windows on them, or active), so empty ones do not show. Click
// switches, the wheel steps through the shown ones. The island never opens.
Item {
    id: root

    // This screen's HyprlandMonitor.
    required property var monitor

    readonly property var shown: {
        if (!monitor) return [];
        const mine = Hyprland.workspaces.values
            .filter(w => w.id > 0 && !!w.monitor && w.monitor.name === monitor.name);
        const active = monitor.activeWorkspace;
        if (active && !mine.includes(active)) mine.push(active);
        return mine.sort((a, b) => a.id - b.id);
    }
    readonly property int activeIndex: shown.findIndex(w => w.active)
    // Centre of the active pill, for the island's inner light.
    readonly property point emberPoint: Qt.point(
        Theme.spaceMd + Math.max(0, activeIndex) * (Theme.workspaceDot + Theme.workspaceGap) + Theme.workspaceActiveWidth / 2,
        Theme.islandHeight / 2)

    // From the targets, not the animated dot widths, so the island morphs once.
    implicitWidth: shown.length === 0 ? Theme.islandHeight
        : Theme.spaceMd * 2 + Theme.workspaceActiveWidth
            + (shown.length - 1) * (Theme.workspaceDot + Theme.workspaceGap)
    implicitHeight: Theme.islandHeight

    // Next (delta 1) or previous (-1) of the shown workspaces; no wrap.
    function step(delta: int): void {
        const i = Math.max(0, Math.min(shown.length - 1, activeIndex + delta));
        if (shown.length > 0 && i !== activeIndex)
            Hyprland.dispatch("hl.dsp.focus({ workspace = " + shown[i].id + " })");
    }

    Row {
        x: Theme.spaceMd
        spacing: Theme.workspaceGap

        Repeater {
            model: root.shown
            WorkspaceDot {}
        }
    }

    // A wheel notch is 120; a trackpad sends many small deltas, so add them up.
    property real wheelSum: 0
    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            root.wheelSum += event.angleDelta.y;
            const notches = Math.trunc(root.wheelSum / 120);
            if (notches !== 0) {
                root.wheelSum -= notches * 120;
                root.step(-notches);
            }
        }
    }
}
