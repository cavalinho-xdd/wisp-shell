pragma Singleton
import QtQuick
import Quickshell
import "."

// First-run gate: launches welcome.qml exactly once, the first time wisp
// starts on a machine.
//
// Both reference shells (ii-dots, iNiR) do this with a sentinel file in the
// state dir (`first_run.txt`) — ii-dots via FileView's onLoadFailed
// FileNotFound, iNiR via a `test -f` Process. wisp uses a plain
// settings.json field instead (`shell.welcomeSeen`), because it already has
// exactly one project-local state file with a FileView watching it: a machine
// that has never run wisp has no settings.json, so the field reads its `false`
// default and the wizard fires — the same signal, with no second file and no
// second existence-check mechanism.
//
// The one real hazard of that choice is timing: for the first ~instant of
// startup `Settings.conf` returns declared defaults, and `welcomeSeen`'s
// default is false — i.e. indistinguishable from a genuine first run. Reading
// it before the file has been consulted would relaunch the wizard on *every*
// start. Hence everything below gates on `Settings.ready`, which flips only
// once the FileView has actually resolved, either way (loaded, or confirmed
// missing — see the onLoadFailed branch in Settings.qml).
Singleton {
    id: root

    // Guards against re-checking if Settings.ready ever cycles (e.g. an
    // external edit to settings.json triggering a reload).
    property bool checked: false

    function launch() {
        Quickshell.execDetached(["/usr/bin/qs", "-p", Settings.welcomeAppPath]);
    }

    // Called by welcome.qml on finish/skip. Sync write, not the debounced
    // one — welcome.qml quits immediately after, which would kill the timer.
    function markSeen() {
        Settings.conf.shell.welcomeSeen = true;
        Settings.flush();
    }

    // "Show welcome screen again" from the Advanced settings page.
    function showAgain() {
        Settings.conf.shell.welcomeSeen = false;
        Settings.flush();
        root.launch();
    }

    function check() {
        if (root.checked || !Settings.ready) return;
        root.checked = true;
        if (!Settings.conf.shell.welcomeSeen) root.launch();
    }

    // Settings usually resolves after this singleton is constructed, but not
    // always (it's instantiated lazily on first access, so a consumer touching
    // Settings earlier can have it already loaded by the time we get here) —
    // cover both orderings.
    Connections {
        target: Settings
        function onReadyChanged() { root.check(); }
    }
    Component.onCompleted: root.check()
}
