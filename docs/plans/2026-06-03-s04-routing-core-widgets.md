# S04: Routing Shell + Core Widgets — Implementation Plan

> **For workers:** implement task-by-task, top to bottom. Each task = a contract + checkbox (`- [ ]`) steps; read the `.agents/skills` it names. Work on branch `feat/s04-routing` in your worktree. **Do not commit** — report each task done for Opus to review & integrate. Spec: `docs/specs/2026-06-03-s04-routing-core-widgets.md`. Design tokens: `docs/design/prototype/app.css` (authoritative) via `lib/ui/core/themes/` (`CrudoColors`, `CrudoText`, `Spacing`, `Radii`, `Shadows`, `Durations`).

**Goal:** 4-tab `StatefulShellRoute.indexedStack` shell, sheet/toast infrastructure, the 7 shared widgets with plain params, themed showcase placeholders, previews, widget + router tests.

**Architecture:** router as `Provider<GoRouter>` in `lib/routing/`; `CrudoApp` becomes `MaterialApp.router`. Widgets live in `lib/ui/core/widgets/`, take primitives/callbacks + domain **enums** only (never aggregates). Placeholder screens in `lib/ui/features/<tab>/views/` showcase the widgets with dummy params — no repos, no controllers. **Do not touch `lib/bootstrap.dart` or anything under `lib/data`/`lib/domain`/`lib/config/di.dart`** (S03 owns those in a parallel branch); `lib/app.dart` is yours.

**Tech Stack:** `go_router 17.x` (already installed — no new deps). Tests: `flutter_test` + `package:checks`.

**Conventions:** follow `AGENTS.md`. Design rules are hard: **no 1px borders, no dividers, no drop shadows** (only `Shadows.cloud` on floating elements), **never pure black**, no Material FABs, pill radius CTAs, partial state uses a **split-circle icon — never the text "½"**. After each task: `dart format . && flutter analyze && flutter test` clean/green.

---

### Task 1: Router + shell + bare tab screens

**Role:** implement · **Skills:** `flutter-setup-declarative-routing`, `flutter-riverpod-arch`, `flutter-add-widget-test`
**Files:** Create `lib/routing/app_router.dart`, `lib/ui/core/widgets/app_shell.dart`, `lib/ui/features/today/views/today_screen.dart`, `lib/ui/features/plans/views/plans_screen.dart`, `lib/ui/features/history/views/history_screen.dart`, `lib/ui/features/profile/views/profile_screen.dart` · Modify `lib/app.dart` · Modify `test/widget_test.dart`, `test/ui/themes/theme_app_test.dart` · Test `test/routing/app_router_test.dart`
**Contract:** `appRouterProvider` = `Provider<GoRouter>`; `StatefulShellRoute.indexedStack` with branches `/today` (initial), `/plans`, `/history`, `/profile`; `AppShell` renders the branch + custom bottom nav (no 1px top border — `surfaceLowest` bar on `surface` body = tonal shift; teal active, `onSurfaceMut` inactive, `CrudoText.label` labels) + dev marker (top-right, only when `appConfigProvider.isDev`). Each screen = minimal themed scaffold with its `CrudoText.headline` title (showcase content arrives Task 6).
**Out of scope:** shared widgets (Tasks 2–5); pushed detail routes; redirects.

- [ ] **Step 1: Write the failing router test**

```dart
// test/routing/app_router_test.dart
import 'package:checks/checks.dart';
import 'package:crudo/app.dart';
import 'package:crudo/config/app_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app({Flavor flavor = Flavor.prod}) => ProviderScope(
  overrides: [
    appConfigProvider.overrideWithValue(AppConfig(flavor: flavor)),
  ],
  child: const CrudoApp(),
);

void main() {
  testWidgets('boots into Today tab', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    expect(find.text('Today'), findsWidgets); // title + nav label
  });

  testWidgets('bottom nav switches all four branches', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    for (final label in ['Plans', 'History', 'Profile', 'Today']) {
      await tester.tap(find.byKey(ValueKey('nav-$label')));
      await tester.pumpAndSettle();
      expect(find.text(label), findsWidgets);
    }
  });

  testWidgets('dev marker only on dev flavor', (tester) async {
    await tester.pumpWidget(_app(flavor: Flavor.dev));
    await tester.pumpAndSettle();
    expect(find.text('Crudo Dev'), findsOneWidget);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    expect(find.text('Crudo Dev'), findsNothing);
  });

  testWidgets('no 1px border on the nav bar', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    final containers = tester.widgetList<Container>(find.byType(Container));
    for (final c in containers) {
      final deco = c.decoration;
      if (deco is BoxDecoration && deco.border != null) {
        fail('found a Border in the shell — no-line rule violated');
      }
    }
    check(true).isTrue();
  });
}
```

