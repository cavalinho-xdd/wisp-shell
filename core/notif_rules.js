.pragma library

// Pure notification-center logic, kept free of QML types so it can be unit
// tested under plain Node (scripts/test_notif_rules.js). core/Notifs.qml owns
// all state and calls into these.

const CRITICAL = 2; // NotificationUrgency.Critical

// Per-app rule with every flag defaulted, so callers never null-check.
function ruleFor(appRules, appName) {
    const r = (appRules && appRules[appName]) || {};
    return {
        noFlash: !!r.noFlash,       // never flash in the pill
        noStore: !!r.noStore,       // keep only "App: summary" in saved history
        allowInDnd: !!r.allowInDnd  // flashes even while DND is on
    };
}

// "HH:MM" -> minutes since midnight, or -1 when malformed.
function parseHm(s) {
    const m = /^(\d{1,2}):(\d{2})$/.exec(String(s || "").trim());
    if (!m) return -1;
    const h = Number(m[1]), min = Number(m[2]);
    if (h > 23 || min > 59) return -1;
    return h * 60 + min;
}

// Half-open [from, to) window that may wrap past midnight (22:00 -> 07:00).
function inSchedule(nowMin, from, to) {
    const f = parseHm(from), t = parseHm(to);
    if (f < 0 || t < 0 || f === t) return false;
    return f < t ? (nowMin >= f && nowMin < t) : (nowMin >= f || nowMin < t);
}

// ctx: { manual, gameActive, fullscreen, nowMin,
//        auto: { game, fullscreen, schedule }, schedule: { from, to } }
// Returns the reason DND is on ("manual" | "game" | "fullscreen" | "schedule"), or "".
function dndReason(ctx) {
    const a = ctx.auto || {};
    if (ctx.manual) return "manual";
    if (a.game && ctx.gameActive) return "game";
    if (a.fullscreen && ctx.fullscreen) return "fullscreen";
    if (a.schedule && ctx.schedule && inSchedule(ctx.nowMin, ctx.schedule.from, ctx.schedule.to)) return "schedule";
    return "";
}

// Critical always gets through; otherwise the app rule, then DND, decide.
function shouldFlash(urgency, rule, dnd) {
    if (urgency === CRITICAL) return true;
    if (rule.noFlash) return false;
    return !dnd || rule.allowInDnd;
}

// Only file images outlive their notification: inline image data arrives as
// an image:// provider URL (or data: URI) that dies with the Notification.
function storableImage(img) {
    return /^(\/|file:)/.test(img || "") ? img : "";
}

// Form written to disk: history only, inline images dropped, content
// stripped for noStore apps.
function toStored(rec, rule) {
    const out = {
        key: rec.key, appName: rec.appName, appIcon: rec.appIcon,
        desktopEntry: rec.desktopEntry, summary: rec.summary, body: rec.body,
        image: storableImage(rec.image),
        urgency: rec.urgency, time: rec.time, live: false,
        redacted: !!rec.redacted
    };
    if (rule.noStore) {
        out.body = "";
        out.image = "";
        out.redacted = true;
    }
    return out;
}

// Newest-first records -> drop history older than maxAgeMs and cap total
// history at maxCount. Live records are never pruned.
function prune(records, now, maxAgeMs, maxCount) {
    let kept = 0;
    return records.filter(r => {
        if (r.live) return true;
        if (now - r.time > maxAgeMs) return false;
        return ++kept <= maxCount;
    });
}

// Newest-first records -> [{ appName, records }], most recently active app first.
function groupByApp(records) {
    const order = [];
    const byApp = {};
    for (const r of records) {
        const k = r.appName || "Notification";
        if (!byApp[k]) { byApp[k] = []; order.push(k); }
        byApp[k].push(r);
    }
    return order.map(k => ({ appName: k, records: byApp[k] }));
}

// Case-insensitive substring match over app, summary and body.
function matches(rec, query) {
    const q = String(query || "").trim().toLowerCase();
    if (!q) return true;
    return [rec.appName, rec.summary, rec.body].some(s => String(s || "").toLowerCase().includes(q));
}

// "now" / "5m" / "3h" / "2d"
function relTime(now, t) {
    const diffMin = Math.floor((now - t) / 60000);
    if (diffMin < 1) return "now";
    if (diffMin < 60) return diffMin + "m";
    const diffH = Math.floor(diffMin / 60);
    if (diffH < 24) return diffH + "h";
    return Math.floor(diffH / 24) + "d";
}
