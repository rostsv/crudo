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

String _$plansListHash() => r'd4e4f920c1c5f7f14331300e950ee3683062076a';
