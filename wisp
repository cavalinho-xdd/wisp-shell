#!/usr/bin/env bash
# wisp — launcher and control CLI for the Wisp shell.
#
# Shape follows iNiR's `inir` CLI, which is the most usable of the reference
# shells' front-ends: one verb per thing a user actually does, plus a `doctor`
# for "why isn't this working".
set -euo pipefail

# ── Where things are ───────────────────────────────────────────────────────
# WISP_SHELL_DIR is set by the packaged launcher; falling back to this
# script's own directory is what makes a plain git checkout work unmodified.
SELF_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
SHELL_DIR="${WISP_SHELL_DIR:-$SELF_DIR}"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/wisp"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/wisp"

QS="$(command -v qs || command -v quickshell || true)"

c_red=$'\033[31m'; c_grn=$'\033[32m'; c_yel=$'\033[33m'
c_dim=$'\033[2m';  c_bold=$'\033[1m'; c_rst=$'\033[0m'

die() { printf '%swisp:%s %s\n' "$c_red" "$c_rst" "$1" >&2; exit 1; }

# ── Bootstrap: directories, then migration, in that order ──────────────────
# Both must complete before Quickshell starts. core/Paths.qml also creates the
# directories, but asynchronously — doing it here is what actually guarantees
# the first settings write has somewhere to go.
bootstrap() {
    mkdir -p "$CONFIG_DIR" "$STATE_DIR/generated"

    # One-time migration from the pre-XDG layout, where state lived next to
    # shell.qml. `cp -n` never overwrites, so this is idempotent and cannot
    # clobber newer config. Only meaningful for checkouts that predate the
    # split; a fresh install finds nothing to move.
    [ -f "$SHELL_DIR/settings.json" ]  && cp -n "$SHELL_DIR/settings.json"  "$CONFIG_DIR/settings.json"  2>/dev/null || true
    [ -f "$SHELL_DIR/colors.json" ]    && cp -n "$SHELL_DIR/colors.json"    "$STATE_DIR/colors.json"     2>/dev/null || true
    [ -f "$SHELL_DIR/events.json" ]    && cp -n "$SHELL_DIR/events.json"    "$STATE_DIR/events.json"     2>/dev/null || true
    [ -f "$SHELL_DIR/app_usage.json" ] && cp -n "$SHELL_DIR/app_usage.json" "$STATE_DIR/app_usage.json"  2>/dev/null || true
    [ -d "$SHELL_DIR/generated" ]      && cp -rn "$SHELL_DIR/generated/." "$STATE_DIR/generated/"        2>/dev/null || true
    return 0
}

entry() { echo "$SHELL_DIR/$1.qml"; }

run_entry() {
    [ -n "$QS" ] || die "quickshell not found in PATH (install 'quickshell')"
    local f; f="$(entry "$1")"
    [ -f "$f" ] || die "missing $f — is WISP_SHELL_DIR correct?"
    shift
    bootstrap
    exec "$QS" -p "$f" "$@"
}

running_pids() { pgrep -f "$SHELL_DIR/shell.qml" 2>/dev/null || true; }

