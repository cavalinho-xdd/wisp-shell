---
name: quickshell-wisp
description: >-
  How to write, debug and redesign Wisp Shell — a Quickshell (QML, Qt 6) desktop
  shell for Hyprland's Lua config. Covers Quickshell's own types (PanelWindow /
  WlrLayershell, Variants per screen, Region masks, IpcHandler, Process,
  FileView, LazyLoader, BackgroundEffect), running and reloading the shell with
  `qs`, Hyprland Lua dispatch from QML, the project's hard-won crash and
  silent-failure lessons, and how the "Wisp Ember" island design translates to
  QML (springs, glow, kindle reveal, per-island masks). Use whenever a task
  touches .qml files in this repo, the pill/islands, layer-shell windows,
  animations in the shell, `qs`/`wisp` commands or Hyprland integration. Load
  it first: its "Which skill when" table says which other skill (qt-qml,
  qt-qml-review, qt-ui-design, qt-qml-profiler, emil-design-eng, apple-design,
  animate, improve-animations, find-animation-opportunities, review-animations,
  break-ui, prototype, impeccable, design-taste-frontend, superpowers) to load
  next for the task at hand.
---

# Quickshell for Wisp

Wisp is a Quickshell config, not a Qt app: there is no build step, `qs` loads
`shell.qml` and live-reloads on save. Facts below were checked against the
local toolchain (Quickshell 0.3.2, Qt 6.12, Hyprland 0.56 with the Lua config)
and the Quickshell source in `~/coding/quickshell/src`. When in doubt, read the
`///` doc comments in that source — it is the real documentation and it is
version-matched. `references/gotchas.md` lists the project's own crash and
silent-failure lessons; read it before touching `shell.qml`, `core/Settings.qml`,
`core/Paths.qml`, `core/Notifs.qml` or anything that shells out.
`references/ember-to-qml.md` maps the approved Wisp Ember design to QML.

## Ground rules

1. **Read before you change.** Every non-obvious line in this repo carries a
   comment explaining a crash or a silent failure it prevents. Do not
   "simplify" code whose comment says not to; if you think the comment is
   stale, prove it with a probe first.
2. **Verify on the live shell.** A change is not done until it ran under `qs`.
   QML errors often do not crash — they log a warning and the item just
   doesn't appear. Check the log every time (see *Run and debug*).
3. **Other skills are loaded by the table below, not by habit.** When two
   skills disagree, this order wins: this skill and its `references/` (they
   know Quickshell and this repo) → `qt-qml` (QML) → the web design/motion
   skills (taste only; their CSS/React mechanics do not apply).
4. **Tokens, not numbers.** Colours already go through `Theme` (keep it that
   way). New code must also take radii, spacing, type sizes and motion from
   tokens; never add a raw `duration:` / `radius:` / `pixelSize:` number.
5. **One owner per piece of state.** Services live in `core/` singletons; views
   in `components/` only read them. A DBus server, timer or Process that must
   survive the pill collapsing belongs in a singleton, never in a view that is
   created and destroyed with the dashboard.

## Which skill when

Load the listed skill with the Skill tool at the moment the trigger happens,
on top of this one. Two skills are **user-only** (`disable-model-invocation`):
you cannot load them — tell the user to type the slash command.

### Writing and checking QML