- [ ] **Step 2:** Run `flutter test test/routing/` — FAIL.

- [ ] **Step 3:** Create the four bare screens (same pattern; repeat for Plans/History/Profile with their titles):

```dart
// lib/ui/features/today/views/today_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/themes/typography.dart';
import '../../../core/themes/dimensions.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(Spacing.md),
        children: const [
          Text('Today', style: CrudoText.headline),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4:** Create `lib/ui/core/widgets/app_shell.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/app_config.dart';
import '../themes/colors.dart';
import '../themes/dimensions.dart';
import '../themes/typography.dart';

/// Persistent app frame: the active branch + the custom bottom nav.
/// No-line rule: the bar separates from the body by surface tone, not border.
class AppShell extends ConsumerWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const _items = [
    (label: 'Today', icon: Icons.restaurant_outlined, active: Icons.restaurant),
    (label: 'Plans', icon: Icons.event_note_outlined, active: Icons.event_note),
    (label: 'History', icon: Icons.bar_chart_outlined, active: Icons.bar_chart),
    (label: 'Profile', icon: Icons.person_outline, active: Icons.person),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    final isDev = ref.watch(appConfigProvider).isDev;

    return Scaffold(
      backgroundColor: colors.surface,
      body: Stack(
        children: [
          navigationShell,
          if (isDev)
            Positioned(
              top: MediaQuery.of(context).padding.top + Spacing.sm,
              right: Spacing.md,
              child: Text(
                'Crudo Dev',
                style: CrudoText.label.copyWith(color: colors.onSurfaceMut),
              ),
            ),
        ],
      ),
      bottomNavigationBar: ColoredBox(
        color: colors.surfaceLowest,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
            child: Row(
              children: [
                for (final (index, item) in _items.indexed)
                  Expanded(
                    child: _NavItem(
                      key: ValueKey('nav-${item.label}'),
                      label: item.label,
                      icon: navigationShell.currentIndex == index
                          ? item.active
                          : item.icon,
                      selected: navigationShell.currentIndex == index,
                      onTap: () => navigationShell.goBranch(
                        index,
                        initialLocation: index == navigationShell.currentIndex,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    final color = selected ? colors.primary : colors.onSurfaceMut;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: Radii.all(Radii.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color),
              const SizedBox(height: Spacing.xs),
              Text(label, style: CrudoText.label.copyWith(color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5:** Create `lib/routing/app_router.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../ui/core/widgets/app_shell.dart';
import '../ui/features/history/views/history_screen.dart';
import '../ui/features/plans/views/plans_screen.dart';
import '../ui/features/profile/views/profile_screen.dart';
import '../ui/features/today/views/today_screen.dart';

/// 4-tab shell. Pushed detail routes (mealDetail, createPlan, ...) are added
/// by their feature specs; sheets are NOT routes (see showCrudoSheet).
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/today',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/today', builder: (_, __) => const TodayScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/plans', builder: (_, __) => const PlansScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/history', builder: (_, __) => const HistoryScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
          ]),
        ],
      ),
    ],
  );
});
```

- [ ] **Step 6:** Rewire `lib/app.dart` (delete `_BootPlaceholder`):

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'routing/app_router.dart';
import 'ui/core/themes/theme.dart';

/// Root application widget — boots straight into the 4-tab shell.
class CrudoApp extends ConsumerWidget {
  const CrudoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Crudo',
      debugShowCheckedModeBanner: false,
      theme: crudoTheme,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
```

- [ ] **Step 7:** Update `test/widget_test.dart` + `test/ui/themes/theme_app_test.dart` — the old tests asserted the boot wordmark. Replace "finds 'Crudo' wordmark" assertions with shell assertions: after `pumpAndSettle`, `find.text('Today')` is present; theme assertions (primary `Color(0xFF004D49)`, `CrudoColors` extension non-null) stay, anchored on `tester.element(find.text('Today').first)`. Dev-marker tests remain valid (marker now lives in the shell).

- [ ] **Step 8:** `flutter test && dart format . && flutter analyze` — green/clean. **Report** (no commit).

---

### Task 2: `PrimaryCta` + `Pill`

**Role:** implement · **Skills:** `flutter-add-widget-test`, `flutter-expert`
**Files:** Create `lib/ui/core/widgets/primary_cta.dart`, `lib/ui/core/widgets/pill.dart` · Test `test/ui/widgets/primary_cta_test.dart`, `test/ui/widgets/pill_test.dart`
**Contract:** `PrimaryCta({required String label, required VoidCallback? onPressed, bool enabled = true})` — full-width, 135° gradient `primary→primarySoft`, `Radii.full` pill, **no shadow**, white `CrudoText.title` label, disabled = 0.5 opacity + taps ignored. `Pill({required String label, required bool selected, required VoidCallback onTap})` — selected: `primary` fill/white text; unselected: `surfaceHigh` fill/`onSurfaceVar` text; `Radii.full`; animates with `Durations.fast`.
**Out of scope:** sticky-bottom placement (feature screens compose that).

- [ ] **Step 1: Failing tests**

```dart
// test/ui/widgets/primary_cta_test.dart
import 'package:checks/checks.dart';
import 'package:crudo/ui/core/themes/theme.dart';
import 'package:crudo/ui/core/widgets/primary_cta.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) =>
    MaterialApp(theme: crudoTheme, home: Scaffold(body: Center(child: child)));

void main() {
  testWidgets('fires onPressed when enabled', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_wrap(PrimaryCta(label: 'Save', onPressed: () => taps++)));
    await tester.tap(find.text('Save'));
    check(taps).equals(1);
  });

  testWidgets('blocks taps when disabled', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_wrap(
      PrimaryCta(label: 'Save', enabled: false, onPressed: () => taps++),
    ));
    await tester.tap(find.text('Save'));
    check(taps).equals(0);
  });

  testWidgets('uses gradient, no BoxShadow', (tester) async {
    await tester.pumpWidget(_wrap(PrimaryCta(label: 'Save', onPressed: () {})));
    final deco = tester
        .widget<Container>(find.byKey(const ValueKey('primary-cta-surface')))
        .decoration! as BoxDecoration;
    check(deco.gradient).isNotNull();
    check(deco.boxShadow).isNull();
  });
}
```

```dart
// test/ui/widgets/pill_test.dart
import 'package:checks/checks.dart';
import 'package:crudo/ui/core/themes/colors.dart';
import 'package:crudo/ui/core/themes/theme.dart';
import 'package:crudo/ui/core/widgets/pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) =>
    MaterialApp(theme: crudoTheme, home: Scaffold(body: Center(child: child)));

void main() {
  testWidgets('selected pill fills teal; unselected surface', (tester) async {
    await tester.pumpWidget(_wrap(Row(children: [
      Pill(label: 'Mon', selected: true, onTap: () {}),
      Pill(label: 'Tue', selected: false, onTap: () {}),
    ])));
    await tester.pumpAndSettle();
    final boxes = tester
        .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
        .toList();
    final selected = boxes.first.decoration! as BoxDecoration;
    final unselected = boxes.last.decoration! as BoxDecoration;
    check(selected.color).equals(CrudoColors.light.primary);
    check(unselected.color).equals(CrudoColors.light.surfaceHigh);
  });

  testWidgets('tap fires', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_wrap(Pill(label: 'Mon', selected: false, onTap: () => taps++)));
    await tester.tap(find.text('Mon'));
    check(taps).equals(1);
  });
}
```

- [ ] **Step 2:** Run — FAIL. Implement `lib/ui/core/widgets/primary_cta.dart`:

```dart
import 'package:flutter/material.dart';

import '../themes/colors.dart';
import '../themes/dimensions.dart';
import '../themes/typography.dart';

/// Full-width primary action: 135° primary→primary-soft gradient, pill radius,
/// no shadow (design system). Disabled = half opacity + taps ignored.
class PrimaryCta extends StatelessWidget {
  const PrimaryCta({
    required this.label,
    required this.onPressed,
    this.enabled = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: GestureDetector(
          onTap: enabled ? onPressed : null,
          child: Container(
            key: const ValueKey('primary-cta-surface'),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: Spacing.md),
            decoration: BoxDecoration(
              borderRadius: Radii.all(Radii.full),
              gradient: LinearGradient(
                begin: Alignment.topLeft, // 135°
                end: Alignment.bottomRight,
                colors: [colors.primary, colors.primarySoft],
              ),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: CrudoText.title.copyWith(color: colors.surfaceLowest),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3:** Implement `lib/ui/core/widgets/pill.dart`:

```dart
import 'package:flutter/material.dart';

import '../themes/colors.dart';
import '../themes/dimensions.dart';
import '../themes/typography.dart';

/// Compact selectable chip (weekdays, tags, filters).
class Pill extends StatelessWidget {
  const Pill({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: Durations.fast,
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.sm,
          ),
          decoration: BoxDecoration(
            color: selected ? colors.primary : colors.surfaceHigh,
            borderRadius: Radii.all(Radii.full),
          ),
          child: Text(
            label,
            style: CrudoText.labelMd.copyWith(
              color: selected ? colors.surfaceLowest : colors.onSurfaceVar,
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4:** Tests PASS → format + analyze clean → **report** (no commit).

---

### Task 3: `SelectionCard` + `MealCard`

**Role:** implement · **Skills:** `flutter-add-widget-test`, `flutter-expert`
**Files:** Create `lib/ui/core/widgets/selection_card.dart`, `lib/ui/core/widgets/meal_card.dart` · Test `test/ui/widgets/selection_card_test.dart`, `test/ui/widgets/meal_card_test.dart`
**Contract:**
- `SelectionCard({required String title, String? subtitle, required bool selected, required VoidCallback onTap, Widget? trailing})` — `Radii.md` card; selected = `primaryContainer` fill, else `surfaceLowest`; **no border**; `Spacing.md` padding.
- `MealCard({required String title, required String timeLabel, required String kcalLabel, required MealStatus status, VoidCallback? onTap})` — imports `MealStatus` (domain **enum** — allowed). Status visuals: `done` → teal filled-circle check icon; `partial` → **gold split-circle** (custom painter, half-filled — NEVER the text "½"); `upcoming` → muted hollow circle; `skipped` → red hollow circle with diagonal. Title `CrudoText.title`, time+kcal `CrudoText.label` in `onSurfaceMut`. Card on `surfaceLowest`, `Radii.md`, no dividers.
**Out of scope:** ingredient checklist rows (S08).

- [ ] **Step 1: Failing tests**

```dart
// test/ui/widgets/meal_card_test.dart
import 'package:checks/checks.dart';
import 'package:crudo/domain/shared/enums.dart';
import 'package:crudo/ui/core/themes/theme.dart';
import 'package:crudo/ui/core/widgets/meal_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) =>
    MaterialApp(theme: crudoTheme, home: Scaffold(body: child));

void main() {
  testWidgets('renders content for every status without "½" text', (tester) async {
    for (final status in MealStatus.values) {
      await tester.pumpWidget(_wrap(MealCard(
        title: 'Breakfast',
        timeLabel: '08:00',
        kcalLabel: '420 kcal',
        status: status,
      )));
      expect(find.text('Breakfast'), findsOneWidget);
      expect(find.text('08:00'), findsOneWidget);
      expect(find.text('420 kcal'), findsOneWidget);
      expect(find.textContaining('½'), findsNothing);
      expect(
        find.byKey(ValueKey('meal-status-${status.name}')),
        findsOneWidget,
      );
    }
  });

  testWidgets('tap fires when provided', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_wrap(MealCard(
      title: 'Lunch',
      timeLabel: '12:30',
      kcalLabel: '650 kcal',
      status: MealStatus.upcoming,
      onTap: () => taps++,
    )));
    await tester.tap(find.text('Lunch'));
    check(taps).equals(1);
  });
}
```

```dart
// test/ui/widgets/selection_card_test.dart
import 'package:checks/checks.dart';
import 'package:crudo/ui/core/themes/colors.dart';
import 'package:crudo/ui/core/themes/theme.dart';
import 'package:crudo/ui/core/widgets/selection_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) =>
    MaterialApp(theme: crudoTheme, home: Scaffold(body: child));

void main() {
  testWidgets('selection switches fill, never adds a border', (tester) async {
    for (final selected in [true, false]) {
      var taps = 0;
      await tester.pumpWidget(_wrap(SelectionCard(
        title: 'Cut plan',
        subtitle: '5 meals',
        selected: selected,
        onTap: () => taps++,
      )));
      await tester.pumpAndSettle();
      final deco = tester
          .widget<AnimatedContainer>(find.byType(AnimatedContainer))
          .decoration! as BoxDecoration;
      check(deco.border).isNull();
      check(deco.color).equals(
        selected
            ? CrudoColors.light.primaryContainer
            : CrudoColors.light.surfaceLowest,
      );
      await tester.tap(find.text('Cut plan'));
      check(taps).equals(1);
    }
  });
}
```

- [ ] **Step 2:** Run — FAIL. Implement `lib/ui/core/widgets/selection_card.dart`:

```dart
import 'package:flutter/material.dart';

import '../themes/colors.dart';
import '../themes/dimensions.dart';
import '../themes/typography.dart';

/// Tappable option card. Selection = surface-tone shift (no border, ever).
class SelectionCard extends StatelessWidget {
  const SelectionCard({
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.trailing,
    super.key,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: Durations.fast,
          padding: const EdgeInsets.all(Spacing.md),
          decoration: BoxDecoration(
            color: selected ? colors.primaryContainer : colors.surfaceLowest,
            borderRadius: Radii.all(Radii.md),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: CrudoText.title),
                    if (subtitle != null) ...[
                      const SizedBox(height: Spacing.xs),
                      Text(
                        subtitle!,
                        style: CrudoText.label.copyWith(
                          color: colors.onSurfaceVar,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3:** Implement `lib/ui/core/widgets/meal_card.dart`:

```dart
import 'package:flutter/material.dart';

import 'package:crudo/domain/shared/enums.dart';

import '../themes/colors.dart';
import '../themes/dimensions.dart';
import '../themes/typography.dart';

/// A meal row: status glyph + title + time/kcal. Status colors per design
/// system: done=teal, partial=gold split-circle (never "½"), upcoming=muted,
/// skipped=red. No dividers — cards separate by spacing.
class MealCard extends StatelessWidget {
  const MealCard({
    required this.title,
    required this.timeLabel,
    required this.kcalLabel,
    required this.status,
    this.onTap,
    super.key,
  });

  final String title;
  final String timeLabel;
  final String kcalLabel;
  final MealStatus status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          color: colors.surfaceLowest,
          borderRadius: Radii.all(Radii.md),
        ),
        child: Row(
          children: [
            _StatusGlyph(status: status, key: ValueKey('meal-status-${status.name}')),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: CrudoText.title),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    '$timeLabel · $kcalLabel',
                    style: CrudoText.label.copyWith(color: colors.onSurfaceMut),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusGlyph extends StatelessWidget {
  const _StatusGlyph({required this.status, super.key});

  final MealStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    return switch (status) {
      MealStatus.done => Icon(Icons.check_circle, color: colors.primary),
      MealStatus.partial => CustomPaint(
        size: const Size.square(24),
        painter: _SplitCirclePainter(colors.gold),
      ),
      MealStatus.upcoming =>
        Icon(Icons.circle_outlined, color: colors.onSurfaceMut),
      MealStatus.skipped => Icon(Icons.do_not_disturb_on_outlined, color: colors.error),
    };
  }
}

/// Half-filled circle: the partial-state glyph (never a "½" character).
class _SplitCirclePainter extends CustomPainter {
  const _SplitCirclePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 1;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, stroke);
    final fill = Paint()..color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708, // -90°: fill the left half
      -3.14159,
      true,
      fill,
    );
  }

  @override
  bool shouldRepaint(_SplitCirclePainter oldDelegate) =>
      oldDelegate.color != color;
}
```

- [ ] **Step 4:** Tests PASS → format + analyze clean → **report** (no commit).

---

### Task 4: `MacroRing`

**Role:** implement · **Skills:** `flutter-add-widget-test`, `flutter-expert`
**Files:** Create `lib/ui/core/widgets/macro_ring.dart` · Test `test/ui/widgets/macro_ring_test.dart`
**Contract:** `MacroRing({required double protein, required double carbs, required double fats, String? centerLabel, double size = 120})` — ring of three arcs proportional to **kcal share** (`p*4 : c*4 : f*9`); protein = `primary`, carbs = **`gold`**, fats = `primarySoft`; track in `surfaceHigh`; optional center label (`CrudoText.headlineSm`). All-zero input renders just the track. **Check `app.css` for dedicated macro colors first** (`--protein`/`--carbs`/`--fat` or similar) — if it defines them and they differ, use the app.css values via a code comment citing the token name, and flag it in the report.
**Out of scope:** animated progress (feature specs).

- [ ] **Step 1: Failing test**

```dart
// test/ui/widgets/macro_ring_test.dart
import 'package:crudo/ui/core/themes/theme.dart';
import 'package:crudo/ui/core/widgets/macro_ring.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) =>
    MaterialApp(theme: crudoTheme, home: Scaffold(body: Center(child: child)));

void main() {
  testWidgets('paints and shows center label', (tester) async {
    await tester.pumpWidget(_wrap(const MacroRing(
      protein: 120,
      carbs: 200,
      fats: 60,
      centerLabel: '2 040',
    )));
    expect(find.byType(CustomPaint), findsWidgets);
    expect(find.text('2 040'), findsOneWidget);
  });

  testWidgets('all-zero input still renders (track only)', (tester) async {
    await tester.pumpWidget(_wrap(const MacroRing(protein: 0, carbs: 0, fats: 0)));
    expect(find.byType(MacroRing), findsOneWidget);
  });
}
```

- [ ] **Step 2:** Run — FAIL. Implement `lib/ui/core/widgets/macro_ring.dart`:

```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../themes/colors.dart';
import '../themes/typography.dart';

/// Macro distribution ring. Arc lengths are proportional to kcal share
/// (protein×4 : carbs×4 : fats×9). Colors: protein=primary (teal),
/// carbs=gold, fats=primary-soft.
class MacroRing extends StatelessWidget {
  const MacroRing({
    required this.protein,
    required this.carbs,
    required this.fats,
    this.centerLabel,
    this.size = 120,
    super.key,
  });

  final double protein;
  final double carbs;
  final double fats;
  final String? centerLabel;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _RingPainter(
          proteinKcal: protein * 4,
          carbsKcal: carbs * 4,
          fatsKcal: fats * 9,
          proteinColor: colors.primary,
          carbsColor: colors.gold,
          fatsColor: colors.primarySoft,
          trackColor: colors.surfaceHigh,
        ),
        child: centerLabel == null
            ? null
            : Center(child: Text(centerLabel!, style: CrudoText.headlineSm)),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.proteinKcal,
    required this.carbsKcal,
    required this.fatsKcal,
    required this.proteinColor,
    required this.carbsColor,
    required this.fatsColor,
    required this.trackColor,
  });

  final double proteinKcal;
  final double carbsKcal;
  final double fatsKcal;
  final Color proteinColor;
  final Color carbsColor;
  final Color fatsColor;
  final Color trackColor;

  static const _gap = 0.06; // radians between segments

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 6;
    final rect = Rect.fromCircle(center: center, radius: radius);
    Paint stroke(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, stroke(trackColor));

    final total = proteinKcal + carbsKcal + fatsKcal;
    if (total <= 0) return;

    var start = -math.pi / 2;
    for (final (kcal, color) in [
      (proteinKcal, proteinColor),
      (carbsKcal, carbsColor),
      (fatsKcal, fatsColor),
    ]) {
      if (kcal <= 0) continue;
      final sweep = (kcal / total) * 2 * math.pi - _gap;
      canvas.drawArc(rect, start + _gap / 2, math.max(sweep, 0.01), false, stroke(color));
      start += (kcal / total) * 2 * math.pi;
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.proteinKcal != proteinKcal ||
      old.carbsKcal != carbsKcal ||
      old.fatsKcal != fatsKcal;
}
```

- [ ] **Step 3:** Tests PASS → format + analyze clean → **report** (note the app.css macro-color check result).

---

### Task 5: `SheetScaffold` + `showCrudoSheet` + Toast

**Role:** implement · **Skills:** `flutter-add-widget-test`, `flutter-expert`
**Files:** Create `lib/ui/core/widgets/sheet.dart`, `lib/ui/core/widgets/toast.dart` · Test `test/ui/widgets/sheet_test.dart`, `test/ui/widgets/toast_test.dart`
**Contract:**
- `showCrudoSheet<T>(BuildContext context, {required WidgetBuilder builder})` → `showModalBottomSheet` with transparent barrier-styling, `isScrollControlled: true`, no Material shape — the sheet body is `SheetScaffold`.
- `SheetScaffold({required String title, required Widget child, Widget? cta})` — top: centered pill drag-handle (`surfaceHighest`, 40×4, `Radii.full`); title `CrudoText.headlineSm`; body; optional sticky `cta` at bottom with `Spacing.md` padding; container: `surfaceLowest` w/ top `Radii.lg` corners, `Shadows.cloud`, SafeArea bottom. No 1px borders.
- `showCrudoToast(BuildContext context, String message)` — `OverlayEntry` near the bottom, `surfaceLowest` rounded `Radii.md` container with `Shadows.cloud`, `CrudoText.labelMd`, auto-removes after 2500ms.
**Out of scope:** specific sheets (snooze/swap/etc. — feature specs).

- [ ] **Step 1: Failing tests**

```dart
// test/ui/widgets/sheet_test.dart
import 'package:crudo/ui/core/themes/theme.dart';
import 'package:crudo/ui/core/widgets/primary_cta.dart';
import 'package:crudo/ui/core/widgets/sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('showCrudoSheet opens a SheetScaffold and closes', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: crudoTheme,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showCrudoSheet<void>(
              context,
              builder: (_) => SheetScaffold(
                title: 'Snooze',
                child: const Text('Pick a delay'),
                cta: PrimaryCta(label: 'Confirm', onPressed: () {}),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Snooze'), findsOneWidget);
    expect(find.text('Pick a delay'), findsOneWidget);
    expect(find.text('Confirm'), findsOneWidget);

    await tester.tapAt(const Offset(10, 10)); // barrier dismiss
    await tester.pumpAndSettle();
    expect(find.text('Snooze'), findsNothing);
  });
}
```

```dart
// test/ui/widgets/toast_test.dart
import 'package:crudo/ui/core/themes/theme.dart';
import 'package:crudo/ui/core/widgets/toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('toast shows then auto-dismisses', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: crudoTheme,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showCrudoToast(context, 'Plan saved'),
            child: const Text('go'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('go'));
    await tester.pump();
    expect(find.text('Plan saved'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 2600));
    expect(find.text('Plan saved'), findsNothing);
  });
}
```

- [ ] **Step 2:** Run — FAIL. Implement `lib/ui/core/widgets/sheet.dart`:

```dart
import 'package:flutter/material.dart';

import '../themes/colors.dart';
import '../themes/dimensions.dart';
import '../themes/typography.dart';

/// Opens a Crudo-styled modal bottom sheet. Sheets are transient overlays —
/// deliberately NOT routes (architecture §5).
Future<T?> showCrudoSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: builder,
  );
}

/// Standard sheet layout: pill handle, title, body, optional sticky CTA.
class SheetScaffold extends StatelessWidget {
  const SheetScaffold({
    required this.title,
    required this.child,
    this.cta,
    super.key,
  });

  final String title;
  final Widget child;
  final Widget? cta;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceLowest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(Radii.lg)),
        boxShadow: Shadows.cloud,
      ),
      padding: const EdgeInsets.all(Spacing.md),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.surfaceHighest,
                  borderRadius: Radii.all(Radii.full),
                ),
              ),
            ),
            const SizedBox(height: Spacing.md),
            Text(title, style: CrudoText.headlineSm, textAlign: TextAlign.center),
            const SizedBox(height: Spacing.md),
            Flexible(child: child),
            if (cta != null) ...[
              const SizedBox(height: Spacing.lg),
              cta!,
            ],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3:** Implement `lib/ui/core/widgets/toast.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';

import '../themes/colors.dart';
import '../themes/dimensions.dart';
import '../themes/typography.dart';

/// Floating confirmation toast (Cloud Shadow, auto-dismiss). For inline
/// validation feedback prefer in-form errors; toasts are for global events.
void showCrudoToast(BuildContext context, String message) {
  final overlay = Overlay.of(context);
  final colors = Theme.of(context).extension<CrudoColors>()!;
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 96,
      left: Spacing.lg,
      right: Spacing.lg,
      child: IgnorePointer(
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md,
              vertical: Spacing.sm + Spacing.xs,
            ),
            decoration: BoxDecoration(
              color: colors.surfaceLowest,
              borderRadius: Radii.all(Radii.md),
              boxShadow: Shadows.cloud,
            ),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: CrudoText.labelMd.copyWith(color: colors.onSurface),
            ),
          ),
        ),
      ),
    ),
  );
  overlay.insert(entry);
  Timer(const Duration(milliseconds: 2500), entry.remove);
}
```

- [ ] **Step 4:** Tests PASS → format + analyze clean → **report** (no commit).

---

### Task 6: Showcase placeholders + previews + full suite

**Role:** implement · **Skills:** `flutter-add-widget-preview`, `flutter-add-widget-test`
**Files:** Modify the four screens from Task 1 · Create `lib/previews.dart` · Extend `test/routing/app_router_test.dart`
**Contract:** Today → 3 `MealCard`s (one per visible status: done/partial/upcoming) + `MacroRing(protein: 120, carbs: 200, fats: 60, centerLabel: '2 040')`; Plans → 2 `SelectionCard`s + a weekday `Pill` row (Mon–Sun, Mon+Wed selected) + a `PrimaryCta('New plan')` that opens a demo `SheetScaffold` via `showCrudoSheet`; History → a `_DemoCounter` (stateful chip incrementing on tap — proves tab-state preservation) + a button triggering `showCrudoToast(context, 'Looking good!')`; Profile → 3 `SelectionCard` rows (Units/Goal/Reminders, unselected) + disabled `PrimaryCta('Sign out')`. All dummy params — **no repos/controllers**. `lib/previews.dart` previews all 7 widgets (every `MealCard` status, selected/unselected, disabled CTA) per the `flutter-add-widget-preview` skill.
**Out of scope:** real data/feature logic.

- [ ] **Step 1:** Fill the four screens (compose the widgets per contract — each screen stays a `ConsumerWidget`/`StatelessWidget` + the one `_DemoCounter` `StatefulWidget` in History).

- [ ] **Step 2:** Add the state-preservation test to `test/routing/app_router_test.dart`:

```dart
  testWidgets('tab state is preserved across branch switches', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('nav-History')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('demo-counter')));
    await tester.tap(find.byKey(const ValueKey('demo-counter')));
    await tester.pumpAndSettle();
    expect(find.text('Taps: 2'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('nav-Today')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('nav-History')));
    await tester.pumpAndSettle();
    expect(find.text('Taps: 2'), findsOneWidget); // survived the round-trip
  });
```

- [ ] **Step 3:** Create `lib/previews.dart` with `@Preview` entries for all widgets/states per the skill's pattern.

- [ ] **Step 4:** Full suite: `flutter test && dart format . && flutter analyze` — green/clean. Run the app once (`flutter run --flavor dev -t lib/main_development.dart --dart-define-from-file=config/dev.json`) if a device is available; otherwise note it for Opus.

- [ ] **Step 5: Report** done for review (no commit). Include which app.css macro tokens were checked (Task 4 note) and a screenshot if you ran the app.

---

## Final verification (Opus, before merging `feat/s04-routing`)
- [ ] Suite green; format/analyze clean; architecture test untouched + green.
- [ ] Boot on simulator: 4 tabs, state preserved, dev marker dev-only; sheet + toast demos work.
- [ ] Visual pass against `app.css`/prototype: radii, spacing, colors, no borders/shadows violations.
- [ ] Merge order: after S03 (rebase onto updated main; only `pubspec.lock` union expected).
