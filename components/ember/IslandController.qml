import QtQuick

// Which island is open on one screen. Only one at a time; the open one is
// closed by clicking it again, a click outside or Esc (see EmberIslands).
QtObject {
    // "none" | "center" | "right". The left island (workspaces) never opens.
    property string openIsland: "none"
    readonly property bool anyOpen: openIsland !== "none"
    // What the open centre island shows: "media" or "launcher".
    property string centerView: "media"
    readonly property bool launcherOpen: openIsland === "center" && centerView === "launcher"

    function toggle(name: string): void {
        if (name === "center" && openIsland !== "center") centerView = "media";
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
