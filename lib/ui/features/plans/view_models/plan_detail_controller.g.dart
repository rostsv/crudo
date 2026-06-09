// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_detail_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages the editable draft for one plan detail screen.
/// Watches upstream stream providers so the draft auto-refreshes when the
/// repo changes underneath (e.g. another screen mutates plans).

@ProviderFor(PlanDetailController)
final planDetailControllerProvider = PlanDetailControllerFamily._();

/// Manages the editable draft for one plan detail screen.
/// Watches upstream stream providers so the draft auto-refreshes when the
/// repo changes underneath (e.g. another screen mutates plans).
final class PlanDetailControllerProvider
    extends $AsyncNotifierProvider<PlanDetailController, PlanDraft> {
  /// Manages the editable draft for one plan detail screen.
  /// Watches upstream stream providers so the draft auto-refreshes when the
  /// repo changes underneath (e.g. another screen mutates plans).
  PlanDetailControllerProvider._({
    required PlanDetailControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'planDetailControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$planDetailControllerHash();

  @override
  String toString() {
    return r'planDetailControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  PlanDetailController create() => PlanDetailController();

  @override
  bool operator ==(Object other) {
    return other is PlanDetailControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$planDetailControllerHash() =>
    r'1bcf966ca0f6b205eee147668e5db795c3b17aca';

/// Manages the editable draft for one plan detail screen.
/// Watches upstream stream providers so the draft auto-refreshes when the
/// repo changes underneath (e.g. another screen mutates plans).

final class PlanDetailControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          PlanDetailController,
          AsyncValue<PlanDraft>,
          PlanDraft,
          FutureOr<PlanDraft>,
          String
        > {
  PlanDetailControllerFamily._()
    : super(
        retry: null,
        name: r'planDetailControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Manages the editable draft for one plan detail screen.
  /// Watches upstream stream providers so the draft auto-refreshes when the
  /// repo changes underneath (e.g. another screen mutates plans).

  PlanDetailControllerProvider call(String planId) =>
      PlanDetailControllerProvider._(argument: planId, from: this);

  @override
  String toString() => r'planDetailControllerProvider';
}

/// Manages the editable draft for one plan detail screen.
/// Watches upstream stream providers so the draft auto-refreshes when the
/// repo changes underneath (e.g. another screen mutates plans).

abstract class _$PlanDetailController extends $AsyncNotifier<PlanDraft> {
  late final _$args = ref.$arg as String;
  String get planId => _$args;

  FutureOr<PlanDraft> build(String planId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<PlanDraft>, PlanDraft>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<PlanDraft>, PlanDraft>,
              AsyncValue<PlanDraft>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
