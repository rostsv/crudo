// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meal_template_rows.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Library feed. Sync derived provider (mirrors plansList): reads .value of
/// the S06 stream providers; empty until data arrives.

@ProviderFor(mealTemplateRows)
final mealTemplateRowsProvider = MealTemplateRowsProvider._();

/// Library feed. Sync derived provider (mirrors plansList): reads .value of
/// the S06 stream providers; empty until data arrives.

final class MealTemplateRowsProvider
    extends
        $FunctionalProvider<
          List<MealTemplateRowVm>,
          List<MealTemplateRowVm>,
          List<MealTemplateRowVm>
        >
    with $Provider<List<MealTemplateRowVm>> {
  /// Library feed. Sync derived provider (mirrors plansList): reads .value of
  /// the S06 stream providers; empty until data arrives.
  MealTemplateRowsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mealTemplateRowsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mealTemplateRowsHash();

  @$internal
  @override
  $ProviderElement<List<MealTemplateRowVm>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<MealTemplateRowVm> create(Ref ref) {
    return mealTemplateRows(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<MealTemplateRowVm> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<MealTemplateRowVm>>(value),
    );
  }
}

String _$mealTemplateRowsHash() => r'de9ba16226d126681b8e718be3b0fed32871be7e';
