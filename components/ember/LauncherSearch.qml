import QtQuick
import Quickshell
import Quickshell.Io
import "../../core"

// What the launcher island searches and runs: apps ranked by name match and
// frecency, plus the prefixes `=` calculator (qalc), `?` web and `$` shell.
// The ranking is the old pill launcher's (components/IslandLauncher.qml); that
// copy goes away when the islands replace the pill.
Item {
    id: root

    property string query: ""
    readonly property int maxResults: 5

    signal launched()

    readonly property var allApps: [...DesktopEntries.applications.values]
        .filter(a => !a.noDisplay)
        .sort((a, b) => a.name.localeCompare(b.name))

    readonly property bool mathMode: query.startsWith("=")
    property string mathResult: ""

    function score(app, q) {
        const name = app.name.toLowerCase();
        if (name.startsWith(q)) return 100;
        if (name.split(/[\s-]+/).some(w => w.startsWith(q))) return 80;
        const idx = name.indexOf(q);
        if (idx >= 0) return 60 - Math.min(idx, 20);
        if (app.keywords.some(k => k.toLowerCase().startsWith(q))) return 40;
        if ((app.genericName || "").toLowerCase().includes(q)) return 30;
        if ((app.comment || "").toLowerCase().includes(q)) return 20;
        return -1;
    }

    readonly property var results: {
        const raw = query.trim();
        const q = raw.toLowerCase();
        const rest = raw.slice(1).trim();

        if (mathMode) return rest ? [{ kind: "math", expr: rest, result: mathResult }] : [];
        if (raw.startsWith("?")) return rest ? [{ kind: "web", term: rest }] : [];
        if (raw.startsWith("$")) return rest ? [{ kind: "shell", cmd: rest }] : [];

        // No query: the apps used most and most recently.
        if (!q) {
            return [...allApps]
                .sort((a, b) => AppUsage.frecencyBoost(b.id) - AppUsage.frecencyBoost(a.id))
                .slice(0, maxResults)
                .map(a => ({ kind: "app", app: a }));
        }
        // Frecency only orders what matches: filtering after adding it would
        // let a much-used app through on any query.
        return allApps
            .map(a => ({ app: a, s: score(a, q) }))
            .filter(r => r.s >= 0)
            .map(r => ({ app: r.app, s: r.s + AppUsage.frecencyBoost(r.app.id) }))
            .sort((a, b) => b.s - a.s)
            .slice(0, maxResults)
            .map(r => ({ kind: "app", app: r.app }));
    }

    function launch(item) {
        if (!item) return;
        if (item.kind === "math") {
            if (mathResult) Quickshell.execDetached(["wl-copy", mathResult]);
        } else if (item.kind === "web") {
            Quickshell.execDetached(["xdg-open", "https://www.google.com/search?q=" + encodeURIComponent(item.term)]);
        } else if (item.kind === "shell") {
            Quickshell.execDetached(["bash", "-c", item.cmd]);
        } else {
            AppUsage.recordLaunch(item.app.id);
            if (item.app.runInTerminal)
                Quickshell.execDetached(["kitty", "-e", ...item.app.command]);
            else
                item.app.execute();
        }
        launched();
    }

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
}
