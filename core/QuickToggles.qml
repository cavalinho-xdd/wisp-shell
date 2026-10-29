pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

// Switches that act on the desktop rather than on a service. Game mode turns
// off blur, animations and vfr in Hyprland. It starts as "off" and does not
// read the compositor, so a game mode left on across a shell restart shows as
// off until it is toggled twice.
Singleton {
    id: root

    property bool gameMode: false
    // Keeps the screen awake: EmberIslands holds an IdleInhibitor on its window
    // while this is on, which hypridle respects.
    property bool coffee: false
    // The warm screen shader of fade_nightmode.sh. Unlike game mode it is read
    // back from the compositor, because the shader outlives a shell restart.
    property bool nightLight: false

    function toggleCoffee(): void {
        root.coffee = !root.coffee;
    }

    function toggleNightLight(): void {
        root.nightLight = !root.nightLight;
        Quickshell.execDetached(["bash", Quickshell.shellPath("core/fade_nightmode.sh"), root.nightLight ? "1" : "0"]);
    }

    // Saver → balanced → performance → saver, skipping performance where the
    // machine has none.
    function cyclePowerProfile(): void {
        const p = PowerProfiles.profile;
        PowerProfiles.profile = p === PowerProfile.PowerSaver ? PowerProfile.Balanced
            : (p === PowerProfile.Balanced && PowerProfiles.hasPerformanceProfile ? PowerProfile.Performance : PowerProfile.PowerSaver);
    }

    Process {
        running: true
        command: ["hyprctl", "getoption", "decoration:screen_shader", "-j"]
        stdout: StdioCollector {
            onStreamFinished: root.nightLight = this.text.includes("wisp-nightmode")
        }
    }

    function toggleGameMode(): void {
        root.gameMode = !root.gameMode;
        const fx = !root.gameMode;
        Quickshell.execDetached(["hyprctl", "eval",
            `hl.config({ decoration = { blur = { enabled = ${fx} } }, animations = { enabled = ${fx} }, debug = { vfr = ${fx} } })`]);
    }
}
