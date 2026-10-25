# Changelog

All notable changes to Wisp Shell. Format after
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions are git tags.

## [Unreleased]

### Added
- Wisp Ember design tokens in `core/Theme.qml` (colours, glow, geometry,
  spacing, type sizes, motion), alongside the current palette.
- Redesign plan (`docs/ember-plan.md`) and decision records (`docs/decisions/`).
- `scripts/lint.py`: qmllint with a warning baseline; fails only on new warnings.
- `scripts/shot.sh`: screenshot of the island area for PRs.
- `probes/` for Quickshell probes worth re-running; a PR template with the
  Definition of Done.

### Changed
- `PRODUCT.md` and `DESIGN.md` rewritten for the Wisp Ember direction.
- `.gitignore` tracks the project docs explicitly instead of ignoring all
  Markdown.
