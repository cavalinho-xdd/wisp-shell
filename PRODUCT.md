# Product

<!-- impeccable:product-schema 1 -->

## Platform

adaptive

## Users
Primary users are Linux enthusiasts and power users who want a clean, minimal Hyprland setup that stays out of the way. It also appeals to gamers who want deep integrations (osu!, Steam, Discord) on their desktop, and to ordinary users curious about a new way to do a desktop bar.

## Product Purpose
Wisp Shell replaces the traditional desktop bar on the Hyprland compositor with a few small floating islands. Each island shows one thing and opens into what you need for it: what is playing, what just happened, your connections and controls, or the launcher. It ships its own settings app, first-run wizard, launcher, lock screen and wallpaper picker, so you get a complete shell without assembling separate tools.

## Positioning
A shell that feels like a small living light rather than a toolbar. Most Hyprland shells are either a static bar plus separate drawers, or a dashboard of widgets. Wisp is a handful of islands that grow out of themselves when context asks for it, carrying one signature element, the ember, that tells you at a glance whether something is happening.

## Operating Context
Users run it inside Hyprland (0.55+ with the Lua config) on Linux. It integrates with Lua-based Hyprland config files, system services (PipeWire, BlueZ, NetworkManager, UPower, polkit, MPRIS, notifications) and gaming clients (Steam, osu!lazer, Discord). The full desktop setup lives in the companion repo wisp-dots; this repo also runs standalone on an existing Hyprland config.

## Capabilities and Constraints
- Built entirely in QML on Quickshell, with no build step; scripts handle what QML can't.
- Islands, not one pill: the top edge holds a few independent islands (workspaces, the centre activity island, status/controls). Each opens on its own; there are no tabs inside them.
- The Dynamic Island behaviour stays: live activities (media, notifications, games, voice calls, device events) take over the centre island by priority and fall back when they end.
- Integrations (Steam, Discord, osu!) work without user-written widget scripts.
- Settings changes write directly to the user's real dotfiles, without a sandbox layer.
- The pill and islands get out of the way of fullscreen windows (hidden, no input).
- Open decision: whether settings and the wallpaper picker move inside the islands or stay separate windows.

## Brand Commitments
- The name is binding: Wisp is a will-o'-the-wisp, a small floating light that appears and fades. The visual identity is built on that light (the "Wisp Ember" direction, chosen 2026-10-25).
- The ember is the signature element and the one colour taken from the wallpaper; everything else uses Wisp's own palette.
- A clickable prototype of the direction is the reference: `.claude/skills/quickshell-wisp/references/ember-prototype.html`.

## Evidence on Hand
- QML services in `core/`, views in `components/`, entry points `shell.qml`, `launcher.qml`, `settings.qml`, `lock.qml`, `wallpaper.qml`, `welcome.qml`.
- The Ember prototype (see above) and its QML mapping in `.claude/skills/quickshell-wisp/references/ember-to-qml.md`.
- No user research, usage numbers or testimonials exist; do not invent them.

## Product Principles
1. **Small until needed:** at rest Wisp is a few quiet islands; it only grows when there is something to show or do.
2. **Grow from where you clicked:** every surface opens out of the island that owns it, so you always know where you are and how to get back.
3. **One signature, used everywhere:** the ember light is the one element that makes Wisp recognisable; it adapts to the wallpaper but stays itself.
4. **Out-of-the-box utility:** integrations work immediately without configuration.
5. **Direct impact:** settings change the user's real files, visibly and reversibly.
