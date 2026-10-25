import QtQuick

// Which island is open on one screen. Only one at a time; the open one is
// closed by clicking it again, a click outside or Esc (see EmberIslands).
QtObject {
    // "none" | "center" | "right". The left island (workspaces) never opens.
    property string openIsland: "none"
    readonly property bool anyOpen: openIsland !== "none"

    function toggle(name: string): void {
        openIsland = openIsland === name ? "none" : name;
    }

    function close(): void {
        openIsland = "none";
    }
}
