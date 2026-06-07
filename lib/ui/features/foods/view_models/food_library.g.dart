// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'food_library.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(libraryFoods)
final libraryFoodsProvider = LibraryFoodsProvider._();

final class LibraryFoodsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Food>>,
          List<Food>,
          Stream<List<Food>>
        >
    with $FutureModifier<List<Food>>, $StreamProvider<List<Food>> {
  LibraryFoodsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'libraryFoodsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$libraryFoodsHash();

  @$internal
  @override
  $StreamProviderElement<List<Food>> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<Food>> create(Ref ref) {
    return libraryFoods(ref);
  }
}

String _$libraryFoodsHash() => r'1d5d4c48f0c8e084342208060e0222023a16d57a';

@ProviderFor(FoodSearchQuery)
final foodSearchQueryProvider = FoodSearchQueryProvider._();

final class FoodSearchQueryProvider
    extends $NotifierProvider<FoodSearchQuery, String> {
  FoodSearchQueryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'foodSearchQueryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$foodSearchQueryHash();

  @$internal
  @override
  FoodSearchQuery create() => FoodSearchQuery();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$foodSearchQueryHash() => r'371ecbf83f6e504bb00a038a277270533641fb1c';

abstract class _$FoodSearchQuery extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Search + grouping over the whole library (S07): kind == dish → "Dishes"
/// group placed last (S05 §1.4); products grouped by category in enum
/// order; alphabetical within a group; empty groups omitted.

@ProviderFor(foodLibrary)
final foodLibraryProvider = FoodLibraryProvider._();

/// Search + grouping over the whole library (S07): kind == dish → "Dishes"
/// group placed last (S05 §1.4); products grouped by category in enum
/// order; alphabetical within a group; empty groups omitted.

final class FoodLibraryProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<FoodGroup>>,
          List<FoodGroup>,
          FutureOr<List<FoodGroup>>
        >
    with $FutureModifier<List<FoodGroup>>, $FutureProvider<List<FoodGroup>> {
  /// Search + grouping over the whole library (S07): kind == dish → "Dishes"
  /// group placed last (S05 §1.4); products grouped by category in enum
  /// order; alphabetical within a group; empty groups omitted.
  FoodLibraryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'foodLibraryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$foodLibraryHash();

  @$internal
  @override
  $FutureProviderElement<List<FoodGroup>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<FoodGroup>> create(Ref ref) {
    return foodLibrary(ref);
  }
}

String _$foodLibraryHash() => r'4b9041b1eae25df5afbb6278a933d357e30fcac9';
