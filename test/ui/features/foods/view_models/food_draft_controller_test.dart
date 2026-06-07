import 'package:checks/checks.dart';
import 'package:crudo/config/di.dart';
import 'package:crudo/data/repositories/in_memory_food_repository.dart';
import 'package:crudo/data/services/id_generator.dart';
import 'package:crudo/domain/food/food.dart';
import 'package:crudo/domain/repositories/food_repository.dart';
import 'package:crudo/domain/shared/enums.dart';
import 'package:crudo/domain/validation/validation_issue.dart';
import 'package:crudo/ui/features/foods/view_models/food_draft.dart';
import 'package:crudo/ui/features/foods/view_models/food_draft_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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
  kcalPer100g: 205, // 30*4 + 10*4 + 5*9 = 205 → matches calc
  isCustom: true,
);
const _jam = Food(
  id: 'c9',
  name: 'Label jam',
  category: FoodCategory.custom,
  protein: 0,
  carbs: 50,
  fats: 0,
  kcalPer100g: 210, // calc = 200; stored ≠ calc → was an explicit override
  isCustom: true,
);

class _FakeIdGenerator implements IdGenerator {
  int _n = 0;
  @override
  String newId() => 'id-${_n++}';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FoodDraft validation', () {
    // calc = 20*4 + 30*4 + 10*9 = 290; ±10% bound = 319.0
    const base = FoodDraft(name: 'X', protein: 20, carbs: 30, fats: 10);

    test('valid draft, auto kcal', () {
      check(base.canSave).isTrue();
      check(base.effectiveKcal).equals(290);
    });

    test('explicit kcal at the ±10% boundary is accepted', () {
      check(base.withExplicitKcal(319).canSave).isTrue();
      check(base.withExplicitKcal(319).effectiveKcal).equals(319);
    });

    test('explicit kcal outside ±10% → kcalOverrideOutOfRange', () {
      check(
        base.withExplicitKcal(320).issues.map((i) => i.code),
      ).contains(ValidationCode.kcalOverrideOutOfRange);
      check(base.withExplicitKcal(320).canSave).isFalse();
    });

    test('blank name → blankName', () {
      check(
        base.withName('  ').issues.map((i) => i.code),
      ).contains(ValidationCode.blankName);
    });

    test('macro mass > 101 blocked; 100.9 ok', () {
      check(
        base.withProtein(60).withCarbs(50).issues.map((i) => i.code),
      ).contains(ValidationCode.macroMassExceeded);
      check(
        const FoodDraft(name: 'X', protein: 60, carbs: 40, fats: 0.9).canSave,
      ).isTrue();
    });

    test('all-zero macros allowed (water); explicit must then be 0', () {
      const water = FoodDraft(name: 'Water');
      check(water.canSave).isTrue();
      check(water.effectiveKcal).equals(0);
      check(water.withExplicitKcal(0).canSave).isTrue();
      check(
        water.withExplicitKcal(5).issues.map((i) => i.code),
      ).contains(ValidationCode.kcalOverrideOutOfRange);
    });

    test(
      'fromFood: stored == calc → auto; stored ≠ calc → prefilled override',
      () {
        check(FoodDraft.fromFood(_shake).explicitKcal).isNull(); // 205 == calc
        check(FoodDraft.fromFood(_jam).explicitKcal).equals(210);
        check(FoodDraft.fromFood(_shake).category).isNull(); // custom → no chip
      },
    );

    test(
      'toFood: kind=dish always saves category=custom regardless of chip',
      () {
        const draft = FoodDraft(
          name: 'Soup',
          kind: FoodKind.dish,
          category: FoodCategory.meat,
        );
        check(draft.toFood('x').category).equals(FoodCategory.custom);
        check(draft.toFood('x').kind).equals(FoodKind.dish);
      },
    );

