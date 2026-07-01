import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/services/id_generator.dart';
import '../../../../domain/plan/plan_template.dart';
import '../../../../domain/services/plan_scheduling.dart';
import '../../../core/formatting.dart';
import '../../../core/themes/colors.dart';
import '../../../core/themes/dimensions.dart';
import '../../../core/themes/typography.dart';
import '../../../core/widgets/macro_total_card.dart';
import '../../../core/widgets/sheet.dart';
import '../../../core/widgets/sheet_actions.dart';
import '../../../core/widgets/toast.dart';
import '../../today/view_models/today_providers.dart';
import '../view_models/plan_activation.dart';
import '../view_models/plan_detail_controller.dart';
import '../view_models/plan_draft.dart';
import '../view_models/plans_list.dart';
import 'coverage_resolution_sheet.dart';

/// Read-only plan detail viewer. `PLAN` eyebrow + name, a gradient daily-target
/// hero (kcal + macros + repeating-weekday footer), and the time-ordered meal
/// slots. Mutating actions live behind the `···` menu (edit / duplicate /
/// delete); pause/resume lives inside the editor.
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
                    // Daily-target hero with the repeating weekdays as footer.
                    MacroTotalCard(
                      macros: view.total,
                      label: 'DAILY TARGET',
                      gradient: true,
                      footer: _HeroWeekStrip(days: view.days, colors: colors),
                    ),
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
                            onTap: () => showCrudoSheet<void>(
                              context,
                              builder: (_) => PlanSlotSheet(slot: s),
                            ),
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetActionRow(
              icon: Icons.edit_outlined,
              label: 'Edit',
              onTap: () => Navigator.of(sheetCtx).pop('edit'),
            ),
            SheetActionRow(
              icon: Icons.content_copy_outlined,
              label: 'Duplicate',
              onTap: () => Navigator.of(sheetCtx).pop('duplicate'),
            ),
            SheetActionRow(
              icon: Icons.delete_outline,
              label: 'Delete plan',
              onTap: () => Navigator.of(sheetCtx).pop('delete'),
            ),
          ],
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
    final activation = ref.read(planActivationProvider.notifier);
    final allPlans = ref.read(planTemplatesProvider).value ?? const [];
    final others = allPlans.where((p) => p.id != planId).toList();

    // The last plan can never be deleted (nothing left to cover the week).
    if (others.isEmpty) {
      showCrudoToast(
        context,
        "Can't delete your only plan",
        body: 'Create another plan first.',
        kind: ToastKind.warn,
      );
      return;
    }

    final orphaned = await activation.daysOrphanedByDeleting(planId);
    if (!context.mounted) return;

    if (orphaned.isEmpty) {
      // Coverage unaffected — plain confirm, then delete.
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
      await ref.read(planDetailControllerProvider(planId).notifier).delete();
      if (context.mounted) Navigator.of(context).pop();
      return;
    }

    // Deleting orphans days — resolve coverage first.
    final candidates = await activation.otherActivePlans(planId);
    if (!context.mounted) return;
    final choice = await showCoverageResolutionSheet(
      context,
      orphanedDays: orphaned,
      candidates: candidates,
    );
    if (choice == null || !context.mounted) return;
    if (choice.create) {
      // Free the days (others remain, so ≥1 plan stays), then seed a new plan.
      await activation.forceDelete(planId);
      if (!context.mounted) return;
      final seed = PlanTemplate(
        id: ref.read(idGeneratorProvider).newId(),
        name: '',
        days: orphaned,
      );
      Navigator.of(context).pop(); // leave the viewer of the deleted plan
      context.push('/plans/new', extra: seed);
    } else {
      await activation.assignDaysAndDelete(
        planId,
        toPlanId: choice.assignToId!,
        days: orphaned,
      );
      if (context.mounted) Navigator.of(context).pop();
    }
  }
}

/// Repeating-weekday strip for the gradient hero footer. Active days are solid
/// white chips; the rest are faint white-alpha.
class _HeroWeekStrip extends StatelessWidget {
  const _HeroWeekStrip({required this.days, required this.colors});

  final List<int> days;
  final CrudoColors colors;

  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final onHero = colors.surfaceLowest;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'REPEATS ON',
          style: CrudoText.label.copyWith(color: onHero.withValues(alpha: 0.7)),
        ),
        const SizedBox(height: Spacing.sm),
        Row(
          children: [
            for (var i = 0; i < 7; i++) ...[
              if (i > 0) const SizedBox(width: Spacing.xs),
              Expanded(
                child: SizedBox(
                  height: 32, // chip height (width > height), 4px grid
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: days.contains(i)
                          ? onHero
                          : onHero.withValues(alpha: 0.16),
                      borderRadius: Radii.all(Radii.sm),
                    ),
                    child: Text(
                      _labels[i],
                      style: CrudoText.labelMd.copyWith(
                        fontWeight: FontWeight.w700,
                        color: days.contains(i)
                            ? colors.primary
                            : onHero.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
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
    final kcal = slot.macros.kcal.round();
    final subtitle = slot.tag.isEmpty
        ? '$kcal kcal'
        : '${slot.tag} · $kcal kcal';
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

/// Read-only bottom sheet for one plan slot — a plain recipe: time + name
/// header, an ingredient list (name · grams · kcal), and a total summary
/// (kcal + macros) at the bottom. Opened by tapping a slot row; the plan
/// itself is edited only from the ··· actions menu.
class PlanSlotSheet extends StatelessWidget {
  const PlanSlotSheet({required this.slot, super.key});

  final PlanSlotView slot;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    final time = mealTimeLabel(slot.time);
    final m = slot.macros;
    return SheetScaffold(
      label: slot.tag.isEmpty ? time : '$time · ${slot.tag}',
      title: slot.mealName,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final ing in slot.ingredients)
              Padding(
                padding: const EdgeInsets.only(bottom: Spacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        ing.name,
                        style: CrudoText.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                    Text(
                      '${ing.grams.round()}g · ${ing.kcal.round()} kcal',
                      style: CrudoText.labelMd.copyWith(
                        color: colors.onSurfaceMut,
                      ),
                    ),
                  ],
                ),
              ),
            // Total summary: kcal + total macros.
            const SizedBox(height: Spacing.xs),
            Row(
              children: [
                Text(
                  'Total',
                  style: CrudoText.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
                ),
                const Spacer(),
                Text(
                  '${m.kcal.round()} kcal',
                  style: CrudoText.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
