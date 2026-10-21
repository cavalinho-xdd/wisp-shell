pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Services.Notifications
import Quickshell.Bluetooth
import Quickshell.Networking

// Live-activity state for the collapsed pill's dynamic-island strip.
//
// Two layers, iOS-style:
//  - persistent activity: media (sticky, lingers on pause) or none
//  - transient activity: notification flash (auto-expires, preempts the
//    persistent layer while it's up, then falls back)
// `current` is the single arbitration point the presentation components
// and shell.qml sizing bind to. A volume/brightness OSD slots in later
// as another transient with priority over notifications.
Singleton {
    id: island

    // Device lists start empty and fill in asynchronously once the
    // Bluetooth/Networking services report — that first fill would read as
    // "just connected". Lists are tracked silently until this settles.
    property bool _settled: false
    Timer {
        running: true
        interval: 3000
        onTriggered: island._settled = true
    }

    // ── Hardware Events (Bluetooth) ──
    property string btFlashName: ""
    property bool btFlashIsConnect: false
    property bool btFlashActive: false

    property var _lastBtConnected: []
    property var _currentBtConnected: {
        if (!Bluetooth.defaultAdapter || !Bluetooth.defaultAdapter.enabled) return [];
        let devs = Bluetooth.defaultAdapter.devices.values;
        let connected = [];
        for (let i = 0; i < devs.length; i++) {
            if (devs[i].connected) connected.push(devs[i].name);
        }
        return connected;
    }

    on_CurrentBtConnectedChanged: {
        let oldList = _lastBtConnected;
        let newList = _currentBtConnected;
        _lastBtConnected = newList;
        if (!_settled) return;
        
        let connected = newList.filter(x => !oldList.includes(x));
        let disconnected = oldList.filter(x => !newList.includes(x));

        if (connected.length > 0) {
            btFlashName = connected[0];
            btFlashIsConnect = true;
            btFlashActive = true;
            btFlashTimer.restart();
        } else if (disconnected.length > 0) {
            btFlashName = disconnected[0];
            btFlashIsConnect = false;
            btFlashActive = true;
            btFlashTimer.restart();
        }
    }

    Timer {
        id: btFlashTimer
        interval: 3000
        onTriggered: island.btFlashActive = false
    }

    // ── Hardware Events (USB) ──
    property bool usbFlashIsConnect: false
    property bool usbFlashActive: false

    function triggerUsbFlash(event) {
        usbFlashIsConnect = (event === "add");
        usbFlashActive = true;
        usbFlashTimer.restart();
    }

    Timer {
        id: usbFlashTimer
        interval: 3000
        onTriggered: island.usbFlashActive = false
    }

    // ── Hardware Events (Battery) ──
    property string batFlashReason: "" // "low", "critical", "charging", "full"
    property bool batFlashActive: false

    function triggerBatteryFlash(reason) {
        batFlashReason = reason;
        batFlashActive = true;
        batFlashTimer.restart();
    }

    Timer {
        id: batFlashTimer
        interval: 3500
        onTriggered: island.batFlashActive = false
    }

    // ── Hardware Events (Network) ──
    property string netFlashName: ""
    property bool netFlashIsConnect: false
    property bool netFlashActive: false

    property var _lastNetConnected: []
    property var _currentNetConnected: {
        let devs = Networking.devices.values;
        let connected = [];
        for (let i = 0; i < devs.length; i++) {
            let nets = devs[i].networks.values;
            for (let j = 0; j < nets.length; j++) {
                if (nets[j].connected) connected.push(nets[j].name);
            }
        }
        return connected;
    }

    on_CurrentNetConnectedChanged: {
        let oldList = _lastNetConnected;
        let newList = _currentNetConnected;
        _lastNetConnected = newList;
        if (!_settled) return;
        
        let connected = newList.filter(x => !oldList.includes(x));
        let disconnected = oldList.filter(x => !newList.includes(x));

        if (connected.length > 0) {
            triggerNetworkFlash(connected[0], true);
        } else if (disconnected.length > 0) {
            triggerNetworkFlash(disconnected[0], false);
        }
    }

    function triggerNetworkFlash(name, connected) {
        netFlashName = name;
        netFlashIsConnect = connected;
        netFlashActive = true;
        netFlashTimer.restart();
    }

    Timer {
        id: netFlashTimer
        interval: 3000
        onTriggered: island.netFlashActive = false
    }

    // ── Arbitration ──
    readonly property string current: flashNotif ? "notif"
        : batFlashActive ? "battery"
        : netFlashActive ? "network"
        : usbFlashActive ? "usb"
        : btFlashActive ? "bluetooth"
        : Games.active ? "game"
        : Osu.active ? "osu"
        : mediaActive ? "media"
        : Discord.inVoice ? "discord" : "none"

    // ── Transient: notification flash ──
    property var flashNotif: null

    Connections {
        target: Notifs
        function onIncoming(notification) {
            island.flashNotif = notification;
            // Critical sticks around longer
            flashTimer.interval = notification.urgency === NotificationUrgency.Critical ? 8000 : 5000;
            flashTimer.restart();
        }
    }
    Timer {
        id: flashTimer
        onTriggered: island.flashNotif = null
    }
    function dismissFlash() {
        flashTimer.stop();
        flashNotif = null;
    }

    // Which player owns the island: among actively-playing players, prefer
    // one that actually has album art (browsers commonly publish the SAME
    // tab twice — e.g. Firefox's own bare MPRIS with no art, alongside
    // plasma-browser-integration's richer one with a real trackArtUrl and
    // cleaner title/artist — picking array-order-first grabs the worse one).
    // Falls back to the first playing player if none have art, then to the
    // last paused one that still has a track loaded.
    readonly property var player: {
        const ps = Mpris.players.values;
        let firstPlaying = null;
        let playingWithArt = null;
        let fallback = null;
        for (let i = 0; i < ps.length; i++) {
            const p = ps[i];
            if (p.playbackState === MprisPlaybackState.Playing) {
                if (!firstPlaying) firstPlaying = p;
                if (!playingWithArt && p.trackArtUrl) playingWithArt = p;
            } else if (!fallback && p.playbackState === MprisPlaybackState.Paused && p.trackTitle) {
                fallback = p;
            }
        }
        return playingWithArt || firstPlaying || fallback;
    }

    readonly property bool playing: !!player && player.playbackState === MprisPlaybackState.Playing

    // The island is stickier than raw playback state: pausing keeps it up
    // for a linger window (resume-from-bar affordance), closing the player
    // drops it instantly.
    property bool mediaActive: false

    onPlayingChanged: {
        if (playing) {
            linger.stop();
            mediaActive = true;
        } else if (mediaActive) {
            linger.restart();
        }
    }

    onPlayerChanged: {
        if (!player) {
            linger.stop();
            mediaActive = false;
        }
    }

    Timer {
        id: linger
        interval: 15000
        onTriggered: island.mediaActive = false
    }
}
