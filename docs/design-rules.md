\# Design System Strategy: The Editorial Wellness Framework



\## 1. Overview \& Creative North Star

The Creative North Star for this design system is \*\*"The Digital Curator."\*\* 



This is not a utility app; it is a premium editorial experience. Unlike standard fitness trackers that overwhelm the user with dense data and aggressive grids, this system prioritizes "Negative Space as a Feature." We move away from the "app-like" feel of Material Design and toward the sophisticated layout of a high-end wellness journal. 



We break the "template" look through \*\*Intentional Asymmetry\*\*—placing large Display typography off-center, allowing elements to bleed into whitespace, and using tonal shifts rather than lines to define structure. The result is a calm, focused environment that encourages habit consistency through visual serenity.



\---



\## 2. Colors \& Tonal Architecture

The palette is rooted in organic, warm neutrals to evoke a sense of health and raw ("Crudo") ingredients.



\### The "No-Line" Rule

\*\*Explicit Instruction:\*\* Designers are prohibited from using 1px solid borders for sectioning or containment. Boundaries must be defined solely through background color shifts. 

\*   \*Example:\* A `surface-container-low` card sitting on a `surface` background provides all the definition required. If you feel the need for a line, you haven't used your surface tokens correctly.



\### Surface Hierarchy \& Nesting

Treat the UI as a series of physical layers—like stacked sheets of heavy-weight vellum or fine paper.

\- \*\*Base Layer:\*\* `surface` (#faf9f6)

\- \*\*Secondary Sectioning:\*\* `surface-container-low` (#f4f3f1)

\- \*\*Active Interactive Elements:\*\* `surface-container-lowest` (#ffffff)

\- \*\*Elevated Contexts:\*\* `surface-container-high` (#e9e8e5)



\### The "Glass \& Gradient" Rule

To elevate CTAs beyond the "flat" look, use subtle linear gradients for `primary` actions. Transition from `primary` (#004d49) to `primary-container` (#196661) at a 135-degree angle. For floating navigation or modal overlays, use \*\*Glassmorphism\*\*: a semi-transparent `surface` color with a `20px` backdrop-blur to allow the content beneath to "glow" through the surface.



\---



\## 3. Typography: The Editorial Voice

We utilize \*\*Manrope\*\* for its geometric yet warm character. The hierarchy is extreme; we use very large display sizes contrasted with small, generous-letter-spaced labels.



\*   \*\*Display (lg/md/sm):\*\* Used for daily summaries or motivational milestones. \*Letter spacing: -0.02em.\*

\*   \*\*Headline (lg/md/sm):\*\* Reserved for section starts. High contrast against body text.

\*   \*\*Title (lg/md/sm):\*\* Used for card headings and navigation titles.

\*   \*\*Body (lg/md):\*\* Set with a line height of 1.6 for maximum readability and "breathability."

\*   \*\*Label (md/sm):\*\* All-caps with \*+0.05em letter spacing\* to create a sophisticated, curated feel for metadata (e.g., MACROS, CALORIES).



\---



\## 4. Elevation \& Depth

Traditional drop shadows are replaced by \*\*Tonal Layering\*\* and \*\*Ambient Diffusion.\*\*



\*   \*\*The Layering Principle:\*\* Depth is achieved by stacking. Place a `surface-container-lowest` card on a `surface-container-low` section to create a soft, natural lift.

\*   \*\*Ambient Shadows:\*\* For floating action buttons or high-priority modals, use a "Cloud Shadow." 

&#x20;   \*   \*Values:\* `Y: 20px, Blur: 40px, Color: rgba(26, 28, 26, 0.04)`. It should feel like a soft glow of light, not a hard shadow.

\*   \*\*The "Ghost Border" Fallback:\*\* If a border is required for accessibility (e.g., in a high-glare environment), use the `outline-variant` token at \*\*15% opacity\*\*. Never use 100% opaque lines.



\---



\## 5. Components



\### Buttons

\*   \*\*Primary:\*\* Gradient fill (`primary` to `primary-container`), white text, `xl` (3rem) corner radius. No shadow.

\*   \*\*Secondary:\*\* `secondary-container` fill with `on-secondary-container` text.

\*   \*\*Tertiary:\*\* Text-only with `primary` color, but with `label-md` styling (all-caps, tracked out).



\### Cards \& Lists

\*   \*\*The Divider Ban:\*\* Never use horizontal rules. Separate list items using `1.5rem` (md) vertical padding or by alternating subtle background shifts between `surface-container-low` and `surface-container-lowest`.

\*   \*\*Radius:\*\* All cards must use the `lg` (2rem) or `xl` (3rem) corner radius to maintain the "soft" aesthetic.



\### Input Fields

\*   \*\*Style:\*\* Minimalist underline or "soft box." Prefer a `surface-container-highest` bottom-only stroke (2px).

\*   \*\*States:\*\* On focus, the stroke transitions to `primary` (#004d49). Error states use `error` (#ba1a1a) text but keep the container neutral to avoid "visual shouting."



\### Nutrition-Specific Components

\*   \*\*Macro-Progress Rings:\*\* Use thin strokes (2px) for circular progress. Do not use heavy "donuts." The background track should be `outline-variant` at 20% opacity.

\*   \*\*Day-Picker:\*\* A horizontal scrolling list of dates. Use `surface-container-highest` for the active day with a `full` (9999px) radius, creating a "pill" effect.



\---



\## 6. Do’s and Don'ts



\### Do

\*   \*\*Do\*\* use asymmetrical margins (e.g., a 32px left margin and 16px right margin) to create an editorial feel.

\*   \*\*Do\*\* use `surface-dim` for inactive states rather than greying them out completely; keep the warmth.

\*   \*\*Do\*\* prioritize icons with "Light" weight strokes (1px or 1.5px) to match the Manrope typography.



\### Don't

\*   \*\*Don't\*\* use pure black (#000000). Use `on-surface` (#1a1c1a) for all high-contrast text.

\*   \*\*Don't\*\* use standard "Material" floating action buttons. Use anchored, full-width "floating sheets" that emerge from the bottom.

\*   \*\*Don't\*\* crowd the screen. If a view feels full, move 20% of the content to a secondary "Details" layer. Whitespace is your primary design tool.

