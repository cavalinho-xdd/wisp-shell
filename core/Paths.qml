pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Single owner of where wisp's files live.
//
// Until 2026-07-28 everything — settings.json, colors.json, events.json,
// app_usage.json, generated/ — was written next to shell.qml via
// Quickshell.shellPath(). That works for clone-and-run, and is fatal for a
// package: the install directory is root-owned and read-only, so the first
// settings write would fail silently and the shell would come up with defaults
// forever. Code and state have to be separable, so this splits them:
//
//   code   → the shell directory (read-only once installed) — Paths.shell(...)
//   config → $XDG_CONFIG_HOME/wisp   — user-editable, hand-editing is supported
//   state  → $XDG_STATE_HOME/wisp    — generated, safe to delete
//
// Deliberately NOT Quickshell.statePath(): that returns a per-shell *hash*
// directory (~/.local/state/quickshell/by-shell/<md5>/), so the path would
// change if the shell were ever installed to a different prefix, silently
// orphaning the user's settings. It is also not something a person can find or
// hand-edit, and the settings app has an "Open settings.json" button that
// promises otherwise.
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME") || "/root"
    readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || (root.home + "/.config")
    readonly property string stateHome: Quickshell.env("XDG_STATE_HOME") || (root.home + "/.local/state")

    readonly property string configDir: root.configHome + "/wisp"
    readonly property string stateDir: root.stateHome + "/wisp"
    readonly property string generatedDir: root.stateDir + "/generated"

    // User-owned config. One file, hand-editable, watched for changes.
    readonly property string settingsFile: root.configDir + "/settings.json"

    // Generated state. Regenerable; deleting any of these costs the user
    // nothing but a re-run.
    readonly property string colorsFile: root.stateDir + "/colors.json"
    readonly property string eventsFile: root.stateDir + "/events.json"
    readonly property string appUsageFile: root.stateDir + "/app_usage.json"
    readonly property string terminalOscFile: root.generatedDir + "/terminal-osc.sh"

    // Read-only shell payload (QML, scripts, templates).
    function shell(p) { return Quickshell.shellPath(p); }

    // Make sure the directories exist, so a FileView's first writeAdapter()
    // has somewhere to land. This is a *fallback* for people running
    // `qs -p shell.qml` straight out of a checkout — the `wisp` launcher does
    // it synchronously before starting Quickshell at all, which is the path
    // that actually guarantees ordering.
    //
    // Deliberately does NOT migrate pre-split files from the shell directory.
    // That was the first version of this, and it is a data-loss race: the
    // migration Process is async, while Settings' FileView reads immediately,
    // fails with FileNotFound, seeds defaults and schedules a write 200 ms
    // later — which would land *on top of* the just-copied file and destroy the
    // user's real settings. Migration belongs somewhere it can be sequenced,
    // i.e. the `wisp` launcher, and it lives there.
    Process {
        running: true
        command: ["mkdir", "-p", root.configDir, root.generatedDir]
    }
}
