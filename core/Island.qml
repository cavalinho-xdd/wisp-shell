pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Services.Notifications

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

    // ── Arbitration ──
    readonly property string current: flashNotif ? "notif"
        : mediaActive ? "media" : "none"

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
