// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_activation.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Pause/resume a plan straight from the Plans list card. Pausing is always
/// safe (it frees the plan's weekdays); resuming can clash with other active
/// plans, so [resumeConflicts] lets the UI show the steal-override confirm
/// before [resume] with `override: true` strips the clashing days from the
/// other plans (mirrors the editor's save flow — the conflict rules stay in
/// [plan_scheduling], not the widget).

@ProviderFor(PlanActivation)
final planActivationProvider = PlanActivationProvider._();

/// Pause/resume a plan straight from the Plans list card. Pausing is always
/// safe (it frees the plan's weekdays); resuming can clash with other active
/// plans, so [resumeConflicts] lets the UI show the steal-override confirm
/// before [resume] with `override: true` strips the clashing days from the
/// other plans (mirrors the editor's save flow — the conflict rules stay in
/// [plan_scheduling], not the widget).
final class PlanActivationProvider
    extends $NotifierProvider<PlanActivation, void> {
  /// Pause/resume a plan straight from the Plans list card. Pausing is always
  /// safe (it frees the plan's weekdays); resuming can clash with other active
  /// plans, so [resumeConflicts] lets the UI show the steal-override confirm
  /// before [resume] with `override: true` strips the clashing days from the
  /// other plans (mirrors the editor's save flow — the conflict rules stay in
  /// [plan_scheduling], not the widget).
  PlanActivationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'planActivationProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$planActivationHash();

  @$internal
  @override
  PlanActivation create() => PlanActivation();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$planActivationHash() => r'a919c9d4ef9b9fb936f8d0cfee6a99335ff65f88';

/// Pause/resume a plan straight from the Plans list card. Pausing is always
/// safe (it frees the plan's weekdays); resuming can clash with other active
/// plans, so [resumeConflicts] lets the UI show the steal-override confirm
/// before [resume] with `override: true` strips the clashing days from the
/// other plans (mirrors the editor's save flow — the conflict rules stay in
/// [plan_scheduling], not the widget).

abstract class _$PlanActivation extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
