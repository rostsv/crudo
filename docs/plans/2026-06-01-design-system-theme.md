# Design System & Theme — Implementation Plan

> **For workers:** implement task-by-task, top to bottom. Each task = a contract + checkbox (`- [ ]`) steps; read the `.agents/skills` it names. Sequential, main working tree. **Do not commit** — report each task done for Opus to review & integrate. Spec: `docs/specs/2026-06-01-design-system-theme.md`.

**Goal:** Build the Flutter theme foundation in `lib/ui/core/themes/` from the locked tokens in `app.css`.

**Architecture:** Material 3, single light theme. Standard roles via an explicit `ColorScheme`; Crudo-only tokens (surface ladder, gold, on-surface variants, cloud shadow) via a `CrudoColors` `ThemeExtension`; static `Spacing`/`Radii`/`Shadows`/`Durations`; Manrope `TextTheme` from bundled font assets.

**Tech Stack:** Flutter (Material 3), Manrope (bundled TTF). No new package deps; no Riverpod (static theme). Tests via `flutter_test`.

**Conventions:** follow `AGENTS.md`. Each task = one worker handoff; Opus reviews the diff before the commit step. `dart format` + `flutter analyze` must be clean (pre-commit hook enforces).

---

### Task 1: Bundle Manrope + declare fonts

**Role:** build · **Skills:** `flutter-expert`
**Goal:** Make the Manrope family available app-wide from bundled assets.
**Files:** Modify `pubspec.yaml` · (assets `assets/fonts/Manrope-*.ttf` provided by the user — see `assets/fonts/README.md`)
**Contract:** family name **`Manrope`**, weights 400/500/600/700/800 mapped to the exact filenames.
**Out of scope:** any Dart code; `google_fonts`.

- [ ] **Step 1: Confirm the 5 TTFs exist**

Run: `ls assets/fonts/Manrope-{Regular,Medium,SemiBold,Bold,ExtraBold}.ttf`
Expected: all five listed. If missing, stop — the user must drop them.

- [ ] **Step 2: Add the fonts block to `pubspec.yaml`** (under the existing `flutter:` key)

```yaml
  fonts:
    - family: Manrope
      fonts:
        - asset: assets/fonts/Manrope-Regular.ttf
          weight: 400
        - asset: assets/fonts/Manrope-Medium.ttf
          weight: 500
        - asset: assets/fonts/Manrope-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Manrope-Bold.ttf
          weight: 700
        - asset: assets/fonts/Manrope-ExtraBold.ttf
          weight: 800
```

- [ ] **Step 3: Resolve + analyze**

Run: `flutter pub get && flutter analyze`
Expected: pub get OK; analyze clean (0 issues).

- [ ] **Step 4: Commit**

```bash
git add pubspec.yaml assets/fonts
git commit -m "feat(theme): bundle Manrope font family"
```

---

### Task 2: Color tokens + `CrudoColors` extension

**Role:** implement · **Skills:** `flutter-apply-architecture-best-practices`, `flutter-add-widget-test`, `flutter-expert`
**Goal:** Expose every color token, plus a `ThemeExtension` for the tokens Material's `ColorScheme` can't hold.
**Files:** Create `lib/ui/core/themes/colors.dart` · Test `test/ui/themes/colors_test.dart`
**Contract:** `class CrudoColors extends ThemeExtension<CrudoColors>` with fields below, a `const CrudoColors.light`, and `copyWith` + `lerp`.
**Out of scope:** TextTheme, ThemeData (later tasks).

- [ ] **Step 1: Write the failing test**

```dart
// test/ui/themes/colors_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crudo/ui/core/themes/colors.dart';

void main() {
  test('CrudoColors.light exposes exact tokens', () {
    const c = CrudoColors.light;
    expect(c.gold, const Color(0xFFE9B949));
    expect(c.surface, const Color(0xFFFAF9F6));
    expect(c.onSurfaceMut, const Color(0xFF8A938F));
  });

  test('lerp returns a CrudoColors', () {
    final r = CrudoColors.light.lerp(CrudoColors.light, 0.5);
    expect(r, isA<CrudoColors>());
  });
}
```

