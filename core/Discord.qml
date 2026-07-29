pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Discord voice-chat presence, derived purely from Pipewire.
//
// Why Pipewire and not Discord's own RPC: `/run/user/$UID/discord-ipc-0` on
// Vesktop is served by arRPC, which implements only the rich-presence subset
// (SET_ACTIVITY / INVITE_BROWSER / DEEP_LINK) — there is no
// GET_SELECTED_VOICE_CHANNEL and no VOICE_STATE_UPDATE to subscribe to. Even
// on the official client those commands need the OAuth `rpc` scope. So the
// channel/guild name is simply not obtainable here; what IS reliable is that
// a Discord client opens an audio *capture* stream only while connected to a
// voice channel. Its permanent Stream/Output/Audio ("Playback") node exists
// the whole time the app runs and is therefore useless as a signal — the
// capture node (isStream && !isSink) is the one that means "in voice".
Singleton {
    id: root

    // Every Discord-family client binary as it appears in
    // `application.process.binary`. Vesktop/Discord report app.name
    // "Chromium", so the binary is the only usable discriminator.
    readonly property var clientBinaries: [
        "vesktop", "Vesktop",
        "Discord", "discord",
        "DiscordCanary", "DiscordPTB", "DiscordDevelopment",
        "ArmCord", "armcord", "webcord", "WebCord", "legcord", "Legcord",
        "dissent", "abaddon"
    ]

    // Pipewire node objects are created dynamically; QML will not bind to
    // their `properties` map without a tracker (see core/Audio.qml).
    PwObjectTracker { objects: Pipewire.nodes.values }

    readonly property var voiceNode: {
        const ns = Pipewire.nodes.values;
        for (let i = 0; i < ns.length; i++) {
            const n = ns[i];
            if (!n.isStream || n.isSink) continue;
            const p = n.properties;
            if (!p) continue;
            const bin = p["application.process.binary"] || "";
            if (root.clientBinaries.indexOf(bin) !== -1) return n;
        }
        return null;
    }

    readonly property bool capturing: !!voiceNode

    // Sticky like Island's media linger: switching input device, or Discord's
    // own reconnect, tears the capture node down and rebuilds it within a
    // second or two. Without the grace window the island would flicker out
    // and back in mid-call.
    property bool inVoice: false
    property double joinedAt: 0

    onCapturingChanged: {
        if (capturing) {
            drop.stop();
            if (!inVoice) {
                joinedAt = Date.now();
                inVoice = true;
            }
        } else if (inVoice) {
            drop.restart();
        }
    }

    Timer {
        id: drop
        interval: 4000
        onTriggered: {
            root.inVoice = false;
            root.joinedAt = 0;
        }
    }

    // Seconds connected. Ticks only while in voice — no idle timer cost.
    property int elapsed: 0
    Timer {
        running: root.inVoice
        interval: 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.elapsed = root.joinedAt > 0
            ? Math.floor((Date.now() - root.joinedAt) / 1000) : 0
    }

    readonly property string elapsedText: {
        const s = Math.max(0, elapsed);
        const h = Math.floor(s / 3600);
        const m = Math.floor((s % 3600) / 60);
        const sec = s % 60;
        const pad = v => (v < 10 ? "0" + v : "" + v);
        return h > 0 ? h + ":" + pad(m) + ":" + pad(sec) : m + ":" + pad(sec);
    }

    // Discord's own mute button is software-side and never touches Pipewire,
    // so this is the *system* mic state: the capture stream's own mute if the
    // node exposes one, else the default source's. Presented as a mic icon,
    // not as "Discord muted", because that is what it actually means.
    readonly property bool micMuted: (voiceNode && voiceNode.audio && voiceNode.audio.muted)
        || Audio.micMuted

    // ── Controls ──
    //
    // Nothing local can be *asked* about Discord's mute/deafen state, and
    // nothing local can command it either: arRPC's IPC socket carries rich
    // presence only, and Vencord has no external surface. What does work is
    // delivering Discord's own in-app shortcuts straight to its window with
    // Hyprland's `send_shortcut` dispatcher, which matches a window by regex
    // and does not require focusing or raising it.
    //
    // Consequence: `selfMuted`/`selfDeafened` below are *optimistic* — they
    // track what we told Discord to do, not what Discord did. Toggling mute
    // from inside Discord itself desyncs them until the next join. That is
    // the honest ceiling here unless the capture node turns out to reflect
    // Discord's mute (it is not expected to — Discord mutes in software — but
    // that has not been measured in a live call yet; if it does, swap these
    // for real readback and delete the optimism).
    property bool selfMuted: false
    property bool selfDeafened: false

    onInVoiceChanged: if (!inVoice) {
        selfMuted = false;
        selfDeafened = false;
    }

    // Hyprland >= 0.55's Lua parser rejects the flat `hyprctl dispatch
    // sendshortcut MOD, KEY, window` form outright ("')' expected near
    // 'CTRL'"); the dispatcher is `hl.dsp.send_shortcut` and it wants a table
    // { mods, key, window? } — confirmed by probing the live compositor,
    // which also confirms the underscore spelling.
    // `spec` is Hyprland bind syntax, "MODS, KEY" (e.g. "CTRL SHIFT, M").
    function sendShortcut(spec) {
        if (!spec) return;
        const parts = spec.split(",");
        const key = (parts.length > 1 ? parts[1] : parts[0]).trim();
        const mods = parts.length > 1 ? parts[0].trim() : "";
        if (!key) return;
        // These three strings land inside a Lua literal. They come from
        // settings.json, so strip anything that could close out of it.
        const lua = s => s.replace(/["'\\\n]/g, "");
        Quickshell.execDetached(["hyprctl", "dispatch",
            'hl.dsp.send_shortcut({ mods = "' + lua(mods)
            + '", key = "' + lua(key)
            + '", window = "' + lua(Settings.conf.discord.windowMatch) + '" })']);
    }

    function toggleMute() {
        sendShortcut(Settings.conf.discord.muteKey);
        selfMuted = !selfMuted;
        // Unmuting while deafened implicitly undeafens in Discord too.
        if (!selfMuted) selfDeafened = false;
    }

    function toggleDeafen() {
        sendShortcut(Settings.conf.discord.deafenKey);
        selfDeafened = !selfDeafened;
        // Discord's deafen also mutes; undeafening restores the mic.
        selfMuted = selfDeafened;
    }

    function leave() {
        sendShortcut(Settings.conf.discord.leaveKey);
    }
}
