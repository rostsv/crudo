# Stitch Prompt — Crudo Onboarding Flow

Design a mobile app onboarding flow for a premium nutrition adherence app called **Crudo**.

---

## PRODUCT CONTEXT

Crudo is a mobile app for people who already have a meal plan or want a structured daily eating plan, but struggle to follow it consistently.

The app helps users:
- Follow a predefined daily plan
- Track ingredients in grams
- Get reminders so they do not skip meals
- Mark meals as done / partial / skipped
- Build consistency through streaks

This is NOT:
- A generic calorie counter
- A recipe app
- A social fitness app
- A bodybuilding aesthetic app
- A huge database-first nutrition tracker

This IS:
- A focused adherence app
- Structured, minimal, and premium
- About consistency, reminders, and follow-through
- Mobile-first and optimized for daily use

---

## BUSINESS MODEL

There is NO free tier.
The app uses a free trial (~7 days), then subscription only.
The onboarding should build emotional understanding first, explain the pain clearly, show the transformation, then lead into setup and a trial paywall.

---

## TARGET USER

A person who already knows roughly what they should eat, but fails because of inconsistency:
- They skip meals
- They forget to eat on time
- Their day gets busy
- They lose discipline because they do not have structure
- Other apps feel too heavy or too generic

---

## PRIMARY GOAL OF THIS FLOW

Help the user feel:
1. "Yes, this is my problem."
2. "This app is different."
3. "This would genuinely help me."
4. "I understand why it costs money."

---

## FRAME / DEVICE

Design for mobile.
Primary frame style: 390 x 844.
Keep layouts realistic for smaller phones too.
Use large touch targets and mobile-safe spacing.

---

## VISUAL STYLE

### Color Tokens
- Base background: `#faf9f6` (warm off-white)
- Secondary surface: `#f4f3f1` (subtle beige, used for sections and grouping)
- Card / active interactive surface: `#ffffff` (clean white)
- Elevated context: `#e9e8e5` (muted warm gray)
- Primary accent: `#004d49` (deep teal)
- Primary container: `#196661` (lighter teal, used for gradient endpoints)
- High-contrast text: `#1a1c1a` (near-black, never pure black)
- Secondary / muted text: warm gray, derived from surface palette
- Error: `#ba1a1a`
- Success / completed: teal primary, used for checkmarks and completed states

### Typography
- Font: **Manrope** (geometric, warm character)
- Headlines: very large, bold weight, tight leading, left-aligned. Letter-spacing `-0.02em`. Editorial feel — the headline should dominate the screen.
- Section labels: all-caps, letter-spacing `+0.05em`, small size — e.g., NAME, PRIMARY GOAL, MEASUREMENT UNITS, STEP 1 OF 4
- Body text: regular weight, line-height `1.6`, warm gray or muted text color
- Button text: medium weight, white on primary CTA

### Elevation & Depth
- No traditional drop shadows
- Depth through tonal layering — stack surface tokens to create visual lift (e.g., white card on beige background)
- Floating elements: Cloud Shadow — `Y: 20px, Blur: 40px, Color: rgba(26, 28, 26, 0.04)`
- No 1px solid borders for sectioning — boundaries defined by background color shifts only

---

## REUSABLE COMPONENT PATTERNS

These patterns must stay visually consistent across every screen:

### Wordmark
- "Crudo" in title case (not all-caps), teal primary color, positioned top-left or top-center depending on screen type
- Intro screens: centered
- Setup screens: top-left

### Navigation
- Intro/pain screens: no top navigation, or a subtle X close button top-right
- Setup screens: back arrow (←) top-left, "Crudo" wordmark center or left
- Never use a hamburger menu in onboarding

### Step Progress Indicator (setup screens only)
- Label: "STEP X OF 4" — all-caps, tracked letter-spacing, small, label style
- Segmented progress bar below the label: 4 segments, filled segments = completed + current step, unfilled = remaining
- Positioned near the top of the screen, below the navigation bar
- Intro/pain screens do NOT show step indicators

