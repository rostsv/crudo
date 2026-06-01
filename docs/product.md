# Crudo — Product

What we're building and why. Companion docs: `design_system.md` (visual language) and `architecture.md` (technical structure & domain model).

## What it is
Ingredient-first nutrition adherence app. Helps users **follow a plan they already have** — not discover food or log meals.

**One-liner:** Crudo is a system that reminds you to eat what you already planned, and holds you accountable.

## Problem
Busy people (gym-focused, desk workers) know what to eat but lose track of time, skip meals, and have no way to measure their consistency over time.

## Target User
- Has a nutrition plan (from a coach or self-defined)
- Eats repetitive, functional ingredients — not recipes
- Struggles with consistency, not knowledge
- Wants structure and accountability, not food inspiration

## Core Habit Loop
1. Reminder fires → meal is due
2. Open Today screen
3. See meal block (ingredients + grams)
4. Mark each ingredient: done or not
5. See adherence update / streak

---

## MVP Scope

### Must have
| Feature | Notes |
|---|---|
| Onboarding | 13-screen flow (see below) ending in sign-up + verify |
| Authentication | Email + password; Google, Apple, Facebook |
| Free trial + paywall | ~7 days trial, monthly + annual subscription |
| One active plan, repeating daily | Default behavior |
| Multiple plans assignable by day | Mon = Plan A, Tue = Plan B, … |
| Meal slots | Pre-created from onboarding meal count |
| Meal tags | Breakfast / Lunch / Dinner / Snack / Pre-workout / Post-workout (multiple) |
| Reusable meals | Same meal across multiple plans |
| Meal blocks with ingredients + grams | User-defined, grams only |
| Built-in starter food list | Bundled, no API |
| Custom food creation | Name + protein/carbs/fats required; kcal auto-calc with 10% validation |
| Today screen | Streak, calories consumed vs planned, meals completed, meal list with status |
| Meal detail | Ingredient checklist + Done / Partial / Skip / Snooze |
| Meal marking | Per-ingredient yes/no → auto done/partial/skip |
| Meal swap | Swap an upcoming slot with a library meal |
| Auto-skip | Skipped if no action by end of window |
| Retroactive logging | Up to 2 hours after the window |
| Reminders / notifications | Pre-meal, at meal time, warning, end-of-day summary, streak-at-risk |
| Notification settings | In Profile → Notifications |
| Reminder mode: fixed time | Exact time per meal |
| Reminder mode: interval | Start time + interval + meal count (max 6), auto-calculated |
| Interval validation | Warn if last meal crosses midnight |
| Snooze | Short, commitment-style; can't push past next meal |
| Daily calories + basic macros | On Today |
| Streak system | Green (≥80%) / Red (below 80%) |
| Streak preferences | Weekend-skip toggle, count-partial-as-complete toggle |
| Streak badges | Milestones 7 / 30 / 100 days on profile avatar |
| History screen | Streak card, stats grid, weekly bar chart, recent days |
| Profile screen | Avatar, name, email, subscription, settings, sign out |
| Plan editing rules | Future-only edits, logged meals locked, history snapshots |
| App store review prompt | After first full day; retry at 7-day streak; never after 2nd dismiss |
| Data retention | 90 days after trial expiry; warning emails day 7 & day 25 |

### May have
| Feature | Notes |
|---|---|
| Yellow streak state | Partial day — streak survives, visually distinct |
| Per-meal reminder customization | Adjust time per meal block |

### Not in MVP
Recipes · Barcode scanner · Large public food database · Grocery list · Social features · Coach plan sharing · Advanced analytics · Wearables · AI meal recognition · Gram-level partial tracking.

---

## Key product decisions

- **Meal marking:** ingredient-level yes/no. All eaten = Done, some = Partial, none = Skip. No gram-level tracking in MVP.
- **Snooze:** short delay only — a commitment to eat soon, not an escape. Can't snooze past the next meal or end of day.
- **Streak:** binary — Green (≥80% meals done) or Red (resets). Yellow/partial-day is parked.
- **Plans:** one default plan repeats daily; users can create multiple and assign them to specific weekdays.
- **Food data:** built-in curated list (~50–100 whole foods, no API). Macros per 100g; kcal auto-calculated. Quantities in grams only (ounces post-MVP).

> Mechanics (data model, nutrition calc, snapshots, conflict validation, day-assignment) are specified in `architecture.md`.

---

## Onboarding Flow

> Canonical flow = the built design (`docs/design/prototype/screens/onboarding.jsx`). 13 screens, horizontal slide transitions.

