// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'food_draft_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Add/edit-food form controller (S07). `foodId == null` = create;
/// otherwise loads the existing CUSTOM food for editing. Seed foods are
/// read-only — routing one here is a programming error and surfaces as
/// the provider's error state.

@ProviderFor(FoodDraftController)
final foodDraftControllerProvider = FoodDraftControllerFamily._();

/// Add/edit-food form controller (S07). `foodId == null` = create;
/// otherwise loads the existing CUSTOM food for editing. Seed foods are
/// read-only — routing one here is a programming error and surfaces as
/// the provider's error state.
final class FoodDraftControllerProvider
    extends $AsyncNotifierProvider<FoodDraftController, FoodDraft> {
  /// Add/edit-food form controller (S07). `foodId == null` = create;
  /// otherwise loads the existing CUSTOM food for editing. Seed foods are
  /// read-only — routing one here is a programming error and surfaces as
  /// the provider's error state.
  FoodDraftControllerProvider._({
    required FoodDraftControllerFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'foodDraftControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$foodDraftControllerHash();

  @override
  String toString() {
    return r'foodDraftControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  FoodDraftController create() => FoodDraftController();

  @override
  bool operator ==(Object other) {
    return other is FoodDraftControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$foodDraftControllerHash() =>
    r'4018cf03ed3e4e429cbc27d7c80372e06c15766b';

/// Add/edit-food form controller (S07). `foodId == null` = create;
/// otherwise loads the existing CUSTOM food for editing. Seed foods are
/// read-only — routing one here is a programming error and surfaces as
/// the provider's error state.

final class FoodDraftControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          FoodDraftController,
          AsyncValue<FoodDraft>,
          FoodDraft,
          FutureOr<FoodDraft>,
          String?
        > {
  FoodDraftControllerFamily._()
    : super(
        retry: null,
        name: r'foodDraftControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Add/edit-food form controller (S07). `foodId == null` = create;
  /// otherwise loads the existing CUSTOM food for editing. Seed foods are
  /// read-only — routing one here is a programming error and surfaces as
  /// the provider's error state.

  FoodDraftControllerProvider call(String? foodId) =>
      FoodDraftControllerProvider._(argument: foodId, from: this);

  @override
  String toString() => r'foodDraftControllerProvider';
}

/// Add/edit-food form controller (S07). `foodId == null` = create;
/// otherwise loads the existing CUSTOM food for editing. Seed foods are
/// read-only — routing one here is a programming error and surfaces as
/// the provider's error state.

abstract class _$FoodDraftController extends $AsyncNotifier<FoodDraft> {
  late final _$args = ref.$arg as String?;
  String? get foodId => _$args;

  FutureOr<FoodDraft> build(String? foodId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<FoodDraft>, FoodDraft>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<FoodDraft>, FoodDraft>,
              AsyncValue<FoodDraft>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