| Trigger | Load | Notes |
|---|---|---|
| About to write or edit any `.qml` / `.js` in this repo | `qt-qml` | Always, for the whole edit. Ignore its i18n/qsTr and C++-backend advice; this repo has neither. |
| Laying out a new island, panel or settings page; choosing a type scale; keyboard navigation or contrast | `qt-ui-design` | Use its desktop sections, skip "Embedded and MCU". The type scale it builds becomes tokens in `core/Theme.qml`. |
| A QML change is finished, before commit, or the user asks to "check/review the code" | `qt-qml-review` | Read-only. Report only behaviour, binding, loader, state and performance findings; drop STY-* and ORD-* style rules (dot-notation anchors are this repo's style). |
| Reviewing a diff or PR for real bugs (not style) | `code-review` | After `qt-qml-review`, or instead of it when the change is mostly JS logic in `core/`. |
| The shell stutters, an animation drops frames, CPU is high | `qt-qml-profiler` | Not yet tested with `qs`; if it cannot attach, fall back to `superpowers:systematic-debugging` with probes and `qs log`. |
| Any bug, crash or "it just doesn't work" | `superpowers:systematic-debugging` | First read `references/gotchas.md`: many symptoms here are known silent failures. |
| A cleanup pass after a working change | `simplify` | Keep every comment that explains a crash or silent failure. |

### Design and motion

| Trigger | Load | Notes |
|---|---|---|
| Starting a new feature, island or visual direction (before any code) | `superpowers:brainstorming` | Then `superpowers:writing-plans` for anything over ~3 files. |
| Critiquing or polishing the look of an island/panel; hierarchy, spacing, colour, type; "it looks generic/boring/too loud" | `impeccable` | Use its modes: `critique`/`audit` to judge, `polish`, `typeset`, `colorize`, `quieter`, `bolder`, `delight`, `layout`, `harden` for edge states, `document` to rewrite `DESIGN.md`. It reads `PRODUCT.md`/`DESIGN.md` in the repo root. `DESIGN.md` still describes the pre-Ember look (Catppuccin, flat, no glow) — run `impeccable document` after the first Ember island ships so it stops pulling the old style back. |
| Building an **HTML** mock or prototype of a shell surface to show the user | `design-taste-frontend` | Only for HTML/web mocks (its browser inspector and anti-slop rules need a web page). Never for QML. Keep the Ember identity from `references/ember-to-qml.md` instead of dealing a new direction. |
| The user should choose between several versions of one element | `prototype` — **user-only** | Ask the user to run `/prototype <element>`; it renders variants in HTML. Port the winner to QML yourself. |
| General component craft: buttons feel responsive, popovers origin-aware, never scale from 0, interruptibility, "make it feel right" | `emil-design-eng` | Taste source. Translate mechanics with the *Motion in QML* table below. |
| Springs, physical/fluid motion, momentum, materials and depth, "premium / Apple-like" feel, typography tracking and leading | `apple-design` | Taste source for the island morph and the ember. Its CSS/Framer code does not apply; use `SpringAnimation` / `BezierSpline`. |
| Building one specific animation (island open, kindle, ember flare, hover) | `animate` | Follow its decision order (should it animate → purpose → properties → curve/duration → interruption → exit → reduced motion), then implement with the QML table below. |
| "What could animate here?", "make it feel more alive" | `find-animation-opportunities` | Read-only proposals; reject anything that would animate continuously on the always-visible bar beyond the ember's breathing. |
| Auditing all motion in the shell, or planning a motion pass | `improve-animations` | Read-only plan. Point it at `shell.qml`, `components/` and `core/Theme.qml`. |
| Reviewing motion in a finished diff | `review-animations` — **user-only** | Ask the user to run `/review-animations`. Until they do, self-check against `animate`'s "Never Ship" list. |
| A component shows user/external data (track titles, notification text, device names, many notifications, zero items, non-Latin text, emoji) | `break-ui` | Its harness is HTML; in QML, feed the same worst cases through a throwaway probe or temporary mock data and screenshot with `grim`. Fix with `elide`, `maximumLineCount`, `Layout.maximumWidth`. |

### Finishing

| Trigger | Load |
|---|---|
| About to say something works, is fixed or is done | `superpowers:verification-before-completion` (evidence = the live shell under `qs`, a screenshot, a clean `qs log`) |
| Work on a branch is complete | `superpowers:finishing-a-development-branch` |

Do not load `run` to launch the shell; use *Run and debug* below. The
`jelinek:*` skills are for the user's employer and never apply to this repo.

## Run and debug

| Need | Command |
|---|---|
| Run the shell (dev) | `qs -p ~/.local/share/wisp-shell/shell.qml` |
| Run one entry point | `qs -p ~/.local/share/wisp-shell/settings.qml` (also `lock.qml`, `wallpaper.qml`, `welcome.qml`) |
| Is it running? | `qs list --all` (plain `qs list` looks for a "default" config and finds none) or `pgrep -af shell.qml` |
| Logs of the running instance | `qs log -p ~/.local/share/wisp-shell/shell.qml` |
| IPC targets it exposes | `qs ipc -p <shell.qml> show` |
| Call IPC | `qs ipc -p <shell.qml> call shell toggleLauncher` |
| Restart via the CLI | `wisp` (see `wisp --help`; `wisp doctor` checks deps) |
| Screenshot to check a change | `grim -g "x,y wxh" out.png` (monitor is 1920x1080, scale 1) |

- Saving a .qml file hot-reloads the running instance. Reload recreates
  windows; `LazyLoader` loads synchronously during a reload so windows can be
  reused. In-memory state is rebuilt on reload; what must survive a reload
  goes in `PersistentProperties` (reload-only) or a `FileView` (disk).
- To open the pill programmatically there is no IPC yet — add a typed
  `IpcHandler` function (see below) rather than simulating clicks; `ydotool`
  needs `ydotoold`, which is not running here.
- A throwaway probe is the project's substitute for tests: a tiny
  `probe.qml` run with `qs -p probe.qml` that prints what you need with
  `console.log`. Keep probes in the scratchpad, not the repo root.

## Quickshell building blocks

**Windows.** `PanelWindow` is a wlr-layer-shell surface. Set `screen`,
`anchors { top: true ... }`, `margins`, `exclusionMode` / `exclusiveZone`,
`WlrLayershell.layer` (Overlay for the pill), `WlrLayershell.namespace`
(Hyprland matches `layer_rule` on it — anchor the regex, `^wisp$`) and
`WlrLayershell.keyboardFocus` (`None` collapsed, `OnDemand` when a text field
may need keys, `Exclusive` only for one modal surface at a time).
`FloatingWindow` is a normal toplevel (used by the separate apps).
`PopupWindow` anchors to another window.

**Per screen.** `Variants { model: Quickshell.screens; delegate: Component {...} }`
creates one delegate per monitor and tracks hotplug. Anything that must exist
once per session (polkit agent, notification server, global keybind
injection, IPC handlers with a fixed target) goes *outside* the Variants.
Global state that drives per-screen surfaces (e.g. `ShellState.launcherActive`)
must name which screen owns it, or every monitor reacts at once.

**Input masks.** The wl_surface stays at its maximum size and only an inner
item animates; `mask: Region { item: container }` limits clicks to the
visible shape. `Region` composes: child `Region`s (its default property) are
combined by each child's `intersection` (`Combine` default, `Subtract`,
`Intersect`, `Xor`) and support `radius` / per-corner radii. An empty
`Region {}` releases all input (used during fullscreen).

