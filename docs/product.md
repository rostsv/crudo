# Product Definition

## What it is
Ingredient-first nutrition adherence app. Helps users follow a plan they already have — not discover food or log meals.

**One-liner:** Crudo is a system that reminds you to eat what you already planned, and holds you accountable.

---

## Problem
Busy people (gym-focused, desk workers) know what to eat but lose track of time, skip meals, and have no way to measure their consistency over time.

---

## Target User
- Has a nutrition plan (from a coach or self-defined)
- Eats repetitive, functional ingredients — not recipes
- Struggles with consistency, not knowledge
- Wants structure and accountability, not food inspiration

---

## Core Habit Loop
1. Reminder fires → meal is due
2. Open Today screen
3. See meal block (ingredients + grams)
4. Mark each ingredient: done or not
5. See adherence update / streak

---

## Key Decisions

**Meal marking:** Ingredient-level yes/no. 5/5 = done, 4/5 or less = partial, 0/5 = skip. No gram-level tracking in MVP.

**Snooze:** Short delay only, feels like a commitment to eat soon — not an escape. Can't snooze past next meal or end of day.

**Streak:** Green (80%+ meals done) or Red (below 80%, streak resets). Binary for MVP.

**Plans:** One default plan repeating daily. User can create multiple plans and assign them to specific days of the week.

**Data hierarchy:**
- Plan → ordered list of meal slots (meal reference + time)
- Meal → name + tags (Breakfast / Lunch / Dinner / Snack / Pre-workout / Post-workout, multiple allowed) + unordered list of ingredients + auto-calculated nutrition
- Ingredient → name + macros per 100g (protein, carbs, fats — required) + calories (auto-calculated, optional manual override with 10% validation) + category (optional, for icon mapping later)
- All quantities in grams only (no unit switching in MVP)
- Meals are reusable — same meal can appear in multiple plans

**Built-in food list:** Small curated list (~50-100 items) of common whole foods, bundled with the app. No external API. Categories: meat & fish, eggs & dairy, grains & legumes, vegetables, fruits, oils & fats.

**Nutrition data (per 100g):** Required: protein, fats, carbs. Calories auto-calculated (p×4 + c×4 + f×9). If user manually enters calories, validate against calculated — allow max ~10% deviation, otherwise reject with error.

---

## Onboarding Flow
1. **Welcome screen** — "Your goals don't care about excuses. Neither does Crudo." → ask name
2. **Pain screens** (2–3 slides) — address user by name, e.g. "[Name], you already know what to eat. The problem is consistency."
3. **Quick preferences** — units (grams/ounces), reminder mode (fixed/interval), goal (cut/bulk/maintain)
4. **First meal setup** — guided, one meal only
5. **Paywall** — trial (~7 days), monthly + annual plans
6. **Rest of plan setup** — inside the app

## Onboarding Messages
- "Your goals don't care about excuses. Neither does Crudo." — welcome screen
- "[Name], you already know what to eat. The problem is consistency."
- "The problem is not information. It's the friction of modern life."
- Skipped meals / losing track / decision fatigue
- "Good plans still fail without structure."
- "Structure is the silent ingredient of every successful diet."

## Meal Detail View
- Meal name, scheduled time
- Total calories + macros (protein, carbs, fats)
- Ingredient checklist (each ingredient checkable for partial marking)
- Action buttons: Done / Partial / Skip / Snooze

## Profile Screen
- Avatar, name, email
- Subscription status / upgrade banner
- Account settings: Notifications, Goals, Units (grams/ounces)
- Streak preferences: "Count partial meals as complete" toggle, "Weekend skip" toggle
- Streak badges: encouragement badges at milestones (7, 30, 100 days)
- Sign out
- Not in MVP: appearance (dark/light mode), app language

## History Screen
- Streak card: current streak + personal best + 7-day bar visualization (green/red per day)
- Stats grid: adherence %, meals completed, avg kcal, meals skipped
- Weekly bar chart: each bar = one day, height = adherence %, green/red coloring
- Last few days: simple per-day breakdown (date, status, meals done)

## Plan Screen
Two levels:
- **Plans list** — all plans with summary (meal count, kcal, assigned days). FAB to create new.
- **Plan detail** — macro overview (total kcal, protein/carbs/fats) + meal list (name, time, kcal per meal)

## Today Screen
Top summary:
- Current streak
- Calories consumed vs planned
- Meals completed (e.g. 3/5)

Meal list — each card shows:
- Time
- Meal name
- Ingredients (brief list)
- Status: Done / Partial / Upcoming / Skipped

---

## Authentication
- Email + password
- Social: Google, Apple, Facebook
- Via Supabase or Firebase

## Notifications
- **Pre-meal** — configurable X min before meal time (e.g. 15 min)
- **At meal time** — "Time to eat [meal name]"
- **No action warning** — Y min after meal time, warns meal will be auto-skipped soon
- **Auto-skip** — meal marked skipped automatically if no action by end of window
- **End of day summary** — meals completed, streak status
- **Streak at risk** — if falling behind mid-day
- **Retroactive logging** — user can log a missed meal up to 2 hours after window, after that it stays skipped

## App Store Review Prompt
- First trigger: after completing first full day
- If dismissed: ask again at 7-day streak
- If dismissed again: never ask again

## Paywall
- ~7 day free trial → full lock on expiry
- Two plans: monthly + annual (annual ~50% cheaper)
- On expiry: full lock screen with subscription options (no read-only mode)
- Lock screen messaging: use user's own progress — "You completed X meals and built a Y-day streak. Don't let it stop here."
- Data retention: 90 days after trial expiry, then deleted
- Warning emails: day 7 and day 25 before deletion

## Reminder Modes
Two modes, user picks during onboarding:
- **Fixed time** — user sets exact time per meal during meal setup
- **Interval** — asked once during onboarding: start time + interval (e.g. every 3 hours) + number of meals (max 6). App calculates all meal times automatically. No per-meal time setting.

---

## Plan & Meal Editing Rules
- Plan is a template — edits affect future days only, not today or history
- Today's logged/skipped meals are locked — cannot be changed
- Today's upcoming meals can be edited or swapped for another meal from library
- Meal slots cannot be deleted mid-day, but content can be replaced
- Must always have at least one plan — last plan cannot be deleted
- Meals can be deleted from library but history/logged days are unaffected (snapshot approach)
- When a meal is scheduled or logged, its data is snapshotted — library changes don't affect past data

## Day Assignment
- Meals belong to the day they were scheduled, not the day they were logged
- A meal scheduled at 01:00 AM is still part of the previous day's plan
- Plan is always the source of truth for day assignment

## Onboarding — Meal Count & Slots
- Both fixed and interval modes ask for meal count upfront (max 6)
- Count is used to pre-create empty meal slots for the first plan
- Fixed mode: user sets exact time per slot
- Interval mode: times auto-calculated from start time + interval
- Validation: if last meal falls after midnight, warn user ("Your last meal will be at 01:00 AM") — no hard block

## Parked Ideas (post-MVP)
- Yellow streak state — partial day, streak survives but visually distinct
- Coach can create and push a plan directly to user
- Gram-level partial tracking per ingredient
