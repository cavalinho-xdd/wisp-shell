import QtQuick

// The theme's copy of Wisp's Ember tokens. The greeter runs as the sddm user
// without Quickshell, so it cannot import core/Theme.qml: keep these in step
// with it by hand. Sizes are in the 1920×1080 frame Main.qml scales.
QtObject {
    id: tokens

    // ── From theme.conf (written by scripts/sddm_sync.sh) ──
    readonly property color ember: /^#[0-9a-fA-F]{6}$/.test(String(config.ember)) ? String(config.ember) : "#8fd3ff"
    readonly property real glow: {
        const g = parseFloat(config.glow);
        return isNaN(g) ? 1 : Math.max(0, Math.min(2, g));
    }
    readonly property bool reduceMotion: String(config.reduceMotion) === "true"

    // ── Fonts (as core/Theme.qml's pickFont) ──
    function pickFont(candidates, fallback) {
        const installed = Qt.fontFamilies();
        for (const c of candidates) {
            if (installed.indexOf(c) !== -1) return c;
        }
        return fallback;
    }
    readonly property string fontFamily: pickFont(["Mona Sans", "Inter", "Noto Sans"], "sans-serif")
    readonly property string fontMono: pickFont(["Monaspace Neon", "JetBrains Mono", "Noto Sans Mono"], "monospace")

    // ── Colours ──
    readonly property color smoke: "#0a0b0e"
    readonly property color ash: "#15171c"
    readonly property color ashHi: "#20232a"
    readonly property color text: "#eef0f4"
    readonly property color muted: "#8a8f9b"
    readonly property color red: "#f38ba8"
    readonly property color topLight: Qt.rgba(1, 1, 1, 0.07)

    // ── Sizes ──
    readonly property int islandHeight: 40
    readonly property int islandMargin: 14
    readonly property int radiusIsland: 20
    readonly property int radiusField: 27
    readonly property int emberSize: 18

    // ── Motion ──
    readonly property int motionFast: 150
    readonly property int motionKindle: reduceMotion ? 200 : 700
    readonly property int kindleDelay: reduceMotion ? 0 : 250
    readonly property int kindleStagger: reduceMotion ? 0 : 70
    readonly property int kindleShift: reduceMotion ? 0 : 8
    readonly property real kindleScale: reduceMotion ? 1 : 0.985
    readonly property real kindleBlur: reduceMotion ? 0 : 0.5
    readonly property var curveKindle: [0.2, 0.8, 0.2, 1, 1, 1]
    readonly property int emberBreathe: 5000
    readonly property int driftDuration: 60000
}