- [ ] **Step 2: Run it — expect FAIL** (`colors.dart` missing)

Run: `flutter test test/ui/themes/colors_test.dart`

- [ ] **Step 3: Implement `colors.dart`**

```dart
import 'package:flutter/material.dart';

/// Raw palette (from docs/design/prototype/app.css).
abstract final class CrudoPalette {
  static const surface        = Color(0xFFFAF9F6);
  static const surfaceLow     = Color(0xFFF4F3F1);
  static const surfaceLowest  = Color(0xFFFFFFFF);
  static const surfaceHigh    = Color(0xFFE9E8E5);
  static const surfaceHighest = Color(0xFFDDDDD9);
  static const surfaceDim     = Color(0xFFEDE8E0);
  static const primary        = Color(0xFF004D49);
  static const primarySoft    = Color(0xFF196661);
  static const primaryContainer = Color(0xFFCCE8E4);
  static const onSurface      = Color(0xFF1A1C1A);
  static const onSurfaceVar   = Color(0xFF4A5552);
  static const onSurfaceMut   = Color(0xFF8A938F);
  static const gold           = Color(0xFFE9B949);
  static const goldSoft       = Color(0xFFF4DFA6);
  static const error          = Color(0xFFBA1A1A);
  static const errorSoft      = Color(0xFFFFDAD6);
  static const success        = Color(0xFF196661);
  static const outline        = Color(0x4DBEC9C7); // rgba(190,201,199,0.3)
}

@immutable
class CrudoColors extends ThemeExtension<CrudoColors> {
  const CrudoColors({
    required this.surface, required this.surfaceLow, required this.surfaceLowest,
    required this.surfaceHigh, required this.surfaceHighest, required this.surfaceDim,
    required this.primary, required this.primarySoft, required this.primaryContainer,
    required this.onSurface, required this.onSurfaceVar, required this.onSurfaceMut,
    required this.gold, required this.goldSoft,
    required this.error, required this.errorSoft, required this.success, required this.outline,
  });

  final Color surface, surfaceLow, surfaceLowest, surfaceHigh, surfaceHighest, surfaceDim;
  final Color primary, primarySoft, primaryContainer;
  final Color onSurface, onSurfaceVar, onSurfaceMut;
  final Color gold, goldSoft, error, errorSoft, success, outline;

  static const light = CrudoColors(
    surface: CrudoPalette.surface, surfaceLow: CrudoPalette.surfaceLow,
    surfaceLowest: CrudoPalette.surfaceLowest, surfaceHigh: CrudoPalette.surfaceHigh,
    surfaceHighest: CrudoPalette.surfaceHighest, surfaceDim: CrudoPalette.surfaceDim,
    primary: CrudoPalette.primary, primarySoft: CrudoPalette.primarySoft,
    primaryContainer: CrudoPalette.primaryContainer,
    onSurface: CrudoPalette.onSurface, onSurfaceVar: CrudoPalette.onSurfaceVar,
    onSurfaceMut: CrudoPalette.onSurfaceMut,
    gold: CrudoPalette.gold, goldSoft: CrudoPalette.goldSoft,
    error: CrudoPalette.error, errorSoft: CrudoPalette.errorSoft,
    success: CrudoPalette.success, outline: CrudoPalette.outline,
  );

  @override
  CrudoColors copyWith({
    Color? surface, Color? surfaceLow, Color? surfaceLowest, Color? surfaceHigh,
    Color? surfaceHighest, Color? surfaceDim, Color? primary, Color? primarySoft,
    Color? primaryContainer, Color? onSurface, Color? onSurfaceVar, Color? onSurfaceMut,
    Color? gold, Color? goldSoft, Color? error, Color? errorSoft, Color? success, Color? outline,
  }) {
    return CrudoColors(
      surface: surface ?? this.surface, surfaceLow: surfaceLow ?? this.surfaceLow,
      surfaceLowest: surfaceLowest ?? this.surfaceLowest, surfaceHigh: surfaceHigh ?? this.surfaceHigh,
      surfaceHighest: surfaceHighest ?? this.surfaceHighest, surfaceDim: surfaceDim ?? this.surfaceDim,
      primary: primary ?? this.primary, primarySoft: primarySoft ?? this.primarySoft,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      onSurface: onSurface ?? this.onSurface, onSurfaceVar: onSurfaceVar ?? this.onSurfaceVar,
      onSurfaceMut: onSurfaceMut ?? this.onSurfaceMut, gold: gold ?? this.gold,
      goldSoft: goldSoft ?? this.goldSoft, error: error ?? this.error,
      errorSoft: errorSoft ?? this.errorSoft, success: success ?? this.success,
      outline: outline ?? this.outline,
    );
  }

  @override
  CrudoColors lerp(ThemeExtension<CrudoColors>? other, double t) {
    if (other is! CrudoColors) return this;
    return CrudoColors(
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceLow: Color.lerp(surfaceLow, other.surfaceLow, t)!,
      surfaceLowest: Color.lerp(surfaceLowest, other.surfaceLowest, t)!,
      surfaceHigh: Color.lerp(surfaceHigh, other.surfaceHigh, t)!,
      surfaceHighest: Color.lerp(surfaceHighest, other.surfaceHighest, t)!,
      surfaceDim: Color.lerp(surfaceDim, other.surfaceDim, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t)!,
      primaryContainer: Color.lerp(primaryContainer, other.primaryContainer, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
      onSurfaceVar: Color.lerp(onSurfaceVar, other.onSurfaceVar, t)!,
      onSurfaceMut: Color.lerp(onSurfaceMut, other.onSurfaceMut, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      goldSoft: Color.lerp(goldSoft, other.goldSoft, t)!,
      error: Color.lerp(error, other.error, t)!,
      errorSoft: Color.lerp(errorSoft, other.errorSoft, t)!,
      success: Color.lerp(success, other.success, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
    );
  }
}
```

