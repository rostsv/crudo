import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/services/id_generator.dart';
import '../../../../domain/meal/meal_template.dart';
import '../../../../domain/plan/plan_template.dart';
import '../../../../domain/services/plan_scheduling.dart';
import '../../../../domain/shared/meal_time.dart';
import '../../../../domain/shared/enums.dart';
import '../../../../domain/shared/macros.dart';
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
import 'meal_picker_sheet.dart';

/// S11 unified plan create/edit screen. Null [planId] = create mode.
/// [seed] (create mode) pre-populates the draft from an in-memory copy.
/// Edit mode: name, weekdays, active toggle, delete, duplicate.
/// Both modes: editable slots (add/retime/reorder/remove), macro preview.
class PlanDetailScreen extends ConsumerWidget {
  const PlanDetailScreen({required this.planId, this.seed, super.key});

  final String? planId; // null = create
  final PlanTemplate? seed; // in-memory duplicate seed

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draftAsync = ref.watch(planDetailControllerProvider(planId));
    return draftAsync.when(
      data: (draft) =>
          _PlanDetailForm(planId: planId, seed: seed, draft: draft),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        body: Center(
          child: Text(
            e is StateError ? 'Plan not found' : 'Something went wrong',
            style: CrudoText.body,
          ),
        ),
      ),
    );
  }
}

class _PlanDetailForm extends ConsumerStatefulWidget {
  const _PlanDetailForm({
    required this.planId,
    required this.seed,
    required this.draft,
  });

  final String? planId;
  final PlanTemplate? seed;
  final PlanDraft draft;

  @override
  ConsumerState<_PlanDetailForm> createState() => _PlanDetailFormState();
}

class _PlanDetailFormState extends ConsumerState<_PlanDetailForm> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.seed?.name ?? widget.draft.name,
    );
    // Seed once: if we're in create mode with a seed, populate the draft.
    if (widget.planId == null && widget.seed != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref
            .read(planDetailControllerProvider(null).notifier)
            .seedFrom(widget.seed!);
      });
    }
  }

  @override
  void didUpdateWidget(covariant _PlanDetailForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep the text field in sync when the provider emits a new draft
    // (e.g. after undo or seed).
    if (oldWidget.draft.name != widget.draft.name &&
        _nameController.text != widget.draft.name) {
      _nameController.text = widget.draft.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  PlanDetailController get _ctrl =>
      ref.read(planDetailControllerProvider(widget.planId).notifier);

  bool get _isEditMode => widget.planId != null;

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
      showCrudoToast(
        context,
        "Can't delete your only plan",
        kind: ToastKind.warn,
      );
    }
  }

  Future<void> _duplicate() async {
    final allPlans = ref.read(planTemplatesProvider).value ?? const [];
    final src = allPlans.where((p) => p.id == widget.planId).firstOrNull;
    if (src == null) return;
    if (!mounted) return;
    // Clone: clears weekdays, names it "{src} copy", re-mints slot ids so the
    // copy never aliases the original. Persisted only if the seeded editor saves.
    final cloned = clonePlan(src, newId: ref.read(idGeneratorProvider).newId);
    await context.push('/plans/new', extra: cloned);
  }

  Future<bool?> _confirmOverride(List<WeekdayConflict> conflicts) {
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

  Future<void> _editTime(int index, MealTime current) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
    );
    if (picked != null && mounted) {
      _ctrl.setSlotTime(index, MealTime(picked.hour * 60 + picked.minute));
    }
  }

  Future<void> _addMeals() async {
    final ctrl = _ctrl;
    final res = await showMealPickerSheet(context);
    if (res == null || !mounted) return;

    if (res.createNew) {
      // Create new meal → navigate to builder, wait for saved template.
      final t = await context.push<MealTemplate>('/meal-templates/new');
      if (t != null && mounted) {
        ctrl.addSlotFromTemplate(t);
      }
    } else if (res.duplicateTemplateId != null) {
      // Clone an existing meal.
      final src = ctrl.templateById(res.duplicateTemplateId!);
      if (src != null) {
        // Clone ("{src} copy") then seed the builder to tweak; persisted only
        // if the builder saves. No orphan on cancel.
        final cloned = cloneMeal(
          src,
          newId: ref.read(idGeneratorProvider).newId,
        );
        final t = await context.push<MealTemplate>(
          '/meal-templates/new',
          extra: cloned,
        );
        if (t != null && mounted) {
          ctrl.addSlotFromTemplate(t);
        }
      }
    } else {
      // Multi-select: add each selected (already-cached) template.
      for (final id in res.selectedTemplateIds ?? const <String>[]) {
        ctrl.addSlot(id);
      }
    }
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
      forPlanId: widget.planId ?? '',
      proposedDays: draft.claimedDays,
    );
    final conflictDays = {for (final c in conflicts) c.weekday};
    final goal = ref.watch(profileProvider).value?.prefs.goal;

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
                      onPressed: () => Navigator.maybePop(context),
                      icon: Icon(
                        Icons.arrow_back,
                        size: IconSizes.lg,
                        color: colors.onSurface,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _isEditMode
                            ? draft.name
                            : (widget.seed?.name ?? 'New plan'),
                        style: CrudoText.headlineSm,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

                      // Macro preview card
                      _MacroPreviewCard(
                        macros: _ctrl.totalMacros,
                        goal: goal,
                        colors: colors,
                      ),
                      const SizedBox(height: Spacing.lg),

                      // Meals (editable slots)
                      const Text('MEALS', style: CrudoText.label),
                      const SizedBox(height: Spacing.sm),
                      if (draft.slots.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: Spacing.sm),
                          child: Text(
                            'No meals scheduled',
                            style: CrudoText.body.copyWith(
                              color: colors.onSurfaceMut,
                            ),
                          ),
                        )
                      else
                        ReorderableListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: draft.slots.length,
                          onReorder: (oldI, newI) {
                            final to = newI > oldI ? newI - 1 : newI;
                            _ctrl.reorderSlots(oldI, to);
                          },
                          itemBuilder: (context, i) {
                            final s = draft.slots[i];
                            return _EditableSlotRow(
                              key: ValueKey(s.id),
                              index: i,
                              slot: s,
                              colors: colors,
                              onTapTime: () => _editTime(i, s.time),
                              onRemove: () => _ctrl.removeSlot(i),
                            );
                          },
                        ),
                      const SizedBox(height: Spacing.sm),

                      // ADD MEAL button
                      TextButton.icon(
                        key: const ValueKey('add-meal'),
                        onPressed: _addMeals,
                        icon: const Icon(
                          Icons.add_circle_outline,
                          size: IconSizes.md,
                        ),
                        label: Text(
                          'ADD MEAL',
                          style: CrudoText.body.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: Spacing.lg),

                      // Edit-mode only actions
                      if (_isEditMode) ...[
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

                        // Duplicate
                        SecondaryAction(
                          label: 'Duplicate',
                          key: const ValueKey('duplicate-plan'),
                          onTap: _duplicate,
                        ),
                        const SizedBox(height: Spacing.lg),

                        // Delete
                        Opacity(
                          opacity: canDeletePlan(allPlans)
                              ? 1
                              : Opacities.disabled,
                          child: SecondaryAction(
                            label: 'Delete plan',
                            onTap: () => _delete(allPlans),
                          ),
                        ),
                        const SizedBox(height: Spacing.md),
                      ],
                    ],
                  ),
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

