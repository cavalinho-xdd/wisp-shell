# Changelog

All notable changes to Wisp Shell. Format after
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions are git tags.

## [Unreleased]

### Added
- Wisp Ember design tokens in `core/Theme.qml` (colours, glow, geometry,
  spacing, type sizes, motion), alongside the current palette.
- Redesign plan (`docs/ember-plan.md`) and decision records (`docs/decisions/`).
- `scripts/lint.py`: qmllint with a warning baseline; fails only on new warnings.
- `scripts/shot.sh`: screenshot of the island area for before/after checks.
- `probes/` for Quickshell probes worth re-running.
- Ember island skeleton (`components/ember/`): three empty islands with the
  ember glow, shown instead of the pill by *Settings → Shell → Ember islands
  (preview)*; one open at a time, closed by click outside or Esc; IPC target
  `ember-<monitor>` for opening islands from the command line.
- Collapsed activity island: breathing ember (beats while media plays), clock
  in Monaspace, track title elided at 120 px; inner ember light inside every
  island; islands swell slightly on hover. Glow strength setting
  (soft / medium / strong).

### Changed
- `PRODUCT.md` and `DESIGN.md` rewritten for the Wisp Ember direction.
- `.gitignore` tracks the project docs explicitly instead of ignoring all
  Markdown.
