# Wisp gotchas — things that already broke once

Each entry: the symptom, the cause, the rule. Sources are the comments in the
named files; read the full comment there before changing that code.

## Crashes

- **StackView double transition → SIGSEGV** (`shell.qml`, click-catcher).
  Calling `pop(null)` and `replace()` in the same tick while a subview is
  pushed raced two transitions in `QQuickTransitionManager`. Rule: one
  StackView operation per tick; only `pop` when `depth > 1`; defer the next
  with `Qt.callLater`. Better: the redesign drops StackView for explicit states.
- **Re-creating PolkitAgent → SIGSEGV** (`shell.qml`). Destroying a
  `PolkitAgent` deletes a process-wide singleton; a Loader-based retry crashed
  the whole shell. Rule: one PolkitAgent, created once, outside `Variants`,
  never in a Loader. Polkit allows one agent per session; if another holds it,
  wisp simply has none.

## Silent failures (no error, feature just doesn't work)

- **`Qt.resolvedUrl()` on .qml paths** returns `qs:@/qs/<file>.qml`, not a file
  path; `execDetached(["qs","-p", that])` then fails with stderr going nowhere
  (`core/Settings.qml`). Rule: `Quickshell.shellPath("x.qml")` for shipped
  files.
- **`Quickshell.statePath()`** is a per-shell hash dir; settings would be
  orphaned if the install prefix changed (`core/Paths.qml`). Rule: XDG
  config/state via `Paths`; code dir is read-only once packaged.
- **Missing font** silently falls back through fontconfig (`core/Theme.qml`).
  Rule: fonts only via `Theme.font*` picked from `Qt.fontFamilies()`.
- **IpcHandler function without type annotations** is not registered.
- **`hyprctl keyword`** is a no-op on Hyprland's Lua parser; flat
  `dispatch sendshortcut MOD, KEY` is rejected (`core/Discord.qml`). Rule:
  `hyprctl eval` / `hl.dsp.*` with Lua tables.
- **Old `"workspace N"` dispatch string** fails under Lua
  (`components/CollapsedBar.qml`). Rule: `hl.dsp.focus({ workspace = N })`.
- **Notification server inside a view** deregisters when the dashboard
  closes (`core/Notifs.qml`). Rule: DBus servers live in singletons loaded
  only by the shell process (loading `Notifs` from settings.qml would start a
  second server). While ii-dots runs, it owns the notification bus.
- **Layer-rule namespace is a regex**: `wisp` also matches `wisp-catcher`.
  Anchor it: `^wisp$`.

## Visual

- **Resizing the window surface per frame** flashes an uninitialised grey
  rectangle. Keep the surface at max size; animate an inner item; restrict
  input with `mask`.
- **Invisible surface still eats input**: when hiding for fullscreen, set the
  mask to an empty `Region {}` too, not just `opacity: 0`.
- **exclusiveZone** is independent of the surface height; 50 + Hyprland's
  `gaps_out` (10) + margin 12 = the reserved strip. Changing gaps_out changes
  the gap under the pill.
- **Device lists fill asynchronously at startup** and look like "just
  connected" events; `core/Island.qml` ignores changes for the first 3 s.

## Known open bugs (from the 2026-10-25 review, verify before relying on it)

- `ShellState.launcherActive` is global, so every monitor opens the launcher
  with exclusive keyboard focus.
- `ExpandedDashboard` assigns `currentTab = index`, breaking the
  `currentTab: expandTab` binding after the first manual tab click.
- `PerformanceCard`'s poll runs while the pill is collapsed on that tab;
  `WeatherCard` fetches even when weather is disabled; both per monitor.
- `core/Settings.qml` launches concurrent python edits of the same Hyprland
  files and reloads after a blind 150 ms timer.
- Dead: `launcher.qml` (launcher lives in the pill via IPC),
  `ShellState.settingsActive`, empty `Settings.applyKeybinds()/applyAll()`.
