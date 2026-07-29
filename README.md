<div align="center">
  <h1>Wisp Shell</h1>
  <p>A floating, expanding pill-based desktop shell for Hyprland, built on Quickshell.</p>
  <a href="#installation">Installation</a> •
  <a href="#the-dynamic-island">Dynamic Island</a> •
  <a href="#what-works-out-of-the-box-vs-what-needs-setup">Manual Setup</a> •
  <a href="#usage">Usage</a>
</div>

<br>

Wisp Shell replaces the traditional desktop bar with a single floating pill: collapsed it's a slim status strip, click it and it expands into a full dashboard (media, widgets, performance). It ships its own settings app, first-run wizard, launcher, lock screen and wallpaper picker — all separate Quickshell entry points sharing one `core/`/`components/` tree.

This repo is the shell itself: QML + the scripts it shells out to, plus the `wisp` CLI and `./setup` installer. It has no build system and no bundled Hyprland config — that half lives in [wisp-dots](https://github.com/cavalinho-xdd/wisp-dots), which pulls this repo in as a dependency and wires up the Hyprland side (autostart, keybinds, window rules) automatically. You can also run this repo standalone against your own Hyprland config; see [Manual / standalone installation](#manual--standalone-installation).

## Table of Contents
- [Installation](#installation)
  - [Recommended: with wisp-dots](#recommended-with-wisp-dots)
  - [Manual / standalone installation](#manual--standalone-installation)
  - [Dependencies](#dependencies)
- [The Dynamic Island](#the-dynamic-island)
- [What works out of the box vs. what needs setup](#what-works-out-of-the-box-vs-what-needs-setup)
- [Usage](#usage)
- [Settings app writes your real dotfiles](#settings-app-writes-your-real-dotfiles)
- [Architecture](#architecture)
- [Troubleshooting](#troubleshooting)
- [License](#license)

## Installation

### Recommended: with wisp-dots
[wisp-dots](https://github.com/cavalinho-xdd/wisp-dots) is the full desktop setup: a generic (no monitor-name assumptions), Lua-based Hyprland config written specifically for this shell, Fish/Kitty/Btop/Fastfetch/Micro configs, a Matugen wallpaper-theming pipeline, and this repo bootstrapped as a dependency.

```bash
git clone https://github.com/cavalinho-xdd/wisp-dots.git ~/.config/wisp-dots
cd ~/.config/wisp-dots
./install.sh
```
That single command installs every package (Hyprland included), clones this repo to `~/.local/share/wisp-shell` and runs its `./setup install`, deploys all dotfiles, generates your first color scheme, and reloads Hyprland. Reboot (or log out/in) once it finishes. This is the only path that gives you working keybinds (`SUPER+E` file manager, `SUPER+Space` launcher, `SUPER+Return` terminal, workspace/window binds, hardware volume/brightness keys) and the `hyprctl` autostart line that launches the shell every login — see [Settings app writes your real dotfiles](#settings-app-writes-your-real-dotfiles) for why that Hyprland config has to be Lua, specifically.

### Manual / standalone installation
If you already have your own Hyprland config and just want the shell:
```bash
git clone https://github.com/cavalinho-xdd/wisp-shell.git ~/.local/share/wisp-shell
cd ~/.local/share/wisp-shell
./setup install
```
This installs the packages below (bootstrapping `paru` from the AUR automatically if neither `paru` nor `yay` is present), copies the QML/scripts to `~/.local/share/wisp-shell`, symlinks the `wisp` CLI into `~/.local/bin`, and adds that directory to your `systemd --user` `PATH` (both for future logins and this session).

You'll then need to add, to your own `hyprland.conf`/Lua config:
- An autostart line: `exec-once = wisp start` (classic syntax) or the Lua equivalent `hl.exec_cmd("$HOME/.local/bin/wisp start")` on `hl.on("hyprland.start", ...)` — a bare `wisp` in Hyprland's own exec environment can silently fail since `~/.local/bin` isn't guaranteed on its PATH; the absolute path always works.
- A launcher keybind, e.g. `SUPER, Space, exec, wisp launcher` (or the Lua `hl.dsp.exec_cmd("$HOME/.local/bin/wisp launcher")`) — `wisp launcher` toggles (opens if closed, closes if already open), it isn't just a launch.

Run `wisp doctor` any time to check what's missing.

### Dependencies
`./setup install` installs all of these for you (see the table below for what each one is for). If you're setting up manually, install them yourself first.

| Dependency | Required for |
|---|---|
| `hyprland` | The compositor |
| `quickshell` (AUR) | The shell itself |
| `python` (`python3`) | Settings > Look & Feel / Keybinds — every edit shells out to a Python script that rewrites your real Hyprland `.lua` files |
| `nodejs` (`node`) | The osu! island lane — spawned unconditionally at startup, harmless (just idles, retrying a closed socket) if you don't play osu! |
| `jq`, `bc` | Parsing `hyprctl`/JSON output, CPU/RAM math |
| `curl` | Weather card, Steam cover art + achievement lookups |
| `upower` | Battery widget (auto-hidden on desktops with no battery) |
| `xdg-user-dirs` | Locale-correct default wallpaper folder |
| `wl-clipboard`, `cliphist` | Copy actions, clipboard history |
| `grim`, `slurp` | Screenshot tooling |
| `matugen-bin` (AUR) | Wallpaper-derived Material You color scheme |
| `awww` | Wallpaper daemon (`swww`/`hyprpaper` also work, detected as fallbacks) |
| `libnotify` | Sending Wisp's own desktop notifications |

Run `./setup deps` to (re-)install just this list, or `wisp doctor` to see what's actually present on your machine right now, including optional-only items like `nvidia-smi` (GPU ring) and `qalc` (launcher calculator).

## The Dynamic Island
The collapsed pill has one content lane that arbitrates between everything competing for it (`core/Island.qml`), highest priority first:

1. **Notification flash** — any incoming notification, 5s (8s if critical).
2. **Running game** — Steam/Heroic/gamemode session (`core/Games.qml` + `scripts/game_watch.sh`): shows the game's cover art and a live session timer the moment it launches, no configuration needed. An achievement unlock swaps the strip's own face for a few seconds, including while the game is fullscreen.
3. **osu!** — live PP/combo/accuracy while osu!lazer is running (`core/Osu.qml` + `scripts/osu_connect.js`, via [tosu](https://github.com/KotRikD/tosu)'s local websocket API).
4. **Media** — whatever's playing via MPRIS, lingers 15s after pause so you can resume from the bar.
5. **Discord voice** — you're in a voice call (`core/Discord.qml`, detected purely from a Pipewire audio-capture node — no Discord API involved), with mute/deafen/leave buttons that send Discord's own keyboard shortcuts to its window.
6. **None** — the plain collapsed pill (clock, workspaces, tray).

Each of these degrades independently and silently: no Steam running, no osu!lazer, no active call, no media player — the lane simply never activates, nothing errors, nothing polls harder than it needs to.

## What works out of the box vs. what needs setup

**Works immediately, zero configuration:**
- Media controls, notifications, system tray, polkit auth prompts, volume/mic OSD, battery widget (if you have one).
- Game detection + session timer + Steam cover art, for anything launched through Steam (native or Proton) — reads the running process, no key needed.
- Discord voice indicator + mute/deafen/leave — works against Vesktop or any Discord client, no key or bot needed.
- osu! live stats, as soon as osu!lazer + [tosu](https://github.com/KotRikD/tosu) are both running (tosu isn't installed by `./setup` — grab it separately, it's the memory-reading bridge osu!lazer itself doesn't provide).
- Weather card (IP-geolocated, via `open-meteo.com`, no key).
- Settings > Look & Feel and Settings > Keybinds — these write directly into your real `~/.config/hypr/*.lua`, no separate "apply"/"save" step, no sandbox layer to fight with.

**Needs a one-time manual step:**
| Feature | What to do |
|---|---|
| Steam achievement popups | Get a free key at [steamcommunity.com/dev/apikey](https://steamcommunity.com/dev/apikey) (your profile's "Game details" must be Public), paste it into Settings > Games. Without it you still get the game strip + timer, just no achievement flashes — there is no local source for unlock events, the Web API is the only one. |
| Cover art for Heroic (Epic/GOG/Amazon) games | Steam's CDN only covers Steam titles. Get a free [SteamGridDB](https://www.steamgriddb.com/) API key and paste it into Settings > Games for cover art on non-Steam launchers. |
| Discord keybind actions | Mute/deafen use Discord's factory-default shortcuts and work as shipped. "Disconnect from voice" has no default shortcut in Discord — bind one yourself and set it in Settings > Discord. |
| Terminal recoloring on wallpaper change | Settings > Colors can fan the palette out to Kitty directly, or (any terminal) via OSC escapes — the latter needs one line added to your shell's own rc file; Settings shows you the exact line and path to add. |
| osu! integration | Install [tosu](https://github.com/KotRikD/tosu) yourself and have it running alongside osu!lazer — this repo only ships the client that talks to it. |

## Usage
```bash
wisp start      # Start the shell (detached)
wisp stop       # Stop it
wisp restart    # Stop, then start
wisp status     # Is it running, and where its files are
wisp doctor     # Dependency + font check

wisp settings   # Open the settings app
wisp welcome    # Re-run the first-run setup wizard
wisp wallpaper  # Open the wallpaper picker
wisp launcher   # Open (or close, if already open) the app launcher
wisp lock       # Lock the session immediately

wisp config     # Print the settings.json path
wisp logs       # Follow the live Quickshell log
```
The first time `wisp start` ever runs on a machine, it launches the first-run wizard automatically (`core/FirstRun.qml`) — re-run it any time with `wisp welcome`, or from Settings > Advanced > "Show welcome screen again".

## Settings app writes your real dotfiles
There is **no sandbox and no separate "apply" layer**: Settings > Look & Feel edits `general.lua`/`animations.lua` in place (`scripts/apply_hypr_look.py`), Settings > Keybinds rewrites the matching `hl.bind("KEY", ...)` line wherever it's declared (`scripts/apply_hypr_keybind.py`), and new keybinds you add are written to `keybinds_custom.lua` (`scripts/write_custom_keybinds.py`) — each followed by `hyprctl reload`. What you see in Settings **is** your config on disk; a reload does not undo it.

This only works against a Hyprland config written in Lua against the `hl.*` API (Hyprland >= 0.55's Lua config layer) — the file *shape* matters: renaming `gaps_in`, restructuring the `blur = {...}` table, or writing binds across multiple lines will make Settings unable to find what it's looking for. wisp-dots' config is written to match this exactly; if you're on a hand-rolled classic `.conf` config instead, Settings' Look & Feel/Keybinds pages won't have anything to edit.

## Architecture
- `core/` — singleton services: `Settings` (config + Hyprland file writes), `Theme` (fonts/colors), `Island` (dynamic-island arbitration), `Audio`/`Battery`/`Notifs`/`Osd` (hardware/system state), `Discord`/`Games`/`Osu` (the three island integrations above), `Paths` (where every file lives), `FirstRun`.
- `components/` — UI: `ExpandedDashboard.qml` (the 4-tab dashboard), `CollapsedBar.qml` + the `Island*Strip.qml` components (the collapsed pill's content lane), `Settings*`/`Welcome*` (the settings app and first-run wizard pages).
- `scripts/` — everything shelled out to: Hyprland config writers, `game_watch.sh`/`osu_connect.js` (the two island data feeds), `apply_colors.sh` (Matugen), `weather.sh`, `sysmon_snapshot.sh`.
- Entry points (`shell.qml`, `settings.qml`, `launcher.qml`, `lock.qml`, `wallpaper.qml`, `welcome.qml`) are separate processes sharing `core/`/`components/` but nothing at runtime.

## Troubleshooting
- **Nothing launches on login.** Confirm the autostart line actually ran: `wisp status`. If it says stopped, check `wisp logs`, and confirm `~/.local/bin` is really on the PATH Hyprland's exec environment sees — `./setup install`/wisp-dots' installer both add an `environment.d` entry for this, but it only takes effect for a compositor session started *after* that file existed (log out/in, or reboot, once after first install).
- **Icons render as boxes / text looks wrong.** Run `wisp doctor` — it checks for a Nerd Font and a body-text font and tells you which is missing, same check the first-run wizard's last step runs.
- **A Settings page (Look & Feel/Keybinds) doesn't seem to do anything.** See [Settings app writes your real dotfiles](#settings-app-writes-your-real-dotfiles) above — it needs a Lua-based Hyprland config in the expected shape.
- **`SUPER+Space` doesn't open the launcher.** Only one bind for it should exist. If you've hand-edited your Hyprland config and it's still not working, check `hyprctl binds -j` for duplicate `SPACE`/`SUPER` entries — Hyprland keeps overlapping binds all live simultaneously rather than the later one winning.

## License
This project is licensed under the MIT License.
