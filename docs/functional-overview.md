# Crudo — Functional Overview

The functional / UX layer: key features, use cases, user flows, and screen flows. Companion to `product.md` (why/what) and `design/prototype/` (pixel-perfect screens). Everything here is **v1 (MVP)** unless marked.

## Key features (v1)

- **Onboarding funnel** → builds the first plan, ends in a card-up-front paywall.
- **Auth** — email / Apple / Google.
- **Plans** — multiple, assigned per weekday (training/rest); reusable meals; duplicate/clone.
- **Meals & food** — build meals from a bundled food list + custom foods (P/C/F per 100g, kcal auto-calc + 10% check); grams or ounces.
- **1-tap adherence** — log a whole meal "Ate it ✓" from the notification; partial via the in-app ingredient checklist.
- **Calorie adherence + 3-state streak** — green / yellow / red, milestone badges, personal best.
- **Reminders** — pre-meal, at-meal (with actions), end-of-day, streak-at-risk.
- **History** — streak, adherence %, weekly chart, recent days.
- **Snooze · Swap · lenient missed-meal logging.**
- **Profile / settings** + subscription management.

## Actors

- **User** — self-coached, has or builds a plan, struggles with consistency. (Coach = v2.)

## Use cases (v1)

| # | Use case | Goal | Gist |
|---|----------|------|------|
| UC1 | Onboard & subscribe | Get from install to a usable, paid setup | Funnel → build first plan → signup → 7-day trial (card) |
| UC2 | Build / edit a plan | Define what to eat & when | Name, goal, weekdays, meal slots + times |
| UC3 | Create a meal / custom food | Reusable building blocks | Meal = tags + time + ingredients; food = macros/100g |
| UC4 | Follow the day | Eat the plan, on time | Reminder → 1-tap done / partial / skip |
| UC5 | Handle a missed / late meal | Recover without punishment | Log any time same day; locks at midnight |
| UC6 | Swap or snooze a meal | Adapt to real life | Swap upcoming slot for a library meal; short snooze |
| UC7 | Track consistency | Stay motivated | Streak, adherence %, history |
| UC8 | Manage plans by weekday | Training vs rest days | Assign plans to days; resolve conflicts |
| UC9 | Manage settings / subscription | Control the app | Units, goal, threshold, notifications, billing |

## User flows

**A — Onboarding → first value**
launch → pain/value screens → video + interactive demo → setup (goal · meal count · meal times · build first plan) → sign up → verify → **paywall (start 7-day trial, card)** → Today.

**B — Daily adherence loop (the core)**
reminder fires → **notification: Ate it ✓ / Snooze / Skip**
- *Ate it* → whole meal `done` (no app open)
- *open app* → ingredient checklist → check some → `partial`
- *Skip* → `skipped`
→ Today intake (consumed/planned kcal) + streak update → at midnight the day's color (green/yellow/red) locks and the streak advances/holds/resets.

**C — Create / edit a plan**
Plans → **＋** → Create plan (name · goal · repeats-on days · pick meals, or "Create new meal") → live macro preview → day-conflict check → save. Edit later only inside Plan detail.

**D — Create a meal (+ custom food)**
Add meal → name · tags · time → Add ingredient → pick from library **or** "Create custom food" (macros/100g) → set grams → save. Meal is reusable across plans.

**E — Missed / late meal (lenient)**
window passes, no action → meal *shown* auto-skipped → user opens any time that day → log done/partial → adherence recomputes → locks at midnight.

**F — Review consistency**
History tab → streak (current + best) · adherence % · weekly green/yellow/red bar · recent days. Calendar sheet (from Today) → per-day color + recent totals.

**G — Trial → subscription**
trial runs 7 days → on expiry, **full lock** → paywall (subscribe / restore) → unlock. (No read-only.)

## Screen flow (navigation map)

```
Launch
 ├─ not authenticated → Onboarding flow ─────────────────────────┐
 │     Welcome → Awareness → Structure → Video → Transformation   │
 │     → Heard-about → Baseline → Daily structure → Meal timing   │
 │     → Reminders → Interactive demo → Sign up → Verify          │
 │     → Paywall (trial) ─────────────────────────────────────────┘→ App
 └─ authenticated ──────────────────────────────────────────────────→ App

App shell — glass bottom nav, 4 tabs:
 Today · Plans · History · Profile

 Today ──▶ Meal detail ──▶ [sheets] ingredient marking · Snooze · Swap
   ├─ top-right ▶ Calendar sheet (per-day stats)
   └─ streak chip ▶ Streak-detail sheet

 Plans (read-only list) ──▶ Plan detail
   │     ├─ Edit days ▶ Plan-days editor sheet ──▶ Conflict modal
   │     ├─ ＋ ▶ Add meal ──▶ Add ingredient ──▶ Add custom food
   │     └─ tap meal ▶ Meal detail
   └─ ＋ ▶ Create plan ──▶ Add meal (─▶ Add ingredient ─▶ Add custom food)
              └─ day conflict ▶ Conflict modal

 History  (streak · adherence · weekly chart · recent days)
   └─ top-right ▶ Calendar sheet (per-day stats)

 Profile (edit name) ──▶ settings (Notifications · Units · Goal · Streak threshold)
   ├─ subscription ▶ Paywall sheet
   └─ Sign out ▶ Confirm sheet

Global sheets: Reminders · Streak-at-risk · Review prompt · Confirm · Toast/error
```

> **Onboarding deliberately diverges from the prototype** — added interactive demo + end paywall, dropped the 2nd survey, fixed-only timing (see `product.md`). In-app screens match the prototype.
>
> When a v2 arc lands (coaches, provisioning, etc.) it gets its own entries here.