# ── doctor ─────────────────────────────────────────────────────────────────
# Same dependency set the welcome wizard's last step checks, in headless form,
# so the installer and the GUI agree on what "ready" means.
doctor() {
    local fail=0 warn=0
    printf '%sWisp doctor%s\n\n' "$c_bold" "$c_rst"
    printf '  shell dir   %s\n' "$SHELL_DIR"
    printf '  config      %s\n' "$CONFIG_DIR"
    printf '  state       %s\n\n' "$STATE_DIR"

    # `chk` needs ALL of the listed binaries; `chk_any` needs at least one
    # (swww and hyprpaper are alternatives, not a pair).
    chk_any() {
        local name=$1 level=$2 desc=$3; shift 3
        for b in "$@"; do
            if command -v "$b" >/dev/null 2>&1; then
                printf '  %s✓%s %-22s %s%s (%s)%s\n' "$c_grn" "$c_rst" "$name" "$c_dim" "$desc" "$b" "$c_rst"; return 0
            fi
        done
        printf '  %s!%s %-22s %snone of: %s — %s%s\n' "$c_yel" "$c_rst" "$name" "$c_yel" "$*" "$desc" "$c_rst"
        warn=$((warn+1))
    }

    chk() { # name, level(req|opt), what-breaks, binaries...
        local name=$1 level=$2 desc=$3; shift 3
        local missing=()
        for b in "$@"; do command -v "$b" >/dev/null 2>&1 || missing+=("$b"); done
        if [ ${#missing[@]} -eq 0 ]; then
            printf '  %s✓%s %-22s %s%s%s\n' "$c_grn" "$c_rst" "$name" "$c_dim" "$desc" "$c_rst"
        elif [ "$level" = req ]; then
            printf '  %s✗%s %-22s %smissing: %s%s\n' "$c_red" "$c_rst" "$name" "$c_red" "${missing[*]}" "$c_rst"
            fail=$((fail+1))
        else
            printf '  %s!%s %-22s %smissing: %s — %s%s\n' "$c_yel" "$c_rst" "$name" "$c_yel" "${missing[*]}" "$desc" "$c_rst"
            warn=$((warn+1))
        fi
    }

    chk "quickshell"  req "the shell itself"                        qs
    chk "Hyprland"    req "settings, keybinds, window rules"         hyprctl
    chk "matugen+jq"  opt "wallpaper-derived colours"                matugen jq
    chk_any "wallpaper" opt "setting the wallpaper"                  swww hyprpaper
    chk "qalc"        opt "launcher calculator"                      qalc
    chk "wl-clipboard" opt "copy actions"                            wl-copy
    chk "nvidia-smi"  opt "GPU ring (Nvidia only)"                   nvidia-smi
    chk "bc"          opt "CPU/RAM readouts"                         bc
    chk "terminal"    opt "launching terminal apps"                  kitty
    chk "xdg-utils"   opt "opening files and folders"                xdg-open xdg-user-dir

    # Fonts: the shell resolves these at runtime and falls back silently, which
    # is exactly why they are worth checking explicitly here.
    printf '\n'
    # Herestrings, not pipes. Under `set -o pipefail`, `... | grep -q` exits on
    # the first match and closes the pipe, the writer dies of SIGPIPE, and the
    # pipeline then reports failure *because it matched* — which inverted every
    # font check on a machine that had the fonts installed. `<<<` has no
    # pipeline for pipefail to poison.
    local fonts=""; fonts="$(fc-list 2>/dev/null || true)"
    if grep -qi "nerd font" <<< "$fonts"; then
        printf '  %s✓%s %-22s %sicon glyphs%s\n' "$c_grn" "$c_rst" "Nerd Font" "$c_dim" "$c_rst"
    else
        printf '  %s✗%s %-22s %snone installed — every icon renders as a box%s\n' "$c_red" "$c_rst" "Nerd Font" "$c_red" "$c_rst"
        fail=$((fail+1))
    fi
    if grep -qiE "google sans|inter|rubik" <<< "$fonts"; then
        printf '  %s✓%s %-22s %sbody text%s\n' "$c_grn" "$c_rst" "UI font" "$c_dim" "$c_rst"
    else
        printf '  %s!%s %-22s %sfalling back to the system sans%s\n' "$c_yel" "$c_rst" "UI font" "$c_yel" "$c_rst"
        warn=$((warn+1))
    fi

    printf '\n'
    if [ "$fail" -gt 0 ]; then
        printf '  %s%d required missing%s, %d optional\n' "$c_red" "$fail" "$c_rst" "$warn"; return 1
    fi
    printf '  %sready%s%s\n' "$c_grn" "$c_rst" "$([ "$warn" -gt 0 ] && echo " — $warn optional missing" || echo "")"
}

status() {
    local pids; pids="$(running_pids)"
    if [ -n "$pids" ]; then
        printf '  %s●%s running   pid %s\n' "$c_grn" "$c_rst" "$(echo "$pids" | tr '\n' ' ')"
    else
        printf '  %s○%s stopped\n' "$c_dim" "$c_rst"
    fi
    printf '  shell dir   %s\n' "$SHELL_DIR"
    printf '  config      %s\n' "$CONFIG_DIR/settings.json"
    printf '  state       %s\n' "$STATE_DIR"
    [ -n "${WAYLAND_DISPLAY:-}" ] || printf '  %s!%s not in a Wayland session\n' "$c_yel" "$c_rst"
}

usage() {
    cat <<EOF
${c_bold}wisp${c_rst} — Quickshell desktop shell for Hyprland

  ${c_bold}wisp run${c_rst}          Start the shell (foreground)
  ${c_bold}wisp start${c_rst}        Start the shell detached
  ${c_bold}wisp stop${c_rst}         Stop the running shell
  ${c_bold}wisp restart${c_rst}      Stop, then start detached
  ${c_bold}wisp status${c_rst}       Is it running, and where its files are
  ${c_bold}wisp doctor${c_rst}       Check dependencies and fonts

  ${c_bold}wisp settings${c_rst}     Open the settings app
  ${c_bold}wisp welcome${c_rst}      Re-run the first-run setup wizard
  ${c_bold}wisp wallpaper${c_rst}    Open the wallpaper picker
  ${c_bold}wisp launcher${c_rst}     Open the app launcher
  ${c_bold}wisp lock${c_rst}         ${c_yel}Lock the session immediately${c_rst}

  ${c_bold}wisp config${c_rst}       Print the config file path
  ${c_bold}wisp logs${c_rst}         Follow the Quickshell log

Environment:
  WISP_SHELL_DIR   where the QML lives (default: this script's directory)
EOF
}

case "${1:-}" in
    run)        shift; run_entry shell "$@" ;;
    settings)   shift; run_entry settings "$@" ;;
    welcome)    shift; run_entry welcome "$@" ;;
    wallpaper)  shift; run_entry wallpaper "$@" ;;
    launcher)   shift; run_entry launcher "$@" ;;
    lock)       shift; run_entry lock "$@" ;;

    start)
        [ -z "$(running_pids)" ] || die "already running (wisp restart to replace it)"
        [ -n "$QS" ] || die "quickshell not found in PATH"
        bootstrap
        setsid "$QS" -p "$(entry shell)" >/dev/null 2>&1 < /dev/null &
        sleep 0.4; status ;;
    stop)
        pids="$(running_pids)"
        [ -n "$pids" ] || die "not running"
        echo "$pids" | xargs -r kill
        echo "stopped" ;;
    restart)
        pids="$(running_pids)"; [ -n "$pids" ] && echo "$pids" | xargs -r kill && sleep 0.5
        exec "$0" start ;;

    status)  status ;;
    doctor)  doctor ;;
    config)  echo "$CONFIG_DIR/settings.json" ;;
    logs)
        d="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/quickshell"
        f="$(find "$d" -name '*.qslog' -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)"
        [ -n "$f" ] || die "no log found under $d"
        echo "$f" >&2; tail -f "$f" ;;

    ""|-h|--help|help) usage ;;
    *) printf '%swisp:%s unknown command "%s"\n\n' "$c_red" "$c_rst" "$1" >&2; usage; exit 1 ;;
esac
