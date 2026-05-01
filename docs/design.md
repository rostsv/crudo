# Crudo — Design System

This document defines the visual language for Crudo. All screens, components, and interactions should follow these rules. Reference this alongside `design-rules.md` for the full creative direction.

---

## 1. Brand Identity

**App name:** Crudo (title case, never all-caps)

**Wordmark style:** Manrope, bold weight, teal primary (`#004d49`). Used as navigation anchor — not a decorative logo.

**Tagline:** "Your digital sanctuary for nutrition" — used sparingly (welcome screen footer, marketing). Never inside the app core UI.

**Voice:** Direct, calm, premium, practical. No exclamation marks. No motivational fluff. No cheesy fitness language.

---

## 2. Color System

### Surface Hierarchy

The UI is built as stacked layers — like sheets of fine paper. No borders. Structure comes from background color shifts.

| Token | Hex | Usage |
|---|---|---|
| `surface` | `#faf9f6` | Base background — every screen starts here |
| `surface-container-low` | `#f4f3f1` | Secondary sections, card groups, form areas |
| `surface-container-lowest` | `#ffffff` | Active cards, interactive elements, inputs |
| `surface-container-high` | `#e9e8e5` | Elevated contexts, unselected chips, inactive states |
| `surface-dim` | warm gray (derived) | Inactive/disabled states — keep warmth, never cold gray |

### Accent Colors

| Token | Hex | Usage |
|---|---|---|
| `primary` | `#004d49` | Wordmark, icons, selected states, text links |
| `primary-container` | `#196661` | Gradient endpoint for CTAs |
| `on-primary` | `#ffffff` | Text on primary buttons |
| `on-surface` | `#1a1c1a` | High-contrast text (never pure `#000000`) |
| `on-surface-variant` | warm muted gray | Secondary text, subtitles, helper text |
| `error` | `#ba1a1a` | Error states — keep container neutral, only text/icon turns red |
| `success` | `#004d49` (primary) | Completed checkmarks, done states — reuse primary teal |

### The "No-Line" Rule

Borders are prohibited for sectioning or containment. Boundaries are defined solely through background color shifts. If you feel the need for a line, you haven't used your surface tokens correctly.

**Ghost border fallback** (accessibility only): `outline-variant` at 15% opacity. Never 100% opaque lines.

---

## 3. Typography

**Font family:** Manrope

| Scale | Weight | Size | Letter-spacing | Line-height | Usage |
|---|---|---|---|---|---|
| Display | Bold | 32–40px | `-0.02em` | 1.1 | Hero headlines, screen titles |
| Headline | SemiBold | 24–28px | `-0.01em` | 1.2 | Section openers |
| Title | SemiBold | 18–20px | `0` | 1.3 | Card headings, nav titles |
| Body | Regular | 14–16px | `0` | 1.6 | Descriptions, supporting text |
| Label | Medium | 11–12px | `+0.05em` | 1.4 | All-caps metadata: STEP 1 OF 4, NAME, PRIMARY GOAL |

### Rules

- Headlines dominate the screen — left-aligned, large, bold, tight leading
- Labels are always all-caps with tracked spacing
- Body text uses `on-surface-variant` (muted), never the same weight as headlines
- Italic is reserved for emotional quote blocks — max one per screen
- No underlined text except links

---

## 4. Elevation & Depth

No traditional drop shadows. Depth is achieved through tonal layering.

| Level | Method |
|---|---|
| Base | `surface` background — the default |
| Lifted | White card (`surface-container-lowest`) on beige background (`surface`) |
| Grouped | `surface-container-low` section containing white cards |
| Floating | Cloud Shadow: `Y: 20px, Blur: 40px, Color: rgba(26, 28, 26, 0.04)` |

- Floating elements (modals, bottom sheets) use Cloud Shadow + optional glassmorphism (semi-transparent `surface` + `20px` backdrop-blur)
- Standard cards never have shadows — only tonal lift

