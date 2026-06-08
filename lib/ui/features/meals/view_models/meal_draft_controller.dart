import 'package:crudo/domain/meal/food_snapshot.dart';
import 'package:crudo/domain/shared/enums.dart';
import 'package:crudo/domain/shared/grams.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../today/view_models/day_controller.dart';
import 'meal_draft.dart';

part 'meal_draft_controller.g.dart';

/// Editor draft for one scheduled meal of one day (S08). Loads the current
/// MealSnapshot ONCE (ref.read, NOT watch — an external day write while the
/// editor is open must never silently reset an in-progress draft; staleness
/// is caught at commit time by the replaceMeal guard). save() commits ONCE
/// through DayController.replaceMeal — the upcoming-only content-edit guard
/// lives in the domain op, not here.
@riverpod
class MealDraftController extends _$MealDraftController {
  MealDraft? _initial;

  @override
  Future<MealDraft> build(DateTime date, String mealId) async {
    final day = await ref.read(dayControllerProvider(date).future);
    final meal = day.meals.where((m) => m.id == mealId).firstOrNull;
    if (meal == null) throw StateError('no meal with id $mealId');
    return _initial = MealDraft.fromSnapshot(meal.meal);
  }

  /// Any change vs the loaded snapshot — freezed deep equality via
  /// toSnapshot(). Drives the editor's discard-confirm gate.
  bool get isDirty {
    final d = state.asData?.value;
    final initial = _initial;
    if (d == null || initial == null) return false;
    return d.toSnapshot() != initial.toSnapshot();
  }

  void setName(String v) => _update((d) => d.copyWith(name: v));

  void toggleTag(MealTag t) => _update(
    (d) => d.copyWith(
      tags: d.tags.contains(t)
          ? [
              for (final x in d.tags)
                if (x != t) x,
            ]
          : [...d.tags, t],
    ),
  );

  void addItem(FoodSnapshot f) =>
      _update((d) => d.copyWith(items: [...d.items, f]));

  void removeItem(int index) => _update(
    (d) => d.copyWith(
      items: [
        for (final (i, f) in d.items.indexed)
          if (i != index) f,
      ],
    ),
  );

  void setItemGrams(int index, Grams g) => _update(
    (d) => d.copyWith(
      items: [
        for (final (i, f) in d.items.indexed) i == index ? f.scaledTo(g) : f,
      ],
    ),
  );

  /// Mirrors the UI gate (SAVE disabled unless canSave). The domain guard
  /// (status flipped while editing) surfaces as StateError — caller toasts.
  Future<void> save() async {
    final draft = state.requireValue;
    if (!draft.canSave) throw StateError('draft has validation issues');
    await ref
        .read(dayControllerProvider(date).notifier)
        .replaceMeal(mealId, draft.toSnapshot());
  }

  void _update(MealDraft Function(MealDraft) fn) {
    final d = state.asData?.value;
    if (d != null) state = AsyncData(fn(d));
  }
}
