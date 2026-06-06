# Crudo — Design System

The complete visual language for Crudo. This document is the single source of truth for styling **principles**; the exact, locked values live in `docs/design/prototype/app.css`. Where prose here and `app.css` disagree, `app.css` wins.

Companion docs: `product.md` (what to build), `architecture.md` (how it's structured).

---

## 1. Creative North Star

**"The Digital Curator."** This is not a utility fitness tracker — it's a premium editorial experience, closer to a high-end wellness journal than to Material Design. We prioritize **negative space as a feature** and break the "template" look through **intentional asymmetry**: large display type placed off-center, elements bleeding into whitespace, and tonal shifts (never lines) defining structure. The result is calm and focused — visual serenity that supports habit consistency.

**Brand:**
- **Name:** Crudo (title case, never all-caps).
- **Wordmark:** Manrope, bold, teal primary (`#004d49`). A navigation anchor, not a decorative logo.
- **Tagline:** "Your digital sanctuary for nutrition" — used sparingly (welcome footer, marketing). Never inside core UI.
- **Voice:** Direct, calm, premium, practical. No exclamation marks. No motivational fluff. No cheesy fitness language.

---

## 2. Color System

The UI is built as stacked layers — like sheets of fine paper. **No borders.** Structure comes from background-color shifts.

### Surfaces

| Token | Hex | Usage |
|---|---|---|
| `surface` | `#faf9f6` | Base background — every screen starts here |
| `surface-low` | `#f4f3f1` | Secondary sections, card groups, form areas |
| `surface-lowest` | `#ffffff` | Active cards, interactive elements, inputs |
| `surface-high` | `#e9e8e5` | Elevated contexts, unselected chips, inactive states |
| `surface-highest` | `#ddddd9` | Active day-pill, deepest tonal step |
| `surface-dim` | `#ede8e0` | Inactive/disabled states — keep warmth, never cold gray |

### Brand & accents

| Token | Hex | Usage |
|---|---|---|
| `primary` | `#004d49` | Wordmark, icons, selected states, text links, **Done** state |
| `primary-soft` | `#196661` | Gradient endpoint for CTAs |
| `primary-container` | `#cce8e4` | Teal tint for icon badges / pills |
| `on-primary` | `#ffffff` | Text on primary buttons |
| `gold` | `#e9b949` | **Partial** meal state, **Carbs** macro, streak flame, upgrade crown |
| `gold-soft` | `#f4dfa6` | Gold tint for chips / soft backgrounds |
| `bronze` | `#9A7E4E` | **Fats** macro bar (warm counterpart to gold for the 3rd macro) |
| `error` | `#ba1a1a` | Error text/icon — container stays neutral, only text/icon turns red |
| `error-soft` | `#ffdad6` | Error soft background |
| `success` | `#196661` | Reuses primary teal |

### Text

| Token | Hex | Usage |
|---|---|---|
| `on-surface` | `#1a1c1a` | High-contrast text (never pure `#000000`) |
| `on-surface-var` | `#4a5552` | Secondary text |
| `on-surface-mut` | `#8a938f` | Muted: subtitles, helper text, labels |

### Meal status colors

Done = `primary` teal · Partial = `gold` · Upcoming = muted (clock icon) · Skipped = `error` red.

### Streak day states

Green (adherent, ≥ threshold) = `success` teal · Yellow (partial day, streak holds) = `gold` · Red (missed, streak resets) = `error` red. No new green token — reuse `success` teal to stay on-palette.

### The "No-Line" rule

1px solid borders are **prohibited** for sectioning or containment. Boundaries are defined solely through surface-color shifts (e.g. a `surface-lowest` card on a `surface` background). Horizontal dividers/rules are banned — separate items with vertical padding or alternating surface shifts. **Ghost-border fallback** (accessibility only): `outline` `rgba(190,201,199,0.3)` — never 100% opaque lines.

---

## 3. Typography

**Font:** Manrope (weights 400–800). Extreme hierarchy: very large display sizes contrasted with small, generously-tracked labels.

| Scale | Size / line / spacing | Weight | Usage |
|---|---|---|---|
| Display | 40 / 44 / `-1.2px` | 600 | Hero headlines, daily summaries, milestones |
| Display sm | 32 / 36 / `-0.8px` | 600 | Smaller hero |
| Headline | 24 / 30 / `-0.5px` | 700 | Section openers |
| Headline sm | 20 / 28 / `-0.3px` | 700 | — |
| Title | 18 / 28 | 600 | Card headings, nav titles |
| Body | 14 / 22 | 500 | Descriptions (uses `on-surface-var`) |
| Body lg | 16 / 26 | 500 | Larger body |
| Label | 10 / `+1.5px` tracking, uppercase | 700 | Metadata: STEP 1 OF 4, MACROS, CALORIES |
| Label md | 12 / `+1.2px` tracking, uppercase | 700 | — |
| Stat | 56 / 56 / `-2px` | 700 | Hero metric (app.css `.streak-num`): Today intake kcal, streak count |

Rules: headlines dominate, left-aligned, large, tight leading. Labels are always all-caps with tracked spacing. Body uses muted color, never headline weight. Italic is reserved for emotional quote blocks (max one per screen). No underlines except links. Use `tnum` for numeric figures.

---

## 4. Elevation & Depth

No traditional drop shadows — depth via **tonal layering** and **ambient diffusion**.

- **Layering:** stack `surface-lowest` cards on `surface-low` sections for a soft, natural lift.
- **Cloud Shadow** (floating elements only): `0 20px 40px rgba(26,28,26,0.04)`; deep variant `0 24px 60px rgba(26,28,26,0.06)`. A soft glow, not a hard shadow.
- **Glassmorphism:** floating nav / modals use semi-transparent `surface` + `20px` backdrop-blur.
- Standard cards never have shadows — only tonal lift.

---

## 5. Dimensional System (strict)

**The 4px grid is law.** Every padding, gap, size, radius, and offset is a multiple of 4px, expressed through a named token — never a raw number. The prototype is a *sketch*, not a spec: where it shows `18px` the system says `md 16`; where it shows `3px` the system says `xs 4`. **Snap to the system, never copy raw px.**

Source-of-truth chain: this section defines the system → `lib/ui/core/themes/dimensions.dart` implements it → the prototype (`app.css`/JSX) informs *composition and fields only*. Colors and type stay locked from `app.css`.

### Spacing (paddings & gaps)

`xs 4` · `sm 8` · `md 16` · `lg 24` · `xl 32` · `xxl 48` — the **only** values allowed for padding, gaps, and offsets (compose for larger: toast offset = `2 × xxl`). Dart: `Spacing.*`.

**Rhythm:** label → `sm` → content; card → `md` → card; major section → `lg`/`xl`. Sticky CTA: `lg` above, `md` below.

### Icon sizes

`sm 16` (dismiss/dense) · `md 20` (inline default) · `lg 24` (nav) · `xl 32` (feature). Dart: `IconSizes.*`. No other icon sizes.

### Corner radius

`sm 12` · `md 20` · `lg 32` · `xl 48` · `full 9999`. Dart: `Radii.*`. All cards use `lg` or `xl`.

### Component sizes

Component-intrinsic dimensions are **named constants in the widget**, must sit on the 4px grid, and get recorded here once locked:

| Component | Size |
|---|---|
| Meal status circle | 36 |
| Meal time-bar | 4 × 44 |
| Macro ring (default) | 72 |
| Day pill | 44 × 60 |
| Macro bar (height) | 4 |
| Nudge icon circle | 40 |
| Sheet grabber | 40 × 4 |
| Toggle | 48 × 28 |
| Check circle | 28 |
| Avatar | 96 |
| Primary CTA min-height | 56 |

### Opacities

Alpha levels for derived colors — never a raw alpha inline. `muted 0.7` (secondary text over tonal/colored fills) · `disabled 0.4` (disabled interactive elements). Dart: `Opacities.*`.

### Strokes — the only off-grid values

Painted stroke widths may be 1–3px: macro ring 2–2.5 · status glyph 2 · ghost ring 1.5 · input underline 2. Strokes are `CustomPaint`/decoration strokes, **never `Border`** (no-line rule; enforced by test).

### Hit targets

Interactive elements ≥ 44×44 effective — pad small visuals (dismiss icons, steppers) to reach it.

### Layout

- **Frame:** 390 × 844 (primary), responsive to smaller phones.
- **Content padding:** `lg 24` horizontal. Asymmetric margins encouraged for editorial feel (`xl 32` left / `md 16` right).

### Adding a size

No fitting token? Add it to `dimensions.dart` **and** this section in the same change — never inline a raw number in a widget.

---

## 6. Components

### Buttons
- **Primary CTA:** full-width, sticky to bottom. Gradient `primary → primary-soft` at 135°. White uppercase tracked text, `full` radius, min-height 56px, no shadow. Often a `→` suffix.
- **Secondary:** `secondary-container` fill, `on-secondary-container` text, same radius.
- **Tertiary/Ghost:** text-only, `primary` color, label style (all-caps tracked). For "I already have an account", "Restore purchase", "← Back".

### Selection cards
Large rounded rectangles (`lg` radius), white fill on beige, center-aligned icon + title + subtitle, min-height 80px. Unselected: white. Selected: `primary-container` tint — surface-tone shift only, **no border, ever** (no-line rule). Used for goals (Cut/Maintain/Bulk), meal counts.

### Pill selectors
`full` radius, side-by-side, equal width. Unselected: outline/`surface` fill. Selected: `primary` fill, white text. Used for Grams/Ounces, Fixed/Flexible.

### Ingredient chips
Wrap layout, `sm` radius, `surface-high` background. Selected: `primary` fill, white text. "Add custom ingredient" text link below.

### Pain point cards
`lg` radius, `surface-low` background. Circular teal icon badge (left) + bold title + muted description (right). Stacked with `md` spacing.

### Quote / insight block
Italic, slightly larger than body. For emphasis: teal-tinted card (`primary` ~10%). Max one per screen.

### Inputs
Minimalist bottom-only stroke (2px `surface-high`); on focus → `primary`. Error: `error` text/icon, container stays neutral. Placeholder uses `on-surface-mut`. No floating labels — use section labels above. (`input-box` variant: `surface-low` fill, `md` radius.)

### Toggle / stepper / checkbox
- Toggle: 48×28 pill, `surface-high` off / `primary` on.
- Stepper: pill container, teal `+`/`−`.
- Check circle: 28px; on = `primary` fill, partial = `gold` fill.

### Notification mock card
Looks like a real system notification: `lg` radius, white card, Cloud Shadow, app icon + "Crudo" + timestamp, bold title + body, label-style action buttons (LOG MEAL / SNOOZE).

### Nutrition-specific
- **Macro-progress rings:** thin 2px strokes (never heavy donuts); background track `outline` ~20%.
- **Macro mini-bars:** Protein/Carbs/Fats consumed-vs-planned bars (Carbs uses gold).
- **Day-picker:** horizontal scrolling dates; active day = `surface-highest`, `full` radius pill.
- **Bar chart (History):** vertical bars, height = adherence %, teal fill, red/gold variants.
- **Avatar:** 96px teal-container circle with initials + optional gold milestone badge.

---

## 7. Navigation Patterns

### Bottom navigation (main app)
Glass tab bar, 4 tabs: **Today · Plans · History · Profile**. Light-stroke icons (1–1.5px). Active = `primary` icon+label; inactive = muted. Floating pill with backdrop-blur. No hamburger menus anywhere.

### Onboarding
Wordmark anchored top (centered on intro screens, top-left on setup). Subtle X-close on intro/pain screens; back arrow on setup. Progress indicator only on the setup steps: "STEP X OF N" label + segmented bar (filled = completed + current). See `product.md` for the 13-screen flow.

---

## 8. Iconography

Light stroke weight (1–1.5px) to match Manrope. Consistent family (Phosphor Light / Lucide / custom). Sizes from `IconSizes` only: `sm 16` dense · `md 20` inline · `lg 24` nav · `xl 32` feature (§5). Color: `primary` for active/accent, `on-surface-mut` for neutral. Icon badges: icon centered in a teal-tinted circle (`primary-container`, 40px).

---

## 9. Motion

Subtle and functional, never decorative.

| Token | Duration | Usage |
|---|---|---|
| `Durations.fast` | 150 ms | Chips, quick tint shifts |
| `Durations.base` | 200 ms | Progress bars, selection pulses |
| `Durations.slow` | 500 ms | Intake-hero settle: number roll, bar growth, ring sweep |

- Screen transitions: horizontal slide for step progression.
- Selection: quick scale pulse / background tint shift on tap.
- CTA: no idle animation; press darkens gradient ~10% (`scale(.985)`).
- Progress bar: segment fill animates on step change (~200 ms ease).
- Chips: background color transition (~150 ms). Sheets: slide-up; modals: pop-in.

---

## 10. Do's & Don'ts

**Do:** use tonal layering for depth · use `surface-dim` for inactive (keep warmth) · use asymmetric margins · let whitespace lead — if a screen feels full, remove content · one primary action per screen · make selected states immediately obvious.

**Don't:** pure black `#000000` · 1px solid borders for sectioning · horizontal dividers · standard Material FABs · neon / generic gradients / sporty visuals · heavy drop shadows · decorative illustrations · crowded screens (move overflow to a secondary layer) · exclamation marks · hamburger menus.

---

## 11. Screen Inventory

The full set is designed in `docs/design/prototype/`. See `product.md` for per-screen behavior and `architecture.md` for the navigation map.

- **Onboarding (13):** Welcome · Awareness · Structure · Video demo · Transformation · Heard-about · Tried-apps · Baseline · Daily structure · Meal timing · Reminders · Sign up · Verify.
- **Core:** Today · Meal detail · Plans (read-only list) · Plan detail · Create plan · History · Profile.
- **Creation:** Add meal · Add ingredient · Add custom food.
- **Sheets/popups:** Snooze · Swap · Reminders · Paywall · Streak risk · Confirm · Review · Calendar (per-day stats) · Plan-days editor · Schedule conflict · Toast.
