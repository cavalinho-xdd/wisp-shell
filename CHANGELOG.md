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
- Open activity island: media view (art, title, artist, source, progress with
  the ember as its head, controls) that kindles in block by block while the
  island morphs; the other islands dim; the inner light follows the ember.
- Notification flare: the centre island grows to show the app icon, name,
  summary and body of a new notification, the glow flares for a moment, then
  it falls back. Click runs the default action, middle click dismisses.
  Skipped over fullscreen and while an island is open. IPC `flash` fakes a
  notification for checking.
  Clicks inside an open island no longer close it.

### Changed
- `PRODUCT.md` and `DESIGN.md` rewritten for the Wisp Ember direction.
- `.gitignore` tracks the project docs explicitly instead of ignoring all
  Markdown.
