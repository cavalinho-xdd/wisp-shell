# Wisp Ember — redesign plan

Roadmap for replacing the pill with the Wisp Ember islands. What the result
looks like is in `DESIGN.md`; how it maps to QML is in
`.claude/skills/quickshell-wisp/references/ember-to-qml.md`; why we chose what
we chose is in `docs/decisions/`. This file only says **in what order** and
**when a step counts as done**. Update the status column in the same commit
that finishes a milestone.

## Principles

- **Build beside, switch late.** The islands live in their own files behind a
  setting; the old pill keeps working until M9 (ADR 0002).
- **One island end-to-end before the next.** Collapsed → open → interrupted →
  closed, shown live, then move on.
- **Small milestones, each shippable.** Work goes straight to `main` in small
  commits (single developer, no PRs); every commit leaves the shell usable
  with the setting both on and off.
- **Decide before building.** Open questions block the milestone that needs
  them, not the whole project (see *Open decisions*).

## Milestones

| # | Milestone | Status |
|---|---|---|
| M0 | Ember tokens in `core/Theme.qml` | ✅ done (c13f482) |
| M1 | Development basics | ✅ done |
| M2 | Island skeleton | ✅ done (e43fe9d) |
| M3 | Activity island, collapsed | ✅ done (db0e752) |
| M4 | Activity island, open (media) | ✅ done (46e87ae) |
| M5 | Notifications and launcher | ⬜ |
| M6 | Workspaces island (left) | ⬜ |
| M7 | Status island and control centre (right) | ⬜ |
| M8 | Remaining features of the old pill | ⬜ |
| M9 | Switch over and clean up | ⬜ |

### M1 — Development basics
Goal: make every later milestone cheaper to build and check.
- `.qmlls.ini` next to `shell.qml` (`touch` it once; Quickshell turns it into
  a link to its tooling VFS on the next start; git-ignored) so the editor
  shows qmllint warnings live.
- `scripts/lint.py`: Qt 6 qmllint over every `.qml` with a baseline of
  today's warnings (681, `scripts/lint-baseline.txt`); fails only on new ones.
- `scripts/shot.sh <name>`: grim screenshot of the island area of every
  monitor into `docs/screens/` (git-ignored) — before/after evidence for a
  visible change.
- `probes/` folder for probe files worth re-running (tracked, left out of the
  package); the stray `test_*` files from the root moved there.
- `CHANGELOG.md` (Keep a Changelog), section *Unreleased*.
- GitHub milestones M1–M9 mirror the table above (D4); a milestone is closed
  when it is done. Tasks stay in this file.

Done when: lint and screenshot scripts run on this machine, the root holds no
stray test files.

### M2 — Island skeleton
Goal: the frame every island lives in.
- New `components/ember/` with one `IslandsWindow` per screen (inside the
  existing `Variants`), shown when `Settings.conf.shell.ember` is on, old pill
  hidden instead.
- Three empty islands (smoke fill, collapsed size, glow), centred layout as in
  `DESIGN.md`.
- Input mask = the three islands only; empty mask over fullscreen.
- One controller with an explicit state: which island is open (`none | left |
  center | right`). Click outside / Esc closes. Owned per screen.
- Setting switch in the settings app.

Done when: toggling the setting swaps old pill ↔ islands live on both
monitors; clicks pass through between islands; fullscreen hides them.

### M3 — Activity island, collapsed
Ember dot (breathing), clock in mono, track title when media plays, hover
scale. Glow and inner light tuned live against two very different wallpapers.

Left over from M3: glow strength not yet judged against two very different
wallpapers; do it whenever the wallpaper changes, adjust `Theme.glow*`.

### M4 — Activity island, open (media)
Morph (geometry spring), kindle reveal of content, dimming of the other two
islands. Media view: art, title, artist, source, progress with ember head,
controls. Interrupting open/close at any point must look right.

### M5 — Notifications and launcher
Ember flare + island grows for a notification, then falls back. Launcher in the
centre island (search field, five results, keyboard), opened by the existing
IPC call. Fixes the known bug that every monitor opens the launcher.

### M6 — Workspaces island
Workspace dots, active one stretched and glowing, click to switch
(`hl.dsp.focus`). Per monitor.

### M7 — Status island and control centre
Collapsed status icons. Open: toggle tiles, volume and brightness sliders,
sound sub-view with back button. Needs decision D1.

### M8 — Remaining features
Everything from the inventory below that has a home after D1 and is not built
yet. OSD and polkit dialog restyled with the Ember tokens.

### M9 — Switch over and clean up
Islands become the default, the setting is removed, the old pill files are
deleted, unused old tokens removed from `Theme.qml`, `DESIGN.md` refreshed
(`impeccable document`), release tagged.

## Definition of Done (every milestone)

- [ ] Ran under `qs`; `qs log` has no new warnings or errors.
- [ ] `scripts/lint.py` adds no new qmllint warnings (from M1 on).
- [ ] Checked on both monitors and with the setting on and off.
- [ ] No raw durations, radii, spacing or font sizes — tokens only.
- [ ] Every animation survives being interrupted halfway.
- [ ] Worst-case data tried where the view shows outside data (`break-ui`).
- [ ] Before/after screenshot (`scripts/shot.sh`) compared.
- [ ] `qt-qml-review` findings fixed or noted in the commit message.
- [ ] CHANGELOG and the status column above updated.

## Inventory: what the old pill does today

Where each feature goes in Ember. *Proposal* rows are not decided yet (D1).

| Feature (today) | Where it lives now | Ember home | Milestone |
|---|---|---|---|
| Workspaces | `CollapsedBar` | left island | M6 |
| Clock | `CollapsedBar` | centre, collapsed | M3 |
| Media strip, media card | `IslandMediaStrip`, `MediaCard` | centre, collapsed + open | M3–M4 |
| Notification flash | `IslandNotifFlash` | centre, flare | M5 |
| Notification list | Dashboard tab | centre, open view — *proposal* | M8 |
| Launcher | `IslandLauncher` | centre | M5 |
| osu / Discord / game strips | `Island*Strip` | centre, collapsed (context) — *proposal* | M8 |
| Battery, network, Bluetooth, USB strips | `Island*Strip` | right, collapsed icons; events flash in centre — *proposal* | M7 |
| Quick toggles, volume, mic, brightness | Dashboard tab | right, control centre | M7 |
| Wi-Fi, Bluetooth, audio sub-views | StackView pushes | right, sub-views | M7–M8 |
| Power menu (lock, log out, restart, shut down) | Dashboard tab | right, control centre — *proposal* | M7 |
| Tray | Dashboard tab | right — *proposal* | M8 |
| Weather, calendar | Widgets tab | centre, opened from the clock — *proposal* | M8 |
| Performance | Performance tab | **open** — right, centre or dropped | M8 |
| OSD | own window | restyle only | M8 |
| Polkit dialog | own window | restyle only | M8 |
| Lock, settings, welcome, wallpaper | own apps | out of scope (later pass) | — |

## Open decisions

| ID | Question | Blocks |
|---|---|---|
| D1 | Final homes for the *proposal* rows and the Performance view | M7 |

Decided (2026-10-25):
- D2 — Mona Sans + Monaspace Neon (compared live with Noto/JetBrains,
  Atkinson Hyperlegible, Overpass; Geist rejected as overused).
- D3 — glow strength is a user setting (soft / medium / strong).
- D4 — GitHub milestones only, no issues.
