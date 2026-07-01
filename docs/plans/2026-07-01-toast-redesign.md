# Toast redesign — top-anchored, 3 levels, bordered + tinted

## Goal
Restyle and reposition the in-app toast (`lib/ui/core/widgets/toast.dart`) to match the reference: a rounded card anchored at the **top** of the screen with a **thin colored border**, a **light tinted background**, a **filled circular colored icon-badge** on the left, a **bold header + muted description**, and a **close (X)** on the right. Three levels: **green = success · yellow = warn · red = error**. The public API (`showCrudoToast(context, title, {body, kind, duration})`) and all existing call sites stay working — this is a visual + position change only.

## Architecture / tech stack
Flutter overlay toast (`OverlayEntry` + `Timer` auto-dismiss) — keep that mechanism. Design system is law; the **no-line rule forbids raw `Border`**, so the colored border is **simulated** (outer solid-color container + inner tinted container; the gap reads as the border). Tokens already exist — no palette changes:

| Kind | Border / badge | Tint (inner bg) | Badge icon |
|------|----------------|-----------------|------------|
| success | `colors.success` | `colors.primaryContainer` | `Icons.check` |
| warn | `colors.gold` | `colors.goldSoft` | `Icons.priority_high` |
| error | `colors.error` | `colors.errorSoft` | `Icons.close` |

Text on the (now light) card uses `colors.onSurface` (header) / `colors.onSurfaceMut` (description). Badge glyph is `colors.surfaceLowest` (white) on the accent fill.

## How to work
Single task. Read `AGENTS.md`, `docs/design_system.md`, and the named `.agents/skills` first. TDD, real values, tokens only. **Do not commit** — end with "report done for review".

---

## Task 1 — Rewrite the toast visual + position

**Role:** Flutter UI engineer.
**Goal:** The bordered/tinted top toast above, without breaking callers.
**Files:** `lib/ui/core/widgets/toast.dart`, `test/ui/core/widgets/toast_test.dart` (create/adjust).
**Skills:** `flutter-expert`, `flutter-fix-layout-issues`, `flutter-add-widget-test`, `dart-run-static-analysis`.

**Contract:**
- Keep the signature `void showCrudoToast(BuildContext, String title, {String? body, ToastKind kind, Duration duration})` and the `ToastKind { success, warn, error }` enum. Keep the `OverlayEntry` + auto-dismiss `Timer` + the `toast-dismiss` X key.
- **Position:** anchor at the **top** — `Positioned(top: MediaQuery.of(context).padding.top + Spacing.sm, left: Spacing.md, right: Spacing.md, ...)`. (Was bottom.) Consider a short fade/slide-in for polish (optional, keep simple).
- **Per-kind mapping:** derive `(border, tint, badgeIcon)` from `kind` per the table above.
- **Simulated border:** outer `Container` `color: border`, `borderRadius: Radii.lg`, `padding: EdgeInsets.all(_borderWidth)` where `static const _borderWidth = 1.5;` (matches the painted-ring stroke used elsewhere). Inner `Container` `color: tint`, `borderRadius: Radii.md`, `padding: EdgeInsets.all(Spacing.md)`. Keep `Shadows.cloud`/`cloudDeep` on the outer for lift.
- **Icon badge:** a circular `Container` (`shape: BoxShape.circle`, `color: border`, sized ~`IconSizes.lg` square via padding around an `Icon(badgeIcon, size: IconSizes.md, color: colors.surfaceLowest)`), leading the row, `crossAxisAlignment: start`.
- **Text block** (`Expanded`): `Text(title)` in `CrudoText.body` **bold** `colors.onSurface`; if `body != null`, a `Spacing.xs` gap then `Text(body)` in `CrudoText.body` `colors.onSurfaceMut`.
- **Close:** trailing `Icons.close`, `IconSizes.sm`, `colors.onSurfaceMut`, `key: ValueKey('toast-dismiss')`, taps `dismiss()`.
- Remove the old dark-surface styling and the left accent-bar (the border replaces it).

**Acceptance:**
- Each `ToastKind` renders its border/tint/badge-icon from the table; a widget test pumps one of each and asserts the mapping (badge color + icon per kind).
- Toast appears near the top (assert vertical position < screen center), title bold, optional body muted, X dismisses.
- No raw `Border` / `BoxBorder` used (border is the nested-container trick); no ad-hoc colors (tokens only).
- Existing call sites compile unchanged; `flutter test --timeout=90s` green; `flutter analyze` + `dart format` clean.

**Out of scope:** adding a 4th (info/blue) level; changing call sites' messages; palette/token changes.
