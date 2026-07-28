pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    property PwNode sink: Pipewire.defaultAudioSink
    
    // Auto-updating volume value (0.0 to 1.0)
    property real volume: (sink && sink.audio) ? sink.audio.volume : 0.0
    property bool muted: (sink && sink.audio) ? !!sink.audio.muted : false

    property PwNode source: Pipewire.defaultAudioSource

    property real micVolume: (source && source.audio) ? source.audio.volume : 0.0
    property bool micMuted: (source && source.audio) ? !!source.audio.muted : false

    function devices(isSink) {
        return Pipewire.nodes.values.filter(node => node.isSink === isSink && !node.isStream && node.audio)
    }

    function appNodes(isSink) {
        return Pipewire.nodes.values.filter(node => node.isSink === isSink && node.isStream && node.audio)
    }

    readonly property var outputDevices: devices(true)
    readonly property var inputDevices: devices(false)
    readonly property var outputAppNodes: appNodes(true)
    readonly property var inputAppNodes: appNodes(false)

    // Essential tracker to make sure QML binds to the dynamically created Pipewire node objects
    PwObjectTracker {
        objects: [root.sink, root.source]
    }

    function setDefaultSink(node) {
        Pipewire.preferredDefaultAudioSink = node
    }

    function setDefaultSource(node) {
        Pipewire.preferredDefaultAudioSource = node
    }

    function setVolume(v) {
        if (sink && sink.audio) {
            sink.audio.volume = Math.max(0, Math.min(1.0, v))
            if (sink.audio.muted && v > 0) {
                sink.audio.muted = false
            }
        }
    }

    function setMicVolume(v) {
        if (source && source.audio) {
            source.audio.volume = Math.max(0, Math.min(1.0, v))
            if (source.audio.muted && v > 0) {
                source.audio.muted = false
            }
        }
    }

    function toggleMute() {
        if (sink && sink.audio) sink.audio.muted = !sink.audio.muted
    }

    function toggleMicMute() {
        if (source && source.audio) source.audio.muted = !source.audio.muted
    }
}
