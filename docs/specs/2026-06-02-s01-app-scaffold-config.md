# Spec — App Scaffold & Config

**Status:** approved · **Spec S01 (foundation)** · scope = project toolchain, flavors, config plumbing, lint, and a themed boot placeholder. No router, no domain, no features.

## Goal
Take the repo from "theme exists, `main.dart` is the default counter" to a real foundation: the app compiles and runs on **iOS + Android** in **dev + prod** flavors, the core toolchain (Riverpod / go_router / freezed / build_runner) and lint are installed, environment config is read through a typed `AppConfig`, and the app boots into a themed "Crudo" placeholder. Everything later builds on this; it ships nothing user-facing beyond the placeholder.

## Why
Every later spec assumes: `ProviderScope` at the root, a config object for environment values (Supabase URL/key land at S20 but the plumbing must exist behind a stable interface), per-flavor builds so dev and prod coexist on a device, codegen wired (`*.g.dart` / `*.freezed.dart`), and Riverpod lint rules active. Doing this once, mechanically, keeps feature specs focused on behavior.

## Decisions (from brainstorm)
- **S01 scope:** bare scaffold, **no router** — all routing in S04.
- **Flavors:** **dev + prod** only (staging deferred).
- **Platforms:** **iOS + Android** (web not configured in v1).
- **Deps:** core toolchain now; `supabase_flutter`/billing/notifications deferred to their specs.
- **Config:** `--dart-define-from-file` per flavor → typed `AppConfig`.
- **Lint:** `flutter_lints` + `riverpod_lint`/`custom_lint`.
- **Folder tree:** already scaffolded; fill gaps only.
- **Identity:** `app.rostsv.crudo` / "Crudo"; dev suffixes to `app.rostsv.crudo.dev` / "Crudo Dev".
- **main:** themed `MaterialApp` + centered wordmark, `ProviderScope` at root.
- **Tests:** widget smoke + `AppConfig` unit test.

## Dependencies (`pubspec.yaml`)
Add the **core toolchain** only — vendor/feature deps land with their specs.

**dependencies:**
- `flutter_riverpod` · `riverpod_annotation` — state layer; `ProviderScope` at root from S01.
- `go_router` — routing dep installed now; *used* in S04.
- `freezed_annotation` · `json_annotation` — model annotations; *used* in S02.

**dev_dependencies:**
- `build_runner` · `riverpod_generator` · `freezed` · `json_serializable` — codegen toolchain.
- `riverpod_lint` · `custom_lint` — Riverpod lint rules (+ existing `flutter_lints`).

**Deferred (do NOT add here):** `supabase_flutter` (S20) · local-notifications package (S14) · billing/RevenueCat (S23) · `flutter_launcher_icons`/`flutter_native_splash` (S25).

`dart run build_runner build --delete-conflicting-outputs` must run clean even though nothing is generated yet.

## Flavors & entry points
Two entry files delegate to one shared bootstrap:

```
lib/main_development.dart   // bootstrap(AppConfig.fromEnvironment(Flavor.dev))
lib/main_production.dart    // bootstrap(AppConfig.fromEnvironment(Flavor.prod))
lib/bootstrap.dart          // bootstrap(AppConfig) → runApp(ProviderScope(overrides:[appConfigProvider.overrideWithValue(config)], child: const CrudoApp()))
```