### Primary CTA Button
- Full-width, sticky to bottom of screen
- Linear gradient fill: `#004d49` → `#196661` at 135°
- White text, medium weight
- Corner radius: `3rem` (fully rounded)
- Text includes `→` arrow suffix (e.g., "Continue →")
- No shadow on the button itself

### Secondary / Ghost Button
- Text-only, teal primary color, label style (all-caps, tracked) or regular style depending on context
- Used for "I already have an account", "Restore purchase", "← Back"

### Selection Cards (for choices like goal, meal count)
- Large rounded rectangles (`2rem` radius), white fill on beige background
- Center-aligned content: icon + title + subtitle
- Unselected: white card, no border
- Selected: teal border (`2px`), subtle teal tint on background or icon
- Large tap targets — minimum 80px height

### Pill Selectors (for binary choices like Grams/Ounces, Fixed/Flexible)
- Rounded pill shape (`9999px` radius)
- Unselected: outline or `surface-container` fill
- Selected: primary teal fill with white text
- Placed inline, side by side

### Pain Point Cards
- Rounded card (`2rem` radius), `surface-container-low` background
- Left: circular teal icon badge (icon on teal-tinted circle)
- Right: bold title + muted description text
- Stacked vertically with spacing between

### Quote / Insight Block
- Italic text, slightly larger body size
- Optionally placed in a teal-tinted card for emphasis (like the "Structure is the silent ingredient..." block)
- Used once per screen max, as an emotional anchor

### Section Labels
- All-caps, tracked (`+0.05em`), small size, `#1a1c1a` or muted color
- Used above form groups: NAME, PRIMARY GOAL, MEASUREMENT UNITS
- 8–12px margin below label, before the content

---

## DESIGN RULES

- One primary action per screen
- Strong focus and clear hierarchy
- Short, high-impact copy
- Do not overcrowd screens — whitespace is a primary design tool
- Keep design implementable in Flutter
- Sticky bottom CTA on every screen
- Selected states must be immediately obvious

**Strictly forbidden:**
- No 1px solid borders for sectioning — use background color shifts only
- No horizontal dividers / rules — use vertical padding or alternating surface shifts
- No generic AI gradients — only the specific CTA gradient defined above
- No pure black (`#000000`) — use `#1a1c1a`
- No neon colors
- No sporty or bodybuilding visuals
- No decorative clutter or illustration overload
- Do not make it feel like a calorie database app
- Do not make it feel like a wellness meditation app
- No hamburger menus

---

## ONBOARDING FLOW

### Screen 1 — WELCOME

**Purpose:** Strong first impression and quick positioning.

**Layout:**
- "Crudo" wordmark centered at top, teal color
- Hero visual in upper half: 3 stacked meal preview cards (cascading, slightly offset), showing meal times + meal names + done/pending checkmarks. Cards use white fill on beige background. This previews the core app experience.
- Large headline below the visual, centered: **"Follow your meal plan without overthinking"**
- Supporting text: "Build your meals once, get reminded on time, and keep your streak alive."
- Primary CTA: "Set up my plan →"
- Secondary ghost button below: "I already have an account"
- Footer label at very bottom: "YOUR DIGITAL SANCTUARY FOR NUTRITION" (all-caps, tracked, small, muted)

**Design:**
- Centered composition
- Maximum whitespace
- The meal cards should look like real UI — not abstract illustrations
- Premium, confident first screen

---

### Screen 2 — PAIN SCREEN: AWARENESS

**Purpose:** Help the user recognize the real problem.

**Layout:**
- "Crudo" wordmark top-left, X close button top-right
- Large headline, left-aligned: **"You already know the plan."**
- Supporting text: "The problem is not information. It's the friction of modern life."
- Three pain point cards stacked vertically:
  - **Skipped Meals** — "Meetings run over, commutes take longer, and suddenly it's 3 PM and you haven't eaten." (icon: X mark in teal circle)
  - **Losing Track** — "Even the best plans dissolve when the day gets loud. Out of sight becomes out of mind." (icon: clock or eye in teal circle)
  - **Decision Fatigue** — "Most plans fail because they require too much thinking, when you're already exhausted." (icon: brain or refresh in teal circle)
- Italic quote block at bottom: *"We don't need more recipes. We need a way to stay present with the choices we've already made."*
- Primary CTA: "Continue →"

