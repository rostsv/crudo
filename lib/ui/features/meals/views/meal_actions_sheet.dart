import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/services/meal_lifecycle.dart';
import '../../../../domain/shared/enums.dart';
import '../../../core/themes/colors.dart';
import '../../../core/widgets/sheet_actions.dart';
import '../../../core/themes/dimensions.dart';
import '../../../core/themes/typography.dart';
import '../../../core/widgets/sheet.dart';
import '../../../core/widgets/toast.dart';
import '../../today/view_models/day_controller.dart';
import '../../today/view_models/today_providers.dart';
import 'snooze_sheet.dart';
import 'swap_sheet.dart';

/// Bottom-sheet actions for a meal: Snooze, Swap, Skip. Eligibility mirrors
/// the detail screen exactly; disabled rows render at [Opacities.disabled]
/// and respond with the same ineligibility toast — except when the meal is
/// locked (skipped, or skipped-then-logged), where an explanatory message
/// below covers it and taps are silent (no extra toast).
class MealActionsSheet extends ConsumerWidget {
  const MealActionsSheet({required this.date, required this.mealId, super.key});

  final DateTime date;
  final String mealId;

  static const _guardMessage = "That can't be changed anymore.";

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    final day = ref.watch(dayControllerProvider(date)).value;
    if (day == null) return const SizedBox.shrink();

    final now = ref.watch(clockProvider)();
    final today = ref.watch(todayProvider);
    final meal = day.meals.firstWhere((m) => m.id == mealId);
    // Matches what the detail screen's header actually displays — a
    // never-snoozed meal whose time has passed shows SKIPPED too, not just
    // an explicit skippedAt. The sheet must lock out everything whenever
    // that's what's on screen, or actions silently no-op while looking live.
    final isSkipped = mealStatus(day, mealId, now) == MealStatus.skipped;
    // A meal that was skipped and then checked/logged anyway: `logMeal`
    // never clears skippedAt, so it can be skippedAt != null AND done/
    // partial at once — `mealStatus` reports done/partial then (checked
    // wins), so this needs its own message instead of going silently blank.
    final isLoggedLocked = !isSkipped && meal.meal.anyChecked;
    final locked = isSkipped || isLoggedLocked;
    final canEdit = !locked && canEditMealContent(meal, day.date, now);

    return SheetScaffold(
      title: 'Meal actions',
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ActionRow(
            key: const ValueKey('action-snooze'),
            icon: Icons.snooze_outlined,
            label: 'Snooze',
            enabled: !locked && canSnoozeMeal(day, mealId, now, today),
            colors: colors,
            onTap: () => showCrudoSheet<void>(
              context,
              builder: (_) => SnoozeSheet(date: date, mealId: mealId),
            ),
            // A locked meal (skipped, or skipped-then-logged) is already
            // explained by the message below — no extra toast on top of it.
            onDisabledTap: locked
                ? null
                : () {
                    final reason = snoozeIneligibilityReason(
                      day,
                      mealId,
                      now,
                      today,
                    );
                    if (reason != null) {
                      showCrudoToast(
                        context,
                        "Can't snooze",
                        body: reason,
                        kind: ToastKind.warn,
                      );
                    }
                  },
          ),
          _ActionRow(
            key: const ValueKey('action-swap'),
            icon: Icons.swap_horiz,
            label: 'Swap meal',
            enabled: canEdit,
            colors: colors,
            onTap: () => showCrudoSheet<void>(
              context,
              builder: (_) => SwapSheet(date: date, mealId: mealId),
            ),
            onDisabledTap: locked
                ? null
                : () => showCrudoToast(
                    context,
                    _guardMessage,
                    body: 'This meal is already logged, skipped, or locked.',
                    kind: ToastKind.warn,
                  ),
          ),
          _ActionRow(
            key: const ValueKey('action-skip'),
            icon: Icons.skip_next,
            label: 'Skip',
            enabled: !locked && canSkipMeal(day, mealId, today),
            colors: colors,
            onTap: () => _skip(context, ref),
            onDisabledTap: locked
                ? null
                : () => showCrudoToast(
                    context,
                    _guardMessage,
                    body: 'This meal is already logged, skipped, or locked.',
                    kind: ToastKind.warn,
                  ),
          ),
          if (locked) ...[
            const SizedBox(height: Spacing.sm),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: IconSizes.sm,
                  color: colors.onSurfaceMut,
                ),
                const SizedBox(width: Spacing.xs),
                Expanded(
                  child: Text(
                    isSkipped
                        ? "This meal was skipped and can't be changed."
                        : "This meal is already logged and can't be changed.",
                    style: CrudoText.body.copyWith(color: colors.onSurfaceMut),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _skip(BuildContext context, WidgetRef ref) async {
    final navigator = Navigator.of(context);
    await runDayOp(context, () async {
      await ref.read(dayControllerProvider(date).notifier).skipMeal(mealId);
      // runDayOp only pops once; close both the sheet and the detail screen.
      navigator.pop();
      navigator.pop();
    }, guardMessage: _guardMessage);
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.colors,
    this.onTap,
    this.onDisabledTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final CrudoColors colors;
  final VoidCallback? onTap;
  final VoidCallback? onDisabledTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : Opacities.disabled,
      child: Semantics(
        button: enabled && onTap != null,
        label: label,
        child: GestureDetector(
          onTap: enabled ? onTap : onDisabledTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Spacing.md),
            child: Row(
              children: [
                Icon(icon, size: IconSizes.md, color: colors.primary),
                const SizedBox(width: Spacing.md),
                Text(
                  label,
                  style: CrudoText.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
