#!/usr/bin/env bash
# game_watch.sh — game-session feed for core/Games.qml.
#
# Emits one compact JSON line per event on stdout, parsed by a Process +
# SplitParser exactly like scripts/sysmon_snapshot.sh and scripts/osu_connect.js:
#
#   {"type":"session","active":true,"source":"steam","appid":"367520",
#    "name":"Hollow Knight","cover":"https://…jpg","startedAt":1785330000,
#    "unlocked":12,"total":63}
#   {"type":"session","active":false}
#   {"type":"achievement","name":"Gathering Swarm","description":"…",
#    "icon":"https://…jpg","unlocked":13,"total":63}
#
# Session lines are emitted only when the *identity* of the running game
# changes, not every tick — QML derives the live timer from startedAt itself,
# so a heartbeat would be pure wakeups for nothing.
#
# Deliberately NOT argv/env for the API keys: this re-reads settings.json every
# tick, so a key pasted into the settings file takes effect without restarting
# the shell, and the keys never appear in `ps` output.
set -u

CONF="${XDG_CONFIG_HOME:-$HOME/.config}/wisp/settings.json"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/wisp"
POLL="${WISP_GAME_POLL:-3}"        # seconds between detection sweeps
ACH_POLL="${WISP_ACH_POLL:-60}"    # seconds between forced achievement polls

STEAM_ROOT=""
for d in "$HOME/.local/share/Steam" "$HOME/.steam/steam" "$HOME/.steam/root"; do
    if [ -d "$d/steamapps" ]; then STEAM_ROOT="$d"; break; fi
done

mkdir -p "$STATE" 2>/dev/null

