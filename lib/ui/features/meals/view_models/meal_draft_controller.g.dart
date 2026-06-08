// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meal_draft_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Editor draft for one scheduled meal of one day (S08). Loads the current
/// MealSnapshot ONCE (ref.read, NOT watch — an external day write while the
/// editor is open must never silently reset an in-progress draft; staleness
/// is caught at commit time by the replaceMeal guard). save() commits ONCE
/// through DayController.replaceMeal — the upcoming-only content-edit guard
/// lives in the domain op, not here.

@ProviderFor(MealDraftController)
final mealDraftControllerProvider = MealDraftControllerFamily._();

/// Editor draft for one scheduled meal of one day (S08). Loads the current
/// MealSnapshot ONCE (ref.read, NOT watch — an external day write while the
/// editor is open must never silently reset an in-progress draft; staleness
/// is caught at commit time by the replaceMeal guard). save() commits ONCE
/// through DayController.replaceMeal — the upcoming-only content-edit guard
/// lives in the domain op, not here.
final class MealDraftControllerProvider
    extends $AsyncNotifierProvider<MealDraftController, MealDraft> {
  /// Editor draft for one scheduled meal of one day (S08). Loads the current
  /// MealSnapshot ONCE (ref.read, NOT watch — an external day write while the
  /// editor is open must never silently reset an in-progress draft; staleness
  /// is caught at commit time by the replaceMeal guard). save() commits ONCE
  /// through DayController.replaceMeal — the upcoming-only content-edit guard
  /// lives in the domain op, not here.
  MealDraftControllerProvider._({
    required MealDraftControllerFamily super.from,
    required (DateTime, String) super.argument,
  }) : super(
         retry: null,
         name: r'mealDraftControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$mealDraftControllerHash();

  @override
  String toString() {
    return r'mealDraftControllerProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  MealDraftController create() => MealDraftController();

  @override
  bool operator ==(Object other) {
    return other is MealDraftControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$mealDraftControllerHash() =>
    r'10a4018f3349ec051567c64f4d3293fbf47c7cbf';

/// Editor draft for one scheduled meal of one day (S08). Loads the current
/// MealSnapshot ONCE (ref.read, NOT watch — an external day write while the
/// editor is open must never silently reset an in-progress draft; staleness
/// is caught at commit time by the replaceMeal guard). save() commits ONCE
/// through DayController.replaceMeal — the upcoming-only content-edit guard
/// lives in the domain op, not here.

final class MealDraftControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          MealDraftController,
          AsyncValue<MealDraft>,
          MealDraft,
          FutureOr<MealDraft>,
          (DateTime, String)
        > {
  MealDraftControllerFamily._()
    : super(
        retry: null,
        name: r'mealDraftControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Editor draft for one scheduled meal of one day (S08). Loads the current
  /// MealSnapshot ONCE (ref.read, NOT watch — an external day write while the
  /// editor is open must never silently reset an in-progress draft; staleness
  /// is caught at commit time by the replaceMeal guard). save() commits ONCE
  /// through DayController.replaceMeal — the upcoming-only content-edit guard
  /// lives in the domain op, not here.

  MealDraftControllerProvider call(DateTime date, String mealId) =>
      MealDraftControllerProvider._(argument: (date, mealId), from: this);

  @override
  String toString() => r'mealDraftControllerProvider';
}

/// Editor draft for one scheduled meal of one day (S08). Loads the current
/// MealSnapshot ONCE (ref.read, NOT watch — an external day write while the
/// editor is open must never silently reset an in-progress draft; staleness
/// is caught at commit time by the replaceMeal guard). save() commits ONCE
/// through DayController.replaceMeal — the upcoming-only content-edit guard
/// lives in the domain op, not here.

abstract class _$MealDraftController extends $AsyncNotifier<MealDraft> {
  late final _$args = ref.$arg as (DateTime, String);
  DateTime get date => _$args.$1;
  String get mealId => _$args.$2;

  FutureOr<MealDraft> build(DateTime date, String mealId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<MealDraft>, MealDraft>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<MealDraft>, MealDraft>,
              AsyncValue<MealDraft>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}
