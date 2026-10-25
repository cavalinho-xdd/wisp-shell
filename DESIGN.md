---
name: Wisp Shell
description: A few floating islands for Hyprland, carried by one living light, the ember.
colors:
  smoke: "#0a0b0e"
  ash: "#15171c"
  ash-hi: "#20232a"
  text: "#eef0f4"
  muted: "#8a8f9b"
  ember-fallback: "#8fd3ff"
  error: "#f38ba8"
  success: "#a6e3a1"
  warning: "#f9e2af"
  discord-blurple: "#5865f2"
typography:
  body:
    fontFamily: '"Mona Sans", "Inter", "Noto Sans", sans-serif'
    fontSize: "13.5px"
    fontWeight: 400
  title:
    fontFamily: '"Mona Sans", "Inter", "Noto Sans", sans-serif'
    fontSize: "17px"
    fontWeight: 600
    letterSpacing: "-0.01em"
  label:
    fontFamily: '"Mona Sans", "Inter", "Noto Sans", sans-serif'
    fontSize: "11px"
    fontWeight: 500
    letterSpacing: "0.08em"
  mono:
    fontFamily: '"Monaspace Neon", "JetBrains Mono", monospace'
    fontSize: "14px"
    fontWeight: 500
rounded:
  island: "20px"
  island-open: "30px"
  tile: "18px"
  row: "14px"
  art: "16px"
spacing:
  xs: "6px"
  sm: "10px"
  md: "16px"
  lg: "20px"
components:
  island:
    backgroundColor: "{colors.smoke}"
    textColor: "{colors.text}"
    rounded: "{rounded.island}"
    height: "40px"
  island-open:
    backgroundColor: "{colors.smoke}"
    rounded: "{rounded.island-open}"
  tile:
    backgroundColor: "{colors.ash}"
    textColor: "{colors.text}"
    rounded: "{rounded.tile}"
    padding: "10px 12px"
  row:
    backgroundColor: "{colors.ash}"
    textColor: "{colors.muted}"
    rounded: "{rounded.row}"
    padding: "9px 12px"
  row-hover:
    backgroundColor: "{colors.ash-hi}"
---

# Design System: Wisp Shell

> **Status:** target specification for the "Wisp Ember" redesign (chosen 2026-10-25). The shipped code still uses the previous Material You / Catppuccin pill; this file describes where it is going. Values come from the clickable prototype (`.claude/skills/quickshell-wisp/references/ember-prototype.html`) and get tuned on the live shell. The QML mapping is in `.claude/skills/quickshell-wisp/references/ember-to-qml.md`.

## Overview

**Creative North Star: "A small living light."** Wisp is a will-o'-the-wisp: a few quiet, near-black islands floating at the top of the screen, lit from inside by one small light, the ember. At rest the ember breathes slowly. When music plays it pulses; when something happens it flares and its island grows to show it. Opening an island springs it open and the content *kindles*: it appears out of the light, from blurred and over-bright to sharp, instead of sliding in.

**Key characteristics:**
- **One borrowed colour.** Only the ember comes from the wallpaper; fill, greys and type are Wisp's own, so the shell adapts without becoming someone else's palette.
- **Islands, not a dashboard.** Each island owns one job and opens in place. No tabs.
- **Light instead of borders.** Islands separate from the desktop by their dark fill and a soft glow in the ember colour, never by outlines.

## Colors

### Primary
- **Ember** (wallpaper `primary` from matugen; fallback `#8fd3ff`): the signature light. Used for the ember dot, the glow around and inside islands, the active workspace, toggles that are on, the selected row indicator and the progress head. Nothing else takes it.

### Neutral
- **Smoke** (`#0a0b0e`): island fill. Opaque.
- **Ash** (`#15171c`): raised surfaces inside an open island (tiles, rows, search field).
- **Ash high** (`#20232a`): hover and inactive tile icon wells, slider track.
- **Text** (`#eef0f4`): primary text and icons.
- **Muted** (`#8a8f9b`): secondary text, labels, inactive icons.

### Semantic (fixed, never themed)
- **Error** (`#f38ba8`), **Success** (`#a6e3a1`), **Warning** (`#f9e2af`), **Discord blurple** (`#5865f2`): keep their meaning regardless of wallpaper.

