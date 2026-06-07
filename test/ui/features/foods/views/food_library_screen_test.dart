import 'package:checks/checks.dart';
import 'package:crudo/config/di.dart';
import 'package:crudo/domain/food/food.dart';
import 'package:crudo/domain/shared/enums.dart';
import 'package:crudo/ui/core/themes/theme.dart';
import 'package:crudo/ui/features/foods/view_models/food_library.dart';
import 'package:crudo/ui/features/foods/views/food_form_screen.dart';
import 'package:crudo/ui/features/foods/views/food_library_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _chicken = Food(
  id: 'seed-chicken-breast',
  name: 'Chicken breast',
  category: FoodCategory.meat,
  protein: 31,
  carbs: 0,
  fats: 3.6,
  kcalPer100g: 156.4,
);
const _turkey = Food(
  id: 'seed-turkey',
  name: 'Turkey',
  category: FoodCategory.meat,
  protein: 29,
  carbs: 0,
  fats: 1,
  kcalPer100g: 125,
);
const _broccoli = Food(
  id: 'seed-broccoli',
  name: 'Broccoli',
  category: FoodCategory.veg,
  protein: 2.8,
  carbs: 7,
  fats: 0.4,
  kcalPer100g: 42.8,
);
const _shake = Food(
  id: 'c1',
  name: 'My shake',
  category: FoodCategory.custom,
  protein: 30,
  carbs: 10,
  fats: 5,
  kcalPer100g: 205,
  isCustom: true,
);
const _soup = Food(
  id: 'c2',
  name: 'Mom soup',
  kind: FoodKind.dish,
  category: FoodCategory.custom,
  protein: 5,
  carbs: 8,
  fats: 3,
  kcalPer100g: 79,
  isCustom: true,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer container() {
    final c = ProviderContainer(
      overrides: [
        seedFoodsProvider.overrideWithValue(const [
          _chicken,
          _turkey,
          _broccoli,
          _shake,
          _soup,
        ]),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  Widget app(ProviderContainer c, {String initial = '/foods'}) {
    final router = GoRouter(
      initialLocation: initial,
      routes: [
        GoRoute(
          path: '/foods',
          builder: (_, _) => const FoodLibraryScreen(),
          routes: [
            GoRoute(
              path: 'new',
              builder: (_, _) => const FoodFormScreen(foodId: null),
            ),
            GoRoute(
              path: ':id',
              builder: (_, s) =>
                  FoodFormScreen(foodId: s.pathParameters['id']!),
            ),
          ],
        ),
      ],
    );
    return UncontrolledProviderScope(
      container: c,
      child: MaterialApp.router(theme: crudoTheme, routerConfig: router),
    );
  }

  /// Shared pump helper: mirrors food_form_screen_test.dart's pumpForm.
  /// Sets 800×1800 viewport (so all rows are visible), seeds the library
  /// provider, and calls pumpAndSettle. All 7 tests use this helper so
  /// the no-match test also gets the viewport override.
  Future<ProviderContainer> pumpLibrary(WidgetTester t) async {
    final c = container();
    c.listen(foodLibraryProvider, (_, _) {});
    t.view.physicalSize = const Size(800, 1800);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(app(c));
    await t.pumpAndSettle();
    return c;
  }

  testWidgets('renders groups + rows', (t) async {
    await pumpLibrary(t);
    expect(find.byKey(const ValueKey('group-Meat')), findsOneWidget);
    expect(find.byKey(const ValueKey('group-Vegetables')), findsOneWidget);
    expect(find.byKey(const ValueKey('group-Custom')), findsOneWidget);
    expect(find.byKey(const ValueKey('group-Dishes')), findsOneWidget);
    // Alphabetical within Meat: Chicken breast before Turkey.
    final chickenBox = t.getRect(find.text('Chicken breast'));
    final turkeyBox = t.getRect(find.text('Turkey'));
    check(chickenBox.top).isLessThan(turkeyBox.top);
    // Summary text for chicken: kcal 156 + P31 C0 F3.6
    expect(find.text('156 kcal · P31 C0 F3.6'), findsOneWidget);
  });

  testWidgets('search narrows the list', (t) async {
    await pumpLibrary(t);
    await t.enterText(find.byKey(const ValueKey('food-search')), 'broc');
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('group-Vegetables')), findsOneWidget);
    expect(find.byKey(const ValueKey('group-Meat')), findsNothing);
    expect(find.text('Broccoli'), findsOneWidget);
  });

  testWidgets('no match → empty hint', (t) async {
    await pumpLibrary(t);
    await t.enterText(find.byKey(const ValueKey('food-search')), 'zzz');
    await t.pumpAndSettle();
    expect(find.textContaining('No foods match'), findsOneWidget);
  });

  testWidgets('custom row tap → edit form route', (t) async {
    await pumpLibrary(t);
    await t.tap(find.text('My shake'));
    await t.pumpAndSettle();
    expect(find.text('Food library'), findsNothing);
  });

  testWidgets('seed row tap is inert (no navigation)', (t) async {
    await pumpLibrary(t);
    await t.tap(find.text('Chicken breast'), warnIfMissed: false);
    await t.pumpAndSettle();
    expect(find.text('Food library'), findsOneWidget);
  });

  testWidgets('add button → create form route', (t) async {
    await pumpLibrary(t);
    await t.tap(find.byKey(const ValueKey('add-food')));
    await t.pumpAndSettle();
    expect(find.text('Food library'), findsNothing);
  });

  testWidgets('custom rows show CUSTOM pill + chevron, seed rows neither', (
    t,
  ) async {
    await pumpLibrary(t);
    // 2 custom rows: My shake (custom/product) and Mom soup (custom/dish).
    expect(find.byKey(const ValueKey('custom-pill')), findsNWidgets(2));
  });
}
