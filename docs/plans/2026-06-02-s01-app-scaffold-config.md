# App Scaffold & Config — Implementation Plan

> **For workers:** implement task-by-task, top to bottom. Each task = a contract + checkbox (`- [ ]`) steps; read the `.agents/skills` it names. Sequential, main working tree. **Do not commit** — report each task done for Opus to review & integrate. Spec: `docs/specs/2026-06-02-s01-app-scaffold-config.md`.

**Goal:** Turn the repo into a runnable foundation — core toolchain + lint installed, dev/prod flavors on iOS+Android, env config behind a typed `AppConfig`, app boots into a themed "Crudo" placeholder. No router, no domain, no features.

**Architecture:** Two entry points (`main.dart` = prod, `main_development.dart` = dev) delegate to a shared `bootstrap(AppConfig)` that builds the config, wraps `runApp` in a `ProviderScope`, and overrides `appConfigProvider`. `CrudoApp` (in `lib/app.dart`) is a `ConsumerWidget` rendering the existing `crudoTheme` + a centered wordmark; it reads `appConfigProvider` only for a dev marker. Env values arrive via `--dart-define-from-file` and are read by `AppConfig.fromEnvironment`.

**Tech Stack:** Flutter (Material 3), Riverpod 3.x (`flutter_riverpod`, `riverpod_annotation`, codegen toolchain), `go_router` (installed, used in S04), `freezed`/`json` annotations (installed, used in S02), `build_runner`, `riverpod_lint`/`custom_lint`. Tests via `flutter_test` + `package:checks`.

**Conventions:** follow `AGENTS.md`. Each task = one worker handoff; Opus reviews the diff and integrates. `dart format` + `flutter analyze` must be clean (pre-commit hook enforces). Generated files (`*.g.dart`, `*.freezed.dart`) **are committed** — never gitignored.

---

### Task 1: Dependencies + lint + codegen toolchain

**Role:** build · **Skills:** `flutter-riverpod-arch`, `flutter-apply-architecture-best-practices`
**Goal:** Install the core toolchain and activate Riverpod lint; `build_runner` runs clean.
**Files:** Modify `pubspec.yaml` · Modify/Create `analysis_options.yaml`
**Contract:** runtime deps `flutter_riverpod`, `riverpod_annotation`, `go_router`, `freezed_annotation`, `json_annotation`; dev deps `build_runner`, `riverpod_generator`, `freezed`, `json_serializable`, `riverpod_lint`, `custom_lint`. `analysis_options.yaml` includes `flutter_lints` + `custom_lint` plugin, excludes generated files.
**Out of scope:** any Dart code; `supabase_flutter`, notifications, billing (deferred to their specs).

- [ ] **Step 1: Add runtime deps** (let pub resolve latest compatible — do not hand-pin)

Run:
```bash
flutter pub add flutter_riverpod riverpod_annotation go_router freezed_annotation json_annotation
```
Expected: `pubspec.yaml` gains the five deps; `pub get` succeeds.

- [ ] **Step 2: Add dev deps**

Run:
```bash
flutter pub add dev:build_runner dev:riverpod_generator dev:freezed dev:json_serializable dev:riverpod_lint dev:custom_lint
```
Expected: six dev deps added (`flutter_lints` already present); `pub get` succeeds.

- [ ] **Step 3: Write `analysis_options.yaml`** (replace whatever is there)

```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  plugins:
    - custom_lint
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"

linter:
  rules: {}
```

- [ ] **Step 4: Verify codegen runs clean** (nothing to generate yet — must still exit 0)

Run:
```bash
dart run build_runner build --delete-conflicting-outputs
```
Expected: completes with "Succeeded" / "no outputs"; exit 0.

- [ ] **Step 5: Analyze**

Run: `flutter analyze && dart run custom_lint`
Expected: `flutter analyze` 0 issues; `custom_lint` 0 issues.

- [ ] **Step 6: Report** this task done for review (do **not** commit).

---

### Task 2: `AppConfig` + `appConfigProvider`

**Role:** implement · **Skills:** `flutter-riverpod-arch`, `dart-add-unit-test`, `dart-migrate-to-checks-package`
**Goal:** A typed, immutable config object read from dart-define values, exposed via an override-required Riverpod provider.
**Files:** Create `lib/config/app_config.dart` (replaces `lib/config/.gitkeep`) · Test `test/config/app_config_test.dart`
**Contract:**
- `enum Flavor { dev, prod }`
- `@immutable class AppConfig` — fields `Flavor flavor`, `String supabaseUrl`, `String supabaseAnonKey`; `const` ctor with `supabaseUrl`/`supabaseAnonKey` defaulting to `''`; `factory AppConfig.fromEnvironment(Flavor flavor)` reading `SUPABASE_URL` / `SUPABASE_ANON_KEY`; getter `bool get isDev`.
- `final Provider<AppConfig> appConfigProvider` that throws unless overridden.
**Out of scope:** wiring into `runApp` (Task 3); any Supabase client (S20).

