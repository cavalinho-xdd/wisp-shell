pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Launch-history store for the app launcher. Persists per-app usage to
// project-local app_usage.json (same FileView pattern as EventStore):
//   { "usage": { "<desktop id>": { "count": 12, "last": 1753700000000 } } }
//
// recordLaunch() is called by launcher.qml on every launch;
// frecencyBoost() feeds the result ranking there.
Singleton {
    id: store

    // appId → { count, last } (last = Date.now() ms)
    property var usage: ({})

    function recordLaunch(appId) {
        const u = usage;
        const cur = u[appId] || { count: 0, last: 0 };
        u[appId] = { count: cur.count + 1, last: Date.now() };
        usage = u;
        save();
    }

    // ── YOUR CODE HERE (learning mode) ──────────────────────────────
    // Returns a score bonus added on top of the text-match score in
    // launcher.qml (tiers there: 100 prefix / 80 word / 60 substring /
    // 40 keyword / 30 genericName / 20 comment / -1 no match).
    //
    // Design decision this shapes: how fast does a frequently-used app
    // climb, and how fast does an abandoned one sink?
    //  - Pure count = ratchet: one heavy month dominates forever.
    //  - Pure recency = amnesia: yesterday's one-off beats your daily
    //    terminal.
    //  - Classic frecency (Firefox/zoxide) = count weighted by age
    //    buckets, e.g. count * (last used <1h ? 4 : <24h ? 2 : <7d ? 1
    //    : 0.5), or exponential decay: count * Math.exp(-ageDays / 7).
    //
    // Keep the returned bonus roughly in the 0–25 range: it should
    // reorder apps *within* the same match tier (gap between tiers is
    // 20), not let a frecent substring-match beat a prefix-match.
    // Cap it (Math.min) so daily drivers can't blow past that.
    //
    // `entry` is { count, last } or undefined (never launched → 0).
    function frecencyBoost(appId) {
        const entry = usage[appId];
        if (!entry) return 0;

        // Classic frecency (zoxide-style): launch count weighted by how
        // recently the app was last used. Log on count so the 50th launch
        // matters less than the 5th; cap keeps the bonus inside one
        // match tier (gap = 20).
        const ageH = (Date.now() - entry.last) / 3600000;
        const weight = ageH < 1 ? 4 : ageH < 24 ? 2 : ageH < 168 ? 1 : 0.5;
        return Math.min(25, Math.log2(1 + entry.count) * 3 * weight);
    }
    // ────────────────────────────────────────────────────────────────

    function save() {
        saveTimer.restart();
    }

    Timer {
        id: saveTimer
        interval: 300
        onTriggered: file.setText(JSON.stringify({ usage: store.usage }, null, 2))
    }

    FileView {
        id: file
        path: Paths.appUsageFile
        onLoaded: {
            try {
                store.usage = JSON.parse(text()).usage || {};
            } catch (e) { store.usage = {}; }
        }
    }
}
