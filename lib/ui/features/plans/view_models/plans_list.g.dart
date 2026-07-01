// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plans_list.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Derived list rows. Watches the S06 stream providers (immediate emit on
/// listen, so loading is transient) + todayProvider. Empty until plans arrive.

@ProviderFor(plansList)
final plansListProvider = PlansListProvider._();

/// Derived list rows. Watches the S06 stream providers (immediate emit on
/// listen, so loading is transient) + todayProvider. Empty until plans arrive.

final class PlansListProvider
    extends
        $FunctionalProvider<List<PlanRowVm>, List<PlanRowVm>, List<PlanRowVm>>
    with $Provider<List<PlanRowVm>> {
  /// Derived list rows. Watches the S06 stream providers (immediate emit on
  /// listen, so loading is transient) + todayProvider. Empty until plans arrive.
  PlansListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'plansListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$plansListHash();

  @$internal
  @override
  $ProviderElement<List<PlanRowVm>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<PlanRowVm> create(Ref ref) {
    return plansList(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<PlanRowVm> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<PlanRowVm>>(value),
    );
  }
}

String _$plansListHash() => r'a350ee46ff6de06a6ef70639a0d2ca93151bc5a5';

/// Read-only detail data for one plan (the viewer screen). Resolves each slot's
/// meal name, tag label, and kcal; totals feed the daily-target hero. Throws a
/// [StateError] if [planId] is unknown (surfaced as "Plan not found").

@ProviderFor(planView)
final planViewProvider = PlanViewFamily._();

/// Read-only detail data for one plan (the viewer screen). Resolves each slot's
/// meal name, tag label, and kcal; totals feed the daily-target hero. Throws a
/// [StateError] if [planId] is unknown (surfaced as "Plan not found").

final class PlanViewProvider
    extends $FunctionalProvider<PlanViewVm, PlanViewVm, PlanViewVm>
    with $Provider<PlanViewVm> {
  /// Read-only detail data for one plan (the viewer screen). Resolves each slot's
  /// meal name, tag label, and kcal; totals feed the daily-target hero. Throws a
  /// [StateError] if [planId] is unknown (surfaced as "Plan not found").
  PlanViewProvider._({
    required PlanViewFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'planViewProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$planViewHash();

  @override
  String toString() {
    return r'planViewProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<PlanViewVm> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PlanViewVm create(Ref ref) {
    final argument = this.argument as String;
    return planView(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlanViewVm value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlanViewVm>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PlanViewProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$planViewHash() => r'59050bb9f66b522736e15be153a030de9b250a43';

/// Read-only detail data for one plan (the viewer screen). Resolves each slot's
/// meal name, tag label, and kcal; totals feed the daily-target hero. Throws a
/// [StateError] if [planId] is unknown (surfaced as "Plan not found").

final class PlanViewFamily extends $Family
    with $FunctionalFamilyOverride<PlanViewVm, String> {
  PlanViewFamily._()
    : super(
        retry: null,
        name: r'planViewProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Read-only detail data for one plan (the viewer screen). Resolves each slot's
  /// meal name, tag label, and kcal; totals feed the daily-target hero. Throws a
  /// [StateError] if [planId] is unknown (surfaced as "Plan not found").

  PlanViewProvider call(String planId) =>
      PlanViewProvider._(argument: planId, from: this);

  @override
  String toString() => r'planViewProvider';
}
