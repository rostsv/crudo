import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../domain/plan/plan_template.dart';
import '../../../../domain/services/plan_scheduling.dart';
import '../../../core/formatting.dart';
import '../../../core/themes/colors.dart';
import '../../../core/themes/dimensions.dart';
import '../../../core/themes/typography.dart';
import '../../../core/widgets/primary_cta.dart';
import '../../../core/widgets/sheet.dart';
import '../../../core/widgets/sheet_actions.dart';
import '../../../core/widgets/toast.dart';
import '../../today/view_models/today_providers.dart';
import '../view_models/plan_draft.dart';
import '../view_models/plan_detail_controller.dart';

/// S10 plan detail / editing screen. Slots are read-only; only name, weekday
/// assignment, and active flag are mutable. Save runs the override→uncovered
/// confirm flow; back is guarded by a dirty check.
class PlanDetailScreen extends ConsumerWidget {
  const PlanDetailScreen({required this.planId, super.key});

  final String planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draftAsync = ref.watch(planDetailControllerProvider(planId));
    return draftAsync.when(
      data: (draft) => _PlanDetailForm(planId: planId, draft: draft),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Plan not found', style: CrudoText.body)),
      ),
    );
  }
}

class _PlanDetailForm extends ConsumerStatefulWidget {
  const _PlanDetailForm({required this.planId, required this.draft});

  final String planId;
  final PlanDraft draft;

  @override
  ConsumerState<_PlanDetailForm> createState() => _PlanDetailFormState();
}