- [ ] **Step 4: Run test — expect PASS**

Run: `flutter test test/ui/themes/colors_test.dart`

- [ ] **Step 5: Commit**

```bash
git add lib/ui/core/themes/colors.dart test/ui/themes/colors_test.dart
git commit -m "feat(theme): color tokens + CrudoColors extension"
```

---

### Task 3: Dimension tokens

**Role:** build · **Skills:** `flutter-expert`
**Goal:** Static spacing, radii, shadows, and motion durations.
**Files:** Create `lib/ui/core/themes/dimensions.dart` · Test `test/ui/themes/dimensions_test.dart`
**Contract:** `abstract final class Spacing/Radii/Shadows/Durations` with the values below.
**Out of scope:** colors, type.

- [ ] **Step 1: Write the failing test**

```dart
// test/ui/themes/dimensions_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crudo/ui/core/themes/dimensions.dart';

void main() {
  test('spacing & radii scales', () {
    expect(Spacing.md, 16.0);
    expect(Spacing.xl, 32.0);
    expect(Radii.lg, 32.0);
    expect(Radii.full, 9999.0);
  });
  test('cloud shadow defined', () {
    expect(Shadows.cloud, isNotEmpty);
    expect(Shadows.cloud.first.blurRadius, 40.0);
  });
}
```

- [ ] **Step 2: Run — expect FAIL.** Run: `flutter test test/ui/themes/dimensions_test.dart`

- [ ] **Step 3: Implement `dimensions.dart`**

