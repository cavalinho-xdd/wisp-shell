// Unit tests for core/notif_rules.js. Run: node --test scripts/test_notif_rules.js
// The file is a QML JS library (.pragma library), so load it into a vm
// context with that directive stripped instead of require()-ing it.
const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");

const src = fs.readFileSync(path.join(__dirname, "../core/notif_rules.js"), "utf8")
    .replace(/^\.pragma library\s*$/m, "");
const R = vm.createContext({});
vm.runInContext(src, R);

// vm-realm arrays/objects fail deepStrictEqual on prototype; compare as JSON.
const plain = x => JSON.parse(JSON.stringify(x));
const noRule = R.ruleFor({}, "x");

test("ruleFor defaults every flag", () => {
    assert.deepEqual(plain(R.ruleFor(undefined, "a")), { noFlash: false, noStore: false, allowInDnd: false });
    assert.equal(R.ruleFor({ a: { noStore: true } }, "a").noStore, true);
});

test("inSchedule handles same-day, overnight and malformed windows", () => {
    const at = (h, m) => h * 60 + m;
    assert.equal(R.inSchedule(at(12, 0), "09:00", "17:00"), true);
    assert.equal(R.inSchedule(at(17, 0), "09:00", "17:00"), false);
    assert.equal(R.inSchedule(at(23, 30), "22:00", "07:00"), true);
    assert.equal(R.inSchedule(at(6, 59), "22:00", "07:00"), true);
    assert.equal(R.inSchedule(at(7, 0), "22:00", "07:00"), false);
    assert.equal(R.inSchedule(at(12, 0), "25:00", "07:00"), false);
    assert.equal(R.inSchedule(at(12, 0), "10:00", "10:00"), false);
});

test("dndReason checks triggers only when enabled", () => {
    const base = { manual: false, gameActive: true, fullscreen: true, nowMin: 0,
                   auto: { game: false, fullscreen: false, schedule: false }, schedule: { from: "22:00", to: "07:00" } };
    assert.equal(R.dndReason(base), "");
    assert.equal(R.dndReason({ ...base, manual: true }), "manual");
    assert.equal(R.dndReason({ ...base, auto: { game: true } }), "game");
    assert.equal(R.dndReason({ ...base, auto: { fullscreen: true } }), "fullscreen");
    assert.equal(R.dndReason({ ...base, auto: { schedule: true } }), "schedule");
});

test("shouldFlash: critical always, then rule, then DND", () => {
    assert.equal(R.shouldFlash(1, noRule, false), true);
    assert.equal(R.shouldFlash(1, noRule, true), false);
    assert.equal(R.shouldFlash(2, { ...noRule, noFlash: true }, true), true);
    assert.equal(R.shouldFlash(1, { ...noRule, noFlash: true }, false), false);
    assert.equal(R.shouldFlash(1, { ...noRule, allowInDnd: true }, true), true);
});

test("toStored drops inline images and redacts noStore apps", () => {
    const rec = { key: "k", appName: "a", summary: "s", body: "secret", image: "data:image/png;base64,xx", urgency: 1, time: 5, live: true };
    const plain = R.toStored(rec, noRule);
    assert.equal(plain.image, "");
    assert.equal(plain.body, "secret");
    assert.equal(plain.live, false);
    const red = R.toStored({ ...rec, image: "/tmp/a.png" }, { ...noRule, noStore: true });
    assert.equal(red.body, "");
    assert.equal(red.image, "");
    assert.equal(red.redacted, true);
    assert.equal(red.summary, "s");
});

test("storableImage keeps only file paths", () => {
    assert.equal(R.storableImage("/home/a.png"), "/home/a.png");
    assert.equal(R.storableImage("file:///home/a.png"), "file:///home/a.png");
    assert.equal(R.storableImage("image://qsimage/12"), "");
    assert.equal(R.storableImage(undefined), "");
});

test("prune keeps live, drops old history and caps count", () => {
    const now = 1000;
    const recs = [
        { key: "l", live: true, time: 0 },
        { key: "a", live: false, time: 990 },
        { key: "b", live: false, time: 980 },
        { key: "c", live: false, time: 970 },
        { key: "old", live: false, time: 0 }
    ];
    assert.deepEqual(plain(R.prune(recs, now, 100, 2).map(r => r.key)), ["l", "a", "b"]);
});

test("groupByApp keeps newest-first app order", () => {
    const g = R.groupByApp([{ appName: "B" }, { appName: "A" }, { appName: "B" }, { appName: "" }]);
    assert.deepEqual(plain(g.map(x => [x.appName, x.records.length])), [["B", 2], ["A", 1], ["Notification", 1]]);
});

test("matches searches app, summary and body case-insensitively", () => {
    const r = { appName: "Discord", summary: "Hi", body: "Lunch at noon" };
    assert.equal(R.matches(r, ""), true);
    assert.equal(R.matches(r, "LUNCH"), true);
    assert.equal(R.matches(r, "disc"), true);
    assert.equal(R.matches(r, "zzz"), false);
});

test("relTime buckets", () => {
    assert.equal(R.relTime(59999, 0), "now");
    assert.equal(R.relTime(5 * 60000, 0), "5m");
    assert.equal(R.relTime(3 * 3600000, 0), "3h");
    assert.equal(R.relTime(49 * 3600000, 0), "2d");
});
