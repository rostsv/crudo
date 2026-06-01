# Spec — Design System & Theme

**Status:** approved · **Spec #1 (foundation)** · scope = the Flutter theme layer only. Components are a separate later spec.

## Goal
Turn the locked design tokens (`docs/design/prototype/app.css`, summarized in `design_system.md`) into a reusable Flutter theme in `lib/ui/core/themes/`, so every screen/widget pulls colors, type, spacing, radii, and shadows from one place. Material 3, single light theme.

## Why
`app.css` is the source of truth for values, but Flutter widgets need `ThemeData` + typed tokens. Material's `ColorScheme` can't hold Crudo's full palette (the surface ladder, gold, exact on-surface variants, cloud shadow), so we pair it with a `ThemeExtension` and static token classes.

## Approach
- **`ColorScheme`** built **explicitly** (not `fromSeed`) so hexes are exact.
- **`CrudoColors extends ThemeExtension<CrudoColors>`** for tokens M3 lacks. Accessed via `Theme.of(context).extension<CrudoColors>()!`.
- **Static const classes** (`Spacing`, `Radii`, `Shadows`, `Durations`) for values that don't vary by theme.
- **Manrope** bundled as a font asset (weights 400/500/600/700/800), wired in `pubspec.yaml`.

## Files (`lib/ui/core/themes/`)

### `colors.dart`
Raw hex consts + the extension.
```
class CrudoColors extends ThemeExtension<CrudoColors> {
  final Color surface, surfaceLow, surfaceLowest, surfaceHigh, surfaceHighest, surfaceDim;
  final Color primary, primarySoft, primaryContainer;
  final Color onSurface, onSurfaceVar, onSurfaceMut;
  final Color gold, goldSoft, error, errorSoft, success, outline;
  // copyWith + lerp (required by ThemeExtension)
}
```
Values (from `app.css`): surface `#faf9f6` · low `#f4f3f1` · lowest `#ffffff` · high `#e9e8e5` · highest `#ddddd9` · dim `#ede8e0` · primary `#004d49` · primarySoft `#196661` · primaryContainer `#cce8e4` · onSurface `#1a1c1a` · onSurfaceVar `#4a5552` · onSurfaceMut `#8a938f` · gold `#e9b949` · goldSoft `#f4dfa6` · error `#ba1a1a` · errorSoft `#ffdad6` · success `#196661` · outline `rgba(190,201,199,0.3)`.

### `typography.dart`
`CrudoText` — Manrope styles matching the scale (size / line-height / letter-spacing / weight):
- display 40 / 44 / -1.2 / 600 · displaySm 32 / 36 / -0.8 / 600
- headline 24 / 30 / -0.5 / 700 · headlineSm 20 / 28 / -0.3 / 700
- title 18 / 28 / 0 / 600
- body 14 / 22 / 0 / 500 (onSurfaceVar) · bodyLg 16 / 26 / 0 / 500
- label 10 / +1.5 tracked / uppercase / 700 (onSurfaceMut) · labelMd 12 / +1.2 / 700
Exposed as named styles **and** mapped onto a Material `TextTheme` (e.g. displayLarge←display, titleLarge←title, bodyMedium←body, labelSmall←label).

### `dimensions.dart`
- `Spacing`: xs 4 · sm 8 · md 16 · lg 24 · xl 32 · xxl 48
- `Radii`: sm 12 · md 20 · lg 32 · xl 48 · full 9999 (as `BorderRadius`/double)
- `Shadows`: cloud `0 20 40 rgba(26,28,26,.04)` · cloudDeep `0 24 60 rgba(26,28,26,.06)`
- `Durations`: fast 150ms · base 200ms

### `theme.dart`
`ThemeData crudoTheme` →
```
ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: <explicit ColorScheme.light(...)>,
  textTheme: CrudoText.textTheme,
  fontFamily: 'Manrope',
  scaffoldBackgroundColor: <surface>,
  extensions: const [CrudoColors.light],
)
```
**ColorScheme mapping:** primary `#004d49` · onPrimary `#ffffff` · primaryContainer `#cce8e4` · onPrimaryContainer `#004d49` · surface `#faf9f6` · surfaceContainerLow `#f4f3f1` · surfaceContainerLowest `#ffffff` · surfaceContainerHigh `#e9e8e5` · surfaceContainerHighest `#ddddd9` · onSurface `#1a1c1a` · onSurfaceVariant `#4a5552` · outlineVariant `#bec9c7` · error `#ba1a1a` · errorContainer `#ffdad6`. (Gold + cloud shadow are **not** M3 roles → `CrudoColors`.)

## Assets
- `assets/fonts/Manrope-{Regular,Medium,SemiBold,Bold,ExtraBold}.ttf` (400/500/600/700/800) — OFL static TTFs, **provided by the user** (see `assets/fonts/README.md`).
- `pubspec.yaml` → `flutter: fonts: - family: Manrope, fonts: [{asset, weight} × 5]`.
- Add `flutter_riverpod` etc. is **out of scope** here — this spec adds only Manrope assets + the theme.

## Out of scope
Dark/light toggle (v2) · any widget/component (next spec) · Cupertino theming · responsive scaling.

## Acceptance
- App's root `MaterialApp` uses `crudoTheme`.
- `ColorScheme` values equal the hexes above (unit test on a few key roles).
- `Theme.of(context).extension<CrudoColors>()` returns non-null with correct `gold` (= `#e9b949`) etc.
- Manrope renders (font asset loads; a `Text` shows the family).
- `flutter analyze` clean, `dart format` clean.
- Widget test: pump `MaterialApp(theme: crudoTheme, home: …)`, assert a `CrudoColors` value + a `TextTheme` size.

## Skills for implementation
`flutter-apply-architecture-best-practices` (placement), `flutter-add-widget-test` (acceptance test), `flutter-expert` (const, structure). No Riverpod needed (static theme).
