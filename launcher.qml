import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import "core"

// Standalone app launcher (5th entry point): `qs -p launcher.qml` pops a
// centered search overlay, Enter launches, Escape/outside-click quits.
// Apps come from Quickshell's native DesktopEntries service — no rofi, no
// .desktop parsing helpers (the nixos-configuration reference predates
// this API; its Python app_fetcher is obsolete here).
//
// Prefix modes (same set ii-dots and walker converged on):
//   = expr   calculator via qalc, Enter copies result (wl-copy)
//   ? query  web search in the default browser
//   $ cmd    run a shell command detached
// Terminal apps (Terminal=true in .desktop) are wrapped into kitty.
ShellRoot {
    id: root

    // All launchable apps, stable-sorted by name once
    readonly property var allApps: [...DesktopEntries.applications.values]
        .filter(a => !a.noDisplay)
        .sort((a, b) => a.name.localeCompare(b.name))

    property string query: ""

    // Prefix > word-boundary > substring on name, then keywords/comment.
    // Plain scoring, no fuzzy matrix — good enough until real frecency
    // ranking lands.
    function score(app, q) {
        const name = app.name.toLowerCase();
        if (name.startsWith(q)) return 100;
        const wordHit = name.split(/[\s-]+/).some(w => w.startsWith(q));
        if (wordHit) return 80;
        const idx = name.indexOf(q);
        if (idx >= 0) return 60 - Math.min(idx, 20);
        if (app.keywords.some(k => k.toLowerCase().startsWith(q))) return 40;
        if ((app.genericName || "").toLowerCase().includes(q)) return 30;
        if ((app.comment || "").toLowerCase().includes(q)) return 20;
        return -1;
    }

    // ── Calculator (= prefix) — qalc runs async, result lands here ──
    property string mathResult: ""
    readonly property bool mathMode: query.startsWith("=")
    onQueryChanged: if (mathMode && query.length > 1) mathDebounce.restart()
    Timer {
        id: mathDebounce
        interval: 120
        onTriggered: {
            mathProc.running = false;
            mathProc.command = ["qalc", "-t", root.query.slice(1).trim()];
            mathProc.running = true;
        }
    }
    Process {
        id: mathProc
        stdout: StdioCollector {
            onStreamFinished: root.mathResult = text.trim()
        }
    }

    // Typed rows: { kind: "app"|"math"|"web"|"shell", ... }
    readonly property var results: {
        const raw = query.trim();
        const q = raw.toLowerCase();

        if (mathMode) {
            const expr = raw.slice(1).trim();
            if (!expr) return [];
            return [{ kind: "math", expr: expr, result: mathResult }];
        }
        if (raw.startsWith("?")) {
            const term = raw.slice(1).trim();
            if (!term) return [];
            return [{ kind: "web", term: term }];
        }
        if (raw.startsWith("$")) {
            const cmd = raw.slice(1).trim();
            if (!cmd) return [];
            return [{ kind: "shell", cmd: cmd }];
        }

        if (!q) {
            // Empty query: frecency alone decides the top of the list
            return [...allApps]
                .sort((a, b) => AppUsage.frecencyBoost(b.id) - AppUsage.frecencyBoost(a.id))
                .map(a => ({ kind: "app", app: a }));
        }
        return allApps
            .map(a => ({ app: a, s: score(a, q) + AppUsage.frecencyBoost(a.id) }))
            .filter(r => r.s >= 0)
            .sort((a, b) => b.s - a.s)
            .map(r => ({ kind: "app", app: r.app }));
    }

    function launch(item) {
        if (!item) return;

        if (item.kind === "math") {
            if (root.mathResult)
                Quickshell.execDetached(["wl-copy", root.mathResult]);
        } else if (item.kind === "web") {
            Quickshell.execDetached(["xdg-open",
                "https://www.google.com/search?q=" + encodeURIComponent(item.term)]);
        } else if (item.kind === "shell") {
            Quickshell.execDetached(["bash", "-c", item.cmd]);
        } else {
            AppUsage.recordLaunch(item.app.id);
            if (item.app.runInTerminal)
                Quickshell.execDetached(["kitty", "-e", ...item.app.command]);
            else
                item.app.execute();
        }
        // Hide instantly, quit after the debounced usage save hits disk
        win.visible = false;
        quitTimer.start();
    }

    Timer {
        id: quitTimer
        interval: 400
        onTriggered: Qt.quit()
    }

    // Cancel path (Escape / outside click): shrink back to the collapsed
    // pill's own size before quitting, mirroring shell.qml's pill — see
    // panel's grown/anchors below. Not used by the launch() path above,
    // which wants to disappear instantly, not linger on a close animation.
    function dismiss() {
        panel.grown = false;
        dismissTimer.restart();
    }
    Timer { id: dismissTimer; interval: 320; onTriggered: Qt.quit() }

    // Lets a second `wisp launcher` invocation (SUPER + Space pressed again
    // while this instance is already up) close it instead of doing nothing/
    // erroring on a duplicate launch. The `wisp` CLI checks for a running
    // instance first and calls this over `qs -p launcher.qml ipc call
    // launcher dismiss` instead of launching a new process.
    IpcHandler {
        target: "launcher"
        function dismiss(): void { root.dismiss() }
    }

    PanelWindow {
        id: win
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "wisp-launcher"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"

        // Dim + outside-click close
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.35)
            opacity: panel.opacity
            MouseArea {
                anchors.fill: parent
                onClicked: root.dismiss()
            }
        }

        Rectangle {
            id: panel
            // Anchored + sized to exactly match shell.qml's collapsed pill
            // (top-center, 12px margin, 320x48, radius 24) so this window
            // opens looking like that always-on-screen pill itself blooming
            // into the launcher, not a separate centered dialog — the real
            // pill sits underneath, unchanged, revealed again on dismiss.
            anchors.top: parent.top
            anchors.topMargin: 12
            anchors.horizontalCenter: parent.horizontalCenter

            property bool grown: false

            width: grown ? 560 : 320
            height: grown ? (searchRow.height + resultList.height + 24) : 48
            radius: 24
            color: Theme.background
            // Borderless — the 0.35 dim behind it already separates the panel
            // from the desktop, same as the welcome wizard's scrim. See
            // DESIGN.md §16.
            clip: true

            opacity: grown ? 1 : 0
            Component.onCompleted: grown = true
            Behavior on opacity { NumberAnimation { duration: 180 } }
            // Same asymmetric morph language as shell.qml's own pill: grow
            // blooms with overshoot, shrink (on dismiss) snaps shut clean.
            Behavior on width {
                NumberAnimation {
                    duration: panel.grown ? 420 : 300
                    easing.type: panel.grown ? Easing.OutBack : Easing.OutQuint
                    easing.overshoot: 1.08
                }
            }
            Behavior on height {
                NumberAnimation {
                    duration: panel.grown ? 420 : 300
                    easing.type: panel.grown ? Easing.OutBack : Easing.OutQuint
                    easing.overshoot: 1.08
                }
            }

            // Swallow clicks so the dim-layer MouseArea doesn't get them
            MouseArea { anchors.fill: parent }

            // ── Search row ──
            Item {
                id: searchRow
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 64

                Text {
                    id: searchIcon
                    anchors.left: parent.left
                    anchors.leftMargin: 24
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰍉"
                    font.family: Theme.fontIcon
                    font.pixelSize: 18
                    color: Theme.primary
                }

                TextInput {
                    font.family: Theme.fontFamily;
                    id: searchInput
                    anchors.left: searchIcon.right
                    anchors.leftMargin: 14
                    anchors.right: parent.right
                    anchors.rightMargin: 24
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.text
                    font.pixelSize: 17
                    clip: true
                    onTextChanged: { root.query = text; resultList.currentIndex = 0; }
                    Component.onCompleted: forceActiveFocus()

                    Keys.onEscapePressed: root.dismiss()
                    Keys.onDownPressed: resultList.currentIndex = Math.min(resultList.currentIndex + 1, resultList.count - 1)
                    Keys.onUpPressed: resultList.currentIndex = Math.max(resultList.currentIndex - 1, 0)
                    Keys.onReturnPressed: root.launch(root.results[resultList.currentIndex])
                    Keys.onEnterPressed: root.launch(root.results[resultList.currentIndex])

                    Text {
                        font.family: Theme.fontFamily;
                        anchors.verticalCenter: parent.verticalCenter
                        visible: searchInput.text.length === 0
                        text: "Search apps…   (= calc, ? web, $ shell)"
                        color: Theme.subtext0
                        font.pixelSize: 16
                    }
                }
            }

            Rectangle {
                anchors.top: searchRow.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                height: 1
                color: Theme.outline
            }

            // ── Results ──
            ListView {
                id: resultList
                anchors.top: searchRow.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.topMargin: 6
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                height: Math.min(count, 8) * 56 + 12
                topMargin: 6
                bottomMargin: 6
                clip: true
                model: root.results
                currentIndex: 0
                keyNavigationWraps: false
                highlightMoveDuration: 150
                highlightResizeDuration: 0

                highlight: Rectangle {
                    radius: 14
                    color: Theme.surface0
                }

                delegate: Item {
                    id: row
                    required property var modelData
                    required property int index
                    readonly property bool isApp: modelData.kind === "app"
                    width: resultList.width
                    height: 56

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 14

                        IconImage {
                            anchors.verticalCenter: parent.verticalCenter
                            implicitSize: 32
                            visible: row.isApp
                            source: row.isApp
                                ? Quickshell.iconPath(row.modelData.app.icon, "application-x-executable")
                                : ""
                        }

                        // Non-app rows get a glyph badge instead of a theme icon
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 32; height: 32; radius: 10
                            visible: !row.isApp
                            color: Theme.surface

                            Text {
                                anchors.centerIn: parent
                                text: row.modelData.kind === "math" ? "󰃬"
                                    : row.modelData.kind === "web" ? "󰖟" : ""
                                font.family: Theme.fontIcon
                                font.pixelSize: 16
                                color: Theme.primary
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1

                            Text {
                                font.family: Theme.fontFamily;
                                text: row.isApp ? row.modelData.app.name
                                    : row.modelData.kind === "math"
                                        ? (row.modelData.result || "…")
                                    : row.modelData.kind === "web"
                                        ? "Search the web for “" + row.modelData.term + "”"
                                    : "Run: " + row.modelData.cmd
                                color: Theme.text
                                font.pixelSize: row.modelData.kind === "math" ? 17 : 14
                                font.bold: row.index === resultList.currentIndex
                                width: resultList.width - 90
                                elide: Text.ElideRight
                            }
                            Text {
                                font.family: Theme.fontFamily;
                                text: row.isApp
                                    ? (row.modelData.app.genericName || row.modelData.app.comment || "")
                                    : row.modelData.kind === "math"
                                        ? row.modelData.expr + "  —  Enter copies"
                                    : row.modelData.kind === "web" ? "Default browser"
                                    : "Detached shell command"
                                color: Theme.subtext0
                                font.pixelSize: 11
                                width: resultList.width - 90
                                elide: Text.ElideRight
                                visible: text.length > 0
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: resultList.currentIndex = row.index
                        onClicked: root.launch(row.modelData)
                    }
                }

                // Empty state
                Text {
                    font.family: Theme.fontFamily;
                    anchors.centerIn: parent
                    visible: resultList.count === 0
                    text: "No matches"
                    color: Theme.subtext0
                    font.pixelSize: 14
                }
            }
        }
    }
}