    test('toFood: kind=product uses chip category (or custom when null)', () {
      const withMeat = FoodDraft(
        name: 'Steak',
        kind: FoodKind.product,
        category: FoodCategory.meat,
      );
      check(withMeat.toFood('x').category).equals(FoodCategory.meat);

      const noChip = FoodDraft(name: 'Steak', kind: FoodKind.product);
      check(noChip.toFood('x').category).equals(FoodCategory.custom);
    });
  });

  group('FoodDraftController', () {
    ProviderContainer container() {
      final c = ProviderContainer(
        overrides: [
          seedFoodsProvider.overrideWithValue(const [_chicken, _shake, _jam]),
          idGeneratorProvider.overrideWithValue(_FakeIdGenerator()),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test(
      'create: defaults, save mints uuid once, isCustom, category default',
      () async {
        final c = container();
        c.listen(foodDraftControllerProvider(null), (_, _) {});
        await c.read(foodDraftControllerProvider(null).future);
        final ctrl = c.read(foodDraftControllerProvider(null).notifier);
        ctrl.setName('My bar');
        ctrl.setProtein(30);
        ctrl.setCarbs(10);
        ctrl.setFats(5);
        await ctrl.save();
        final saved = await c.read(foodRepositoryProvider).getById('id-0');
        check(saved).isNotNull();
        check(saved!.isCustom).isTrue();
        check(saved.kind).equals(FoodKind.product);
        check(saved.category).equals(FoodCategory.custom);
        check(saved.kcalPer100g).equals(205); // unrounded effective (auto)
      },
    );

    test('save with invalid draft → StateError, nothing written', () async {
      final c = container();
      c.listen(foodDraftControllerProvider(null), (_, _) {});
      await c.read(foodDraftControllerProvider(null).future);
      final ctrl = c.read(foodDraftControllerProvider(null).notifier);
      await check(ctrl.save()).throws<StateError>(); // blank name
      check(await c.read(foodRepositoryProvider).getById('id-0')).isNull();
    });

    test('edit: loads draft, save keeps id', () async {
      final c = container();
      c.listen(foodDraftControllerProvider('c1'), (_, _) {});
      final draft = await c.read(foodDraftControllerProvider('c1').future);
      check(draft.name).equals('My shake');
      final ctrl = c.read(foodDraftControllerProvider('c1').notifier);
      ctrl.setProtein(35);
      await ctrl.save();
      final saved = await c.read(foodRepositoryProvider).getById('c1');
      check(saved!.protein).equals(35);
      check(saved.kcalPer100g).equals(225); // auto recalc: 35*4+10*4+5*9
    });

    test('edit a seed food → error state', () async {
      final c = container();
      c.listen(foodDraftControllerProvider('seed-chicken-breast'), (_, _) {});
      await check(
        c.read(foodDraftControllerProvider('seed-chicken-breast').future),
      ).throws<StateError>();
    });

    test(
      'save repo failure: draft state preserved, exception propagates',
      () async {
        // Build a repo directly and wrap in a throwing decorator.
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

        c.listen(foodDraftControllerProvider(null), (_, _) {});
        await c.read(foodDraftControllerProvider(null).future);
        final ctrl = c.read(foodDraftControllerProvider(null).notifier);
        ctrl.setName('My bar');
        ctrl.setProtein(25);

        // save() throws because the repo rejects it.
        await check(ctrl.save()).throws<Exception>();

        // Draft state is preserved (still AsyncData with the current draft).
        final state = c.read(foodDraftControllerProvider(null));
        check(state).isA<AsyncData<FoodDraft>>();
        check(state.requireValue.name).equals('My bar');
        check(state.requireValue.protein).equals(25);
      },
    );

    test('delete removes from repo; create-mode delete throws', () async {
      final c = container();
      c.listen(foodDraftControllerProvider('c1'), (_, _) {});
      await c.read(foodDraftControllerProvider('c1').future);
      await c.read(foodDraftControllerProvider('c1').notifier).delete();
      check(await c.read(foodRepositoryProvider).getById('c1')).isNull();

      c.listen(foodDraftControllerProvider(null), (_, _) {});
      await c.read(foodDraftControllerProvider(null).future);
      await check(
        c.read(foodDraftControllerProvider(null).notifier).delete(),
      ).throws<StateError>();
    });
  });
}
