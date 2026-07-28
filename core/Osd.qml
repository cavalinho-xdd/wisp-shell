pragma Singleton
import QtQuick
import Quickshell
import "."

// Purely reactive — no hyprctl keybind wiring needed at all. Hardware
// volume/mic keys already go through Pipewire (wpctl/pactl), which
// core/Audio.qml already tracks live; this singleton just watches Audio's
// properties and exposes a single transient "what changed last" slot that
// every monitor's OSD popup window (see shell.qml) renders locally.
Singleton {
    id: root

    // Guards against Pipewire's async initial node population firing a
    // spurious OSD at shell startup — same lazy-init gotcha Island.qml
    // already documents for Mpris. Driven off Audio's own sink/source
    // readiness (PwObjectTracker-backed, see core/Audio.qml) rather than a
    // blind fixed delay: a hardcoded timer either fires too early on a slow
    // boot (Pipewire nodes populate after the guess expires — volume jumps
    // from the 0.0 fallback to its real value, and that jump itself looks
    // like a user-triggered change) or needlessly late on a fast one. The
    // extra 50ms settle timer absorbs the same-tick ordering race between
    // "sink just populated" and its first onVolumeChanged firing.
    readonly property bool sinksPopulated: !!(Audio.sink && Audio.sink.audio) && !!(Audio.source && Audio.source.audio)
    property bool ready: false
    onSinksPopulatedChanged: if (sinksPopulated) settleTimer.restart()
    Timer { id: settleTimer; interval: 50; onTriggered: root.ready = true }

    property string reason: "volume" // "volume" | "mic"
    property real value: 0
    property bool muted: false
    property bool shown: false

    function show(r, v, m) {
        reason = r;
        value = v;
        muted = m;
        shown = true;
        hideTimer.restart();
    }

    Timer {
        id: hideTimer
        interval: 1600
        onTriggered: root.shown = false
    }

    Connections {
        target: Audio
        function onVolumeChanged() { if (root.ready) root.show("volume", Audio.volume, Audio.muted); }
        function onMutedChanged() { if (root.ready) root.show("volume", Audio.volume, Audio.muted); }
        function onMicVolumeChanged() { if (root.ready) root.show("mic", Audio.micVolume, Audio.micMuted); }
        function onMicMutedChanged() { if (root.ready) root.show("mic", Audio.micVolume, Audio.micMuted); }
    }
}
