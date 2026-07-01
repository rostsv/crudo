import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/services/id_generator.dart';
import '../../../../domain/plan/plan_template.dart';
import '../../../../domain/services/plan_scheduling.dart';
import '../../../core/themes/colors.dart';
import '../../../core/themes/dimensions.dart';
import '../../../core/themes/typography.dart';
import '../../../core/widgets/sheet.dart';
import '../../../core/widgets/sheet_actions.dart';
import '../view_models/plan_activation.dart';
import '../view_models/plan_draft.dart';
import '../view_models/plans_list.dart';
import 'coverage_resolution_sheet.dart';
import 'plan_list_card.dart';

/// S10 plans list screen. `LIBRARY` eyebrow + title, a top-right circular add
/// button (the only "new plan" affordance), an advisory banner when a single
/// plan covers the whole week, and a card per plan. Tapping a card pushes the
/// read-only viewer at `/plans/:id`.
class PlansScreen extends ConsumerWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = ref.watch(plansListProvider);
    final colors = Theme.of(context).extension<CrudoColors>()!;

    // Advisory: only one plan exists, or a single plan blankets all 7 days.
    final showRepeatsHint =
        rows.length == 1 || rows.any((r) => r.days.toSet().length == 7);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: eyebrow + title + add button.
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.md,
              Spacing.md,
              Spacing.md,
              Spacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('LIBRARY', style: CrudoText.label),
                const SizedBox(height: Spacing.xs),
                // '+' shares the title line so it aligns with "Plans".
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Expanded(
                      child: Text('Plans', style: CrudoText.headline),
                    ),
                    _AddPlanButton(
                      key: const ValueKey('new-plan'),
                      onTap: () => context.push('/plans/new'),
                      colors: colors,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (showRepeatsHint && rows.isNotEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(
                Spacing.md,
                0,
                Spacing.md,
                Spacing.lg,
              ),
              child: _RepeatsHint(),
            ),
          Expanded(
            child: rows.isEmpty
                ? Center(
                    child: Text(
                      'No plans yet',
                      style: CrudoText.body.copyWith(
                        color: colors.onSurfaceMut,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      Spacing.md,
                      Spacing.xs,
                      Spacing.md,
                      Spacing.md,
                    ),
                    itemCount: rows.length,
                    itemBuilder: (context, index) {
                      final row = rows[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: Spacing.md),
                        child: PlanListCard(
                          row: row,
                          onTap: () => context.push('/plans/${row.id}'),
                          onToggleActive: () =>
                              _toggleActive(context, ref, row),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// Quick pause/resume from a card. Pausing that would uncover weekdays opens
  /// the coverage-resolution sheet first (assign the days to another plan or
  /// create one). Resuming that would clash opens the steal-override confirm.
  Future<void> _toggleActive(
    BuildContext context,
    WidgetRef ref,
    PlanRowVm row,
  ) async {
    final ctrl = ref.read(planActivationProvider.notifier);
    if (row.active) {
      final orphaned = await ctrl.daysOrphanedByPausing(row.id);
      if (!context.mounted) return;
      if (orphaned.isEmpty) {
        await ctrl.pause(row.id);
        return;
      }
      final candidates = await ctrl.otherActivePlans(row.id);
      if (!context.mounted) return;
      final choice = await showCoverageResolutionSheet(
        context,
        orphanedDays: orphaned,
        candidates: candidates,
      );
      if (choice == null) return; // cancelled — stays active
      if (choice.create) {
        // Free the days, then open a new plan pre-filled with them.
        await ctrl.pause(row.id);
        if (!context.mounted) return;
        final seed = PlanTemplate(
          id: ref.read(idGeneratorProvider).newId(),
          name: '',
          days: orphaned,
        );
        context.push('/plans/new', extra: seed);
      } else {
        await ctrl.assignDaysAndPause(
          row.id,
          toPlanId: choice.assignToId!,
          days: orphaned,
        );
      }
      return;
    }
    final conflicts = await ctrl.resumeConflicts(row.id);
    if (!context.mounted) return;
    if (conflicts.isEmpty) {
      await ctrl.resume(row.id);
      return;
    }
    final ok = await _confirmResumeOverride(context, conflicts);
    if (ok == true) await ctrl.resume(row.id, override: true);
  }

  Future<bool?> _confirmResumeOverride(
    BuildContext context,
    List<WeekdayConflict> conflicts,
  ) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final groups = <String, (String name, List<int> days)>{};
    for (final c in conflicts) {
      final entry = groups.putIfAbsent(
        c.otherPlanId,
        () => (c.otherPlanName, <int>[]),
      );
      entry.$2.add(c.weekday);
    }
    return showCrudoSheet<bool>(
      context,
      builder: (sheetCtx) => SheetScaffold(
        title: 'Weekday conflict',
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final entry in groups.values)
              Padding(
                padding: const EdgeInsets.only(bottom: Spacing.sm),
                child: Text(
                  '${entry.$1} loses '
                  '${entry.$2.map((d) => names[d]).join(', ')}',
                  style: CrudoText.body,
                ),
              ),
            const SizedBox(height: Spacing.sm),
            SheetActionRow(
              icon: Icons.sync_alt,
              label: 'Resolve conflict',
              onTap: () => Navigator.of(sheetCtx).pop(true),
            ),
          ],
        ),
        cta: SecondaryAction(
          label: 'Cancel',
          onTap: () => Navigator.of(sheetCtx).pop(false),
        ),
      ),
    );
  }
}

/// Add button — the sole "new plan" entry point. Bare icon (no fill); the
/// [_size] box keeps a 48px touch target.
class _AddPlanButton extends StatelessWidget {
  const _AddPlanButton({required this.onTap, required this.colors, super.key});

  final VoidCallback onTap;
  final CrudoColors colors;

  static const _size = 48.0; // touch target, 4px grid

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'New plan',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: _size,
          height: _size,
          child: Icon(Icons.add, size: IconSizes.lg, color: colors.primary),
        ),
      ),
    );
  }
}

/// Advisory banner shown when a single plan covers the whole week.
class _RepeatsHint extends StatelessWidget {
  const _RepeatsHint();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceLow,
        borderRadius: Radii.all(Radii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon centered on the header line.
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.info_outline,
                size: IconSizes.md,
                color: colors.onSurfaceMut,
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Text(
                  'One plan repeats daily',
                  style: CrudoText.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.xs),
          // Indent to line up with the header text (past icon + gap).
          Padding(
            padding: const EdgeInsets.only(left: IconSizes.md + Spacing.md),
            child: Text(
              'Assign different plans to specific days for variety.',
              style: CrudoText.labelMd.copyWith(
                color: colors.onSurfaceMut,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
