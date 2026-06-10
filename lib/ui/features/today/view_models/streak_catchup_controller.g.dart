// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'streak_catchup_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Fires streak catch-up on every Today rollover / app-open. Watches
/// todayProvider so it re-runs when the day label advances. Reads (never
/// watches, to avoid mid-run rebuilds) the streak, prefs threshold, the active
/// plans/templates/foods, and the persisted days in the catch-up range; calls
/// the pure catchUp(); persists each newly-locked day + the new streak.
/// Idempotent — re-running once caught up is a no-op (lastCountedDay guards).
/// Milestones are returned for S13 to celebrate; S12 does not store them.

@ProviderFor(StreakCatchUp)
final streakCatchUpProvider = StreakCatchUpProvider._();

/// Fires streak catch-up on every Today rollover / app-open. Watches
/// todayProvider so it re-runs when the day label advances. Reads (never
/// watches, to avoid mid-run rebuilds) the streak, prefs threshold, the active
/// plans/templates/foods, and the persisted days in the catch-up range; calls
/// the pure catchUp(); persists each newly-locked day + the new streak.
/// Idempotent — re-running once caught up is a no-op (lastCountedDay guards).
/// Milestones are returned for S13 to celebrate; S12 does not store them.
final class StreakCatchUpProvider
    extends $AsyncNotifierProvider<StreakCatchUp, List<int>> {
  /// Fires streak catch-up on every Today rollover / app-open. Watches
  /// todayProvider so it re-runs when the day label advances. Reads (never
  /// watches, to avoid mid-run rebuilds) the streak, prefs threshold, the active
  /// plans/templates/foods, and the persisted days in the catch-up range; calls
  /// the pure catchUp(); persists each newly-locked day + the new streak.
  /// Idempotent — re-running once caught up is a no-op (lastCountedDay guards).
  /// Milestones are returned for S13 to celebrate; S12 does not store them.
  StreakCatchUpProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'streakCatchUpProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$streakCatchUpHash();

  @$internal
  @override
  StreakCatchUp create() => StreakCatchUp();
}

String _$streakCatchUpHash() => r'f708de90a5525e7c97164aef0e7f2e56dfe3d826';

/// Fires streak catch-up on every Today rollover / app-open. Watches
/// todayProvider so it re-runs when the day label advances. Reads (never
/// watches, to avoid mid-run rebuilds) the streak, prefs threshold, the active
/// plans/templates/foods, and the persisted days in the catch-up range; calls
/// the pure catchUp(); persists each newly-locked day + the new streak.
/// Idempotent — re-running once caught up is a no-op (lastCountedDay guards).
/// Milestones are returned for S13 to celebrate; S12 does not store them.

abstract class _$StreakCatchUp extends $AsyncNotifier<List<int>> {
  FutureOr<List<int>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<int>>, List<int>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<int>>, List<int>>,
              AsyncValue<List<int>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