1. **Welcome** — "Follow your meal plan without overthinking." Stacked meal-preview cards. CTAs: "Set up my plan" / "I already have an account".
2. **Awareness** (pain) — "You already know the plan." Friction cards: Skipped Meals, Lost Momentum, Decision Fatigue ("What should I eat now?" drains willpower).
3. **Structure** (pain) — "Structure beats willpower." / "Good plans still fail without structure." Typical-chaos vs Crudo-structure comparison.
4. **Video demo** — short product walkthrough (placeholder poster + play button; real video later).
5. **Transformation** — "Turn your plan into a routine." Highlights: Smart reminders, Structured plans, Flexible snoozing.
6. **Where did you hear about Crudo?** — single-select survey (TikTok, Instagram, YouTube, Reddit, Friend/family, App store/search, Press/blog, Somewhere else).
7. **Tried something like this before?** — single-select (MyFitnessPal, Noom, Lose It!/Cronometer, Mealime/Eat This Much, A few of these, No — first time).
8. **Baseline** — primary goal: Cut / Maintain / Bulk.
9. **Daily structure** — meal count (pre-creates empty slots, max 6).
10. **Meal timing** — Fixed meal times vs Flexible intervals (the reminder mode).
11. **Reminders** — multi-select notifications to enable: Before meals (15 min), At meal time, If running late, End of day.
12. **Sign up** — email + password.
13. **Verify** — 6-digit code, auto-advance.

Notes: sign-up + verify are at the **end** (the old "Paywall" + "Ready" steps are gone from the linear flow). The **paywall is an in-app sheet**, shown on trial expiry / upgrade taps. Units selection lives in Profile, not onboarding.

### Onboarding copy / voice
Direct, calm, premium, practical — no exclamation marks, no motivational fluff. Anchor lines:
- "Follow your meal plan without overthinking."
- "You already know the plan." / "The problem is not information. It's the friction of modern life."
- "Good plans still fail without structure." / "Structure is the silent ingredient of every successful diet."

---

## Screens

### Today
Greeting + date; **Calendar** button top-right (no bell). Intake summary card (calories consumed vs planned) with a floating streak chip and Protein/Carbs/Fats mini-bars. Day-picker. Meal list — each card: time, name, brief ingredients, status (Done / Partial / Upcoming / Skipped). End-of-day nudge.

### Meal detail
Name, scheduled time, total calories + macros, ingredient checklist (each checkable for partial marking). Actions: Done / Partial / Skip / Snooze (+ Swap for upcoming).

### Plans
- **Plans list** — read-only summary cards (name, goal/kcal tag, meal count, assigned days). Create-new entry point.
- **Plan detail** — macro overview + meal list; all editing (incl. weekday assignment) happens here via an Edit action.
- **Create plan** — dedicated screen: name, goal, repeats-on days, meal picker (with "Create new meal" shortcut), live macro preview.

### History
Streak card (current + personal best + 7-day bar), stats grid (adherence %, meals completed, avg kcal, meals skipped), weekly adherence bar chart, recent per-day breakdown.

### Profile
Avatar, name, email; subscription status / upgrade banner (gold crown). Settings: Notifications, Goals, Units. Streak preferences (count-partial-as-complete, weekend-skip). Streak badges (7/30/100). Sign out. Not in MVP: dark/light mode, app language.

### Creation
- **Add meal** — name, time, tags, ingredient list.
- **Add ingredient** — pick from library; persistent "Create custom food" CTA at top.
- **Add custom food** — name, macros per 100g (required), optional category (Meat, Fish, Eggs & Dairy, Grains, Vegetables, Fruits, Oils & Fats), kcal auto-calc with override + 10% validation.

### Sheets / popups
Snooze · Swap · Reminders · Paywall · Streak risk · Confirm · Review (app-store prompt) · Calendar (month grid + per-day stats + 30-day totals) · Plan-days editor · Schedule conflict (Override) · Toast.

---

## Authentication
Email + password; social: Google, Apple, Facebook. Backend via Supabase or Firebase (see `architecture.md`).

## Notifications
Pre-meal (configurable lead) · at meal time · no-action warning · auto-skip · end-of-day summary · streak-at-risk · retroactive logging window (2h). Managed in Profile → Notifications.

## Paywall
~7-day free trial → full lock on expiry (no read-only mode). Monthly + annual; design pricing **Monthly €6.99/mo**, **Annual €39.99/yr (≈€3.33/mo)**, annual highlighted. Lock-screen messaging uses the user's own progress ("You completed X meals and built a Y-day streak. Don't let it stop here."). Data retention: 90 days after expiry, then deleted; warning emails day 7 & day 25.

## App Store Review Prompt
First trigger after the first full day; if dismissed, ask again at a 7-day streak; if dismissed again, never ask.

---

## Parked / post-MVP
Yellow streak state (partial day survives, visually distinct) · coach creates/pushes a plan directly to a user · gram-level partial tracking per ingredient · appearance (dark/light) & app language.
