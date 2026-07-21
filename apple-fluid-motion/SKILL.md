---
name: apple-fluid-motion
description: >
  Apple's approach to fluid, physical motion — translated for the web (CSS, Pointer Events,
  requestAnimationFrame, spring libraries like Motion/Framer Motion). Use when building or reviewing
  gesture-driven UI, spring animations, drag/swipe/sheet interactions, momentum and interruptible
  transitions, translucent materials & depth, motion typography, reduced-motion, or the design
  foundations behind Apple-style interfaces. This is a BUILD skill (how to implement fluid motion);
  for broad cross-platform HIG compliance review, use `apple-design` instead.
---

# Apple Fluid Motion (Condensed)

Distilled from Apple's WWDC design talks — chiefly *Designing Fluid Interfaces* (WWDC 2018) — and
translated to the web. Source knowledge: Emil Kowalski / [animations.dev](https://animations.dev).

**Through-line:** an interface feels alive when motion **starts from the current on-screen value,
inherits the user's velocity, projects momentum forward, and can be grabbed and reversed at any
instant.** Springs are the tool that makes this natural — they are inherently interruptible and
velocity-aware. Apple frames design as serving four needs: **safety/predictability, understanding,
achievement, joy.**

## 1 · Response — kill latency

- **Respond on pointer-down, not release.** Highlight the instant it's pressed; waiting for
  `click`/touch-up feels dead.
- Audit every latency: debounces, artificial timers, transition waits, the ~300ms tap delay.
- **Feedback must be continuous *during* the interaction**, not only at the end — drags/sliders/
  drawers update 1:1 with the pointer the whole way.

```css
.button:active { transform: scale(0.97); transition: transform 100ms ease-out; }
```

## 2 · Direct manipulation — 1:1 tracking

- Dragged content stays glued to the finger and **respects the grab offset** (don't snap to center).
- Use Pointer Events + `setPointerCapture` so tracking survives leaving the element's bounds.
- Track a short **velocity/position history** (last few `pointermove`s) — you need velocity at release.

```js
el.addEventListener('pointerdown', (e) => {
  el.setPointerCapture(e.pointerId);
  const grabOffset = e.clientY - el.getBoundingClientRect().top; // respect where they grabbed
});
```

## 3 · Interruptibility — the single most important principle

> "The thought and the gesture happen in parallel."

- **Never lock out input during a transition.** A closing modal the user grabs again follows the
  finger — it doesn't finish closing first.
- **Always animate from the *presentation* (live on-screen) value, never the target** — read the
  live transform on interrupt or you get a visible jump.
- **Avoid CSS transitions / `@keyframes` for gesture-driven motion** — they can't be grabbed and
  reversed mid-flight. Springs animate from the current value by default.
- **On reversal, blend velocity — don't hard-cut it** (a velocity discontinuity is a "brick wall").
  Use a spring library that re-targets from current velocity (web equivalent of iOS additive anims).
- **Decompose 2D motion into independent X and Y springs** — one spring on a 2D distance desyncs.

## 4 · Behavior over animation — use springs

Two designer-friendly params (not mass/stiffness/damping):
- **Damping ratio** — overshoot. `1.0` = critically damped, no bounce. `< 1.0` = bouncier.
- **Response** — how fast it reaches target, in seconds. Lower = snappier. **Not "duration"** — a
  spring has no fixed duration.

**Defaults:** start most UI at **damping `1.0`**; add bounce (**~`0.8`**) **only when the gesture
carried momentum** (flick/throw/drag-release). Overshoot on a faded-in menu feels wrong; on a
flicked card it feels right.

| Interaction | Damping | Response |
| --- | --- | --- |
| Move / reposition (e.g. PiP) | `1.0` | `0.4` |
| Rotation | `0.8` | `0.4` |
| Drawer / sheet | `0.8` | `0.3` |

**Web mapping (Motion / Framer Motion):** `bounce` + `duration` ≈ Apple's damping + response.

```js
import { animate } from 'motion';
animate(el, { y: 0 },      { type: 'spring', bounce: 0,   duration: 0.4 }); // critically damped
animate(el, { y: target }, { type: 'spring', bounce: 0.2, duration: 0.4 }); // momentum → slight bounce
```

## 5 · Velocity handoff — the seam between drag and animation

When a gesture ends, the animation **continues at the finger's exact velocity** — no visible seam.
Pass release velocity as the spring's initial velocity. Some APIs want **relative** velocity:

```
relativeVelocity = gestureVelocity / (targetValue − currentValue)
```

e.g. at `y=50`, target `y=150` (100px to go), finger 50px/s → `50/100 = 0.5`. Motion/Framer Motion
take absolute px/s directly (`velocity` option).

## 6 · Momentum projection — animate to where the gesture is *going*

Don't snap from the release point — use velocity to **project the resting position** (like scroll
deceleration), then snap to the nearest target to that projection. Apple's exact function:

```js
// decelerationRate ≈ 0.998 normal scroll feel; 0.99 snappier
function project(initialVelocity /* px/s */, decelerationRate = 0.998) {
  return (initialVelocity / 1000) * decelerationRate / (1 - decelerationRate);
}
const projectedEndpoint = currentPosition + project(releaseVelocity);
const target = nearestSnapPoint(projectedEndpoint);
animateSpringTo(target, { velocity: releaseVelocity }); // then hand off velocity (§5)
```

Use the exponential-decay form, **not** textbook `v²/(2·decel)`. Standard in Vaul, Embla.

## 7 · Spatial consistency — symmetric paths, anchored origins

- **Enter and exit along the same path** (slide in from right → dismiss to the right).
- **Anchor to the source:** menus/popovers/sheets originate from the trigger — set `transform-origin`
  to it (popovers scale from trigger, not center).
- **Mirror the easing** on reversible transitions (inverse cubic-bézier for the two directions).

## 8 · Hint in the direction of the gesture

Intermediate motion should telegraph the outcome (Control Center modules "grow up and out toward
your finger"). Make in-between frames point at the result, not interpolate blindly.

## 9 · Rubber-banding — soft boundaries

Resist progressively past an edge instead of a hard stop (which reads as "frozen").

```js
function rubberband(overshoot, dimension, constant = 0.55) {
  return (overshoot * dimension * constant) / (dimension + constant * Math.abs(overshoot));
}
```

## 10 · Gesture "feel" checklist

- **Tap:** highlight on touch-*down*, commit on touch-*up*; ~10px hit padding; cancel-by-drag-away.
- **Drag/swipe:** ~10px movement threshold (hysteresis) before committing to a direction, then 1:1.
- **Detect all plausible gestures in parallel** from the first move, cancel losers once intent clear.
  Avoid recognizers that only report a *final* state — they throw away continuous tracking.
- **Minimize disambiguation delays** (double-tap delays single tap — only pay it where needed).

## 11 · Frame-level smoothness

- Keep per-frame positional change below the perception threshold (avoid strobing).
- Very fast motion → subtle **motion blur / stretch** reads better than a sharp streak.
- `requestAnimationFrame` is the display-synced clock. Animate only **`transform` and `opacity`**;
  hint with `will-change` where motion is imminent.

## 12 · Materials & depth — translucency conveys hierarchy

- **Nav/toolbars/sheets = translucent layers** (`backdrop-filter: blur()` + semi-transparent bg),
  content scrolling underneath — not opaque bars.
- **Weight encodes hierarchy:** darker/heavier separates structure (sidebars); lighter draws to
  interactive elements. **Never stack a light translucent surface on another** — legibility collapses.
- **Bigger surfaces read thicker:** stronger blur + deeper shadow. Context-aware shadow (heavier over
  busy/text content).
- **Dim to focus, separate to keep flow:** modal → surface + dimming scrim, push background back;
  parallel panel → translucency + offset, **no** scrim. Stacked sheets progressively dim parents.
- **Vibrancy for legibility over changing backgrounds:** higher contrast, slightly heavier weight,
  small letter-spacing bump; put color on a solid layer, not the translucent foreground.
- **Scroll edge effects, not hard dividers:** fade a small blur/gradient mask where content meets
  floating chrome, only where it overlaps.
- **Materialize, don't just fade:** animate blur radius + scale together on enter/exit.

```css
.toolbar {
  background: rgba(255, 255, 255, 0.6);
  backdrop-filter: blur(20px) saturate(180%);
  border-top: 1px solid rgba(255, 255, 255, 0.4); /* bright top edge = light on the material */
}
```

## 13 · Multimodal feedback — motion + sound + haptics

1. **Causality** — trigger on the actual causal event; match character to the action's physicality.
2. **Harmony** — visual + sound + haptic fire on the **same frame**; don't let a CSS transition lag
   the audio/haptic (Vibration API).
3. **Utility** — reserve haptics/sound for meaningful moments (success/error/commit/snap).
   Over-feedback trains users to ignore all of it.

## 14 · Reduced motion & accessibility

Reduced motion = gentler, non-vestibular equivalent, not *no* feedback. Respond to three signals:

- **`prefers-reduced-motion: reduce`** — slides/springs/parallax → short opacity **cross-fades**;
  drop overshoot; keep comprehension-aiding opacity/color changes.
- **`prefers-reduced-transparency: reduce`** — frostier/solid surfaces: raise bg opacity, drop blur.
- **`prefers-contrast: more`** — near-solid backgrounds + defined contrasting border.

Also avoid full-viewport moving backgrounds, slow loops (~0.2 Hz), abrupt brightness jumps.

```css
@media (prefers-reduced-motion: reduce) { .sheet { transition: opacity 200ms ease; transform: none !important; } }
@media (prefers-reduced-transparency: reduce) { .toolbar { background: white; backdrop-filter: none; } }
```

## 15 · Typography — optical sizing, tracking, leading

- **Tracking (letter-spacing) is size-specific** — large display wants *negative* tracking, small
  text slightly *positive*. Tighten headings (`-0.02em`), body near `0`. A fixed value is wrong somewhere.
- **Leading (line-height) tracks size inversely** — tight on headings (`1.05`), looser on body (`1.5`).
- **Hierarchy from weight + size + leading as a set,** not size alone.
- **Respect Dynamic Type:** scale layout with text — spacing in `rem`/`em`, not fixed px.
- **Default to the platform system font** (ships optical sizing + tracking); override only with reason.

```css
.display { font-size: clamp(2rem,5vw,4rem); line-height: 1.05; letter-spacing: -0.02em; font-optical-sizing: auto; }
```

## 16 · Design foundations — the eight principles

Motion serves these (*Principles of Great Design*). Reason with their names:

1. **Purpose** — build with intention; decide what *not* to build.
2. **Agency** — keep control; forgiveness (easy undo); confirm only truly destructive actions.
3. **Responsibility** — act in the user's interest; privacy at the right moment; anticipate misuse (esp. AI).
4. **Familiarity** — build on known metaphors + honor their physics; consistent = same look, same behavior, same place.
5. **Flexibility** — adapt to device/context/ability; design inclusively; let people personalize.
6. **Simplicity — not minimalism** — strip the unnecessary so the core shines; be concise + clear; common path first.
7. **Craft** — deliberate spacing/timing/alignment; adaptive color; responsive feedback; iterate.
8. **Delight** — the result of the other seven done right, not confetti on top.

Tactical: feedback comes in four kinds (**status, completion, warning, error**) — validate inline,
not on submit. Wayfinding — every screen answers where am I / where can I go / what's there / how do
I get out. Grouping & mapping — place a control near what it affects. Direct, specific labels beat
generic ones ("Library" over "Home").

## 17 · Process

- **Prototype interactively** — a working demo is "worth a million static designs" and sets a bar.
- **Design interaction and visuals together** — motion is not a layer added after the pixels.
- **Test with real people;** review motion in slow-motion / frame-by-frame.

## Quick Reference

| Need | Technique | Concrete value |
| --- | --- | --- |
| Default UI spring | Critically damped, no overshoot | `damping 1.0`, `response 0.3–0.4` |
| Momentum / flick spring | Under-damped, slight bounce | `damping ~0.8`, `response 0.3–0.4` |
| Gesture → spring velocity | Hand off release velocity | `gestureVelocity / (target − current)` if normalized |
| Flick landing point | Project momentum | `current + (v/1000)·d/(1−d)`, `d ≈ 0.998` |
| Interrupt cleanly | Start from presentation (live) value | read the on-screen transform |
| Avoid reversal "brick wall" | Carry velocity through re-target | spring that blends velocity |
| Reversible transition | Mirror the easing curve | inverse cubic-bézier |
| Decide reverse vs. commit | Use velocity **sign**, not position | at release |
| 1:1 drag | Pointer Events + capture | respect the grab offset |
| Feedback | On pointer-down, continuous | never only at the end |
| Boundary | Rubber-band, don't hard-stop | progressive resistance |
| Translucent chrome | `backdrop-filter` layer | content scrolls under |
| Type tracking | Size-specific, never fixed | tighten large text (`-0.02em`), body near `0` |
| Reduced motion | Cross-fade, not slide/spring | `@media (prefers-reduced-motion)` |