/// Macro preview card — gradient, shows summed P/C/F/kcal + goal label.
class _MacroPreviewCard extends StatelessWidget {
  const _MacroPreviewCard({
    required this.macros,
    required this.goal,
    required this.colors,
  });

  final Macros macros;
  final Goal? goal;
  final CrudoColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [CrudoPalette.primary, CrudoPalette.primarySoft],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: Radii.all(Radii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${macros.kcal.round()}',
                style: CrudoText.headline.copyWith(color: colors.surfaceLowest),
              ),
              const SizedBox(width: Spacing.sm),
              Text(
                'KCAL',
                style: CrudoText.label.copyWith(
                  color: colors.surfaceLowest.withValues(alpha: 0.8),
                ),
              ),
              const Spacer(),
              if (goal != null)
                Text(
                  goal!.name.toUpperCase(),
                  style: CrudoText.label.copyWith(
                    color: colors.surfaceLowest.withValues(alpha: 0.8),
                  ),
                ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          Row(
            children: [
              _MacroLabel(
                label: 'P',
                value: macros.protein.round(),
                color: colors.surfaceLowest,
              ),
              const SizedBox(width: Spacing.md),
              _MacroLabel(
                label: 'C',
                value: macros.carbs.round(),
                color: colors.surfaceLowest,
              ),
              const SizedBox(width: Spacing.md),
              _MacroLabel(
                label: 'F',
                value: macros.fats.round(),
                color: colors.surfaceLowest,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroLabel extends StatelessWidget {
  const _MacroLabel({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: CrudoText.body.copyWith(
            fontWeight: FontWeight.w700,
            color: color.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(width: Spacing.xs),
        Text(
          '$value',
          style: CrudoText.body.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Editable slot row: tappable time chip · meal name · kcal · drag handle · remove.
class _EditableSlotRow extends StatelessWidget {
  const _EditableSlotRow({
    required this.index,
    required this.slot,
    required this.colors,
    required this.onTapTime,
    required this.onRemove,
    super.key,
  });

  final int index;
  final PlanSlotDraft slot;
  final CrudoColors colors;
  final VoidCallback onTapTime;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
      child: Row(
        children: [
          // Time chip — tappable
          GestureDetector(
            key: ValueKey('slot-time-$index'),
            onTap: onTapTime,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.sm,
                vertical: Spacing.xs,
              ),
              decoration: BoxDecoration(
                color: colors.surfaceHigh,
                borderRadius: Radii.all(Radii.sm),
              ),
              child: Text(
                mealTimeLabel(slot.time),
                style: CrudoText.body.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: Spacing.sm),
          // Meal name + kcal
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
                ),
                Text(
                  '${slot.kcal} kcal',
                  style: CrudoText.body.copyWith(color: colors.onSurfaceMut),
                ),
              ],
            ),
          ),
          // Drag handle
          ReorderableDragStartListener(
            index: index,
            child: Padding(
              padding: const EdgeInsets.all(Spacing.sm),
              child: Icon(
                Icons.drag_handle,
                size: IconSizes.md,
                color: colors.onSurfaceVar,
              ),
            ),
          ),
          // Remove
          GestureDetector(
            key: ValueKey('slot-remove-$index'),
            onTap: onRemove,
            child: Padding(
              padding: const EdgeInsets.all(Spacing.sm),
              child: Icon(
                Icons.close_rounded,
                size: IconSizes.md,
                color: colors.onSurfaceMut,
              ),
            ),
          ),
        ],
      ),
    );
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
