import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/services/id_generator.dart';
import '../../../../domain/services/plan_scheduling.dart';
import '../../../../domain/shared/macros.dart';
import '../../../core/formatting.dart';
import '../../../core/themes/colors.dart';
import '../../../core/themes/dimensions.dart';
import '../../../core/themes/typography.dart';
import '../../../core/widgets/sheet.dart';
import '../../../core/widgets/sheet_actions.dart';
import '../../../core/widgets/toast.dart';
import '../../today/view_models/today_providers.dart';
import '../view_models/plan_detail_controller.dart';
import '../view_models/plan_draft.dart';
import '../view_models/plans_list.dart';

/// Read-only plan detail viewer. `LIBRARY`-style `PLAN` eyebrow + name, a
/// gradient daily-target hero, the read-only weekday strip with an `EDIT` link,
/// and the time-ordered meal slots. Mutating actions live behind the `···`
/// menu (edit / duplicate / delete); pause/resume lives inside the editor.
class PlanViewScreen extends ConsumerWidget {
  const PlanViewScreen({required this.planId, super.key});

  final String planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<CrudoColors>()!;

    final PlanViewVm view;
    try {
      view = ref.watch(planViewProvider(planId));
    } on StateError {
      return Scaffold(
        backgroundColor: colors.surface,
        body: Center(child: Text('Plan not found', style: CrudoText.body)),
      );
    }

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: back · eyebrow+name · actions.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.sm,
                Spacing.sm,
                Spacing.sm,
                0,
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.maybePop(context),
                    icon: Icon(
                      Icons.arrow_back,
                      size: IconSizes.lg,
                      color: colors.onSurface,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('PLAN', style: CrudoText.label),
                        const SizedBox(height: Spacing.xs),
                        Text(
                          view.name,
                          style: CrudoText.headlineSm,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('plan-actions'),
                    onPressed: () => _showActions(context, ref),
                    icon: Icon(
                      Icons.more_horiz,
                      size: IconSizes.lg,
                      color: colors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.md,
                  Spacing.md,
                  Spacing.md,
                  Spacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DailyTargetHero(total: view.total, colors: colors),
                    const SizedBox(height: Spacing.lg),

                    // Repeats on + EDIT link.
                    Row(
                      children: [
                        const Text('REPEATS ON', style: CrudoText.label),
                        const Spacer(),
                        GestureDetector(
                          key: const ValueKey('plan-edit-link'),
                          onTap: () => context.push('/plans/$planId/edit'),
                          behavior: HitTestBehavior.opaque,
                          child: Text(
                            'EDIT',
                            style: CrudoText.label.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacing.sm),
                    _ReadonlyWeekStrip(days: view.days, colors: colors),
                    const SizedBox(height: Spacing.lg),

                    // Meal slots header.
                    Row(
                      children: [
                        const Text('MEAL SLOTS', style: CrudoText.label),
                        const Spacer(),
                        Text(
                          '${view.mealCount} '
                          '${view.mealCount == 1 ? 'SLOT' : 'SLOTS'}',
                          style: CrudoText.label.copyWith(
                            color: colors.onSurfaceMut,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacing.sm),
                    if (view.slots.isEmpty)
                      Text(
                        'No meals scheduled',
                        style: CrudoText.body.copyWith(
                          color: colors.onSurfaceMut,
                        ),
                      )
                    else
                      for (final (i, s) in view.slots.indexed)
                        Padding(
                          padding: const EdgeInsets.only(bottom: Spacing.sm),
                          child: _SlotRow(
                            slot: s,
                            zebra: i.isOdd,
                            colors: colors,
                            onTap: () => context.push('/plans/$planId/edit'),
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showActions(BuildContext context, WidgetRef ref) async {
    final action = await showCrudoSheet<String>(
      context,
      builder: (sheetCtx) => SheetScaffold(
        title: 'Plan actions',
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SecondaryAction(
              label: 'Edit',
              onTap: () => Navigator.of(sheetCtx).pop('edit'),
            ),
            const SizedBox(height: Spacing.sm),
            SecondaryAction(
              label: 'Duplicate',
              onTap: () => Navigator.of(sheetCtx).pop('duplicate'),
            ),
            const SizedBox(height: Spacing.sm),
            SecondaryAction(
              label: 'Delete plan',
              onTap: () => Navigator.of(sheetCtx).pop('delete'),
            ),
          ],
        ),
        cta: SecondaryAction(
          label: 'Cancel',
          onTap: () => Navigator.of(sheetCtx).pop(),
        ),
      ),
    );
    if (action == null || !context.mounted) return;
    switch (action) {
      case 'edit':
        context.push('/plans/$planId/edit');
      case 'duplicate':
        await _duplicate(context, ref);
      case 'delete':
        await _delete(context, ref);
    }
  }

  Future<void> _duplicate(BuildContext context, WidgetRef ref) async {
    final allPlans = ref.read(planTemplatesProvider).value ?? const [];
    final src = allPlans.where((p) => p.id == planId).firstOrNull;
    if (src == null || !context.mounted) return;
    final cloned = clonePlan(src, newId: ref.read(idGeneratorProvider).newId);
    await context.push('/plans/new', extra: cloned);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final allPlans = ref.read(planTemplatesProvider).value ?? const [];
    if (!canDeletePlan(allPlans)) {
      showCrudoToast(
        context,
        "Can't delete your only plan",
        body: 'Create another plan before deleting this one.',
        kind: ToastKind.warn,
      );
      return;
    }
    final confirmed = await showCrudoSheet<bool>(
      context,
      builder: (sheetCtx) => SheetScaffold(
        title: 'Delete plan?',
        body: Text(
          'This plan and its schedule will be removed.',
          style: CrudoText.body,
        ),
        cta: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SecondaryAction(
              label: 'Delete',
              onTap: () => Navigator.of(sheetCtx).pop(true),
            ),
            const SizedBox(height: Spacing.sm),
            SecondaryAction(
              label: 'Cancel',
              onTap: () => Navigator.of(sheetCtx).pop(false),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final deleted = await ref
        .read(planDetailControllerProvider(planId).notifier)
        .delete();
    if (!context.mounted) return;
    if (deleted) {
      Navigator.of(context).pop();
    } else {
      showCrudoToast(
        context,
        "Can't delete your only plan",
        body: 'Create another plan before deleting this one.',
        kind: ToastKind.warn,
      );
    }
  }
}

/// Gradient daily-target hero: kcal headline + P/C/F with underline accents.
class _DailyTargetHero extends StatelessWidget {
  const _DailyTargetHero({required this.total, required this.colors});

  final Macros total;
  final CrudoColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [CrudoPalette.primary, CrudoPalette.primarySoft],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: Radii.all(Radii.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DAILY TARGET',
            style: CrudoText.label.copyWith(
              color: colors.surfaceLowest.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${total.kcal.round()}',
                style: CrudoText.display.copyWith(color: colors.surfaceLowest),
              ),
              const SizedBox(width: Spacing.sm),
              Text(
                'kcal',
                style: CrudoText.body.copyWith(
                  color: colors.surfaceLowest.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.lg),
          Row(
            children: [
              _HeroMacro(
                label: 'PROTEIN',
                grams: total.protein,
                colors: colors,
              ),
              _HeroMacro(label: 'CARBS', grams: total.carbs, colors: colors),
              _HeroMacro(label: 'FATS', grams: total.fats, colors: colors),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMacro extends StatelessWidget {
  const _HeroMacro({
    required this.label,
    required this.grams,
    required this.colors,
  });

  final String label;
  final double grams;
  final CrudoColors colors;

  @override
  Widget build(BuildContext context) {
    final onHero = colors.surfaceLowest;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: CrudoText.label.copyWith(
              color: onHero.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: Spacing.xs),
          Text.rich(
            TextSpan(
              style: CrudoText.title.copyWith(color: onHero),
              children: [
                TextSpan(text: '${grams.round()}'),
                TextSpan(
                  text: 'g',
                  style: CrudoText.labelMd.copyWith(
                    color: onHero.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.sm),
          // Underline accent (painted stroke, allowed off-grid).
          Container(
            height: 2,
            width: Spacing.xl,
            decoration: BoxDecoration(
              color: onHero.withValues(alpha: 0.4),
              borderRadius: Radii.all(Radii.full),
            ),
          ),
        ],
      ),
    );
  }
}

/// Read-only full-width weekday strip.
class _ReadonlyWeekStrip extends StatelessWidget {
  const _ReadonlyWeekStrip({required this.days, required this.colors});

  final List<int> days;
  final CrudoColors colors;

  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 7; i++) ...[
          if (i > 0) const SizedBox(width: Spacing.xs),
          Expanded(
            child: SizedBox(
              height: 36, // chip height (width > height), 4px grid
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: days.contains(i) ? colors.primary : colors.surfaceHigh,
                  borderRadius: Radii.all(Radii.sm),
                ),
                child: Text(
                  _labels[i],
                  style: CrudoText.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: days.contains(i)
                        ? colors.surfaceLowest
                        : colors.onSurfaceMut,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// One meal-slot row: time · name · (tag · kcal) · chevron. Zebra rows shift
/// surface tone instead of drawing dividers.
class _SlotRow extends StatelessWidget {
  const _SlotRow({
    required this.slot,
    required this.zebra,
    required this.colors,
    required this.onTap,
  });

  final PlanSlotView slot;
  final bool zebra;
  final CrudoColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = slot.tag.isEmpty
        ? '${slot.kcal} kcal'
        : '${slot.tag} · ${slot.kcal} kcal';
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.md,
        ),
        decoration: BoxDecoration(
          color: zebra ? colors.surfaceLow : colors.surfaceLowest,
          borderRadius: Radii.all(Radii.md),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 52, // time column, 4px grid
              child: Text(
                mealTimeLabel(slot.time),
                style: CrudoText.body.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.primary,
                ),
              ),
            ),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    slot.mealName,
                    style: CrudoText.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    subtitle,
                    style: CrudoText.labelMd.copyWith(
                      color: colors.onSurfaceMut,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: IconSizes.md,
              color: colors.onSurfaceVar,
            ),
          ],
        ),
      ),
    );
  }
}
