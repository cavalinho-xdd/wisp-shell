// Pure helpers for core/Beat.qml, kept free of QML so scripts/test_beat.js
// can run them under node.

// One raw ascii cava frame ("0;512;1000;") -> `count` levels in 0..1, or
// null when the frame is short or unreadable.
function parseFrame(line, count) {
    const parts = line.split(";").filter(s => s !== "");
    if (parts.length < count) return null;
    const out = [];
    for (let i = 0; i < count; i++) {
        const v = Number(parts[i]);
        if (!isFinite(v)) return null;
        out.push(Math.max(0, Math.min(1, v / 1000)));
    }
    return out;
}

// The kick: loudest of the lowest three bars.
function bass(bars) {
    return Math.max(bars[0] || 0, bars[1] || 0, bars[2] || 0);
}

// Fast attack, slow release, so the light hits on the beat and fades after.
function follow(prev, target) {
    return prev + (target - prev) * (target > prev ? 0.7 : 0.18);
}