**IPC.** `IpcHandler { target: "shell"; function toggleLauncher(): void {...} }`.
Argument and return types **must be annotated** or the function is silently
not registered. Allowed types: `string`, `int`, `bool`, `real`, `color`
(returns also `void`); max 10 arguments. Signals (0–1 typed arg) can be
observed with `qs ipc wait` / `qs ipc listen`.

**Processes.** `Process { command: ["cmd", "arg"]; running: true; stdout: StdioCollector {...} }`
or `SplitParser` for line streams. Each argument is its own string — no shell
unless you call `["sh", "-c", ...]` deliberately. Setting `running: true`
starts it; to loop, restart in `onRunningChanged`. `Quickshell.execDetached([...])`
fires and forgets; its stderr goes nowhere, so a wrong path fails invisibly —
log the command you build. Gate every polling Process/Timer on visibility
(`running: open && tabVisible`) and on its feature setting, and remember a
view inside `Variants` polls once **per monitor**.

**Files.** `FileView { path: ...; JsonAdapter {...} }` for JSON state with
`writeAdapter()`; handle `FileViewError.FileNotFound` on first run. Paths come
from `core/Paths.qml` (XDG config/state split) and `Quickshell.shellPath(...)`
for files shipped with the shell — never `Qt.resolvedUrl()` for .qml paths.

**Lazy creation.** `LazyLoader` builds components between frames (good for
windows/panels not needed at startup) and can unload them. Plain `Loader` with
`active:` is fine for in-window content.

**Blur.** `BackgroundEffect.blurRegion: Region { item: ... }` attached to a
window uses ext-background-effect-v1 (compositor must support it). Wisp's
design is opaque-first; use blur only if a design decision asks for it.

