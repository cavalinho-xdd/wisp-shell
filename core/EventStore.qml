pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Persistent per-day events/todos for CalendarCard.qml.
// Stored in events.json next to shell.qml (same philosophy as the planned
// settings.json — never touch user dotfiles). Shape:
//   { "days": { "2026-07-27": [ { "text": "dentist", "done": false } ] } }
// FileView + JsonAdapter pattern borrowed from ii-dots Persistent.qml.
Singleton {
    id: root

    // Bind to this from UI for reactivity; reassigned wholesale on every mutation
    property var days: adapter.days

    function keyFor(date) {
        return Qt.formatDate(date, "yyyy-MM-dd");
    }

    function eventsFor(key) {
        return adapter.days[key] || [];
    }

    function addEvent(key, text) {
        if (text.trim() === "") return;
        const d = JSON.parse(JSON.stringify(adapter.days));
        if (!d[key]) d[key] = [];
        d[key].push({ text: text.trim(), done: false });
        adapter.days = d;
    }

    function toggleDone(key, idx) {
        const d = JSON.parse(JSON.stringify(adapter.days));
        if (!d[key] || !d[key][idx]) return;
        d[key][idx].done = !d[key][idx].done;
        adapter.days = d;
    }

    function removeEvent(key, idx) {
        const d = JSON.parse(JSON.stringify(adapter.days));
        if (!d[key]) return;
        d[key].splice(idx, 1);
        if (d[key].length === 0) delete d[key];
        adapter.days = d;
    }

    FileView {
        id: fileView
        path: Paths.eventsFile
        watchChanges: true
        onFileChanged: reloadTimer.restart()
        onAdapterUpdated: writeTimer.restart()
        onLoadFailed: error => {
            if (error == FileViewError.FileNotFound) writeTimer.restart();
        }

        adapter: JsonAdapter {
            id: adapter
            property var days: ({})
        }
    }

    // Debounce disk writes/reloads so rapid edits collapse into one
    Timer { id: writeTimer; interval: 200; onTriggered: fileView.writeAdapter() }
    Timer { id: reloadTimer; interval: 100; onTriggered: fileView.reload() }
}
