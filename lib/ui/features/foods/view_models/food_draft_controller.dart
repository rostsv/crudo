import 'package:crudo/config/di.dart';
import 'package:crudo/data/services/id_generator.dart';
import 'package:crudo/domain/food/food.dart';
import 'package:crudo/domain/shared/enums.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'food_draft.dart';

part 'food_draft_controller.g.dart';

/// Add/edit-food form controller (S07). `foodId == null` = create;
/// otherwise loads the existing CUSTOM food for editing. Seed foods are
/// read-only — routing one here is a programming error and surfaces as
/// the provider's error state.
@riverpod
class FoodDraftController extends _$FoodDraftController {
  @override
  Future<FoodDraft> build(String? foodId) async {
    if (foodId == null) return const FoodDraft();
    final food = await ref.watch(foodRepositoryProvider).getById(foodId);
    if (food == null) throw StateError('no food with id $foodId');
    if (!food.isCustom) throw StateError('seed foods are read-only');
    return FoodDraft.fromFood(food);
  }

  void setName(String v) => _update((d) => d.withName(v));
  void setKind(FoodKind v) => _update((d) => d.withKind(v));
  void setCategory(FoodCategory? v) => _update((d) => d.withCategory(v));
  void setProtein(double v) => _update((d) => d.withProtein(v < 0 ? 0 : v));
  void setCarbs(double v) => _update((d) => d.withCarbs(v < 0 ? 0 : v));
  void setFats(double v) => _update((d) => d.withFats(v < 0 ? 0 : v));
  void setExplicitKcal(double? v) =>
      _update((d) => d.withExplicitKcal(v != null && v < 0 ? 0 : v));

  /// Mirrors the UI gate (SAVE disabled unless canSave) — reaching this
  /// with an invalid draft is a bug, not a user error.
  ///
  /// Returns the saved [Food] so callers can pop it as a route result.
  Future<Food> save() async {
    final draft = state.requireValue;
    if (!draft.canSave) throw StateError('draft has validation issues');
    final id = foodId ?? ref.read(idGeneratorProvider).newId();
    final food = draft.toFood(id);
    await ref.read(foodRepositoryProvider).save(food);
    return food;
  }

  /// Unconditional in S07: nothing can reference a food before templates
  /// exist (S09 adds the block-while-referenced check). Logged days hold
  /// frozen FoodSnapshot copies — never affected.
  Future<void> delete() async {
    final id = foodId;
    if (id == null) throw StateError('cannot delete an unsaved draft');
    await ref.read(foodRepositoryProvider).delete(id);
  }

  void _update(FoodDraft Function(FoodDraft) fn) {
    final d = state.asData?.value;
    if (d != null) state = AsyncData(fn(d));
  }
}
