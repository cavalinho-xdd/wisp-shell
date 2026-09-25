pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Services.Notifications
import "notif_rules.js" as Rules

// Notification centre state: one newest-first list of plain records, live and
// history alike, so the dashboard card and the island read one source.
// Decision logic (DND, app rules, pruning, redaction) lives in notif_rules.js.
//
// The DBus server must live here, not in NotificationCard: the card only
// exists while the dashboard is on the StackView, so a server inside it would
// deregister every time the pill collapses — exactly when the island flash
// needs notifications most. Only reference this singleton from the shell
// process: loading it anywhere else (settings.qml) would start a second server.
//
// NB: while ii runs it owns org.freedesktop.Notifications, so this server
// fails to register (tracked in plan.md Big Future Task #1).
Singleton {
    id: root

    readonly property int maxHistoryAgeMs: 7 * 24 * 3600 * 1000
    readonly property int maxHistoryCount: 200

    // { key, appName, appIcon, desktopEntry, summary, body, image, urgency,
    //   time, live, transient, expiresAt, redacted } — reassigned wholesale
    // on every change so bindings fire.
    property var records: []
    readonly property var liveRecords: records.filter(r => r.live)
    readonly property var historyRecords: records.filter(r => !r.live)

    // key -> live Notification. Not reactive and never persisted; records
    // carry `live` for the UI, this is only for actions/replies/dismiss.
    property var _live: ({})
    property int _seq: 0

    // Coarse clock for relative timestamps and the DND schedule.
    property real now: Date.now()
    Timer { interval: 30000; running: true; repeat: true; onTriggered: root.now = Date.now() }

    readonly property var conf: Settings.conf.notifications
    readonly property bool fullscreen: {
        const m = Hyprland.focusedMonitor;
        return !!m && !!m.activeWorkspace && m.activeWorkspace.hasFullscreen;
    }
    // "" when DND is off, else why it is on: manual | game | fullscreen | schedule
    readonly property string dndReason: {
        const d = new Date(root.now);
        return Rules.dndReason({
            manual: conf.dnd,
            gameActive: Games.active,
            fullscreen: root.fullscreen,
            nowMin: d.getHours() * 60 + d.getMinutes(),
            auto: { game: conf.dndDuringGames, fullscreen: conf.dndWhenFullscreen, schedule: conf.dndScheduleEnabled },
            schedule: { from: conf.dndFrom, to: conf.dndTo }
        });
    }
    readonly property bool dnd: dndReason !== ""

    // Emitted only for notifications that should flash in the pill
    // (DND and app rules already applied) — core/Island.qml listens.
    signal incoming(var notification)

    function setDnd(on) {
        Settings.conf.notifications.dnd = on;
    }

    function relTime(t) {
        return Rules.relTime(root.now, t);
    }

    function live(key) {
        return root._live[key] || null;
    }

    // Click: the app's own "default" action if it offers one, otherwise bring
    // the app forward (focus its window, or launch it).
    function activate(key) {
        const rec = root.records.find(r => r.key === key);
        if (!rec) return;
        const n = root._live[key];
        if (n) {
            for (let i = 0; i < n.actions.length; i++) {
                if (n.actions[i].identifier === "default") {
                    n.actions[i].invoke();
                    return;
                }
            }
        }
        root._focusApp(rec);
        if (n && !n.resident) n.dismiss();
    }

    function reply(key, text) {
        const n = root._live[key];
        if (n && n.hasInlineReply && text.trim() !== "") n.sendInlineReply(text);
    }

    // Live -> closes it (it then drops into history); history -> deletes it.
    function dismiss(key) {
        const n = root._live[key];
        if (n) {
            n.dismiss();
            return;
        }
        root.records = root.records.filter(r => r.key !== key);
        root._save();
    }

    function dismissAll() {
        for (const key of Object.keys(root._live)) root._live[key].dismiss();
    }

    function clearHistory() {
        root.records = root.records.filter(r => r.live);
        root._save();
    }

    function _focusApp(rec) {
        const ids = [rec.desktopEntry, rec.appName].filter(s => !!s).map(s => s.toLowerCase());
        for (const t of ToplevelManager.toplevels.values) {
            if (ids.includes((t.appId || "").toLowerCase())) {
                t.activate();
                return;
            }
        }
        const entry = rec.desktopEntry ? DesktopEntries.byId(rec.desktopEntry) : null;
        if (entry) entry.execute();
    }

    function _recordFrom(n, key, time) {
        // expireTimeout is milliseconds (verified against Quickshell 0.3.1);
        // <= 0 means the client left it to us, and we keep it until dismissed.
        const timeoutMs = n.expireTimeout > 0 ? n.expireTimeout : 0;
        return {
            key: key,
            appName: n.appName,
            appIcon: n.appIcon,
            desktopEntry: n.desktopEntry,
            summary: n.summary,
            body: n.body,
            image: n.image,
            urgency: n.urgency,
            time: time,
            live: true,
            transient: n.transient,
            // Critical and resident notifications never time out on their own.
            expiresAt: (timeoutMs > 0 && !n.resident && n.urgency !== NotificationUrgency.Critical) ? time + timeoutMs : 0,
            redacted: false
        };
    }

    function _onNotification(n) {
        n.tracked = true;
        const key = Date.now() + "-" + (++root._seq);
        root._live[key] = n;
        root.records = [root._recordFrom(n, key, Date.now())].concat(root.records);

        n.closed.connect(() => root._markClosed(key));
        // replaces_id updates the same object in place: refresh the record
        // and float it to the top, but don't flash again (progress spam).
        const refresh = () => root._refresh(key);
        n.summaryChanged.connect(refresh);
        n.bodyChanged.connect(refresh);
        n.imageChanged.connect(refresh);

        if (Rules.shouldFlash(n.urgency, Rules.ruleFor(conf.appRules, n.appName), root.dnd))
            root.incoming(n);
    }

    function _refresh(key) {
        const n = root._live[key];
        if (!n) return;
        const rec = root._recordFrom(n, key, Date.now());
        root.records = [rec].concat(root.records.filter(r => r.key !== key));
    }

    function _markClosed(key) {
        delete root._live[key];
        const rec = root.records.find(r => r.key === key);
        if (!rec) return;
        if (rec.transient) {
            root.records = root.records.filter(r => r.key !== key);
        } else {
            const closed = Object.assign({}, rec, { live: false, expiresAt: 0, image: Rules.storableImage(rec.image) });
            root.records = root.records.map(r => r.key === key ? closed : r);
        }
        root._save();
    }

    function _save() {
        root.records = Rules.prune(root.records, Date.now(), root.maxHistoryAgeMs, root.maxHistoryCount);
        writeTimer.restart();
    }

    // Honour app-requested timeouts: expire() closes the notification, which
    // moves it into history via _markClosed.
    readonly property bool _anyExpiring: liveRecords.some(r => r.expiresAt > 0)
    Timer {
        interval: 1000
        repeat: true
        running: root._anyExpiring
        onTriggered: {
            const t = Date.now();
            for (const r of root.liveRecords) {
                const n = root._live[r.key];
                if (n && r.expiresAt > 0 && r.expiresAt <= t) n.expire();
            }
        }
    }

    NotificationServer {
        id: server
        actionsSupported: true
        imageSupported: true
        bodyImagesSupported: true
        inlineReplySupported: true
        persistenceSupported: true
        onNotification: notification => root._onNotification(notification)
    }

    // ── History on disk ──
    FileView {
        id: fileView
        path: Paths.notificationsFile
        // First run: create the file so later loads stay quiet.
        onLoadFailed: error => {
            if (error == FileViewError.FileNotFound) writeTimer.restart();
        }
        onLoaded: {
            const saved = (adapter.records || []).map(r => Object.assign({}, r, { live: false, expiresAt: 0 }));
            const known = new Set(root.records.map(r => r.key));
            root.records = Rules.prune(root.records.concat(saved.filter(r => !known.has(r.key))),
                                       Date.now(), root.maxHistoryAgeMs, root.maxHistoryCount);
        }
        adapter: JsonAdapter {
            id: adapter
            property var records: []
        }
    }

    Timer {
        id: writeTimer
        interval: 500
        onTriggered: {
            adapter.records = root.records
                .filter(r => !r.live && !r.transient)
                .map(r => Rules.toStored(r, Rules.ruleFor(root.conf.appRules, r.appName)));
            fileView.writeAdapter();
        }
    }

    // History holds message contents: keep the state dir private to the user.
    Component.onCompleted: Quickshell.execDetached(["chmod", "700", Paths.stateDir])
}