---

## 5. Spacing & Layout

### Grid

- Frame: 390 x 844 (primary), responsive to smaller screens
- Content padding: `24px` horizontal
- Asymmetric margins are encouraged where editorial feel is needed (e.g., `32px` left / `16px` right)

### Spacing Scale

| Token | Value | Usage |
|---|---|---|
| `xs` | `4px` | Icon padding, tight gaps |
| `sm` | `8px` | Between label and input |
| `md` | `16px` | Between cards, between sections |
| `lg` | `24px` | Major section breaks |
| `xl` | `32px` | Screen-level top/bottom padding |
| `2xl` | `48px` | Hero spacing, above headline |

### Rhythm

- Section label → `sm` gap → content
- Card → `md` gap → card
- Major section → `lg` or `xl` gap → next section
- Sticky CTA area: `lg` padding above button, `md` padding below

---

## 6. Corner Radius

| Token | Value | Usage |
|---|---|---|
| `sm` | `8px` | Small chips, badges |
| `md` | `12px` | Input fields, small cards |
| `lg` | `2rem` (20px) | Standard cards, selection cards, pain point cards |
| `xl` | `3rem` (24px) | CTA buttons, hero cards |
| `full` | `9999px` | Pill selectors, tags, day-picker active state |

---

## 7. Components

### Primary CTA Button

- Full-width, sticky to bottom of screen
- Gradient fill: `#004d49` → `#196661` at 135 degrees
- White text, medium weight, includes `→` arrow suffix
- Corner radius: `xl` (3rem)
- No shadow
- Min height: `56px`
- Bottom safe area padding respected

### Secondary Button

- `surface-container` fill with `on-secondary-container` text
- Same radius as primary
- Used for alternative actions (not dismissal)

### Ghost / Tertiary Button

- Text-only, `primary` color
- Label style (all-caps, tracked) or regular style depending on context
- Used for: "I already have an account", "Restore purchase", "← Back"

### Selection Cards

- Large rounded rectangles, `lg` radius
- White fill (`surface-container-lowest`) on beige background
- Center-aligned: icon + title + subtitle
- Min height: `80px`
- **Unselected:** white card, no border
- **Selected:** `2px` teal border + subtle teal tint on icon/background
- Used for: goals (Cut/Maintain/Bulk), meal counts (3/4/5/6)

### Pill Selectors

- `full` radius (pill shape)
- Side by side, equal width
- **Unselected:** outline or `surface-container` fill, dark text
- **Selected:** `primary` fill, white text
- Used for: Grams/Ounces, Fixed/Flexible

### Ingredient Chips

- Wrap layout, variable width based on text
- `sm` radius, `surface-container-high` background
- **Unselected:** muted background, dark text
- **Selected:** `primary` fill, white text
- "Add custom ingredient" as a text link below the chip grid

### Pain Point Cards

- `lg` radius, `surface-container-low` background
- Layout: circular teal icon badge (left) + bold title + muted description (right)
- Stacked vertically with `md` spacing
- Icon badges: teal-tinted circle with light-stroke icon inside

### Quote / Insight Block

- Italic text, slightly larger than body
- For emphasis: placed in a teal-tinted card (`primary` at ~10% opacity background)
- For subtlety: plain italic text with no card
- Max one per screen — used as an emotional anchor

### Notification Mock Card

- Looks like a real iOS/Android system notification
- `lg` radius, white card, Cloud Shadow
- App icon + "Crudo" + timestamp
- Bold title + body text
- Action buttons: label-style text (LOG MEAL / SNOOZE)

### Input Fields

- Minimalist: bottom-only stroke (`2px`, `surface-container-high` color)
- On focus: stroke transitions to `primary`
- Error: `error` color on text/icon, container stays neutral
- Placeholder text: `on-surface-variant`
- No floating labels in MVP — use section labels above

### Cards & Lists

