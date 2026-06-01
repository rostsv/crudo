# Crudo — Product

What we're building and why. Companion docs: `design_system.md` (visual language), `architecture.md` (technical structure & domain model), `workflow.md` (how we build it).

## What it is
Ingredient-first nutrition **adherence** app. Helps users **follow a plan they already have** — not discover food or log meals. The simplest path to **consistency**.

**One-liner:** Crudo reminds you to eat what you already planned, and holds you accountable.

## Positioning
- **Ambition:** indie launch, monetize sustainably.
- **Beachhead user:** self-coached gym-goers — know their macros, eat repetitive functional foods, often run **training-day vs rest-day** eating, fail on *consistency* not knowledge.
- **Differentiator:** frictionless adherence to *your own* plan + light motivation (streaks). **Not** a food logger / calorie database / discovery app. The win is "did I follow my plan today," not "what did I eat."
- **Coaches** (push a plan to clients) = a deliberate **v2** direction; v1 keeps the door open, doesn't build it.

## Problem
Busy, plan-aware people lose track of time, skip meals, and have no way to measure consistency over time.

## Core habit loop
1. Reminder fires → meal due.
2. **One tap "Ate it ✓"** from the notification (or open the app for a partial).
3. Calorie adherence updates.
4. Streak reflects the day.

---

## MVP (v1)

### Onboarding
Full funnel (demonstrate value → personalize → commit), ending in a card-up-front paywall. This **supersedes** the prototype's onboarding (`docs/design/prototype/screens/onboarding.jsx` is visual reference only).

1. Welcome
2. Awareness (pain)
3. Structure (pain)
4. Video demo (tell)
5. Transformation
6. "Where did you hear about Crudo?" (attribution survey)
7. Baseline — primary goal (Cut / Maintain / Bulk) — a **label/personalization**, see Adherence
8. Daily structure — meal count (pre-creates slots, max 6)
9. Meal timing — set your meal times (**fixed**; interval → v2)
10. Reminders — which notifications to enable
11. **Interactive demo** (show) — tap-mark a sample meal, watch the streak tick
12. Sign up — email / Apple / Google
13. Verify — 6-digit code (skipped for Apple/Google)
14. **Paywall** — last screen, after setup (max sunk-cost): 7-day free trial, **card up front** (store subscription, auto-converts), monthly + annual, annual highlighted

Setup (steps 7–9) builds the user's **first plan**: meals + ingredients + grams/oz. Voice: direct, calm, premium — no exclamation marks, no fluff.

### Plans
- **Multiple plans**, assigned per weekday (e.g. Training-day / Rest-day, or per-day). Onboarding builds one; more added in-app.
- **Reusable meals** (a meal dropped into any plan) + **duplicate/clone** plan & meal (build once, clone, tweak). *(Starter template plans → v2.)*
- Plans **list = read-only** summary; all editing (incl. weekday assignment) in **Plan detail**. **Day-conflict validation** when two plans claim the same weekday (block + override).
- Must always have ≥1 plan.

### Meals & food
- **Meal** = name + tags (Breakfast/Lunch/Dinner/Snack/Pre-workout/Post-workout, multiple) + fixed time + ingredients (food + quantity). Nutrition auto-summed.
- **Built-in food list** (~50–100 whole foods, bundled, no API) + **custom food** (name, P/C/F per 100g required, kcal auto-calc `p×4+c×4+f×9` with ±10% manual-override check, optional category).
- **Units: grams + ounces**, user-selectable (stored as grams internally).

### Daily loop
- **Today:** greeting + date, calendar button, intake card (**consumed vs planned kcal**) + P/C/F mini-bars (**display-only**), streak chip, day-picker, meal list (time · name · ingredients · status).
- **Reminder** (fixed per-meal time) → notification **Ate it ✓ / Snooze / Skip**. "Ate it" = whole meal done (all ingredients), one tap, no app open.
- **Partial** = open app → ingredient checklist; **consumed = the checked ingredients' kcal**.
- **Missed meals = lenient:** auto-skip is *shown*, but the meal can still be logged **anytime that day**; locks at **midnight** (the day is source of truth).
- **Snooze:** short, commitment-style; can't push past the next meal or midnight.
- **Meal status:** Done · Partial · Upcoming · Skipped.