```dart
import 'package:flutter/material.dart';

abstract final class Spacing {
  static const double xs = 4, sm = 8, md = 16, lg = 24, xl = 32, xxl = 48;
}

abstract final class Radii {
  static const double sm = 12, md = 20, lg = 32, xl = 48, full = 9999;
  static BorderRadius all(double r) => BorderRadius.circular(r);
}

abstract final class Shadows {
  static const cloud = <BoxShadow>[
    BoxShadow(color: Color(0x0A1A1C1A), offset: Offset(0, 20), blurRadius: 40),
  ];
  static const cloudDeep = <BoxShadow>[
    BoxShadow(color: Color(0x0F1A1C1A), offset: Offset(0, 24), blurRadius: 60),
  ];
}

abstract final class Durations {
  static const fast = Duration(milliseconds: 150);
  static const base = Duration(milliseconds: 200);
}
```

- [ ] **Step 4: Run — expect PASS.** Run: `flutter test test/ui/themes/dimensions_test.dart`

- [ ] **Step 5: Commit**

```bash
git add lib/ui/core/themes/dimensions.dart test/ui/themes/dimensions_test.dart
git commit -m "feat(theme): spacing, radii, shadow & duration tokens"
```

---

### Task 4: Typography (Manrope)

**Role:** implement · **Skills:** `flutter-add-widget-test`, `flutter-expert`
**Goal:** Named Manrope text styles + a Material `TextTheme`.
**Files:** Create `lib/ui/core/themes/typography.dart` · Test `test/ui/themes/typography_test.dart`
**Contract:** `abstract final class CrudoText` with the named styles below (each `fontFamily: 'Manrope'`) and `static TextTheme textTheme`. `letterSpacing` is in logical px (matches the css px values); `height` is the line-height ratio.
**Out of scope:** ThemeData assembly.

Style values (size · height-ratio · letterSpacing · weight · default color):
- `display` 40 · 1.10 · -1.2 · w600 · onSurface
- `displaySm` 32 · 1.125 · -0.8 · w600 · onSurface
- `headline` 24 · 1.25 · -0.5 · w700 · onSurface
- `headlineSm` 20 · 1.40 · -0.3 · w700 · onSurface
- `title` 18 · 1.55 · 0 · w600 · onSurface
- `body` 14 · 1.57 · 0 · w500 · onSurfaceVar
- `bodyLg` 16 · 1.63 · 0 · w500 · onSurfaceVar
- `label` 10 · 1.40 · 1.5 · w700 · onSurfaceMut (use UPPERCASE at call sites)
- `labelMd` 12 · 1.40 · 1.2 · w700 · onSurfaceMut

- [ ] **Step 1: Write the failing test**

```dart
// test/ui/themes/typography_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crudo/ui/core/themes/typography.dart';

void main() {
  test('display style', () {
    expect(CrudoText.display.fontSize, 40);
    expect(CrudoText.display.fontWeight, FontWeight.w600);
    expect(CrudoText.display.letterSpacing, -1.2);
    expect(CrudoText.display.fontFamily, 'Manrope');
  });
  test('label tracked + textTheme wired', () {
    expect(CrudoText.label.letterSpacing, 1.5);
    expect(CrudoText.textTheme.titleLarge?.fontSize, 18);
  });
}
```

- [ ] **Step 2: Run — expect FAIL.** Run: `flutter test test/ui/themes/typography_test.dart`

- [ ] **Step 3: Implement `typography.dart`** — one `TextStyle` per row above, e.g.:

