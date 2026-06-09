import 'package:checks/checks.dart';
import 'package:crudo/config/app_config.dart';
import 'package:crudo/config/di.dart';
import 'package:crudo/data/services/id_generator.dart';
import 'package:crudo/data/services/seed_service.dart';
import 'package:crudo/domain/food/food.dart';
import 'package:crudo/domain/shared/grams.dart';
import 'package:crudo/ui/core/themes/theme.dart';
import 'package:crudo/ui/features/foods/views/food_form_screen.dart';
import 'package:crudo/ui/features/meals/views/add_ingredient_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../../helpers/fake_id_generator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<Food> seedFoods;
  setUpAll(() async => seedFoods = await SeedService().loadFoods());

  ({Food food, Grams grams})? capturedResult;

  ProviderContainer container() {
    final c = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(AppConfig(flavor: Flavor.dev)),
        seedFoodsProvider.overrideWithValue(seedFoods),
        idGeneratorProvider.overrideWithValue(FakeIdGenerator()),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  /// Harness: launcher at '/' that pushes '/add' → AddIngredientScreen;
  /// '/foods/new' → real FoodFormScreen (for custom-food round-trip).
  Widget app(ProviderContainer c) {
    capturedResult = null;
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  final result = await context.push<({Food food, Grams grams})>(
                    '/add',
                  );
                  capturedResult = result;
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
        GoRoute(path: '/add', builder: (_, _) => const AddIngredientScreen()),
        GoRoute(
          path: '/foods/new',
          builder: (_, _) => const FoodFormScreen(foodId: null),
        ),
      ],
    );
    return UncontrolledProviderScope(
      container: c,
      child: MaterialApp.router(theme: crudoTheme, routerConfig: router),
    );
  }

  Future<ProviderContainer> pump(WidgetTester t) async {
    final c = container();
    t.view.physicalSize = const Size(800, 1800);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(app(c));
    await t.pumpAndSettle();
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    return c;
  }

  testWidgets('stage 1: library groups visible', (t) async {
    await pump(t);
    // Seed data is grouped — at least the Meat group from SeedService
    expect(find.byKey(const ValueKey('food-search')), findsOneWidget);
    expect(find.byKey(const ValueKey('create-custom-cta')), findsOneWidget);
    // Some food rows rendered (seed data)
    expect(find.byType(ListView).last, findsOneWidget);
  });

  testWidgets('stage 1→2: tap a food row shows grams stage', (t) async {
    await pump(t);
    // Tap a seed food row (e.g. Chicken Breast in seed data)
    final chickenFinder = find.text('Chicken breast');
    expect(chickenFinder, findsOneWidget);
    await t.tap(chickenFinder);
    await t.pumpAndSettle();
    // Stage 2: selected card + grams input preset at 100
    expect(find.text('SELECTED'), findsOneWidget);
    expect(find.text('Chicken breast'), findsOneWidget);
    expect(find.byKey(const ValueKey('grams-input')), findsOneWidget);
    // Default 100g filled in
    final inputWidget = t.widget<TextField>(
      find.byKey(const ValueKey('grams-input')),
    );
    expect(inputWidget.controller?.text, equals('100'));
  });

  testWidgets('preset tap updates input and preview kcal', (t) async {
    await pump(t);
    await t.tap(find.text('Chicken breast'));
    await t.pumpAndSettle();

    // Find the chicken food to get per100g kcal
    final chicken = seedFoods.firstWhere((f) => f.name == 'Chicken breast');
    // Tap 150g preset
    await t.tap(find.byKey(const ValueKey('grams-preset-150')));
    await t.pumpAndSettle();

    final inputWidget = t.widget<TextField>(
      find.byKey(const ValueKey('grams-input')),
    );
    expect(inputWidget.controller?.text, equals('150'));

    // Preview should show kcal for 150g
    final expected = (chicken.kcalPer100g * 1.5).round();
    expect(find.byKey(const ValueKey('grams-preview-kcal')), findsOneWidget);
    expect(find.text('$expected kcal'), findsOneWidget);
  });

  testWidgets('clearing input shows invalid hint + disables Add to Meal', (
    t,
  ) async {
    await pump(t);
    await t.tap(find.text('Chicken breast'));
    await t.pumpAndSettle();

    await t.enterText(find.byKey(const ValueKey('grams-input')), '');
    await t.pumpAndSettle();

    expect(find.byKey(const ValueKey('grams-invalid')), findsOneWidget);
  });

  testWidgets('Add to Meal at 150g pops FoodSnapshot with correct data', (
    t,
  ) async {
    await pump(t);
    final chicken = seedFoods.firstWhere((f) => f.name == 'Chicken breast');

    await t.tap(find.text('Chicken breast'));
    await t.pumpAndSettle();

    await t.tap(find.byKey(const ValueKey('grams-preset-150')));
    await t.pumpAndSettle();

    await t.tap(find.byKey(const ValueKey('add-to-meal')));
    await t.pumpAndSettle();

    check(capturedResult).isNotNull();
    check(capturedResult!.food.id).equals(chicken.id);
    check(capturedResult!.grams).equals(const Grams(150));
  });

  testWidgets('back from stage 2 returns to stage 1', (t) async {
    await pump(t);
    await t.tap(find.text('Chicken breast'));
    await t.pumpAndSettle();

    // Should be on stage 2
    expect(find.text('SELECTED'), findsOneWidget);

    // Tap back (picker-back key)
    await t.tap(find.byKey(const ValueKey('picker-back')));
    await t.pumpAndSettle();

    // Back to stage 1 — no SELECTED, list visible
    expect(find.text('SELECTED'), findsNothing);
    expect(find.byKey(const ValueKey('food-search')), findsOneWidget);
    // We're still on the picker screen (not popped)
    expect(find.byKey(const ValueKey('create-custom-cta')), findsOneWidget);
  });

  testWidgets(
    'custom-food CTA: create food, land in grams stage with it prefilled',
    (t) async {
      await pump(t);

      // Tap the CTA to create a custom food
      await t.tap(find.byKey(const ValueKey('create-custom-cta')));
      await t.pumpAndSettle();

      // We're on the FoodFormScreen now
      expect(find.byKey(const ValueKey('food-name')), findsOneWidget);

      // Fill in a valid food
      await t.enterText(find.byKey(const ValueKey('food-name')), 'My blend');
      await t.enterText(find.byKey(const ValueKey('macro-protein')), '30');
      await t.enterText(find.byKey(const ValueKey('macro-carbs')), '10');
      await t.enterText(find.byKey(const ValueKey('macro-fats')), '5');
      await t.pumpAndSettle();

      await t.tap(find.byKey(const ValueKey('save-food')));
      await t.pumpAndSettle();

      // Back on the picker, stage 2 with 'My blend' selected
      expect(find.text('SELECTED'), findsOneWidget);
      expect(find.text('My blend'), findsOneWidget);

      // Default 100g shown
      final inputWidget = t.widget<TextField>(
        find.byKey(const ValueKey('grams-input')),
      );
      expect(inputWidget.controller?.text, equals('100'));

      // Add to meal → record with the new food's name
      await t.tap(find.byKey(const ValueKey('add-to-meal')));
      await t.pumpAndSettle();

      check(capturedResult).isNotNull();
      check(capturedResult!.food.name).equals('My blend');
      check(capturedResult!.grams).equals(const Grams(100));
    },
  );

  testWidgets('empty search shows picker-empty-hint in picker mode', (t) async {
    await pump(t);
    await t.enterText(
      find.byKey(const ValueKey('food-search')),
      'zzz_no_match',
    );
    await t.pumpAndSettle();

    expect(find.byKey(const ValueKey('picker-empty-hint')), findsOneWidget);
    expect(
      find.text('Use the button above to add it as a custom food.'),
      findsOneWidget,
    );
    // CTA still visible (outside the list)
    expect(find.byKey(const ValueKey('create-custom-cta')), findsOneWidget);
  });
}