- [ ] **Step 1: Write the failing test**

```dart
// test/config/app_config_test.dart
import 'package:checks/checks.dart';
import 'package:crudo/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('const ctor defaults supabase fields to empty', () {
    const c = AppConfig(flavor: Flavor.dev);
    check(c.flavor).equals(Flavor.dev);
    check(c.supabaseUrl).equals('');
    check(c.supabaseAnonKey).equals('');
    check(c.isDev).isTrue();
  });

  test('explicit values are retained', () {
    const c = AppConfig(
      flavor: Flavor.prod,
      supabaseUrl: 'https://x.supabase.co',
      supabaseAnonKey: 'anon',
    );
    check(c.flavor).equals(Flavor.prod);
    check(c.supabaseUrl).equals('https://x.supabase.co');
    check(c.isDev).isFalse();
  });

  test('fromEnvironment uses the given flavor and defaults missing keys to empty', () {
    // No --dart-define provided in the test runner → keys default to ''.
    final c = AppConfig.fromEnvironment(Flavor.prod);
    check(c.flavor).equals(Flavor.prod);
    check(c.supabaseUrl).equals('');
    check(c.supabaseAnonKey).equals('');
  });
}
```

- [ ] **Step 2: Run — expect FAIL** (`app_config.dart` missing)

Run: `flutter test test/config/app_config_test.dart`
Expected: FAIL (URI doesn't exist / `AppConfig` undefined).

- [ ] **Step 3: Implement `lib/config/app_config.dart`**

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Build flavor. dev = side-loadable debug build; prod = release identity.
enum Flavor { dev, prod }

/// Typed, immutable environment configuration.
///
/// Supabase values are empty until S20 wires the backend; the plumbing exists
/// now so later specs read config through [appConfigProvider], never globals.
@immutable
class AppConfig {
  const AppConfig({
    required this.flavor,
    this.supabaseUrl = '',
    this.supabaseAnonKey = '',
  });

  /// Reads compile-time values injected via `--dart-define-from-file`.
  factory AppConfig.fromEnvironment(Flavor flavor) => AppConfig(
        flavor: flavor,
        supabaseUrl: const String.fromEnvironment('SUPABASE_URL'),
        supabaseAnonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
      );

  final Flavor flavor;
  final String supabaseUrl;
  final String supabaseAnonKey;

  bool get isDev => flavor == Flavor.dev;
}

/// App-wide config. MUST be overridden in `bootstrap()`; throws otherwise so a
/// missing override fails loudly at startup rather than silently.
final Provider<AppConfig> appConfigProvider = Provider<AppConfig>(
  (ref) => throw UnimplementedError(
    'appConfigProvider must be overridden in bootstrap()',
  ),
);
```

- [ ] **Step 4: Run — expect PASS**

Run: `flutter test test/config/app_config_test.dart`
Expected: 3 tests pass.

- [ ] **Step 5: Format + analyze**

Run: `dart format . && flutter analyze`
Expected: no format changes; 0 issues.

- [ ] **Step 6: Report** this task done for review (do **not** commit).

---

### Task 3: Bootstrap, entry points, and `CrudoApp` placeholder

**Role:** implement · **Skills:** `flutter-riverpod-arch`, `flutter-add-widget-test`, `flutter-expert`
**Goal:** App boots through `bootstrap(AppConfig)` into a themed wordmark; dev builds show a "Crudo Dev" marker.
**Files:** Create `lib/app.dart` · Create `lib/bootstrap.dart` · Create `lib/main_development.dart` · Modify `lib/main.dart` · Modify `test/widget_test.dart` · Modify `test/ui/themes/theme_app_test.dart`
**Contract:**
- `lib/app.dart`: `class CrudoApp extends ConsumerWidget` → `MaterialApp(theme: crudoTheme, debugShowCheckedModeBanner: false, home: _BootPlaceholder())`. `_BootPlaceholder` is a `ConsumerWidget` showing a centered "Crudo" wordmark (`CrudoText.display`); when `ref.watch(appConfigProvider).isDev`, also shows a small "Crudo Dev" label.
- `lib/bootstrap.dart`: `void bootstrap(AppConfig config)` → `WidgetsFlutterBinding.ensureInitialized()`, `runApp(ProviderScope(overrides: [appConfigProvider.overrideWithValue(config)], child: const CrudoApp()))`.
- `lib/main.dart`: `void main() => bootstrap(AppConfig.fromEnvironment(Flavor.prod));`
- `lib/main_development.dart`: `void main() => bootstrap(AppConfig.fromEnvironment(Flavor.dev));`
**Out of scope:** router/shell (S04); any feature screen.

- [ ] **Step 1: Write the failing widget smoke test** (replace the default counter test)

```dart
// test/widget_test.dart
import 'package:checks/checks.dart';
import 'package:crudo/app.dart';
import 'package:crudo/config/app_config.dart';
import 'package:crudo/ui/core/themes/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Flavor flavor) => ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(AppConfig(flavor: flavor)),
      ],
      child: const CrudoApp(),
    );