# ── Config ────────────────────────────────────────────────────────────────
STEAM_KEY=""; STEAM_ID=""; SGDB_KEY=""; ENABLED=1
read_conf() {
    STEAM_KEY=""; STEAM_ID=""; SGDB_KEY=""; ENABLED=1
    [ -f "$CONF" ] || return 0
    # One value per line, read with mapfile — NOT `@tsv` + `read -r a b c d`.
    # Tab is an IFS *whitespace* character, so `read` collapses a run of them
    # into one delimiter: an empty middle field (steamId is normally unset,
    # since it auto-detects) silently shifts every later field left, handing
    # the SteamGridDB key to STEAM_ID. The Web API then gets a garbage steamid,
    # returns an error object, and achievements never fire — with no error
    # anywhere, because the response simply has no .achievements to parse.
    local vals
    mapfile -t vals < <(jq -r '(.games.steamApiKey // ""),
                               (.games.steamId // ""),
                               (.games.steamGridDbKey // ""),
                               (if .games.enable == false then "0" else "1" end)' \
                        "$CONF" 2>/dev/null)
    [ "${#vals[@]}" -ge 4 ] || return 0
    STEAM_KEY="${vals[0]}"
    STEAM_ID="${vals[1]}"
    SGDB_KEY="${vals[2]}"
    ENABLED="${vals[3]}"
    # SteamID64 is discoverable locally — no reason to make the user paste a
    # number they'd have to go look up. loginusers.vdf's block key IS the id.
    if [ -z "$STEAM_ID" ] && [ -n "$STEAM_ROOT" ]; then
        STEAM_ID="$(grep -oE '"7656[0-9]{13}"' "$STEAM_ROOT/config/loginusers.vdf" 2>/dev/null \
                    | head -1 | tr -d '"')"
    fi
}

# ── Helpers ───────────────────────────────────────────────────────────────

# Wall-clock epoch a pid started at, so a shell restarted mid-session still
# shows the true elapsed time instead of restarting the clock at zero.
# /proc/<pid>/stat field 22 is start time in clock ticks since boot.
proc_start_epoch() {
    local pid=$1 btime ticks hz start
    btime="$(awk '/^btime/ {print $2}' /proc/stat 2>/dev/null)"
    [ -n "$btime" ] || { date +%s; return; }
    hz="$(getconf CLK_TCK 2>/dev/null)"; [ -n "$hz" ] || hz=100
    # Field 22 counted from the end of the comm field, since comm may contain
    # spaces or parentheses.
    ticks="$(awk '{ s = substr($0, index($0, ")") + 2); split(s, f, " "); print f[20] }' \
             "/proc/$pid/stat" 2>/dev/null)"
    [ -n "$ticks" ] || { date +%s; return; }
    start=$(( btime + ticks / hz ))
    echo "$start"
}

steam_app_name() {
    local appid=$1 name=""
    [ -n "$STEAM_ROOT" ] || { echo "App $appid"; return; }
    for lib in "$STEAM_ROOT/steamapps" "$HOME/.steam/steam/steamapps"; do
        [ -f "$lib/appmanifest_$appid.acf" ] || continue
        name="$(grep -m1 -oP '"name"\s*"\K[^"]+' "$lib/appmanifest_$appid.acf" 2>/dev/null)"
        [ -n "$name" ] && break
    done
    [ -n "$name" ] && echo "$name" || echo "App $appid"
}

# Steam's public CDN carries library art for every app with no key and no auth,
# which is why the SteamGridDB key is only a fallback for everything else.
# Portrait first (fits the strip), landscape header as the backstop.
steam_cover() {
    # Two statements, not one `local a=$1 b=$a`: under `set -u` bash marks every
    # name in a single `local` as declared-but-unset before running any of the
    # assignments, so referencing the first from the second is an unbound-
    # variable error.
    local appid=$1
    local base="https://cdn.cloudflare.steamstatic.com/steam/apps/$appid"
    if [ "$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "$base/library_600x900.jpg")" = "200" ]; then
        echo "$base/library_600x900.jpg"
    else
        echo "$base/header.jpg"
    fi
}

# SteamGridDB — used for launchers whose art is not on Steam's CDN (Heroic:
# Epic/GOG/Amazon). Needs the key's Authorization header, so the URL is
# resolved here and only the final image URL reaches QML.
sgdb_cover() {
    local query=$1
    [ -n "$SGDB_KEY" ] || return 0
    local id
    id="$(curl -s --max-time 6 -H "Authorization: Bearer $SGDB_KEY" \
          "https://www.steamgriddb.com/api/v2/search/autocomplete/$(jq -rn --arg q "$query" '$q|@uri')" \
          2>/dev/null | jq -r '.data[0].id // empty' 2>/dev/null)"
    [ -n "$id" ] || return 0
    curl -s --max-time 6 -H "Authorization: Bearer $SGDB_KEY" \
        "https://www.steamgriddb.com/api/v2/grids/game/$id?dimensions=600x900" \
        2>/dev/null | jq -r '.data[0].url // empty' 2>/dev/null
}

# ── Detection ─────────────────────────────────────────────────────────────
# Sets D_SOURCE / D_APPID / D_NAME / D_PID, or leaves D_PID empty.
#
# Steam is exact: every launch goes through `reaper SteamLaunch AppId=<id>`,
# so the running app id is right there in the process cmdline — no window
# matching, no heuristics, works for native and Proton alike.
detect_steam() {
    local pid argv0 cmd appid fallback_pid="" fallback_id=""
    for pid in $(pgrep -f 'SteamLaunch AppId=' 2>/dev/null); do
        [ -r "/proc/$pid/cmdline" ] || continue
        cmd="$(tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null)"
        appid="$(grep -oE 'AppId=[0-9]+' <<< "$cmd" | head -1 | cut -d= -f2)"
        [ -n "$appid" ] || continue

        # argv[0], not the whole line: any shell that merely *mentions* the
        # launch command in its own cmdline (a `bash -c`, a terminal running
        # the game by hand, this project's own test harness) matches the raw
        # pattern too and would be reported as the running game, outliving the
        # real process. Steam launches everything through `reaper`, so argv[0]
        # is what tells the launcher apart from something talking about it.
        argv0="$(basename "$(cut -d' ' -f1 <<< "$cmd")" 2>/dev/null)"
        if [ "$argv0" = "reaper" ]; then
            D_SOURCE="steam"; D_APPID="$appid"; D_PID="$pid"
            D_NAME="$(steam_app_name "$appid")"
            return 0
        fi
        case "$argv0" in
            bash|sh|zsh|fish|dash|pgrep|game_watch.sh) ;;
            *) [ -n "$fallback_pid" ] || { fallback_pid="$pid"; fallback_id="$appid"; } ;;
        esac
    done

    # No reaper (a game started straight from a .desktop or a custom script)
    # still counts, as long as the match isn't just a shell quoting the string.
    [ -n "$fallback_pid" ] || return 1
    D_SOURCE="steam"; D_APPID="$fallback_id"; D_PID="$fallback_pid"
    D_NAME="$(steam_app_name "$fallback_id")"
    return 0
}