- Never use horizontal dividers between list items
- Separate with `md` vertical padding or alternating surface shifts
- All cards: `lg` or `xl` radius

---

## 8. Navigation Patterns

### Onboarding

| Screen type | Top-left | Top-center | Top-right |
|---|---|---|---|
| Welcome | — | Crudo (wordmark) | — |
| Intro / pain slides | — or Crudo | Crudo | X (close) |
| Setup steps | ← (back) | Crudo | ? (help, optional) |
| Paywall | — | — | X (close) |
| Ready / success | — | Crudo | — |

### Step Progress Indicator

- Only on setup screens (Steps 1–4)
- Label: "STEP X OF 4" — label style (all-caps, tracked, small)
- Segmented bar below: 4 equal segments
  - Completed: `primary` fill
  - Current: `primary` fill
  - Remaining: `surface-container-high` fill
- Position: below navigation bar, above headline

### Bottom Navigation (main app, post-onboarding)

- Tab bar with 4 tabs: Today, History, Plans, Profile
- Icons: light stroke (1–1.5px)
- Active: `primary` icon + label
- Inactive: `on-surface-variant` icon, no label or muted label
- Bar uses glassmorphism: semi-transparent `surface` + `20px` backdrop-blur

---

## 9. Iconography

- Style: light stroke weight (1px–1.5px) to match Manrope
- Set: consistent icon family (e.g., Phosphor Light, Lucide, or custom)
- Sizes: `20px` inline, `24px` navigation, `32px` feature blocks
- Color: `primary` for active/accent, `on-surface-variant` for neutral
- Icon badges (pain cards, features): icon centered in a teal-tinted circle (`primary` at 10% opacity, `40px` diameter)

---

## 10. Motion & Transitions

Keep motion subtle and functional — not decorative.

- Screen transitions: horizontal slide (left/right) for step progression
- Selection feedback: quick scale pulse or background tint shift on tap
- CTA: no animation on idle, subtle press state (darken gradient 10%)
- Progress bar: segment fill animates on step change (200ms ease)
- Chips: background color transition on select/deselect (150ms)

---

## 11. Do's and Don'ts

### Do

- Use tonal layering to create depth — stack surface tokens
- Use `surface-dim` for inactive states — keep the warmth
- Use asymmetric margins for editorial feel
- Let whitespace do the heavy lifting — if a screen feels full, remove content
- Keep every screen to one primary action
- Make selected states immediately obvious

### Don't

- Use pure black (`#000000`) anywhere
- Use 1px solid borders for sectioning
- Use horizontal dividers or rules
- Use standard Material floating action buttons
- Use neon colors, generic gradients, or sporty visuals
- Use heavy drop shadows
- Use decorative illustrations that don't serve the content
- Crowd a screen — move overflow content to a secondary layer
- Use exclamation marks in copy

---

## 12. Screen Inventory

| Screen | Status | Notes |
|---|---|---|
| Welcome | Design phase | Onboarding entry |
| Pain: Awareness | Design phase | "You already know the plan." |
| Pain: Structure | Design phase | Chaos vs structure comparison |
| Value / Transformation | Design phase | App preview, CTA to setup |
| Step 1: Baseline | Design phase | Name, goal, units |
| Step 2: Daily Structure | Design phase | Meal count, reminder mode |
| Step 3: First Meal | Design phase | One meal setup |
| Step 4: Reminders | Design phase | Notification value pitch |
| Paywall | Design phase | Trial + subscription |
| Ready | Design phase | Summary + enter app |
| Today | Not started | Main daily view |
| Meal Detail | Not started | Ingredient checklist + actions |
| History | Not started | Streak, stats, weekly chart |
| Plans (list) | Not started | All plans overview |
| Plan Detail | Not started | Macro overview + meals |
| Profile | Not started | Settings, streak prefs, account |
| Meal Creation | Not started | Add/edit meal in library |
| Food Library | Not started | Browse/search ingredients |
| Lock Screen | Not started | Expired trial |