void main() {
  testWidgets('boots into themed Crudo wordmark', (tester) async {
    await tester.pumpWidget(_wrap(Flavor.prod));

    expect(find.text('Crudo'), findsOneWidget);

    final ctx = tester.element(find.text('Crudo'));
    check(Theme.of(ctx).colorScheme.primary).equals(const Color(0xFF004D49));
    check(Theme.of(ctx).extension<CrudoColors>()).isNotNull();
  });

  testWidgets('prod build shows no dev marker', (tester) async {
    await tester.pumpWidget(_wrap(Flavor.prod));
    expect(find.text('Crudo Dev'), findsNothing);
  });

  testWidgets('dev build shows the dev marker', (tester) async {
    await tester.pumpWidget(_wrap(Flavor.dev));
    expect(find.text('Crudo Dev'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run — expect FAIL** (`lib/app.dart` missing; old `main.dart`/counter test gone)

Run: `flutter test test/widget_test.dart`
Expected: FAIL (URI `package:crudo/app.dart` doesn't exist).

- [ ] **Step 3: Implement `lib/app.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/app_config.dart';
import 'ui/core/themes/theme.dart';
import 'ui/core/themes/typography.dart';

/// Root application widget. No router yet — that lands in S04.
class CrudoApp extends ConsumerWidget {
  const CrudoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Crudo',
      debugShowCheckedModeBanner: false,
      theme: crudoTheme,
      home: const _BootPlaceholder(),
    );
  }
}

class _BootPlaceholder extends ConsumerWidget {
  const _BootPlaceholder();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDev = ref.watch(appConfigProvider).isDev;
    return Scaffold(
      body: Stack(
        children: [
          Center(child: Text('Crudo', style: CrudoText.display)),
          if (isDev)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 12,
              child: Text('Crudo Dev', style: CrudoText.label),
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Implement `lib/bootstrap.dart`**

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'config/app_config.dart';

/// Shared entry path for every flavor: build config, scope it, run the app.
void bootstrap(AppConfig config) {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      overrides: [appConfigProvider.overrideWithValue(config)],
      child: const CrudoApp(),
    ),
  );
}
```

- [ ] **Step 5: Replace `lib/main.dart`** (prod default entry)

```dart
import 'bootstrap.dart';
import 'config/app_config.dart';

void main() => bootstrap(AppConfig.fromEnvironment(Flavor.prod));
```

- [ ] **Step 6: Create `lib/main_development.dart`** (dev entry)

```dart
import 'bootstrap.dart';
import 'config/app_config.dart';

void main() => bootstrap(AppConfig.fromEnvironment(Flavor.dev));
```

- [ ] **Step 7: Fix the existing theme widget test** — it imported `CrudoApp` from `main.dart` and pumped it without a `ProviderScope`. `CrudoApp` now lives in `app.dart` and reads `appConfigProvider`, so it needs the override. Replace `test/ui/themes/theme_app_test.dart` with:

```dart
// test/ui/themes/theme_app_test.dart
import 'package:crudo/app.dart';
import 'package:crudo/config/app_config.dart';
import 'package:crudo/ui/core/themes/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app uses crudoTheme + exposes CrudoColors', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(
            const AppConfig(flavor: Flavor.prod),
          ),
        ],
        child: const CrudoApp(),
      ),
    );

    final ctx = tester.element(find.text('Crudo'));
    final theme = Theme.of(ctx);
    expect(theme.colorScheme.primary, const Color(0xFF004D49));
    expect(theme.extension<CrudoColors>()!.gold, const Color(0xFFE9B949));
  });
}
```

- [ ] **Step 8: Run the full suite — expect PASS**

Run: `flutter test`
Expected: all tests green (config + smoke + theme tests).

- [ ] **Step 9: Format + analyze**

Run: `dart format . && flutter analyze && dart run custom_lint`
Expected: no format changes; 0 analyzer issues; 0 lint issues.

- [ ] **Step 10: Report** this task done for review (do **not** commit).

---

### Task 4: Config files, `.gitignore`, and `testing/` scaffold

**Role:** build · **Skills:** `flutter-apply-architecture-best-practices`
**Goal:** Per-flavor dart-define files (secrets gitignored, example committed) + the shared `testing/` subpackage stub.
**Files:** Create `config/example.json`, `config/dev.json`, `config/prod.json` · Create `testing/fakes/.gitkeep`, `testing/models/.gitkeep` · Modify `.gitignore`
**Contract:** `config/dev.json` + `config/prod.json` are gitignored; `config/example.json` is committed with empty placeholder keys. `.gitignore` does **not** ignore `*.g.dart` / `*.freezed.dart` (those are committed).
**Out of scope:** real Supabase values (supplied locally at S20).

- [ ] **Step 1: Create `config/example.json`** (committed template)

```json
{
  "SUPABASE_URL": "",
  "SUPABASE_ANON_KEY": ""
}
```

- [ ] **Step 2: Create `config/dev.json` and `config/prod.json`** (same shape; gitignored — local only)

```json
{
  "SUPABASE_URL": "",
  "SUPABASE_ANON_KEY": ""
}
```

- [ ] **Step 3: Append to `.gitignore`**

```gitignore
# Per-flavor dart-define config (secrets) — keep config/example.json committed
/config/dev.json
/config/prod.json
```
Do **not** add `*.g.dart` or `*.freezed.dart` — generated files are committed.

- [ ] **Step 4: Create the `testing/` subpackage stub**

Run:
```bash
mkdir -p testing/fakes testing/models
touch testing/fakes/.gitkeep testing/models/.gitkeep
```
Expected: both `.gitkeep` files exist (shared mocks/fakes land here in later specs; not shipped).

- [ ] **Step 5: Verify config is read end-to-end** (dev flavor injects the file)

Run:
```bash
flutter test --dart-define-from-file=config/example.json
```
Expected: suite still green (empty keys → `AppConfig` defaults hold).

- [ ] **Step 6: Report** this task done for review (do **not** commit).

---

### Task 5: Android dev/prod flavors

**Role:** build · **Skills:** `flutter-apply-architecture-best-practices`
**Goal:** Android `dev`/`prod` product flavors that install side by side with distinct app names.
**Files:** Modify `android/app/build.gradle.kts` (or `android/app/build.gradle` if this project uses Groovy)
**Contract:** flavor dimension `app`; `dev` → `applicationIdSuffix ".dev"`, app label "Crudo Dev"; `prod` → base id `app.rostsv.crudo`, label "Crudo". Base `applicationId` = `app.rostsv.crudo`.
**Out of scope:** signing configs / release keystore (S25); iOS (Task 6).

- [ ] **Step 1: Inspect the Gradle file** to confirm Kotlin-DSL vs Groovy and the current `applicationId`

Run: `ls android/app/ && grep -n "applicationId" android/app/build.gradle* `
Expected: identifies `build.gradle.kts` (Kotlin DSL, default for recent Flutter) or `build.gradle`; shows current id.

- [ ] **Step 2: Set the base `applicationId`** to `app.rostsv.crudo` inside `defaultConfig` (replace the auto-generated `com.example.crudo`).

Kotlin DSL (`build.gradle.kts`):
```kotlin
defaultConfig {
    applicationId = "app.rostsv.crudo"
    // …existing minSdk/targetSdk/versionCode/versionName unchanged…
}
```

- [ ] **Step 3: Add the flavor block** directly after `defaultConfig` (inside `android { }`)

Kotlin DSL:
```kotlin
flavorDimensions += "app"

productFlavors {
    create("dev") {
        dimension = "app"
        applicationIdSuffix = ".dev"
        resValue(type = "string", name = "app_name", value = "Crudo Dev")
    }
    create("prod") {
        dimension = "app"
        resValue(type = "string", name = "app_name", value = "Crudo")
    }
}
```
(Groovy equivalent if `build.gradle`: `flavorDimensions "app"` + `productFlavors { dev { dimension "app"; applicationIdSuffix ".dev"; resValue "string", "app_name", "Crudo Dev" } prod { dimension "app"; resValue "string", "app_name", "Crudo" } }`.)

- [ ] **Step 4: Use `@string/app_name` for the label** in `android/app/src/main/AndroidManifest.xml`

Set the `<application android:label=...>` to:
```xml
android:label="@string/app_name"
```

- [ ] **Step 5: Build both flavors** (debug APK assembly — no emulator needed)

Run:
```bash
flutter build apk --debug --flavor dev  -t lib/main_development.dart --dart-define-from-file=config/dev.json
flutter build apk --debug --flavor prod -t lib/main.dart            --dart-define-from-file=config/prod.json
```
Expected: both builds succeed. (If the local Android toolchain is unavailable, report that — Opus will verify on a configured machine.)

- [ ] **Step 6: Report** this task done for review (do **not** commit).

---

### Task 6: iOS dev/prod flavors (worker = text files; Opus = Xcode GUI)

**Role:** build · **Skills:** `flutter-apply-architecture-best-practices`
**Goal:** iOS schemes `dev`/`prod` with distinct bundle ids + display names. The worker prepares the **text-editable** pieces (xcconfig + Info.plist variables); Opus completes the **Xcode-GUI** pieces (build configurations + schemes) on this Mac and verifies the build.
**Files:** Create `ios/Flutter/Dev.xcconfig`, `ios/Flutter/Prod.xcconfig` · Modify `ios/Runner/Info.plist`
**Contract:** display name driven by `$(APP_DISPLAY_NAME)`, bundle id by base `app.rostsv.crudo` + `$(BUNDLE_ID_SUFFIX)`; dev → "Crudo Dev" / suffix `.dev`, prod → "Crudo" / no suffix.
**Out of scope:** App Store signing / provisioning (S25). **This task does not fully build via text alone — the Xcode steps are explicitly Opus's.**

- [ ] **Step 1: Create `ios/Flutter/Dev.xcconfig`**

```
#include "Generated.xcconfig"
APP_DISPLAY_NAME=Crudo Dev
BUNDLE_ID_SUFFIX=.dev
```

- [ ] **Step 2: Create `ios/Flutter/Prod.xcconfig`**

```
#include "Generated.xcconfig"
APP_DISPLAY_NAME=Crudo
BUNDLE_ID_SUFFIX=
```

- [ ] **Step 3: Edit `ios/Runner/Info.plist`** so name + bundle id read from the build settings

Set `CFBundleDisplayName` (add the key if absent) and ensure the bundle id uses the suffix variable:
```xml
<key>CFBundleDisplayName</key>
<string>$(APP_DISPLAY_NAME)</string>
<key>CFBundleName</key>
<string>$(APP_DISPLAY_NAME)</string>
<key>CFBundleIdentifier</key>
<string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
```

- [ ] **Step 4: Document the Xcode GUI steps for Opus** — add a short note to the task report (these CANNOT be done reliably by text edit):

```
OPUS / XCODE (manual, on macOS):
1. Open ios/Runner.xcworkspace.
2. Project ▸ Runner ▸ Info ▸ Configurations: duplicate Debug→Debug-dev/Debug-prod,
   Release→Release-dev/Release-prod, Profile→Profile-dev/Profile-prod.
3. Set each *-dev config file = Flutter/Dev.xcconfig, each *-prod = Flutter/Prod.xcconfig.
4. Build Settings ▸ PRODUCT_BUNDLE_IDENTIFIER = app.rostsv.crudo$(BUNDLE_ID_SUFFIX).
5. Manage Schemes: create schemes "dev" (uses *-dev configs) and "prod" (uses *-prod).
6. Verify: flutter run --flavor dev -t lib/main_development.dart --dart-define-from-file=config/dev.json
```

- [ ] **Step 5: Report** the text files done + the Xcode checklist for Opus (do **not** commit). Opus performs the Xcode steps, then verifies dev+prod install side by side on a simulator.

---

## Final verification (Opus, before integrating)
- [ ] `dart format .` — no changes
- [ ] `flutter analyze` — 0 issues · `dart run custom_lint` — 0 issues
- [ ] `dart run build_runner build --delete-conflicting-outputs` — exit 0
- [ ] `flutter test` — all green (config + smoke + theme)
- [ ] dev: `flutter run --flavor dev -t lib/main_development.dart --dart-define-from-file=config/dev.json` → themed wordmark + "Crudo Dev" marker
- [ ] prod: `flutter run --flavor prod -t lib/main.dart --dart-define-from-file=config/prod.json` → wordmark, no marker, bundle `app.rostsv.crudo`
- [ ] dev + prod install side by side on one device (Android confirmed via Task 5; iOS via Task 6)
- [ ] `config/dev.json`/`config/prod.json` gitignored; `config/example.json` committed
- [ ] Update `AGENTS.md` Commands section with the per-flavor run lines (Opus, at integration).
