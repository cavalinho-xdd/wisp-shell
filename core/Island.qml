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
    // osu!lazer (via Osu.qml/tosu) outranks media: while it's running it's
    // the thing the user is actively engaged with, live PP/combo is more
    // time-sensitive than a song title.
    // Discord voice sits at the *bottom* of the stack, below media: being in
    // a call is a long-lived ambient fact, not a moment worth the island, so
    // anything with actual content — a notification, a live osu score, a
    // playing track — takes the strip back off it.
    // A running game sits directly under notifications and above osu: it is
    // the single longest-lived thing the user is actively inside, and unlike
    // osu it carries its own transient (an achievement unlock swaps the game
    // strip's own face rather than taking a lane, so it never has to win
    // arbitration to be seen).
    readonly property string current: flashNotif ? "notif"
        : Games.active ? "game"
        : Osu.active ? "osu"
        : mediaActive ? "media"
        : Discord.inVoice ? "discord" : "none"

    // Collapsed-pill width for whichever activity is current; shell.qml
    // falls back to its own "none" width (320) when current === "none".
    readonly property int activeWidth: current === "osu"
        ? (Osu.inGameplay ? 620 : 540)
        : current === "game" ? (Games.flashing ? 620 : 530)
        : current === "discord" ? 460
        : 540

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
