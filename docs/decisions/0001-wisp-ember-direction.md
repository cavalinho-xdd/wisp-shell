# 0001 — Wisp Ember as the design direction

- **Status:** Accepted
- **Date:** 2026-10-25

## Context
The shell is one floating pill that expands into a tabbed dashboard, coloured
from the wallpaper (Material You) with a Catppuccin fallback. Several
directions were prototyped in HTML.

## Decision
Wisp Ember: three opaque near-black islands at the top edge (workspaces,
activity, status). Only the ember light takes its colour from the wallpaper;
neutrals are Wisp's own. Each island opens its own content, no tabs. Opening
springs the island and the content "kindles" in. Spec: `DESIGN.md`; prototype:
`.claude/skills/quickshell-wisp/references/ember-prototype.html`.

## Consequences
- Most of `components/` is rebuilt, not restyled.
- The tabbed dashboard goes away, so every tab's content needs a new home
  (see the inventory in `docs/ember-plan.md`).
- Glow effects add GPU work on an always-visible surface; budget it per island.
- Wallpaper changes now affect one colour, not the whole palette.