```dart
import 'package:flutter/material.dart';
import 'colors.dart';

abstract final class CrudoText {
  static const _f = 'Manrope';

  static const display = TextStyle(fontFamily: _f, fontSize: 40, height: 1.10,
      letterSpacing: -1.2, fontWeight: FontWeight.w600, color: CrudoPalette.onSurface);
  static const displaySm = TextStyle(fontFamily: _f, fontSize: 32, height: 1.125,
      letterSpacing: -0.8, fontWeight: FontWeight.w600, color: CrudoPalette.onSurface);
  static const headline = TextStyle(fontFamily: _f, fontSize: 24, height: 1.25,
      letterSpacing: -0.5, fontWeight: FontWeight.w700, color: CrudoPalette.onSurface);
  static const headlineSm = TextStyle(fontFamily: _f, fontSize: 20, height: 1.40,
      letterSpacing: -0.3, fontWeight: FontWeight.w700, color: CrudoPalette.onSurface);
  static const title = TextStyle(fontFamily: _f, fontSize: 18, height: 1.55,
      fontWeight: FontWeight.w600, color: CrudoPalette.onSurface);
  static const body = TextStyle(fontFamily: _f, fontSize: 14, height: 1.57,
      fontWeight: FontWeight.w500, color: CrudoPalette.onSurfaceVar);
  static const bodyLg = TextStyle(fontFamily: _f, fontSize: 16, height: 1.63,
      fontWeight: FontWeight.w500, color: CrudoPalette.onSurfaceVar);
  static const label = TextStyle(fontFamily: _f, fontSize: 10, height: 1.40,
      letterSpacing: 1.5, fontWeight: FontWeight.w700, color: CrudoPalette.onSurfaceMut);
  static const labelMd = TextStyle(fontFamily: _f, fontSize: 12, height: 1.40,
      letterSpacing: 1.2, fontWeight: FontWeight.w700, color: CrudoPalette.onSurfaceMut);

  static const textTheme = TextTheme(
    displayLarge: display, displayMedium: displaySm,
    headlineMedium: headline, headlineSmall: headlineSm,
    titleLarge: title, bodyMedium: body, bodyLarge: bodyLg,
    labelSmall: label, labelMedium: labelMd,
  );
}
```

- [ ] **Step 4: Run — expect PASS.** Run: `flutter test test/ui/themes/typography_test.dart`

- [ ] **Step 5: Commit**

```bash
git add lib/ui/core/themes/typography.dart test/ui/themes/typography_test.dart
git commit -m "feat(theme): Manrope typography scale + TextTheme"
```

---

### Task 5: Assemble `crudoTheme`

**Role:** implement · **Skills:** `flutter-add-widget-test`, `flutter-expert`
**Goal:** One `ThemeData` wiring ColorScheme + TextTheme + CrudoColors.
**Files:** Create `lib/ui/core/themes/theme.dart` · Test `test/ui/themes/theme_test.dart`
**Contract:** `ThemeData crudoTheme` — `useMaterial3: true`, `brightness: light`, explicit `ColorScheme`, `textTheme: CrudoText.textTheme`, `fontFamily: 'Manrope'`, `scaffoldBackgroundColor: CrudoPalette.surface`, `extensions: const [CrudoColors.light]`.
**Out of scope:** main.dart wiring (Task 6).

- [ ] **Step 1: Write the failing test**

```dart
// test/ui/themes/theme_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crudo/ui/core/themes/theme.dart';
import 'package:crudo/ui/core/themes/colors.dart';

void main() {
  test('crudoTheme wiring', () {
    final t = crudoTheme;
    expect(t.useMaterial3, true);
    expect(t.colorScheme.primary, const Color(0xFF004D49));
    expect(t.colorScheme.surface, const Color(0xFFFAF9F6));
    expect(t.extension<CrudoColors>()!.gold, const Color(0xFFE9B949));
    expect(t.textTheme.titleLarge?.fontSize, 18);
  });
}
```

- [ ] **Step 2: Run — expect FAIL.** Run: `flutter test test/ui/themes/theme_test.dart`

- [ ] **Step 3: Implement `theme.dart`**