---

### Screen 3 — PAIN SCREEN: STRUCTURE

**Purpose:** Name the cost of inconsistency and introduce the solution concept.

**Layout:**
- "Crudo" wordmark top-left, X close button top-right
- Large headline, left-aligned: **"Good plans still fail without structure"**
- Supporting text: "When meals are delayed or skipped, consistency breaks — **even if your plan is good.**"
- Two-section comparison:
  - Section label: "TYPICAL CHAOS"
    - Card: Skipped Breakfast — "Too busy to eat" — 09:15 AM (red X icon)
    - Card: Random Snacking — "High-sugar spike" — 03:45 PM (red X icon)
  - "VS" separator (small, centered, muted)
  - Section label: "CRUDO STRUCTURE"
    - Card: High-Protein Morning — "Metabolic baseline set" — 08:00 AM (teal check icon)
    - Card: Planned Fueling — "Consistent energy levels" — 01:00 PM (teal check icon)
- Insight block (teal-tinted card): **"Structure is the silent ingredient of every successful diet."**
- Primary CTA: "Continue →"

---

### Screen 4 — VALUE / TRANSFORMATION

**Purpose:** Show how Crudo solves the problem.

**Layout:**
- "Crudo" wordmark top-left, X close button top-right
- Large headline, left-aligned: **"Turn your plan into a routine."**
- Supporting text: "Ingredients, gram amounts, reminders, and quick check-ins help you stay on track every day."
- Visual: elegant preview of the app — show a mini Today screen with meal cards, a streak badge, a reminder notification. Should look like real app UI, not an illustration.
- Primary CTA: "Set up my plan →"

---

### Screen 5 — STEP 1 OF 4: DEFINE YOUR BASELINE

**Purpose:** Personalize — name, goal, and units.

**Layout:**
- Back arrow (←) top-left, "Crudo" wordmark top-center, help icon (?) top-right
- Step progress: "STEP 1 OF 4" label + segmented bar (1 of 4 filled)
- Title: **"Define your baseline."**
- Subtitle: "Set up your profile to curate your nutritional journey."
- Section label: "NAME"
  - Text input field, placeholder: "How should we call you?"
- Section label: "PRIMARY GOAL"
  - 3 selection cards (vertical stack):
    - **Cut** — icon: downward arrows — subtitle: "Caloric deficit"
    - **Maintain** — icon: horizontal arrow — subtitle: "Equilibrium"
    - **Bulk** — icon: upward arrows — subtitle: "Caloric surplus"
- Section label: "MEASUREMENT UNITS"
  - Pill selector: **Grams** / **Ounces**
- Sticky bottom CTA: "Continue →"

---

### Screen 6 — STEP 2 OF 4: DAILY STRUCTURE

**Purpose:** Define meal count and reminder style.

**Layout:**
- Back arrow (←) top-left, "Crudo" wordmark top-center
- Step progress: "STEP 2 OF 4" label + segmented bar (2 of 4 filled)
- Title: **"How many meals do you eat in a day?"**
- 4 selection cards in 2x2 grid:
  - **03** — "Standard" — "Classic structure"
  - **04** — "Active" — "Fuelled performance"
  - **05** — "Frequent" — "Smaller portions"
  - **06** — "Athlete" — "High metabolism"
- Section with icon: "How should reminders work?"
  - Pill selector: **Fixed meal times** / **Flexible intervals**
  - Helper text below: contextual description of selected mode (e.g., "We'll notify you at specific times to ensure you stay consistent with your schedule.")
- "← Back" link bottom-left, "Continue →" CTA bottom-right

---

### Screen 7 — STEP 3 OF 4: FIRST MEAL SETUP

**Purpose:** Create one usable meal — low friction.

**Layout:**
- Back arrow (←) top-left, "Crudo" wordmark top-center
- Step progress: "STEP 3 OF 4" label + segmented bar (3 of 4 filled)
- Title: **"Let's add your first meal."**
- Subtitle: "You'll add the rest after setup."
- Meal name input — placeholder: "e.g. Breakfast"
- Meal time selector (tappable time picker)
- Section label: "ADD INGREDIENTS"
  - Starter ingredient chips (tappable, wrap layout):
    Chicken, Rice, Oats, Eggs, Yogurt, Tomato, Banana, Olive oil
  - Unselected chips: `surface-container-high` background, dark text
  - Selected chips: `primary` fill, white text
  - "Add custom ingredient" text link below chips