# Heroic (Epic/GOG/Amazon). UNVERIFIED on this machine — Heroic has never been
# launched here, so there is no ~/.config/heroic to read and no live process to
# match. Written to fail closed: it only looks at wine/proton processes, and
# only claims one whose WINEPREFIX or HEROIC_APP_NAME actually points at a
# Heroic prefix, so the worst case is "no game detected", never a false one.
# Revisit against a real launch before trusting it.
detect_heroic() {
    pgrep -x heroic >/dev/null 2>&1 || return 1
    local pid env prefix name=""
    for pid in $(pgrep -f 'wine|proton' 2>/dev/null | head -20); do
        env="$(tr '\0' '\n' < "/proc/$pid/environ" 2>/dev/null)"
        [ -n "$env" ] || continue
        name="$(grep -m1 '^HEROIC_APP_NAME=' <<< "$env" | cut -d= -f2-)"
        prefix="$(grep -m1 '^WINEPREFIX=' <<< "$env" | cut -d= -f2-)"
        if [ -z "$name" ]; then
            case "$prefix" in
                *[Hh]eroic*) name="$(basename "$prefix")" ;;
                *) continue ;;
            esac
        fi
        [ -n "$name" ] || continue
        D_SOURCE="heroic"; D_APPID=""; D_PID="$pid"; D_NAME="$name"
        return 0
    done
    return 1
}

# Last resort for anything launched with gamemoderun (Lutris, Bottles, a
# hand-written .desktop). gamemoded knows the pid of every registered game;
# only queried when the daemon is already running, so this never activates it.
detect_gamemode() {
    pgrep -x gamemoded >/dev/null 2>&1 || return 1
    local pid comm
    pid="$(busctl --user --json=short call com.feralinteractive.GameMode \
            /com/feralinteractive/GameMode com.feralinteractive.GameMode ListGames \
            2>/dev/null | jq -r '.data[0][0][0] // empty' 2>/dev/null)"
    [ -n "$pid" ] || return 1
    [ -d "/proc/$pid" ] || return 1
    comm="$(cat "/proc/$pid/comm" 2>/dev/null)"
    [ -n "$comm" ] || return 1
    D_SOURCE="gamemode"; D_APPID=""; D_PID="$pid"; D_NAME="$comm"
    return 0
}

detect() {
    D_SOURCE=""; D_APPID=""; D_NAME=""; D_PID=""
    detect_steam || detect_heroic || detect_gamemode || return 1
    return 0
}

# ── Steam achievements ────────────────────────────────────────────────────
# There is no local source for these: userdata/<id>/<appid>/ holds only
# remotecache.vdf, and logs/stats_log.txt records stat *syncs* without ever
# naming an achievement. The Web API is the only way to know what unlocked.
declare -A SEEN
ACH_TOTAL=0
ACH_UNLOCKED=0
SCHEMA_FILE=""

ach_ready() { [ -n "$STEAM_KEY" ] && [ -n "$STEAM_ID" ] && [ "$D_SOURCE" = "steam" ]; }

ach_schema() {
    local appid=$1
    SCHEMA_FILE="$STATE/steam_schema_$appid.json"
    # Schemas are static; refresh weekly at most.
    if [ ! -s "$SCHEMA_FILE" ] || [ -n "$(find "$SCHEMA_FILE" -mtime +7 2>/dev/null)" ]; then
        curl -s --max-time 10 \
            "https://api.steampowered.com/ISteamUserStats/GetSchemaForGame/v2/?key=$STEAM_KEY&appid=$appid&l=english" \
            -o "$SCHEMA_FILE.tmp" 2>/dev/null
        if [ -s "$SCHEMA_FILE.tmp" ] && jq -e . "$SCHEMA_FILE.tmp" >/dev/null 2>&1; then
            mv "$SCHEMA_FILE.tmp" "$SCHEMA_FILE"
        else
            rm -f "$SCHEMA_FILE.tmp"
        fi
    fi
}

