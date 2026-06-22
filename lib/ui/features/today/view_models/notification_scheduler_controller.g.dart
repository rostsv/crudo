// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_scheduler_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Session-scoped "Mute today": holds the muted day-label (UTC) or null.
/// Lost on restart (no Prefs field — editing is S15). Set by StreakRiskSheet.

@ProviderFor(MutedRiskDay)
final mutedRiskDayProvider = MutedRiskDayProvider._();

/// Session-scoped "Mute today": holds the muted day-label (UTC) or null.
/// Lost on restart (no Prefs field — editing is S15). Set by StreakRiskSheet.
final class MutedRiskDayProvider
    extends $NotifierProvider<MutedRiskDay, DateTime?> {
  /// Session-scoped "Mute today": holds the muted day-label (UTC) or null.
  /// Lost on restart (no Prefs field — editing is S15). Set by StreakRiskSheet.
  MutedRiskDayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mutedRiskDayProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mutedRiskDayHash();

  @$internal
  @override
  MutedRiskDay create() => MutedRiskDay();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime?>(value),
    );
  }
}

String _$mutedRiskDayHash() => r'9b76828e201b030a830ab3ecdede0ce085246410';

/// Session-scoped "Mute today": holds the muted day-label (UTC) or null.
/// Lost on restart (no Prefs field — editing is S15). Set by StreakRiskSheet.

abstract class _$MutedRiskDay extends $Notifier<DateTime?> {
  DateTime? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<DateTime?, DateTime?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DateTime?, DateTime?>,
              DateTime?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Watches today's Day; on every change recomputes notificationSchedule and
/// cancel-all-rearms via NotificationService. Strips the risk spec when today
/// is muted. Mirrors StreakCatchUp's watch-today shape.

@ProviderFor(NotificationScheduler)
final notificationSchedulerProvider = NotificationSchedulerProvider._();

/// Watches today's Day; on every change recomputes notificationSchedule and
/// cancel-all-rearms via NotificationService. Strips the risk spec when today
/// is muted. Mirrors StreakCatchUp's watch-today shape.
final class NotificationSchedulerProvider
    extends $AsyncNotifierProvider<NotificationScheduler, void> {
  /// Watches today's Day; on every change recomputes notificationSchedule and
  /// cancel-all-rearms via NotificationService. Strips the risk spec when today
  /// is muted. Mirrors StreakCatchUp's watch-today shape.
  NotificationSchedulerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationSchedulerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationSchedulerHash();

  @$internal
  @override
  NotificationScheduler create() => NotificationScheduler();
}

String _$notificationSchedulerHash() =>
    r'41bf34b00e4580d4984f6f2e3670a04fea19042a';

/// Watches today's Day; on every change recomputes notificationSchedule and
/// cancel-all-rearms via NotificationService. Strips the risk spec when today
/// is muted. Mirrors StreakCatchUp's watch-today shape.

abstract class _$NotificationScheduler extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Pipes NotificationService.actions (and the one terminated-launch action)
/// into dayController for today. Activated by AppShell.

@ProviderFor(NotificationActionRouter)
final notificationActionRouterProvider = NotificationActionRouterProvider._();

/// Pipes NotificationService.actions (and the one terminated-launch action)
/// into dayController for today. Activated by AppShell.
final class NotificationActionRouterProvider
    extends $AsyncNotifierProvider<NotificationActionRouter, void> {
  /// Pipes NotificationService.actions (and the one terminated-launch action)
  /// into dayController for today. Activated by AppShell.
  NotificationActionRouterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationActionRouterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationActionRouterHash();

  @$internal
  @override
  NotificationActionRouter create() => NotificationActionRouter();
}

String _$notificationActionRouterHash() =>
    r'fe0c097188f5da966efbca456c080d108211fdb0';

/// Pipes NotificationService.actions (and the one terminated-launch action)
/// into dayController for today. Activated by AppShell.

abstract class _$NotificationActionRouter extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
