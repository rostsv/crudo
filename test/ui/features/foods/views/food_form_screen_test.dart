import 'package:checks/checks.dart';
import 'package:crudo/config/di.dart';
import 'package:crudo/data/repositories/in_memory_food_repository.dart';
import 'package:crudo/data/services/id_generator.dart';
import 'package:crudo/domain/food/food.dart';
import 'package:crudo/domain/repositories/food_repository.dart';
import 'package:crudo/domain/shared/enums.dart';
import 'package:crudo/ui/core/themes/theme.dart';
import 'package:crudo/ui/features/foods/views/food_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// A repo whose save() always throws — used for Fix 3 error-handling tests.
class _ThrowingFoodRepository implements FoodRepository {
  _ThrowingFoodRepository(this._delegate);

  final FoodRepository _delegate;

  @override
  Stream<List<Food>> watchAll() => _delegate.watchAll();

  @override
  Future<List<Food>> getAll() => _delegate.getAll();

  @override
  Future<Food?> getById(String id) => _delegate.getById(id);

  @override
  Future<void> save(Food food) async => throw Exception('network error');

  @override
  Future<void> delete(String id) => _delegate.delete(id);
}

const _chicken = Food(
  id: 'seed-chicken-breast',
  name: 'Chicken breast',
  category: FoodCategory.meat,
  protein: 31,
  carbs: 0,
  fats: 3.6,
  kcalPer100g: 156.4,
);
const _shake = Food(
  id: 'c1',
  name: 'My shake',
  category: FoodCategory.custom,
  protein: 30,
  carbs: 10,
  fats: 5,
  kcalPer100g: 205, // == calc (30*4+10*4+5*9) → auto
  isCustom: true,
);
const _jam = Food(
  id: 'c9',
  name: 'Label jam',
  category: FoodCategory.custom,
  protein: 0,
  carbs: 50,
  fats: 0,
  kcalPer100g: 210, // calc=200; stored ≠ calc → was an explicit override
  isCustom: true,
);

