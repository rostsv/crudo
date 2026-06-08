// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'day_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Day resolution per S05 §4.3 — the contract the engine left to S06:
/// repo hit wins (snapshot authoritative, never re-materialized) → past
/// miss = empty locked day → otherwise build from plan; today persists
/// EAGERLY so ScheduledMeal ids are minted exactly once (S14 keys off
/// them); future days stay pure previews (template edits flow through).

@ProviderFor(DayController)
final dayControllerProvider = DayControllerFamily._();

/// Day resolution per S05 §4.3 — the contract the engine left to S06:
/// repo hit wins (snapshot authoritative, never re-materialized) → past
/// miss = empty locked day → otherwise build from plan; today persists
/// EAGERLY so ScheduledMeal ids are minted exactly once (S14 keys off
/// them); future days stay pure previews (template edits flow through).
final class DayControllerProvider
    extends $AsyncNotifierProvider<DayController, Day> {
  /// Day resolution per S05 §4.3 — the contract the engine left to S06:
  /// repo hit wins (snapshot authoritative, never re-materialized) → past
  /// miss = empty locked day → otherwise build from plan; today persists
  /// EAGERLY so ScheduledMeal ids are minted exactly once (S14 keys off
  /// them); future days stay pure previews (template edits flow through).
  DayControllerProvider._({
    required DayControllerFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: null,
         name: r'dayControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$dayControllerHash();

  @override
  String toString() {
    return r'dayControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  DayController create() => DayController();

  @override
  bool operator ==(Object other) {
    return other is DayControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$dayControllerHash() => r'0ba8b25cc21b8522e0b9594aef27537e5e8ba900';

/// Day resolution per S05 §4.3 — the contract the engine left to S06:
/// repo hit wins (snapshot authoritative, never re-materialized) → past
/// miss = empty locked day → otherwise build from plan; today persists
/// EAGERLY so ScheduledMeal ids are minted exactly once (S14 keys off
/// them); future days stay pure previews (template edits flow through).

final class DayControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          DayController,
          AsyncValue<Day>,
          Day,
          FutureOr<Day>,
          DateTime
        > {
  DayControllerFamily._()
    : super(
        retry: null,
        name: r'dayControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Day resolution per S05 §4.3 — the contract the engine left to S06:
  /// repo hit wins (snapshot authoritative, never re-materialized) → past
  /// miss = empty locked day → otherwise build from plan; today persists
  /// EAGERLY so ScheduledMeal ids are minted exactly once (S14 keys off
  /// them); future days stay pure previews (template edits flow through).

  DayControllerProvider call(DateTime date) =>
      DayControllerProvider._(argument: date, from: this);

  @override
  String toString() => r'dayControllerProvider';
}

/// Day resolution per S05 §4.3 — the contract the engine left to S06:
/// repo hit wins (snapshot authoritative, never re-materialized) → past
/// miss = empty locked day → otherwise build from plan; today persists
/// EAGERLY so ScheduledMeal ids are minted exactly once (S14 keys off
/// them); future days stay pure previews (template edits flow through).

abstract class _$DayController extends $AsyncNotifier<Day> {
  late final _$args = ref.$arg as DateTime;
  DateTime get date => _$args;

  FutureOr<Day> build(DateTime date);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Day>, Day>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Day>, Day>,
              AsyncValue<Day>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