# baseline=1 records the already-unlocked set without emitting anything —
# otherwise every session start would flash every achievement ever earned.
ach_poll() {
    local baseline=${1:-0} json rows apiname display desc icon
    json="$(curl -s --max-time 10 \
        "https://api.steampowered.com/ISteamUserStats/GetPlayerAchievements/v1/?appid=$D_APPID&key=$STEAM_KEY&steamid=$STEAM_ID&l=english" \
        2>/dev/null)"
    jq -e '.playerstats.achievements' <<< "$json" >/dev/null 2>&1 || return 0

    ACH_TOTAL="$(jq -r '.playerstats.achievements | length' <<< "$json" 2>/dev/null)"
    ACH_UNLOCKED="$(jq -r '[.playerstats.achievements[] | select(.achieved == 1)] | length' <<< "$json" 2>/dev/null)"
    rows="$(jq -r '.playerstats.achievements[] | select(.achieved == 1) | .apiname' <<< "$json" 2>/dev/null)"

    while IFS= read -r apiname; do
        [ -n "$apiname" ] || continue
        [ -n "${SEEN[$apiname]:-}" ] && continue
        SEEN[$apiname]=1
        [ "$baseline" = "1" ] && continue

        display="$apiname"; desc=""; icon=""
        if [ -s "$SCHEMA_FILE" ]; then
            IFS=$'\t' read -r display desc icon <<< "$(jq -r --arg n "$apiname" \
                '.game.availableGameStats.achievements[]? | select(.name == $n)
                 | [(.displayName // $n), (.description // ""), (.icon // "")] | @tsv' \
                "$SCHEMA_FILE" 2>/dev/null)"
            [ -n "$display" ] || display="$apiname"
        fi

        jq -nc --arg name "$display" --arg description "$desc" --arg icon "$icon" \
               --argjson unlocked "${ACH_UNLOCKED:-0}" --argjson total "${ACH_TOTAL:-0}" \
               '{type:"achievement", name:$name, description:$description, icon:$icon,
                 unlocked:$unlocked, total:$total}'
    done <<< "$rows"
}

stats_log_stamp() {
    [ -n "$STEAM_ROOT" ] || { echo 0; return; }
    stat -c %Y "$STEAM_ROOT/logs/stats_log.txt" 2>/dev/null || echo 0
}

# ── Main loop ─────────────────────────────────────────────────────────────
CUR_KEY=""
LAST_ACH=0
LAST_STAMP=0

while true; do
    # Self-terminate once orphaned. Quickshell does not always reap a Process
    # child when its shell dies abruptly (a killed probe, a crash), and every
    # such orphan keeps polling forever — and would keep calling the Steam Web
    # API once a key is configured. A reparented process gets PPID 1, which is
    # the cheapest reliable "my shell is gone" signal. Read from /proc rather
    # than bash's $PPID, which is captured at startup and never updates.
    # /proc/$$, never /proc/self: inside a command substitution `self` is the
    # substituted command's own process, whose parent is this script — so the
    # check would compare against the wrong pid and never fire.
    if [ "$(cut -d' ' -f4 "/proc/$$/stat" 2>/dev/null)" = "1" ]; then
        exit 0
    fi

    read_conf

    if [ "$ENABLED" = "0" ]; then
        if [ -n "$CUR_KEY" ]; then
            printf '{"type":"session","active":false}\n'
            CUR_KEY=""
        fi
        sleep "$POLL"
        continue
    fi

    if detect; then
        key="$D_SOURCE:$D_APPID:$D_PID"
        if [ "$key" != "$CUR_KEY" ]; then
            # New session — resolve art and achievement baseline once, then
            # emit the single session line QML holds until this game exits.
            CUR_KEY="$key"
            SEEN=(); ACH_TOTAL=0; ACH_UNLOCKED=0; SCHEMA_FILE=""

            cover=""
            if [ "$D_SOURCE" = "steam" ]; then
                cover="$(steam_cover "$D_APPID")"
            else
                cover="$(sgdb_cover "$D_NAME")"
            fi

            if ach_ready; then
                ach_schema "$D_APPID"
                ach_poll 1 >/dev/null
                LAST_ACH="$(date +%s)"
                LAST_STAMP="$(stats_log_stamp)"
            fi

            jq -nc --arg source "$D_SOURCE" --arg appid "$D_APPID" --arg name "$D_NAME" \
                   --arg cover "$cover" --argjson startedAt "$(proc_start_epoch "$D_PID")" \
                   --argjson unlocked "${ACH_UNLOCKED:-0}" --argjson total "${ACH_TOTAL:-0}" \
                   '{type:"session", active:true, source:$source, appid:$appid, name:$name,
                     cover:$cover, startedAt:$startedAt, unlocked:$unlocked, total:$total}'
        elif ach_ready; then
            # Steam rewrites stats_log.txt when it syncs a game's stats, which
            # is what an unlock triggers — using its mtime as the "something
            # happened" signal turns a blind 60s poll into a near-immediate one
            # while keeping the API call count low.
            now="$(date +%s)"
            stamp="$(stats_log_stamp)"
            if [ "$stamp" != "$LAST_STAMP" ] || [ $(( now - LAST_ACH )) -ge "$ACH_POLL" ]; then
                LAST_STAMP="$stamp"
                LAST_ACH="$now"
                ach_poll 0
            fi
        fi
    elif [ -n "$CUR_KEY" ]; then
        CUR_KEY=""
        printf '{"type":"session","active":false}\n'
    fi

    sleep "$POLL"
done