**Hyprland.** `import Quickshell.Hyprland`: `Hyprland.focusedWorkspace`,
`Hyprland.workspaces.values`, `Hyprland.monitorFor(screen)` →
`.activeWorkspace.hasFullscreen` (per-monitor; never use the global focused
workspace for per-screen decisions). Dispatch uses the **Lua** syntax because
the user runs Hyprland's Lua config: `Hyprland.dispatch("hl.dsp.focus({ workspace = 3 })")`,
and from a process `hyprctl dispatch 'hl.dsp.send_shortcut({ mods = "...", key = "...", window = "..." })'`.
Runtime config goes through `hyprctl eval '<lua>'`; `hyprctl keyword` is a
no-op on the Lua parser. Strip `"'\\\n` from any user string placed in a Lua
literal. Do not inject keybinds at runtime that `keybinds.lua` (wisp-dots)
already defines — Hyprland keeps both and fires both.

## Motion in QML

Translate the web motion skills like this:

| Web idea | QML |
|---|---|
| CSS transition (interruptible) | `Behavior on x { ... }` — retargets mid-flight |
| spring | `SpringAnimation { spring; damping; mass; epsilon }` for geometry that follows a changing target; it is velocity-preserving, so interruption feels physical |
| `cubic-bezier(a,b,c,d)` | `easing.type: Easing.BezierSpline; easing.bezierCurve: [a, b, c, d, 1, 1]` |
| keyframes / stagger | `SequentialAnimation` + `PauseAnimation { duration: i * step }` |
| `transform-origin` | `transformOrigin: Item.Top` (or set `origin` on a `Scale` transform) |
| `filter: blur()` | `layer.enabled: true; layer.effect: MultiEffect { blurEnabled: true; blur: ... }` — enable the layer only while animating, it costs an offscreen texture |
| box-shadow / glow | `RectangularShadow` (QtQuick.Effects, Qt ≥ 6.9) behind the rect, or `MultiEffect { shadowEnabled }` |
| `prefers-reduced-motion` | no system signal here — add a `Theme.reduceMotion` setting and make tokens collapse to 0 / no overshoot |

Rules that matter most in this shell:
- Animate **inner items**, never the window's `implicitWidth/Height`
  (resizing the wl_surface per frame flashes an uninitialised grey area).
- Geometry morphs (island width/height/radius): spring or a slight-overshoot
  bezier, 400–650 ms. Content opacity/blur: 150–300 ms, ease-out, starting
  after the container has started moving. Hover: ≤ 150 ms.
- Never animate from `scale: 0`; start at ~0.9–0.96 with opacity.
- Origin-aware: content grows from the island that opened it.
- Every animation must survive being interrupted halfway (click, click again).
- Glow and blur effects are GPU work on an always-visible surface: one shared
  effect per island, not one per child, and idle animations (breathing) at
  low frequency.

## Redesign workflow

1. The approved direction is **Wisp Ember** (three islands, the ember light as
   the signature, own neutrals + wallpaper accent, "kindle" reveal). The
   clickable prototype is `references/ember-prototype.html` (open it in a
   browser); `references/ember-to-qml.md` has the mapping.
2. Add tokens to `core/Theme.qml` first (radius, space, type scale, motion
   durations + curves, glow), then build components against them.
3. Rebuild the pill as an explicit state machine (`states:` on one controller
   or an enum property) — not three flags combined in ternaries.
4. Build one island end-to-end (collapsed → open → interrupted → closed) and
   show it live before doing the others.
5. Per island, run the skills in this order: `animate` (+ `apple-design`) while
   building the motion → `break-ui` with worst-case data → `impeccable critique`
   on a screenshot → `qt-qml-review` → `superpowers:verification-before-completion`.
   Ask the user to run `/review-animations` before the island counts as done.

## Reference code

`~/coding/wisp-refs/` holds read-only references: `caelestia-shell`
(polished Quickshell shell; good token/animation structure, e.g.
`components/Anim.qml`, `components/effects/Elevation.qml`) and `k4-island`
(island-style Hyprland shell, quality unverified). Caelestia is **GPL-3.0**
and Wisp is **MIT**: learn patterns from it, do not copy code. Most public
Quickshell configs do not follow current best practice (the Quickshell docs say
so); the Quickshell source wins over any config.