class _PlanDetailFormState extends ConsumerState<_PlanDetailForm> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.draft.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  PlanDetailController get _ctrl =>
      ref.read(planDetailControllerProvider(widget.planId).notifier);

  static const _weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _weekdayNames = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  Future<void> _save() async {
    var out = await _ctrl.save();
    if (!out.committed) {
      final ok = await _confirmOverride(out.conflicts);
      if (ok != true) return;
      out = await _ctrl.save(override: true);
    }
    if (out.uncovered.isNotEmpty) {
      final leave = await _confirmUncovered(out.uncovered);
      if (leave != true) return;
    }
    if (mounted) context.pop();
  }

  Future<void> _delete(List<PlanTemplate> allPlans) async {
    if (!canDeletePlan(allPlans)) {
      showCrudoToast(
        context,
        "Can't delete your only plan",
        kind: ToastKind.warn,
      );
      return;
    }
    final confirmed = await _confirmDelete();
    if (confirmed != true) return;
    final deleted = await _ctrl.delete();
    if (!mounted) return;
    if (deleted) {
      context.pop();
    } else {
      // Lost the race — another tab deleted down to one plan meanwhile.
      showCrudoToast(
        context,
        "Can't delete your only plan",
        kind: ToastKind.warn,
      );
    }
  }

  Future<bool?> _confirmOverride(List<WeekdayConflict> conflicts) {
    // Group by otherPlanId / otherPlanName.
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
        title: 'Override existing plans?',
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final entry in groups.values)
              Padding(
                padding: const EdgeInsets.only(bottom: Spacing.sm),
                child: Text(
                  '${entry.$1} loses '
                  '${entry.$2.map((d) => _weekdayNames[d]).join(', ')}',
                  style: CrudoText.body,
                ),
              ),
          ],
        ),
        cta: Row(
          children: [
            Expanded(
              child: SecondaryAction(
                label: 'Cancel',
                onTap: () => Navigator.of(sheetCtx).pop(false),
              ),
            ),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: PrimaryCta(
                label: 'Override',
                onPressed: () => Navigator.of(sheetCtx).pop(true),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _confirmUncovered(List<int> uncovered) {
    final names = uncovered.map((d) => _weekdayNames[d]).join(', ');
    return showCrudoSheet<bool>(
      context,
      builder: (sheetCtx) => SheetScaffold(
        title: 'Save anyway?',
        body: Text('$names have no plan — save anyway?', style: CrudoText.body),
        cta: Row(
          children: [
            Expanded(
              child: SecondaryAction(
                label: 'Cancel',
                onTap: () => Navigator.of(sheetCtx).pop(false),
              ),
            ),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: PrimaryCta(
                label: 'Save',
                onPressed: () => Navigator.of(sheetCtx).pop(true),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete() {
    return showCrudoSheet<bool>(
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
            PrimaryCta(
              label: 'Delete',
              onPressed: () => Navigator.of(sheetCtx).pop(true),
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
  }

  Future<bool?> _confirmDiscard() {
    return showCrudoSheet<bool>(
      context,
      builder: (sheetCtx) => SheetScaffold(
        title: 'Discard changes?',
        body: Text('Your edits will be lost.', style: CrudoText.body),
        cta: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PrimaryCta(
              label: 'Discard',
              onPressed: () => Navigator.of(sheetCtx).pop(true),
            ),
            const SizedBox(height: Spacing.sm),
            TextButton(
              key: const ValueKey('keep-editing'),
              onPressed: () => Navigator.of(sheetCtx).pop(false),
              child: const Text('Keep editing'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    final draft = ref
        .watch(planDetailControllerProvider(widget.planId))
        .requireValue;

    final allPlans = ref.watch(planTemplatesProvider).value ?? const [];
    final conflicts = detectConflicts(
      allPlans,
      forPlanId: widget.planId,
      proposedDays: draft.claimedDays,
    );
    final conflictDays = {for (final c in conflicts) c.weekday};

    return PopScope(
      canPop: !_ctrl.isDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final nav = Navigator.of(context);
        final leave = await _confirmDiscard();
        if (leave == true && mounted) nav.pop();
      },
      child: Scaffold(
        backgroundColor: colors.surface,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.md,
                  Spacing.sm,
                  Spacing.md,
                  0,
                ),
                child: Row(
                  children: [
                    IconButton(
                      // Delegates to PopScope which handles dirty-check + confirm.
                      onPressed: () => Navigator.maybePop(context),
                      icon: Icon(
                        Icons.arrow_back,
                        size: IconSizes.lg,
                        color: colors.onSurface,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        draft.name,
                        style: CrudoText.headlineSm,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.md,
                    Spacing.md,
                    Spacing.md,
                    Spacing.xl,
                  ),
                  children: [
                    // Name field
                    const Text('PLAN NAME', style: CrudoText.label),
                    const SizedBox(height: Spacing.sm),
                    TextField(
                      key: const ValueKey('plan-name-field'),
                      controller: _nameController,
                      style: CrudoText.title,
                      decoration: InputDecoration(
                        hintText: 'Plan name',
                        hintStyle: CrudoText.title.copyWith(
                          color: colors.onSurfaceMut,
                        ),
                        filled: true,
                        fillColor: colors.surfaceLow,
                        border: OutlineInputBorder(
                          borderRadius: Radii.all(Radii.md),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: Spacing.md,
                          vertical: Spacing.md,
                        ),
                      ),
                      onChanged: _ctrl.setName,
                    ),
                    const SizedBox(height: Spacing.lg),

                    // Weekday chips
                    const Text('REPEATS ON', style: CrudoText.label),
                    const SizedBox(height: Spacing.sm),
                    Wrap(
                      spacing: Spacing.sm,
                      runSpacing: Spacing.sm,
                      children: [
                        for (var i = 0; i < 7; i++)
                          PlanDayChip(
                            key: ValueKey('day-chip-$i'),
                            label: _weekdayLabels[i],
                            selected: draft.days.contains(i),
                            conflict: conflictDays.contains(i),
                            colors: colors,
                            onTap: () => _ctrl.toggleDay(i),
                          ),
                      ],
                    ),

                    // Conflict banner
                    if (conflicts.isNotEmpty) ...[
                      const SizedBox(height: Spacing.md),
                      Container(
                        padding: const EdgeInsets.all(Spacing.md),
                        decoration: BoxDecoration(
                          color: colors.errorSoft,
                          borderRadius: Radii.all(Radii.md),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final entry in _groupConflicts(conflicts))
                              Text(
                                entry,
                                key: ValueKey('conflict-${entry.hashCode}'),
                                style: CrudoText.body.copyWith(
                                  color: colors.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: Spacing.lg),

                    // Active toggle
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('STATUS', style: CrudoText.label),
                              const SizedBox(height: Spacing.xs),
                              Text(
                                draft.active ? 'Active' : 'Paused',
                                style: CrudoText.body.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colors.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          key: const ValueKey('active-switch'),
                          value: draft.active,
                          onChanged: _ctrl.setActive,
                          activeThumbColor: colors.primary,
                          activeTrackColor: colors.primary.withValues(
                            alpha: 0.5,
                          ),
                          inactiveTrackColor: colors.surfaceHigh,
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacing.lg),

                    // Meals (read-only slots)
                    const Text('MEALS', style: CrudoText.label),
                    const SizedBox(height: Spacing.sm),
                    if (draft.slots.isEmpty)
                      Text(
                        'No meals scheduled',
                        style: CrudoText.body.copyWith(
                          color: colors.onSurfaceMut,
                        ),
                      )
                    else
                      for (final (i, slot) in draft.slots.indexed)
                        _SlotRow(
                          key: ValueKey('slot-row-$i'),
                          slot: slot,
                          colors: colors,
                        ),
                    const SizedBox(height: Spacing.lg),

                    // Delete — visually dimmed when only one plan exists,
                    // but always tappable so the guard toast can fire.
                    Opacity(
                      opacity: canDeletePlan(allPlans) ? 1 : Opacities.disabled,
                      child: SecondaryAction(
                        label: 'Delete plan',
                        onTap: () => _delete(allPlans),
                      ),
                    ),
                    const SizedBox(height: Spacing.md),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: PrimaryCta(
              key: const ValueKey('save-plan'),
              label: 'Save',
              onPressed: draft.canSave ? _save : null,
            ),
          ),
        ),
      ),
    );
  }

  List<String> _groupConflicts(List<WeekdayConflict> conflicts) {
    final groups = <String, List<int>>{};
    for (final c in conflicts) {
      groups.putIfAbsent(c.otherPlanName, () => []).add(c.weekday);
    }
    return [
      for (final entry in groups.entries)
        '${entry.value.map((d) => _weekdayNames[d]).join(', ')} overlaps ${entry.key}',
    ];
  }
}

/// A single day-of-week chip. Conflict state is shown via a tonal shift
/// (error-soft background / error text) — no 1px borders.
class PlanDayChip extends StatelessWidget {
  const PlanDayChip({
    required this.label,
    required this.selected,
    required this.conflict,
    required this.colors,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final bool conflict;
  final CrudoColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = switch ((selected, conflict)) {
      (true, true) => colors.errorSoft,
      (true, false) => colors.primary,
      (false, true) => colors.surfaceHigh,
      (false, false) => colors.surfaceHigh,
    };
    final fg = switch ((selected, conflict)) {
      (true, true) => colors.error,
      (true, false) => colors.surfaceLowest,
      (false, true) => colors.error,
      (false, false) => colors.onSurfaceVar,
    };

    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: Radii.all(Radii.full),
          ),
          child: Text(
            label,
            style: CrudoText.body.copyWith(
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}

/// Read-only slot row: time · meal name · kcal.
class _SlotRow extends StatelessWidget {
  const _SlotRow({required this.slot, required this.colors, super.key});

  final SlotVm slot;
  final CrudoColors colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
      child: Row(
        children: [
          Text(
            mealTimeLabel(slot.time),
            style: CrudoText.body.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.onSurfaceMut,
            ),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Text(
              slot.mealName,
              style: CrudoText.body.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
          ),
          Text(
            '${slot.kcal} kcal',
            style: CrudoText.body.copyWith(color: colors.onSurfaceMut),
          ),
        ],
      ),
    );
  }
}
