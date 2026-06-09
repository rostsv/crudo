// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meal_template_draft_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MealTemplateDraftController)
final mealTemplateDraftControllerProvider =
    MealTemplateDraftControllerFamily._();

final class MealTemplateDraftControllerProvider
    extends
        $AsyncNotifierProvider<MealTemplateDraftController, MealTemplateDraft> {
  MealTemplateDraftControllerProvider._({
    required MealTemplateDraftControllerFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'mealTemplateDraftControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$mealTemplateDraftControllerHash();

  @override
  String toString() {
    return r'mealTemplateDraftControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  MealTemplateDraftController create() => MealTemplateDraftController();

  @override
  bool operator ==(Object other) {
    return other is MealTemplateDraftControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$mealTemplateDraftControllerHash() =>
    r'321c76c7a0bff61dc7b4408b2671f13fff1e7ff0';

final class MealTemplateDraftControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          MealTemplateDraftController,
          AsyncValue<MealTemplateDraft>,
          MealTemplateDraft,
          FutureOr<MealTemplateDraft>,
          String?
        > {
  MealTemplateDraftControllerFamily._()
    : super(
        retry: null,
        name: r'mealTemplateDraftControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  MealTemplateDraftControllerProvider call(String? templateId) =>
      MealTemplateDraftControllerProvider._(argument: templateId, from: this);

  @override
  String toString() => r'mealTemplateDraftControllerProvider';
}

abstract class _$MealTemplateDraftController
    extends $AsyncNotifier<MealTemplateDraft> {
  late final _$args = ref.$arg as String?;
  String? get templateId => _$args;

  FutureOr<MealTemplateDraft> build(String? templateId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<MealTemplateDraft>, MealTemplateDraft>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<MealTemplateDraft>, MealTemplateDraft>,
              AsyncValue<MealTemplateDraft>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
