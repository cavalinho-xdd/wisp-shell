#!/usr/bin/env node
// Reconnecting client for tosu's v2 websocket API (osu!lazer memory reader).
// Emits one compact JSON line per update on stdout — mirrors the
// Process+SplitParser convention used by sysmon_snapshot.sh, but push-based
// (tosu sends a message on every game tick) instead of polled.
//
// Node's built-in WebSocket (stable since Node 22) is used instead of a pip/
// npm dependency, since this project has no package manager step.

const URI = process.env.TOSU_WS_URI || "ws://127.0.0.1:24050/websocket/v2";
const RETRY_MS = 2000;

let announcedDisconnected = false;

function connect() {
    const ws = new WebSocket(URI);
    // A failed handshake fires BOTH "error" and "close" for the same
    // attempt — without this guard each scheduled its own retry, doubling
    // the number of pending reconnects every cycle until the process hit
    // its open-file-descriptor limit (observed: 1024 stuck ESTABLISHED
    // sockets against tosu, exhausting the ephemeral port range).
    let retryScheduled = false;

    function scheduleRetry() {
        if (retryScheduled) return;
        retryScheduled = true;
        try { ws.close(); } catch { /* already closed/closing */ }
        if (!announcedDisconnected) {
            announcedDisconnected = true;
            console.log(JSON.stringify({ connected: false }));
        }
        setTimeout(connect, RETRY_MS);
    }

    ws.addEventListener("message", (event) => {
        announcedDisconnected = false;
        let payload;
        try {
            payload = JSON.parse(event.data);
        } catch {
            return;
        }
        emit(payload);
    });

    ws.addEventListener("close", scheduleRetry);
    ws.addEventListener("error", scheduleRetry);
}

function emit(payload) {
    const profile = payload.profile || {};
    const play = payload.play || payload.gameplay || {};
    const ppBlock = play.pp || {};
    const comboBlock = play.combo || {};
    const hits = play.hits || {};
    const state = payload.state || {};

    console.log(JSON.stringify({
        connected: true,
        state: typeof state.number === "number" ? state.number : -1,
        username: profile.name || "",
        userId: profile.id || 0,
        globalRank: profile.globalRank || 0,
        profilePp: profile.pp || 0,
        livePp: ppBlock.current || 0,
        combo: comboBlock.current || 0,
        maxCombo: comboBlock.max || 0,
        accuracy: play.accuracy || 0,
        hits300: (hits["300"]) || 0,
        hits100: (hits["100"]) || 0,
        hits50: (hits["50"]) || 0,
        hitsMiss: (hits["0"]) || 0,
    }));
}

connect();
