import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/day/scheduled_meal.dart';
import '../../../../domain/services/meal_lifecycle.dart';
import '../../../core/themes/colors.dart';
import '../../../core/themes/dimensions.dart' as dim;
import '../../../core/themes/typography.dart';
import '../../../core/widgets/primary_cta.dart';
import '../../../core/widgets/sheet.dart';
import '../view_models/day_controller.dart';
import '../view_models/today_providers.dart';
import 'formatting.dart';
import 'sheet_actions.dart';

/// The canned snooze durations (minutes) — sheets.jsx SnoozeSheet.
const List<int> snoozePresetMinutes = <int>[10, 15, 20, 30];

/// Commitment-style snooze: short presets only, bounded by the next meal /
/// midnight (`maxSnoozeUntil`). Presets past the bound render disabled, so
/// the rule is visible before the user commits.
class SnoozeSheet extends ConsumerStatefulWidget {
  const SnoozeSheet({required this.date, required this.mealId, super.key});

  final DateTime date;
  final String mealId;

  @override
  ConsumerState<SnoozeSheet> createState() => _SnoozeSheetState();
}

class _SnoozeSheetState extends ConsumerState<SnoozeSheet> {
  static const _preferredPreset = 15;

  int? _selected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    final day = ref.watch(dayControllerProvider(widget.date)).value;
    if (day == null) return const SizedBox.shrink();
    final now = ref.watch(clockProvider)();
    final base = snoozeBaseFor(day, widget.mealId, now);
    final bound = maxSnoozeUntil(day, widget.mealId, now);

    DateTime untilFor(int m) => base.add(Duration(minutes: m));
    bool enabled(int m) => !untilFor(m).toUtc().isAfter(bound);

    // which cap is in play? maxSnoozeUntilFor returns the next meal's
    // instant when one exists, else midnight — so the reason follows from
    // whether a strictly-later meal exists (same comparison rule: strictly
    // greater by time, earliest such).
    final mealNow = day.meals.firstWhere((m) => m.id == widget.mealId);
    ScheduledMeal? next;
    for (final m in day.meals) {
      if (m.time.compareTo(mealNow.time) > 0 &&
          (next == null || m.time.compareTo(next.time) < 0)) {
        next = m;
      }
    }
    final nextTag = next == null
        ? null
        : next.meal.tags.isEmpty
        ? 'next meal'
        : next.meal.tags.first.name[0].toUpperCase() +
              next.meal.tags.first.name.substring(1);
    final disabledReason = nextTag == null ? 'Past midnight' : 'Past $nextTag';

    // Default: the preferred preset, else the largest still-enabled one —
    // never open on a dead selection + disabled CTA.
    final selected =
        _selected ??
        (enabled(_preferredPreset)
            ? _preferredPreset
            : snoozePresetMinutes.lastWhere(
                enabled,
                orElse: () => snoozePresetMinutes.first,
              ));

    return SheetScaffold(
      label: 'Commitment',
      title: 'Snooze, then eat.',
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Short delay only — can't push past your next meal.",
            style: CrudoText.body.copyWith(color: colors.onSurfaceMut),
          ),
          const SizedBox(height: dim.Spacing.lg),
          Row(
            children: [
              for (final m in snoozePresetMinutes) ...[
                Expanded(
                  child: _PresetTile(
                    key: ValueKey('snooze-preset-$m'),
                    minutes: m,
                    selected: selected == m,
                    enabled: enabled(m),
                    resultLabel: enabled(m)
                        ? timeOfDayLabel(untilFor(m).toLocal())
                        : disabledReason,
                    colors: colors,
                    onTap: () => setState(() => _selected = m),
                  ),
                ),
                if (m != snoozePresetMinutes.last)
                  const SizedBox(width: dim.Spacing.sm),
              ],
            ],
          ),
          if (!enabled(snoozePresetMinutes.first)) ...[
            const SizedBox(height: dim.Spacing.md),
            Text(
              'No room to snooze — your next meal is too soon',
              key: const ValueKey('snooze-empty'),
              style: CrudoText.body.copyWith(color: colors.onSurfaceMut),
            ),
          ],
        ],
      ),
      cta: Row(
        children: [
          Expanded(
            child: SecondaryAction(
              label: 'Cancel',
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(width: dim.Spacing.sm),
          Expanded(
            child: PrimaryCta(
              label: 'Snooze ${selected}m',
              enabled: enabled(selected),
              onPressed: () => runDayOp(
                context,
                () => ref
                    .read(dayControllerProvider(widget.date).notifier)
                    .snooze(widget.mealId, untilFor(selected)),
                guardMessage: "Can't snooze that far.",
                pop: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PresetTile extends StatelessWidget {
  const _PresetTile({
    required this.minutes,
    required this.selected,
    required this.enabled,
    this.resultLabel,
    required this.colors,
    required this.onTap,
    super.key,
  });

  final int minutes;
  final bool selected;
  final bool enabled;
  final String? resultLabel;
  final CrudoColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : dim.Opacities.disabled,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: dim.Durations.fast,
          padding: const EdgeInsets.symmetric(vertical: dim.Spacing.md),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected && enabled ? colors.primary : colors.surfaceLow,
            borderRadius: dim.Radii.all(dim.Radii.md),
          ),
          child: Column(
            children: [
              Text(
                '$minutes',
                style: CrudoText.headline.copyWith(
                  color: selected && enabled
                      ? colors.surfaceLowest
                      : colors.onSurface,
                ),
              ),
              Text(
                'MIN',
                style: CrudoText.label.copyWith(
                  color:
                      (selected && enabled
                              ? colors.surfaceLowest
                              : colors.onSurfaceMut)
                          .withValues(alpha: dim.Opacities.muted),
                ),
              ),
              if (resultLabel != null)
                Text(
                  resultLabel!,
                  style: CrudoText.labelMd.copyWith(
                    color: selected && enabled
                        ? colors.surfaceLowest
                        : colors.onSurfaceMut,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
