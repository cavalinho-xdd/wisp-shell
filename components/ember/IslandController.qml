import QtQuick

// Which island is open on one screen. Only one at a time; the open one is
// closed by clicking it again, a click outside or Esc (see EmberIslands).
QtObject {
    // "none" | "center" | "right" | "bubble" (the call beside the centre).
    // The left island (workspaces) never opens.
    property string openIsland: "none"
    readonly property bool anyOpen: openIsland !== "none"
    // What the open centre island shows: "media" or "launcher".
    property string centerView: "media"
    // What the open right island shows: "cc", "wifi", "wifi-list", "bluetooth"
    // or "bluetooth-list".
    property string rightView: "cc"
    readonly property bool launcherOpen: openIsland === "center" && centerView === "launcher"

    function toggle(name: string): void {
        if (name === "center" && openIsland !== "center") centerView = "media";
        if (name === "right" && openIsland !== "right") rightView = "cc";
        openIsland = openIsland === name ? "none" : name;
    }

    function openLauncher(): void {
        centerView = "launcher";
        openIsland = "center";
    }

    function toggleLauncher(): void {
        if (launcherOpen) close();
        else openLauncher();
    }

    function close(): void {
        openIsland = "none";
    }
}