- Sticky bottom CTA: "Continue →"

---

### Screen 8 — STEP 4 OF 4: SMART REMINDERS

**Purpose:** Make notification value clear before permission request and paywall.

**Layout:**
- Back arrow (←) top-left, "Crudo" wordmark top-center
- Step progress: "STEP 4 OF 4" label + segmented bar (4 of 4 filled)
- Title: **"Don't let a busy day break your plan."**
- Supporting text: "Crudo reminds you when it's time to eat, so your plan survives real life."
- Mock notification card (looks like a real system notification):
  - App icon + "Crudo" + "JUST NOW"
  - **"Meal 3 is due."**
  - "You have 450 kcal left for today. Don't break your streak."
  - Actions: "LOG MEAL" / "SNOOZE"
- Info block below:
  - Icon: bell
  - **"Smart Notifications"**
  - "We only send meaningful reminders tied to your schedule. No noise, just focus."
- Primary CTA: "Continue →"
- Footer label: "YOU CAN CHANGE NOTIFICATION SETTINGS ANYTIME"

---

### Screen 9 — TRIAL PAYWALL

**Purpose:** Convert users after value and setup are clear.

**Layout:**
- X close button top-right (no back arrow — this is a conversion screen)
- Headline: **"Stay consistent with Crudo Pro"**
- Short intro: "You've built your plan. Now use reminders, adherence tracking, and streaks to actually follow it."
- Benefits list (teal checkmark + text, stacked):
  - Structured daily meal plan
  - Ingredient-based tracking in grams
  - Smart reminders at meal time
  - Done / partial / skipped meal tracking
  - Weekly adherence history
  - Streaks and consistency support
- Plan toggle or cards:
  - **Monthly** — price shown
  - **Yearly** — price shown + "Best value" label (visually preferred via teal border or highlight, not deceptive)
- Primary CTA: "Start 7-day free trial →"
- Billing text: "Then €X.XX/month or €XX.XX/year. Cancel anytime before trial ends."
- Secondary link: "Restore purchase"

**Design rules:**
- Premium and calm — no fake urgency, no countdown timers
- Clear hierarchy: headline → benefits → pricing → CTA
- Yearly highlighted subtly, not aggressively

---

### Screen 10 — READY

**Purpose:** Confirm setup and transition into the app.

**Layout:**
- "Crudo" wordmark top-center
- Teal circle with checkmark icon, centered
- Headline: **"READY."**
- Supporting text: "Your personalized plan has been created."
- Summary card (`surface-container-low` background):
  - Label: "DAILY TARGET"
  - Large display: **"2100 kcal"**
  - Row of stats: Meals: 5 | First reminder: 07:30
- Primary CTA: "Go to Today →"

**Design:**
- Calm and confirming
- The summary card should feel like a real data card, not decorative
- Only show data that the user actually configured (meals, kcal, reminder time)

---

## COPY TONE

- Direct
- Calm
- Premium
- Practical
- Not motivational fluff
- Not cheesy fitness language
- No exclamation marks
- Address real problems, not aspirational goals

---

## UX PRINCIPLES

- Onboarding should feel like a guided setup, not a slideshow
- Each screen has one main job
- Copy is concise — if it can be shorter, make it shorter
- User follows a clear arc: pain → solution → setup → trial
- Visual consistency across the whole flow
- Reuse cards, buttons, progress patterns, and selection components
- Keep layouts realistic for Flutter implementation

---

## OUTPUT

Generate a polished mobile onboarding flow with all 10 screens above.
Every screen must use the same component patterns defined in the "Reusable Component Patterns" section — step indicators, CTAs, cards, pills, labels, and navigation should look identical across screens.
Keep it cohesive, premium, minimal, and conversion-aware.
Make it look like a focused startup product, not a generic AI fitness template.
