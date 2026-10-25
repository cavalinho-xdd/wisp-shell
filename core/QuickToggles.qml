pragma Singleton
import QtQuick
import Quickshell

// Switches that act on the desktop rather than on a service. Game mode turns
// off blur, animations and vfr in Hyprland. It starts as "off" and does not
// read the compositor, so a game mode left on across a shell restart shows as
// off until it is toggled twice.
Singleton {
    id: root

    property bool gameMode: false

    function toggleGameMode(): void {
        root.gameMode = !root.gameMode;
        const fx = !root.gameMode;
        Quickshell.execDetached(["hyprctl", "eval",
            `hl.config({ decoration = { blur = { enabled = ${fx} } }, animations = { enabled = ${fx} }, debug = { vfr = ${fx} } })`]);
    }
}
