import 'package:crudo/config/app_config.dart';
import 'package:crudo/domain/shared/meal_time.dart';
import 'package:crudo/ui/core/themes/theme.dart';
import 'package:crudo/ui/features/today/view_models/notification_scheduler_controller.dart';
import 'package:crudo/ui/features/today/view_models/today_providers.dart';
import 'package:crudo/ui/features/today/views/streak_risk_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Holds a [ProviderContainer] so tests can read it synchronously.
class _ContainerHolder extends StatefulWidget {
  const _ContainerHolder({
    required this.child,
    required this.container,
    super.key,
  });

  final Widget child;
  final ProviderContainer container;

  @override
  State<_ContainerHolder> createState() => _ContainerHolderState();
}

class _ContainerHolderState extends State<_ContainerHolder> {
  ProviderContainer get container => widget.container;

  @override
  void dispose() {
    widget.container.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return UncontrolledProviderScope(
      container: widget.container,
      child: widget.child,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final today = DateTime.utc(2026, 6, 10);

  final holderKey = GlobalKey<_ContainerHolderState>();

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(AppConfig(flavor: Flavor.dev)),
        clockProvider.overrideWithValue(() => today),
        todayProvider.overrideWithValue(today),
      ],
    );
  }

  Widget testableApp() {
    return _ContainerHolder(
      key: holderKey,
      container: makeContainer(),
      child: MaterialApp(
        theme: crudoTheme,
        home: Builder(
          builder: (context) => Column(
            children: [
              ElevatedButton(
                onPressed: () => showStreakRiskSheet(context, (
                  streakDays: 12,
                  mealsLeft: 2,
                  pivotalMealName: 'Pre-Workout',
                  pivotalMealTime: const MealTime(16 * 60),
                  minutesFromNow: 32,
                )),
                child: const Text('Show risk'),
              ),
              Consumer(
                builder: (context, ref, child) {
                  final muted = ref.watch(mutedRiskDayProvider);
                  return Text(
                    muted == null ? 'muted-null' : 'muted-$muted',
                    key: const ValueKey('muted-state'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  group('StreakRiskSheet', () {
    testWidgets('renders headline and body with correct data', (tester) async {
      await tester.pumpWidget(testableApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show risk'));
      await tester.pumpAndSettle();

      // Headline
      expect(find.text('2 meals left to keep 12 days alive.'), findsOneWidget);

      // Body
      expect(
        find.text('Pre-Workout at 4:00 PM — 32 minutes from now.'),
        findsOneWidget,
      );

      // Label
      expect(find.text('STREAK AT RISK'), findsOneWidget);

      // Flame icon
      expect(find.byIcon(Icons.local_fire_department), findsOneWidget);

      // CTA buttons
      expect(find.text('Got it'), findsOneWidget);
      expect(find.text('Mute today'), findsOneWidget);
    });

    testWidgets('tapping Got it dismisses the dialog', (tester) async {
      await tester.pumpWidget(testableApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show risk'));
      await tester.pumpAndSettle();

      expect(find.text('2 meals left to keep 12 days alive.'), findsOneWidget);

      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();

      expect(find.text('2 meals left to keep 12 days alive.'), findsNothing);
    });

    testWidgets('tapping Mute today sets mutedRiskDayProvider and pops', (
      tester,
    ) async {
      await tester.pumpWidget(testableApp());
      await tester.pumpAndSettle();

      // Verify initial state is null
      expect(find.text('muted-null'), findsOneWidget);

      await tester.tap(find.text('Show risk'));
      await tester.pumpAndSettle();

      expect(find.text('2 meals left to keep 12 days alive.'), findsOneWidget);

      await tester.tap(find.text('Mute today'));
      await tester.pumpAndSettle();

      // Dialog should be dismissed
      expect(find.text('2 meals left to keep 12 days alive.'), findsNothing);

      // Verify the provider was set via the Consumer widget
      expect(find.text('muted-$today'), findsOneWidget);
    });
  });
}
