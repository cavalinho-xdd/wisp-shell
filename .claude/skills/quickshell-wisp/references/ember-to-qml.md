# Wisp Ember → QML

The approved direction (user, 2026-10-25): light/will-o'-the-wisp identity,
own neutrals + one accent from the wallpaper, several small islands instead of
one pill with tabs, prototype first. Prototype: `ember-prototype.html` next to
this file. Values below come from that prototype; treat them as starting
points to tune live, not as final.

## Identity in one paragraph

Three opaque near-black islands at the top edge. The only colour taken from
the wallpaper is the **ember**: a small glowing dot in the centre island and
the light inside every island. Idle it breathes slowly; with media playing it
pulses; on a notification it flares and the island grows. Opening an island
springs its geometry and the content *kindles* — fades in from a blurred,
over-bright state to sharp. Other islands dim while one is open. No tabs: each
island opens its own thing.

## Tokens to add to `core/Theme.qml`

| Token | Prototype value | Note |
|---|---|---|
| `smoke` (island fill) | `#0a0b0e` | own neutral, not wallpaper |
| `ash` / `ashHi` (raised / hover) | `#15171c` / `#20232a` | |
| `text` / `muted` | `#eef0f4` / `#8a8f9b` | |
| `ember` | wallpaper-derived (`primary` from matugen), fallback `#8fd3ff` | the only themed colour |
| `glow` | 0.6 / 1.0 / 1.6 (setting) | multiplies glow blur + alpha |
| radius collapsed / open | 20 / 30 | island; tiles 18, rows 14 |
| island height collapsed | 40 | top margin 12 |
| font UI / mono | Mona Sans / Monaspace Neon (resolve via `pickFont`, keep fallbacks) | D2; packages `ttf-mona-sans`, `otf-monaspace` |
| motion `morph` | 620 ms, `BezierSpline [0.22, 1.18, 0.36, 1, 1, 1]` or `SpringAnimation` | geometry |
| motion `kindle` | 550 ms, stagger 50 ms, delay 100 ms, `[0.2, 0.8, 0.2, 1, 1, 1]` | content |
| motion `fast` | 150–200 ms | hover, press |
| breathe / beat / flare | 5 s loop / 520 ms alternate / 1.1 s once | ember |

## Structure

- One `PanelWindow` per screen (inside `Variants`) anchored top, full width,
  fixed height ≥ the tallest open island + glow padding. Three island items
  inside it. `mask: Region { Region { item: leftIsland } Region { item: centerIsland } Region { item: rightIsland } }`
  (child regions combine; verify on first use, then add per-island `radius`).
- Island state: one property per island with an explicit set of values
  (`center: "idle" | "notif" | "media" | "launcher"`, `right: "idle" | "cc" | "sound"`),
  owned by a per-screen controller. Only one island open at a time; opening
  one closes the others; a click outside or Esc closes all.
- Keep `core/Island.qml` arbitration as the source of what the centre island
  shows when idle/notif; the controller only decides open/closed.
- Width/height per state come from the content's implicit size where
  possible, not a lookup table of magic numbers.

## Effects

- **Island glow:** `RectangularShadow { color: Qt.alpha(Theme.ember, 0.22 * glow); blur: 22 * glow; spread: 0; radius: island.radius }`
  behind each island. Stronger when open (`0.26`, `46`). The window must have
  transparent padding around islands for the glow to render — layer
  surfaces clip at their bounds.
- **Inner light:** a `Shape` whose `ShapePath.fillGradient` is a
  `RadialGradient` (both from `QtQuick.Shapes`) centred on the ember position,
  ember at alpha ≈ 0.16 × glow fading to transparent, clipped by the island.
  Cheaper alternative: a blurred small circle via `MultiEffect`.
- **Ember:** 8 px `Rectangle { radius: 4; color: Theme.ember }` +
  `RectangularShadow` or `MultiEffect { shadowEnabled; shadowColor: Theme.ember; shadowBlur }`.
  Breathe: `SequentialAnimation on opacity { loops: Animation.Infinite ... }`
  (0.55↔1, scale 0.85↔1). Keep it cheap: it runs all day.
- **Kindle:** per content block: opacity 0→1, `y` +5→0, scale 0.98→1, and a
  `MultiEffect` blur 1→0 + brightness 1.2→0. Turn `layer.enabled` on only for
  the duration of the animation (bind to the animation's `running`).
- **Dim others:** opacity 0.35, scale 0.96, desaturate via `MultiEffect`
  saturation −0.6 (or skip desaturation if it costs too much).

## Don'ts carried over from the prototype review

- No outline/border around islands; separation comes from fill + glow.
- No tabs inside islands.
- Don't theme the neutrals from the wallpaper; only the ember changes.
- Semantic colours (error red, Discord blurple) stay fixed.