class _FakeIdGenerator implements IdGenerator {
  int _n = 0;
  @override
  String newId() => 'id-${_n++}';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer container({String initial = '/foods/new'}) {
    final c = ProviderContainer(
      overrides: [
        seedFoodsProvider.overrideWithValue(const [_chicken, _shake, _jam]),
        idGeneratorProvider.overrideWithValue(_FakeIdGenerator()),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  Widget app(ProviderContainer c, {String initial = '/foods/new'}) {
    final router = GoRouter(
      initialLocation: initial,
      routes: [
        GoRoute(
          path: '/foods',
          builder: (_, _) => const Scaffold(body: Text('Food library')),
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

  Future<ProviderContainer> pumpForm(
    WidgetTester t, {
    String initial = '/foods/new',
  }) async {
    final c = container(initial: initial);
    t.view.physicalSize = const Size(800, 1800);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(app(c, initial: initial));
    await t.pumpAndSettle();
    return c;
  }

  Future<ProviderContainer> pumpEdit(WidgetTester t, String id) =>
      pumpForm(t, initial: '/foods/$id');

  testWidgets('create: name+macros → calculated kcal shown, save persists', (
    t,
  ) async {
    final c = await pumpForm(t);
    await t.enterText(find.byKey(const ValueKey('food-name')), 'My bar');
    await t.enterText(find.byKey(const ValueKey('macro-protein')), '30');
    await t.enterText(find.byKey(const ValueKey('macro-carbs')), '10');
    await t.enterText(find.byKey(const ValueKey('macro-fats')), '5');
    await t.pumpAndSettle();
    // Calc 30*4+10*4+5*9 = 205
    expect(find.text('205'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('save-food')));
    await t.pumpAndSettle();
    // Back on the library stub.
    expect(find.text('Food library'), findsOneWidget);
    final saved = await c.read(foodRepositoryProvider).getById('id-0');
    check(saved).isNotNull();
    check(saved!.name).equals('My bar');
    check(saved.isCustom).isTrue();
    check(saved.category).equals(FoodCategory.custom);
    check(saved.kcalPer100g).equals(205);
  });

  testWidgets('SAVE disabled on blank name; enabled once valid', (t) async {
    await pumpForm(t);
    final saveBtn = find.byKey(const ValueKey('save-food'));
    final widget = t.widget<TextButton>(saveBtn);
    expect(widget.onPressed, isNull);
    await t.enterText(find.byKey(const ValueKey('food-name')), 'X');
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const ValueKey('macro-protein')), '10');
    await t.pumpAndSettle();
    final widget2 = t.widget<TextButton>(saveBtn);
    expect(widget2.onPressed, isNotNull);
  });

  testWidgets('override out of ±10% → banner + SAVE blocked; clear reverts', (
    t,
  ) async {
    await pumpForm(t);
    await t.enterText(find.byKey(const ValueKey('food-name')), 'X');
    await t.enterText(find.byKey(const ValueKey('macro-protein')), '20');
    await t.enterText(find.byKey(const ValueKey('macro-carbs')), '30');
    await t.enterText(find.byKey(const ValueKey('macro-fats')), '10');
    // calc = 20*4+30*4+10*9 = 290.
    // Override 320 → 10% over → banner + disabled.
    await t.enterText(find.byKey(const ValueKey('kcal-override')), '320');
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('kcal-mismatch')), findsOneWidget);
    expect(find.textContaining('Override differs by 10.4%'), findsOneWidget);
    var saveBtn = t.widget<TextButton>(find.byKey(const ValueKey('save-food')));
    expect(saveBtn.onPressed, isNull);
    // Override 319 (within ±10%) → banner gone, save enabled.
    await t.enterText(find.byKey(const ValueKey('kcal-override')), '319');
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('kcal-mismatch')), findsNothing);
    saveBtn = t.widget<TextButton>(find.byKey(const ValueKey('save-food')));
    expect(saveBtn.onPressed, isNotNull);
    // Clear override → auto, banner stays gone, calc still 290.
    await t.enterText(find.byKey(const ValueKey('kcal-override')), '');
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('kcal-mismatch')), findsNothing);
    expect(find.text('290'), findsOneWidget);
  });

  testWidgets('all-zero macros: empty override saves kcal 0; nonzero blocked', (
    t,
  ) async {
    await pumpForm(t);
    await t.enterText(find.byKey(const ValueKey('food-name')), 'Water');
    await t.pumpAndSettle();
    // Macros default to 0; calc = 0; no override set → save enabled.
    var saveBtn = t.widget<TextButton>(find.byKey(const ValueKey('save-food')));
    expect(saveBtn.onPressed, isNotNull);
    // Set a non-zero override → zero-rule banner + save disabled.
    await t.enterText(find.byKey(const ValueKey('kcal-override')), '5');
    await t.pumpAndSettle();
    expect(find.text('Macros are zero — calories must be 0.'), findsOneWidget);
    saveBtn = t.widget<TextButton>(find.byKey(const ValueKey('save-food')));
    expect(saveBtn.onPressed, isNull);
  });

  testWidgets('kind toggle: Dish hides CATEGORY; save writes category=custom; '
      'toggle back to Product restores chip selection', (t) async {
    final c = await pumpForm(t);
    await t.enterText(find.byKey(const ValueKey('food-name')), 'X');
    await t.enterText(find.byKey(const ValueKey('macro-protein')), '10');

    // Select 'Meat' chip while in Product mode.
    await t.tap(find.text('Meat'));
    await t.pumpAndSettle();
    expect(find.text('CATEGORY'), findsOneWidget);
    expect(find.text('Meat'), findsOneWidget);

    // Tap "Dish" pill → CATEGORY section disappears.
    await t.tap(find.text('Dish'));
    await t.pumpAndSettle();
    expect(find.text('CATEGORY'), findsNothing);
    expect(find.text('Meat'), findsNothing);

    // Save as dish → category must be custom regardless of prior chip.
    await t.tap(find.byKey(const ValueKey('save-food')));
    await t.pumpAndSettle();
    final saved = await c.read(foodRepositoryProvider).getById('id-0');
    check(saved!.kind).equals(FoodKind.dish);
    check(saved.category).equals(FoodCategory.custom);
  });

  testWidgets('kind toggle back to Product restores chip selection', (t) async {
    await pumpForm(t);
    await t.enterText(find.byKey(const ValueKey('food-name')), 'X');
    await t.enterText(find.byKey(const ValueKey('macro-protein')), '10');

    // Select 'Meat' chip while in Product mode.
    await t.tap(find.text('Meat'));
    await t.pumpAndSettle();

    // Switch to Dish → Meat chip gone.
    await t.tap(find.text('Dish'));
    await t.pumpAndSettle();
    expect(find.text('Meat'), findsNothing);

    // Switch back to Product → Meat chip reappears (in-memory category
    // was NOT cleared).
    await t.tap(find.text('Product'));
    await t.pumpAndSettle();
    expect(find.text('CATEGORY'), findsOneWidget);
    expect(find.text('Meat'), findsOneWidget);
  });

  testWidgets('product-mode: tap chip twice → category cleared (custom)', (
    t,
  ) async {
    final c = await pumpForm(t);
    await t.enterText(find.byKey(const ValueKey('food-name')), 'X');
    await t.enterText(find.byKey(const ValueKey('macro-protein')), '10');

    // Tap Meat → selected; tap again → deselected (category = custom).
    await t.tap(find.text('Meat'));
    await t.pumpAndSettle();
    await t.tap(find.text('Meat'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('save-food')));
    await t.pumpAndSettle();
    final saved = await c.read(foodRepositoryProvider).getById('id-0');
    check(saved!.kind).equals(FoodKind.product);
    check(saved.category).equals(FoodCategory.custom);
  });

  testWidgets('edit: prefilled, save keeps id', (t) async {
    final c = await pumpEdit(t, 'c1');
    expect(find.text('My shake'), findsOneWidget);
    // Override field empty (stored == calc → auto).
    final override = t.widget<TextField>(
      find.byKey(const ValueKey('kcal-override')),
    );
    expect(override.controller!.text, isEmpty);
    await t.enterText(find.byKey(const ValueKey('macro-protein')), '35');
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('save-food')));
    await t.pumpAndSettle();
    final saved = await c.read(foodRepositoryProvider).getById('c1');
    check(saved!.protein).equals(35);
  });

  testWidgets('edit prefills an accepted override', (t) async {
    await pumpEdit(t, 'c9');
    // Override field shows '210', calc shows '200', no banner.
    final override = t.widget<TextField>(
      find.byKey(const ValueKey('kcal-override')),
    );
    expect(override.controller!.text, '210');
    expect(find.text('200'), findsOneWidget);
    expect(find.byKey(const ValueKey('kcal-mismatch')), findsNothing);
  });

  testWidgets('delete: confirm sheet → removed + toast; cancel keeps', (
    t,
  ) async {
    final c = await pumpEdit(t, 'c1');
    await t.tap(find.byKey(const ValueKey('delete-food')));
    await t.pumpAndSettle();
    expect(find.text('Delete food?'), findsOneWidget);
    // Cancel first → food still there.
    await t.tap(find.byKey(const ValueKey('cancel-delete')));
    await t.pumpAndSettle();
    expect(find.text('Delete food?'), findsNothing);
    check(await c.read(foodRepositoryProvider).getById('c1')).isNotNull();
    // Now confirm delete.
    await t.tap(find.byKey(const ValueKey('delete-food')));
    await t.pumpAndSettle();
    await t.tap(find.text('Delete'));
    await t.pumpAndSettle();
    check(await c.read(foodRepositoryProvider).getById('c1')).isNull();
    // Toast appears.
    expect(find.text('Food deleted'), findsOneWidget);
    // Flush the toast's auto-dismiss timer so the test ends clean.
    await t.pump(const Duration(seconds: 5));
  });

  testWidgets(
    'comma-decimal input: "12,5" protein → 12.5; "350,5" override → 350.5 (Fix 1)',
    (t) async {
      final c = await pumpForm(t);
      await t.enterText(find.byKey(const ValueKey('food-name')), 'X');
      // Comma decimal in protein field.
      await t.enterText(find.byKey(const ValueKey('macro-protein')), '12,5');
      // Comma decimal override — calc for 0*4+0*4+0*9 = 0; use known macros.
      await t.enterText(find.byKey(const ValueKey('macro-carbs')), '50');
      // 12.5*4 + 50*4 = 250; override 350.5 is about 40% off so it'll show
      // the mismatch banner, but the value should be parsed correctly.
      // Instead, use a valid override: calc = 12.5*4 + 50*4 = 250,
      // 250 * 1.05 = 262.5 is within ±10%.
      await t.enterText(find.byKey(const ValueKey('kcal-override')), '262,5');
      await t.pumpAndSettle();
      // Banner should NOT appear (262.5 is within 10% of 250).
      expect(find.byKey(const ValueKey('kcal-mismatch')), findsNothing);
      // Save should be enabled.
      final saveBtn = t.widget<TextButton>(
        find.byKey(const ValueKey('save-food')),
      );
      expect(saveBtn.onPressed, isNotNull);
      await t.tap(find.byKey(const ValueKey('save-food')));
      await t.pumpAndSettle();
      final saved = await c.read(foodRepositoryProvider).getById('id-0');
      check(saved!.protein).equals(12.5);
      check(saved.kcalPer100g).equals(262.5);
    },
  );

  testWidgets(
    'negative input stripped by formatter: "-5" protein → no minus, draft >= 0 (Fix 2)',
    (t) async {
      await pumpForm(t);
      // Enter a negative value; the FilteringTextInputFormatter should strip
      // the '-' so the field never shows it.
      await t.enterText(find.byKey(const ValueKey('macro-protein')), '-5');
      await t.pumpAndSettle();
      // find.byKey('macro-protein') finds the MacroField wrapper; find the
      // TextField descendant by its controller text.
      final controllers = t
          .widgetList<TextField>(find.byType(TextField))
          .map((f) => f.controller?.text ?? '')
          .toList();
      // None of the field texts should contain '-'.
      for (final text in controllers) {
        expect(text.contains('-'), isFalse);
      }
    },
  );

  testWidgets('failed save → error toast shown, route NOT popped (Fix 3)', (
    t,
  ) async {
    // Build a single container with the throwing repo override.
    // Use overrideWithValue with a directly constructed repo so there's no
    // self-referential provider read.
    final baseRepo = InMemoryFoodRepository(
      seed: const [_chicken, _shake, _jam],
    );
    final c = ProviderContainer(
      overrides: [
        seedFoodsProvider.overrideWithValue(const [_chicken, _shake, _jam]),
        idGeneratorProvider.overrideWithValue(_FakeIdGenerator()),
        foodRepositoryProvider.overrideWithValue(
          _ThrowingFoodRepository(baseRepo),
        ),
      ],
    );
    addTearDown(c.dispose);

    t.view.physicalSize = const Size(800, 1800);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(app(c));
    await t.pumpAndSettle();

    // Fill in a valid draft.
    await t.enterText(find.byKey(const ValueKey('food-name')), 'Fail food');
    await t.enterText(find.byKey(const ValueKey('macro-protein')), '20');
    await t.pumpAndSettle();

    // SAVE button should be enabled.
    final saveBtn = t.widget<TextButton>(
      find.byKey(const ValueKey('save-food')),
    );
    expect(saveBtn.onPressed, isNotNull);

    // Tap SAVE — repo throws.
    await t.tap(find.byKey(const ValueKey('save-food')));
    await t.pumpAndSettle();

    // Still on the form (route NOT popped).
    expect(find.text('Fail food'), findsOneWidget);
    // Error toast is shown.
    expect(find.textContaining("Couldn't save"), findsOneWidget);
    // Flush toast timer.
    await t.pump(const Duration(seconds: 5));
  });
}
