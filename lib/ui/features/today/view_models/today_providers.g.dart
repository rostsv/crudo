// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'today_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The current local calendar day as a UTC day-label (S02 convention).
/// Re-derived via [refresh] on app resume + the midnight tick (TodayScreen
/// owns the observer/timer); never advances on its own.

@ProviderFor(Today)
final todayProvider = TodayProvider._();

/// The current local calendar day as a UTC day-label (S02 convention).
/// Re-derived via [refresh] on app resume + the midnight tick (TodayScreen
/// owns the observer/timer); never advances on its own.
final class TodayProvider extends $NotifierProvider<Today, DateTime> {
  /// The current local calendar day as a UTC day-label (S02 convention).
  /// Re-derived via [refresh] on app resume + the midnight tick (TodayScreen
  /// owns the observer/timer); never advances on its own.
  TodayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'todayProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$todayHash();

  @$internal
  @override
  Today create() => Today();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime>(value),
    );
  }
}

String _$todayHash() => r'83116d651fc53577de8f8d292ef81854c7cebf75';

/// The current local calendar day as a UTC day-label (S02 convention).
/// Re-derived via [refresh] on app resume + the midnight tick (TodayScreen
/// owns the observer/timer); never advances on its own.

abstract class _$Today extends $Notifier<DateTime> {
  DateTime build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<DateTime, DateTime>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DateTime, DateTime>,
              DateTime,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// The day the UI is looking at. Follows today (snaps back on rollover —
/// watch dependency) until the user picks another date in the week strip.

@ProviderFor(SelectedDate)
final selectedDateProvider = SelectedDateProvider._();

/// The day the UI is looking at. Follows today (snaps back on rollover —
/// watch dependency) until the user picks another date in the week strip.
final class SelectedDateProvider
    extends $NotifierProvider<SelectedDate, DateTime> {
  /// The day the UI is looking at. Follows today (snaps back on rollover —
  /// watch dependency) until the user picks another date in the week strip.
  SelectedDateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedDateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedDateHash();

  @$internal
  @override
  SelectedDate create() => SelectedDate();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime>(value),
    );
  }
}

String _$selectedDateHash() => r'92f72ff21982223dc6d8daeb70605b35d224d3c2';

/// The day the UI is looking at. Follows today (snaps back on rollover —
/// watch dependency) until the user picks another date in the week strip.

abstract class _$SelectedDate extends $Notifier<DateTime> {
  DateTime build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<DateTime, DateTime>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DateTime, DateTime>,
              DateTime,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Streak count for the chip. Stub data until S12 writes real streaks —
/// the provider contract is final, only the data source matures.

@ProviderFor(streakCount)
final streakCountProvider = StreakCountProvider._();

/// Streak count for the chip. Stub data until S12 writes real streaks —
/// the provider contract is final, only the data source matures.

final class StreakCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  /// Streak count for the chip. Stub data until S12 writes real streaks —
  /// the provider contract is final, only the data source matures.
  StreakCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'streakCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$streakCountHash();

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    return streakCount(ref);
  }
}

String _$streakCountHash() => r'60c446b3fc0714078df2f9fef31cd5f49044e0a6';

@ProviderFor(profile)
final profileProvider = ProfileProvider._();

final class ProfileProvider
    extends
        $FunctionalProvider<
          AsyncValue<UserProfile>,
          UserProfile,
          Stream<UserProfile>
        >
    with $FutureModifier<UserProfile>, $StreamProvider<UserProfile> {
  ProfileProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileHash();

  @$internal
  @override
  $StreamProviderElement<UserProfile> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<UserProfile> create(Ref ref) {
    return profile(ref);
  }
}

String _$profileHash() => r'a06da394d3305d5d310a48a850e7d34612a1997b';

/// The persisted Day snapshot for a date — null while the repo has no row.
/// Repo presence is the authoritative bit of the S05 §4.3 read path.

@ProviderFor(persistedDay)
final persistedDayProvider = PersistedDayFamily._();

/// The persisted Day snapshot for a date — null while the repo has no row.
/// Repo presence is the authoritative bit of the S05 §4.3 read path.

final class PersistedDayProvider
    extends $FunctionalProvider<AsyncValue<Day?>, Day?, Stream<Day?>>
    with $FutureModifier<Day?>, $StreamProvider<Day?> {
  /// The persisted Day snapshot for a date — null while the repo has no row.
  /// Repo presence is the authoritative bit of the S05 §4.3 read path.
  PersistedDayProvider._({
    required PersistedDayFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: null,
         name: r'persistedDayProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$persistedDayHash();

  @override
  String toString() {
    return r'persistedDayProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Day?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Day?> create(Ref ref) {
    final argument = this.argument as DateTime;
    return persistedDay(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PersistedDayProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$persistedDayHash() => r'a611b40900223a843c0e8c82b1b24b8e7d514f4d';

/// The persisted Day snapshot for a date — null while the repo has no row.
/// Repo presence is the authoritative bit of the S05 §4.3 read path.

final class PersistedDayFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Day?>, DateTime> {
  PersistedDayFamily._()
    : super(
        retry: null,
        name: r'persistedDayProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The persisted Day snapshot for a date — null while the repo has no row.
  /// Repo presence is the authoritative bit of the S05 §4.3 read path.

  PersistedDayProvider call(DateTime date) =>
      PersistedDayProvider._(argument: date, from: this);

  @override
  String toString() => r'persistedDayProvider';
}

@ProviderFor(planTemplates)
final planTemplatesProvider = PlanTemplatesProvider._();

final class PlanTemplatesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PlanTemplate>>,
          List<PlanTemplate>,
          Stream<List<PlanTemplate>>
        >
    with
        $FutureModifier<List<PlanTemplate>>,
        $StreamProvider<List<PlanTemplate>> {
  PlanTemplatesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'planTemplatesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$planTemplatesHash();

  @$internal
  @override
  $StreamProviderElement<List<PlanTemplate>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<PlanTemplate>> create(Ref ref) {
    return planTemplates(ref);
  }
}

String _$planTemplatesHash() => r'eabc2c95da808c339d253afb5a30a1d0c2c437ef';

@ProviderFor(mealTemplates)
final mealTemplatesProvider = MealTemplatesProvider._();

final class MealTemplatesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MealTemplate>>,
          List<MealTemplate>,
          Stream<List<MealTemplate>>
        >
    with
        $FutureModifier<List<MealTemplate>>,
        $StreamProvider<List<MealTemplate>> {
  MealTemplatesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mealTemplatesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mealTemplatesHash();

  @$internal
  @override
  $StreamProviderElement<List<MealTemplate>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<MealTemplate>> create(Ref ref) {
    return mealTemplates(ref);
  }
}

String _$mealTemplatesHash() => r'e799921015e149a2bc6aaaff65c6e4139862aa94';

@ProviderFor(foods)
final foodsProvider = FoodsProvider._();

final class FoodsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Food>>,
          List<Food>,
          Stream<List<Food>>
        >
    with $FutureModifier<List<Food>>, $StreamProvider<List<Food>> {
  FoodsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'foodsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$foodsHash();

  @$internal
  @override
  $StreamProviderElement<List<Food>> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<Food>> create(Ref ref) {
    return foods(ref);
  }
}

String _$foodsHash() => r'13c10227a98ceffd8cdd0c8b1dc59c40e8df6784';