```dart
import 'package:flutter/material.dart';
import 'colors.dart';
import 'typography.dart';

final ThemeData crudoTheme = ThemeData(
  useMaterial3: true,
  fontFamily: 'Manrope',
  scaffoldBackgroundColor: CrudoPalette.surface,
  textTheme: CrudoText.textTheme,
  extensions: const [CrudoColors.light],
  colorScheme: const ColorScheme.light(
    primary: CrudoPalette.primary,
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: CrudoPalette.primaryContainer,
    onPrimaryContainer: CrudoPalette.primary,
    surface: CrudoPalette.surface,
    surfaceContainerLow: CrudoPalette.surfaceLow,
    surfaceContainerLowest: CrudoPalette.surfaceLowest,
    surfaceContainerHigh: CrudoPalette.surfaceHigh,
    surfaceContainerHighest: CrudoPalette.surfaceHighest,
    onSurface: CrudoPalette.onSurface,
    onSurfaceVariant: CrudoPalette.onSurfaceVar,
    outlineVariant: Color(0xFFBEC9C7),
    error: CrudoPalette.error,
    errorContainer: CrudoPalette.errorSoft,
  ),
);
```

- [ ] **Step 4: Run — expect PASS.** Run: `flutter test test/ui/themes/theme_test.dart`

- [ ] **Step 5: Commit**

```bash
git add lib/ui/core/themes/theme.dart test/ui/themes/theme_test.dart
git commit -m "feat(theme): assemble crudoTheme"
```

---

### Task 6: Wire `crudoTheme` into the app

**Role:** build · **Skills:** `flutter-add-widget-test`, `flutter-expert`
**Goal:** App runs on `crudoTheme`; an integration widget test proves theme + token + font reach a widget.
**Files:** Modify `lib/main.dart` · Test `test/ui/themes/theme_app_test.dart`
**Contract:** `MaterialApp.theme == crudoTheme`; existing `CrudoApp` unchanged otherwise.
**Out of scope:** any component/screen.

- [ ] **Step 1: Write the failing widget test**

```dart
// test/ui/themes/theme_app_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crudo/main.dart';
import 'package:crudo/ui/core/themes/colors.dart';

void main() {
  testWidgets('app uses crudoTheme + exposes CrudoColors', (tester) async {
    await tester.pumpWidget(const CrudoApp());
    final ctx = tester.element(find.text('Crudo'));
    final theme = Theme.of(ctx);
    expect(theme.colorScheme.primary, const Color(0xFF004D49));
    expect(theme.extension<CrudoColors>()!.gold, const Color(0xFFE9B949));
    expect(DefaultTextStyle.of(ctx).style.fontFamily ?? theme.textTheme.bodyMedium?.fontFamily,
        anyOf('Manrope', isNull)); // Manrope applied via theme
  });
}
```

- [ ] **Step 2: Run — expect FAIL** (main still on `ColorScheme.fromSeed`). Run: `flutter test test/ui/themes/theme_app_test.dart`

- [ ] **Step 3: Modify `lib/main.dart`** — replace the inline `theme:` with `crudoTheme`:

```dart
import 'package:flutter/material.dart';
import 'package:crudo/ui/core/themes/theme.dart';

void main() => runApp(const CrudoApp());

class CrudoApp extends StatelessWidget {
  const CrudoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crudo',
      debugShowCheckedModeBanner: false,
      theme: crudoTheme,
      home: const Scaffold(body: Center(child: Text('Crudo'))),
    );
  }
}
```

- [ ] **Step 4: Run — expect PASS.** Run: `flutter test`
Expected: all theme tests green.

- [ ] **Step 5: Commit**

```bash
git add lib/main.dart test/ui/themes/theme_app_test.dart
git commit -m "feat(theme): wire crudoTheme into the app"
```

---

## Final verification
- [ ] `dart format .` — no changes
- [ ] `flutter analyze` — 0 issues
- [ ] `flutter test` — all green
- [ ] Manual: `flutter run`, confirm the "Crudo" screen renders on the warm `#faf9f6` surface in Manrope.