### Adherence & streak (the motivation engine)
- **Daily adherence % = consumed planned-kcal ÷ total planned-kcal.** Consumed comes from ingredient-level marks (Done = whole meal; Partial = checked ingredients; Skip = 0). You only ever mark *planned* items → consumed ≤ planned.
- **"Planned kcal" = the sum of that day's plan** (goal is just a label; no separate numeric target).
- **Three-state day:**
  - **Green** — `% ≥ threshold` → streak **+1**
  - **Yellow** — `50% ≤ % < threshold` → streak **holds** (survives, doesn't grow or reset)
  - **Red** — `% < 50%` → streak **resets to 0**
- **Threshold** = the green line: default **80%**, user-selectable (70 / 80 / 90 / 100). Red floor fixed at 50%.
- Track **personal best**; milestone **badges** at 7 / 30 / 100 days.

### History
Streak card (current + personal best, colored day bar), adherence %, weekly bar chart (green/yellow/red), recent-days breakdown.

### Profile & settings
Avatar, name, email; subscription status / upgrade; settings: units (g/oz), goal, notifications, **streak threshold**; sign out.

### Notifications (v1)
Pre-meal (configurable lead) · at meal time · end-of-day summary · streak-at-risk. (No-action warning folds into end-of-day.)

### Auth
Email + password, **Apple**, **Google** (no Facebook). Backend Supabase or Firebase (see `architecture.md`).

### Paywall / monetization
**No freemium.** 7-day free trial, **card up front** via App/Play subscription (auto-converts unless cancelled). Monthly + annual, annual highlighted (placeholder €6.99/mo, €39.99/yr ≈ €3.33/mo). Full lock on expiry (no read-only). Lock-screen messaging uses the user's own progress. Data retention 90 days after expiry, then deleted; warning emails day 7 & 25 (backend).

### Screens (designed in `docs/design/prototype/`)
Today · Meal detail · Plans (list + detail + create) · History · Profile · Add meal · Add ingredient · Add custom food. Sheets: Snooze · Swap · Reminders · Paywall · Streak risk · Confirm · Review (app-store prompt) · Calendar (per-day stats) · Plan-days editor · Schedule conflict · Toast. *(Prototype is the pixel-perfect visual target; onboarding flow above supersedes the prototype's.)*

---

## Parked (v2+)

**Provisioning — "plan → groceries"**
- Barcode scan to add foods (introduces an external food DB)
- Price / cost per food
- Total products consumed over time
- Shopping list generated from plans
- Pantry / fridge stock (list = needed − in-stock)
- Grocery-delivery integrations (very later)

**Coaches / B2B2C**
- Coach creates & pushes a plan to clients; adherence visibility

**Other**
- Interval reminder mode · starter template plans · weekend-skip from streak · macro-level adherence (not just kcal) · recommended daily kcal from personal stats (TDEE) · iOS Live Activity / lock-screen widget · gram-level partial (vs ingredient on/off) · dark/light mode · localization

> Data-model implications of these are deferred — to be discussed when each is scheduled.

---

## Key decisions (rationale)
- **Calorie-based adherence, not meal-count** — a skipped snack hurts less than a skipped main meal; ties directly to the Today "consumed vs planned" number.
- **1-tap from the notification** — adherence must be near-zero friction; ingredient checklist is the exception (partial), not the default.
- **Lenient missed-meals + yellow streak** — reduce rage-quit; any real effort keeps the streak alive, only a no-show day breaks it.
- **Follow your plan, not a target** — planned kcal = your plan's sum; keeps Crudo an adherence tool, not a tracker.
- **Multi-plan is core** — the gym wedge genuinely needs training/rest-day plans.

> Mechanics (data model, nutrition calc, snapshots, day-assignment, conflict validation) live in `architecture.md`.