### Named Rules
**The One Light Rule.** The ember colour appears only where something is alive or active. If an element isn't on, playing, selected or new, it doesn't glow.

**The Own Neutrals Rule.** Neutrals never follow the wallpaper. A wallpaper change animates the ember only.

## Typography

**UI font:** Mona Sans (fallbacks Inter, Noto Sans). **Numbers and clock:** Monaspace Neon, a monospace, so digits never jump. Chosen over Geist, which is too common (D2). Fonts are resolved from a preference list at startup (`Theme.pickFont`), never hardcoded.

### Hierarchy
- **Title** (17px, 600, −0.01em): track title, sub-panel title.
- **Body** (13.5px, 400–500): tile names, rows, messages.
- **Label** (11px, 500, uppercase, +0.08em): section labels such as "Output", "Input", media source.
- **Mono** (14px collapsed clock, 11–12.5px for times and battery).

### Named Rules
**The Few Sizes Rule.** Every size comes from the type tokens. No new pixel sizes in components.

## Layout

Three islands sit 12px below the top edge: **workspaces** on the left, the **activity island** (clock, media, notifications, launcher) in the centre, **status and controls** on the right. Collapsed islands are 40px tall and as wide as their content. Only one island is open at a time; the others dim and shrink slightly so it's clear where you are. A click outside or Esc closes everything. Islands hide entirely (and take no input) over fullscreen windows.

## Elevation & Depth

There are no drop shadows in the usual sense and no outlines. Depth comes from:
- the opaque smoke fill against the wallpaper and a faint inner top highlight (white at 6%);
- an **ember glow** around each island (ember at ~22% opacity, ~22px blur; open: ~26%, ~46px), scaled by the user's glow setting (soft 0.6 / medium 1.0 / strong 1.6);
- an **inner light**: a radial glow inside the island centred on the ember (~16% opacity).

## Shapes

Islands are rounded rectangles: 20px radius collapsed (a full capsule at 40px height), 30px open. Inside: tiles 18px, rows 14px, album art 16px, toggles and buttons fully round. Workspace indicators are 6px dots; the active one stretches to 20px and glows.

## Components

### The Ember (signature component)
An 8px dot in the ember colour with a soft glow, at the left of the activity island. States: **idle**, breathing (5s loop, opacity 0.55↔1, scale 0.85↔1); **playing**, pulsing (≈0.5s alternate); **event**, a single flare (scale up ~2.4× and brighten, 1.1s) just before its island grows to show the notification.

### Islands
- **Open morph:** width, height and radius spring to the open size (≈620ms, slight overshoot; spring or `BezierSpline [0.22, 1.18, 0.36, 1]`). Interruptible at any point.
- **Kindle reveal:** content blocks fade in from blur and brightness to sharp, rising 5px, 550ms, staggered 50ms, starting ~100ms after the morph begins.
- **Hover (collapsed):** scale to 1.04.
- **Dimmed (another island open):** opacity 0.35, scale 0.96, desaturated.

### Activity island contents
- **Collapsed:** ember, clock; with media playing, the track title in muted text.
- **Media:** 112px art, title, artist, source label, progress bar with a glowing ember head, previous / play-pause / next.
- **Notification:** grows briefly to show app and message, then falls back.
- **Launcher:** search field and up to five results; the selected row gets an ember icon well.

### Control centre (status island)
Four toggle tiles (Wi-Fi, Bluetooth, Do not disturb, Game mode) whose icon well fills with the ember when on; full-width volume and brightness sliders filled with a lightened ember; "Devices" opens a sound sub-view in the same island (output and input lists, selected row marked by a glowing dot) with a back button.

## Do's and Don'ts

### Do:
- **Do** let every surface grow out of the island that owns it.
- **Do** keep the ember for things that are alive or active.
- **Do** take every radius, size, spacing value and duration from tokens.
- **Do** make every animation interruptible.

### Don't:
- **Don't** put outlines or borders around islands.
- **Don't** add tabs inside an island.
- **Don't** theme the neutrals from the wallpaper.
- **Don't** animate the window surface size; animate the island inside it.
- **Don't** add continuous animation beyond the ember's breathing on the always-visible bar.