Drop the default `lib/main.dart` (replace with `main_production.dart`; keep a `main.dart` that points to prod, or remove and update run configs — implementer's call, documented in AGENTS.md).

**Flavor differentiation (coexist on device):**
- dev: applicationId/bundleId `app.rostsv.crudo.dev`, display name **Crudo Dev**
- prod: `app.rostsv.crudo`, display name **Crudo**
- **Android:** `productFlavors { dev { applicationIdSuffix ".dev"; resValue app_name "Crudo Dev" } prod { } }` in `android/app/build.gradle`.
- **iOS:** two build configurations / xcconfigs (Dev, Prod) with `PRODUCT_BUNDLE_IDENTIFIER` + `DISPLAY_NAME`; schemes `dev` and `prod`. (No App Store signing setup here — S25.)

Launch commands (document in AGENTS.md):
```
flutter run --flavor dev  -t lib/main_development.dart --dart-define-from-file=config/dev.json
flutter run --flavor prod -t lib/main_production.dart  --dart-define-from-file=config/prod.json
```

## Config / secrets (`lib/config/`)
- `config/dev.json`, `config/prod.json` — **gitignored**; `config/example.json` committed with empty/placeholder keys.
- `lib/config/app_config.dart`:
  ```
  class AppConfig {
    final Flavor flavor;            // enum { dev, prod }
    final String supabaseUrl;       // '' until S20
    final String supabaseAnonKey;   // '' until S20
    const AppConfig({required this.flavor, this.supabaseUrl = '', this.supabaseAnonKey = ''});
    factory AppConfig.fromEnvironment(Flavor flavor);  // reads String.fromEnvironment(...)
  }
  ```
- Exposed via `Provider<AppConfig> appConfigProvider` (throws if not overridden) so any layer reads config through Riverpod, never globals.
- JSON keys: `SUPABASE_URL`, `SUPABASE_ANON_KEY` (empty in committed example; real values supplied locally at S20).

## main / placeholder (`lib/`)
- `CrudoApp` (`ConsumerWidget`): `MaterialApp(theme: crudoTheme, debugShowCheckedModeBanner: false, home: const _BootPlaceholder())`.
- `_BootPlaceholder`: `Scaffold` (themed surface) with a centered "Crudo" wordmark using `CrudoText` display style — proves theme + Manrope are live.
- A subtle flavor marker (e.g. "Crudo Dev" label) shown only when `flavor == dev`, read from `appConfigProvider`.

## Lint (`analysis_options.yaml`)
```
include: package:flutter_lints/flutter.yaml
analyzer:
  plugins:
    - custom_lint
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
```
`riverpod_lint` activates via `custom_lint`. `flutter analyze` (and `dart run custom_lint`) clean.

## Folder tree
Already scaffolded (`.gitkeep` across `lib/` + `test/`). S01 only fills gaps:
- `lib/config/app_config.dart` (replaces the `.gitkeep`).
- `lib/bootstrap.dart`, `lib/main_development.dart`, `lib/main_production.dart`.
- `testing/` subpackage stub (`testing/fakes/.gitkeep`, `testing/models/.gitkeep`) for shared mocks/fakes (not shipped) — per architecture §2.
- `.gitignore`: add `config/dev.json`, `config/prod.json` (keep `config/example.json`). Generated `*.g.dart` / `*.freezed.dart` — commit policy: **commit** generated files (so CI/workers don't need codegen to analyze); document in AGENTS.md.

## Tests
- **Widget smoke** (`test/widget_test.dart`, replacing the default): pump `ProviderScope(overrides: [appConfigProvider.overrideWithValue(const AppConfig(flavor: Flavor.dev))], child: const CrudoApp())`; assert the "Crudo" wordmark renders and `Theme.of(context)` is `crudoTheme` (e.g. `CrudoColors` extension non-null).
- **Unit** (`test/config/app_config_test.dart`): `AppConfig.fromEnvironment` maps dart-define values; empty/missing keys default to `''`; `flavor` set correctly. Use `package:checks` for assertions.

## Acceptance
- `flutter run --flavor dev -t lib/main_development.dart --dart-define-from-file=config/dev.json` launches on an iOS simulator **and** an Android emulator, showing the themed wordmark + "Crudo Dev" marker.
- prod flavor launches with bundle `app.rostsv.crudo`, name "Crudo", no dev marker.
- dev + prod install **side by side** on one device.
- `dart run build_runner build --delete-conflicting-outputs` exits 0.
- `dart format .` clean · `flutter analyze` clean · `dart run custom_lint` clean · `flutter test` green.
- `appConfigProvider` is overridden at the root and readable from a `ConsumerWidget`.
- `config/dev.json` / `config/prod.json` are gitignored; `config/example.json` committed.

## Out of scope
Router / `StatefulShellRoute` / nav (S04) · any domain model or enum (S02) · any repository/service (S03) · real Supabase keys or SDK (S20) · notifications (S14) · billing (S23) · app icon / splash / store signing (S25) · staging flavor · web build.

## Skills for implementation
`flutter-apply-architecture-best-practices` (folder placement, flavors) · `flutter-riverpod-arch` (`ProviderScope`, `appConfigProvider`) · `dart-add-unit-test` (`AppConfig` test) · `flutter-add-widget-test` (smoke test) · `dart-migrate-to-checks-package` (assertions via `package:checks`) · `flutter-expert` (const, structure overlay).
