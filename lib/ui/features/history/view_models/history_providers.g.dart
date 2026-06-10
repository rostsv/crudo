// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Full streak (current + personalBest).

@ProviderFor(streak)
final streakProvider = StreakProvider._();

/// Full streak (current + personalBest).

final class StreakProvider
    extends $FunctionalProvider<AsyncValue<Streak>, Streak, Stream<Streak>>
    with $FutureModifier<Streak>, $StreamProvider<Streak> {
  /// Full streak (current + personalBest).
  StreakProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'streakProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$streakHash();

  @$internal
  @override
  $StreamProviderElement<Streak> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Streak> create(Ref ref) {
    return streak(ref);
  }
}

String _$streakHash() => r'9d2b9f7c9442d0d88cfc591b8785f3026af43189';

/// Mon..Sun of weekOf(today). Past locked days use frozenDayState; today uses
/// live classifyDayState; future cells carry null state.

@ProviderFor(weeklyAdherence)
final weeklyAdherenceProvider = WeeklyAdherenceProvider._();

/// Mon..Sun of weekOf(today). Past locked days use frozenDayState; today uses
/// live classifyDayState; future cells carry null state.

final class WeeklyAdherenceProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<WeekCell>>,
          List<WeekCell>,
          FutureOr<List<WeekCell>>
        >
    with $FutureModifier<List<WeekCell>>, $FutureProvider<List<WeekCell>> {
  /// Mon..Sun of weekOf(today). Past locked days use frozenDayState; today uses
  /// live classifyDayState; future cells carry null state.
  WeeklyAdherenceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'weeklyAdherenceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$weeklyAdherenceHash();

  @$internal
  @override
  $FutureProviderElement<List<WeekCell>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<WeekCell>> create(Ref ref) {
    return weeklyAdherence(ref);
  }
}

String _$weeklyAdherenceHash() => r'c49d379e2942ec9873393be441e104a663f9bef0';

/// 30-day rollup ending today inclusive (getRange(today-29d, today)).
/// Empty range → all 0.

@ProviderFor(historyStats)
final historyStatsProvider = HistoryStatsProvider._();

/// 30-day rollup ending today inclusive (getRange(today-29d, today)).
/// Empty range → all 0.

final class HistoryStatsProvider
    extends
        $FunctionalProvider<
          AsyncValue<HistoryStats>,
          HistoryStats,
          FutureOr<HistoryStats>
        >
    with $FutureModifier<HistoryStats>, $FutureProvider<HistoryStats> {
  /// 30-day rollup ending today inclusive (getRange(today-29d, today)).
  /// Empty range → all 0.
  HistoryStatsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'historyStatsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$historyStatsHash();

  @$internal
  @override
  $FutureProviderElement<HistoryStats> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<HistoryStats> create(Ref ref) {
    return historyStats(ref);
  }
}

String _$historyStatsHash() => r'2da1891e0cce9e9d33810c0e96c5b2059f2a257f';

/// Last 5 days descending (today first).

@ProviderFor(recentDays)
final recentDaysProvider = RecentDaysProvider._();

/// Last 5 days descending (today first).

final class RecentDaysProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<RecentDay>>,
          List<RecentDay>,
          FutureOr<List<RecentDay>>
        >
    with $FutureModifier<List<RecentDay>>, $FutureProvider<List<RecentDay>> {
  /// Last 5 days descending (today first).
  RecentDaysProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recentDaysProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recentDaysHash();

  @$internal
  @override
  $FutureProviderElement<List<RecentDay>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<RecentDay>> create(Ref ref) {
    return recentDays(ref);
  }
}

String _$recentDaysHash() => r'2c10a9888b7140a9f537571dba0e51f03aef86ac';

/// Cells for [month]'s grid, Mon-first: leading nulls then one cell/day.
/// Days after today have kind=future and null state. Past days use frozen/live.

@ProviderFor(monthGrid)
final monthGridProvider = MonthGridFamily._();

/// Cells for [month]'s grid, Mon-first: leading nulls then one cell/day.
/// Days after today have kind=future and null state. Past days use frozen/live.

final class MonthGridProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CalendarCell?>>,
          List<CalendarCell?>,
          FutureOr<List<CalendarCell?>>
        >
    with
        $FutureModifier<List<CalendarCell?>>,
        $FutureProvider<List<CalendarCell?>> {
  /// Cells for [month]'s grid, Mon-first: leading nulls then one cell/day.
  /// Days after today have kind=future and null state. Past days use frozen/live.
  MonthGridProvider._({
    required MonthGridFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: null,
         name: r'monthGridProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$monthGridHash();

  @override
  String toString() {
    return r'monthGridProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<CalendarCell?>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<CalendarCell?>> create(Ref ref) {
    final argument = this.argument as DateTime;
    return monthGrid(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MonthGridProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$monthGridHash() => r'2fdf74ccbc8f17c4ec9ae5cca3a3c361448108d8';

/// Cells for [month]'s grid, Mon-first: leading nulls then one cell/day.
/// Days after today have kind=future and null state. Past days use frozen/live.

final class MonthGridFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<CalendarCell?>>, DateTime> {
  MonthGridFamily._()
    : super(
        retry: null,
        name: r'monthGridProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Cells for [month]'s grid, Mon-first: leading nulls then one cell/day.
  /// Days after today have kind=future and null state. Past days use frozen/live.

  MonthGridProvider call(DateTime month) =>
      MonthGridProvider._(argument: month, from: this);

  @override
  String toString() => r'monthGridProvider';
}
