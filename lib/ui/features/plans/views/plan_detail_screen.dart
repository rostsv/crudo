import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/services/id_generator.dart';
import '../../../../domain/meal/meal_template.dart';
import '../../../../domain/plan/plan_template.dart';
import '../../../../domain/services/plan_scheduling.dart';
import '../../../../domain/shared/meal_time.dart';
import '../../../core/formatting.dart';
import '../../../core/themes/colors.dart';
import '../../../core/themes/dimensions.dart';
import '../../../core/themes/typography.dart';
import '../../../core/widgets/macro_total_card.dart';
import '../../../core/widgets/primary_cta.dart';
import '../../../core/widgets/sheet.dart';
import '../../../core/widgets/sheet_actions.dart';
import '../../meals/views/formatting.dart' show mealTagLabels;
import '../view_models/plan_draft.dart';
import '../view_models/plan_detail_controller.dart';
import 'meal_picker_sheet.dart';
import 'plan_view_screen.dart' show PlanSlotSheet;

/// Outcome of the save-time collision sheet.
enum _ConflictChoice { resolve, paused }

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

  /// Set once Save is attempted with missing fields; drives the inline errors.
  bool _showErrors = false;

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
    final draft = ref
        .read(planDetailControllerProvider(widget.planId))
        .requireValue;
    // Field validation surfaces inline (name + at least one meal).
    if (draft.name.trim().isEmpty || draft.slots.isEmpty) {
      if (!_showErrors) setState(() => _showErrors = true);
      return;
    }

    var out = await _ctrl.save();
    if (!mounted) return;
    if (!out.committed) {
      // Weekday collision — resolve (steal days) or save paused.
      final choice = await _resolveConflict(out.conflicts);
      if (!mounted || choice == null) return;
      if (choice == _ConflictChoice.resolve) {
        out = await _ctrl.save(override: true);
      } else {
        // Save as paused: a dormant plan claims no days, so it never clashes.
        _ctrl.setActive(false);
        out = await _ctrl.save();
      }
      if (!mounted) return;
    }
    if (out.uncovered.isNotEmpty) {
      final leave = await _confirmUncovered(out.uncovered);
      if (!mounted || leave != true) return;
    }
    if (mounted) context.pop();
  }

  /// Save-time collision sheet: lists which plans lose which days, then offers
  /// to resolve (steal the days) or save the plan paused. Returns null on
  /// cancel (tap-outside or the Cancel button).
  Future<_ConflictChoice?> _resolveConflict(List<WeekdayConflict> conflicts) {
    final groups = <String, (String name, List<int> days)>{};
    for (final c in conflicts) {
      final entry = groups.putIfAbsent(
        c.otherPlanId,
        () => (c.otherPlanName, <int>[]),
      );
      entry.$2.add(c.weekday);
    }

    return showCrudoSheet<_ConflictChoice>(
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
                  '${entry.$2.map((d) => _weekdayNames[d]).join(', ')}',
                  style: CrudoText.body,
                ),
              ),
            const SizedBox(height: Spacing.sm),
            SheetActionRow(
              icon: Icons.sync_alt,
              label: 'Resolve conflict',
              onTap: () => Navigator.of(sheetCtx).pop(_ConflictChoice.resolve),
            ),
            SheetActionRow(
              icon: Icons.pause_circle_outline,
              label: 'Save as paused',
              onTap: () => Navigator.of(sheetCtx).pop(_ConflictChoice.paused),
            ),
          ],
        ),
        cta: SecondaryAction(
          label: 'Cancel',
          onTap: () => Navigator.of(sheetCtx).pop(),
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
    var picked = DateTime(2020, 1, 1, current.hour, current.minute);
    final result = await showCrudoSheet<MealTime>(
      context,
      builder: (sheetCtx) => SheetScaffold(
        title: 'Meal time',
        body: SizedBox(
          height: 216, // Cupertino wheel intrinsic height (8px grid)
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.time,
            use24hFormat: MediaQuery.alwaysUse24HourFormatOf(sheetCtx),
            initialDateTime: picked,
            onDateTimeChanged: (dt) => picked = dt,
          ),
        ),
        cta: PrimaryCta(
          label: 'Done',
          onPressed: () => Navigator.of(
            sheetCtx,
          ).pop(MealTime(picked.hour * 60 + picked.minute)),
        ),
      ),
    );
    if (result != null && mounted) _ctrl.setSlotTime(index, result);
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
    final nameError = _showErrors && draft.name.trim().isEmpty;
    final mealsError = _showErrors && draft.slots.isEmpty;

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
                        _isEditMode ? 'Edit plan' : 'New plan',
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
                      // Name field (active/pause lives on the Plans card).
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
                      if (nameError) ...[
                        const SizedBox(height: Spacing.xs),
                        _FieldError(text: 'Add a plan name', colors: colors),
                      ],
                      const SizedBox(height: Spacing.lg),

                      // DAILY TARGET (tonal) with the editable weekday strip as
                      // a full-width footer. Weekday collisions are validated on
                      // Save, not while picking days.
                      MacroTotalCard(
                        macros: _ctrl.totalMacros,
                        label: 'DAILY TARGET',
                        footerBelow: _EditableWeekStrip(
                          days: draft.days,
                          labels: _weekdayLabels,
                          colors: colors,
                          onToggle: _ctrl.toggleDay,
                        ),
                      ),
                      const SizedBox(height: Spacing.lg),

                      // Meal slots header (count on the right, like the viewer).
                      Row(
                        children: [
                          const Text('MEAL SLOTS', style: CrudoText.label),
                          const Spacer(),
                          Text(
                            '${draft.slots.length} '
                            '${draft.slots.length == 1 ? 'SLOT' : 'SLOTS'}',
                            style: CrudoText.label.copyWith(
                              color: colors.onSurfaceMut,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Spacing.sm),
                      if (draft.slots.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: Spacing.sm),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'No meals scheduled',
                                style: CrudoText.body.copyWith(
                                  color: colors.onSurfaceMut,
                                ),
                              ),
                              if (mealsError) ...[
                                const SizedBox(height: Spacing.xs),
                                _FieldError(
                                  text: 'Add at least one meal',
                                  colors: colors,
                                ),
                              ],
                            ],
                          ),
                        )
                      else
                        ReorderableListView.builder(
                          shrinkWrap: true,
                          buildDefaultDragHandles: false,
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
                              subtitle: _slotSubtitle(s),
                              zebra: i.isOdd,
                              colors: colors,
                              onTapTime: () => _editTime(i, s.time),
                              onTapInfo: () => showCrudoSheet<void>(
                                context,
                                builder: (_) =>
                                    PlanSlotSheet(slot: _ctrl.slotView(s)),
                              ),
                              onRemove: () => _ctrl.removeSlot(i),
                            );
                          },
                        ),
                      const SizedBox(height: Spacing.sm),

                      // ADD MEAL — centered pill button.
                      Semantics(
                        button: true,
                        label: 'Add meal',
                        child: GestureDetector(
                          key: const ValueKey('add-meal'),
                          onTap: _addMeals,
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: Spacing.md,
                            ),
                            decoration: BoxDecoration(
                              color: colors.surfaceLow,
                              borderRadius: Radii.all(Radii.md),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add,
                                  size: IconSizes.sm,
                                  color: colors.primary,
                                ),
                                const SizedBox(width: Spacing.sm),
                                Text(
                                  'ADD MEAL',
                                  style: CrudoText.labelMd.copyWith(
                                    color: colors.primary,
                                  ),
                                ),
                              ],
                            ),
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
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: PrimaryCta(
              key: const ValueKey('save-plan'),
              label: 'Save',
              onPressed: _save,
            ),
          ),
        ),
      ),
    );
  }

  /// Slot row subtitle: `tag · kcal` (matching the viewer) or just `kcal`.
  String _slotSubtitle(PlanSlotDraft s) {
    final tpl = _ctrl.templateById(s.mealTemplateId);
    final tag = tpl == null || tpl.tags.isEmpty
        ? ''
        : tpl.tags.map((t) => mealTagLabels[t]).join(' · ');
    return tag.isEmpty ? '${s.kcal} kcal' : '$tag · ${s.kcal} kcal';
  }
}

/// Inline validation message (warn icon + red text) shown under a field after
/// a failed Save attempt.
class _FieldError extends StatelessWidget {
  const _FieldError({required this.text, required this.colors});

  final String text;
  final CrudoColors colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.error_outline, size: IconSizes.sm, color: colors.error),
        const SizedBox(width: Spacing.xs),
        Text(text, style: CrudoText.labelMd.copyWith(color: colors.error)),
      ],
    );
  }
}

/// Editable weekday strip for the DAILY TARGET footer: `REPEATS ON` label,
/// a `TAP TO CHANGE` hint, and 7 tappable day chips. Any day is selectable —
/// weekday collisions are resolved on Save, not here.
class _EditableWeekStrip extends StatelessWidget {
  const _EditableWeekStrip({
    required this.days,
    required this.labels,
    required this.colors,
    required this.onToggle,
  });

  final List<int> days;
  final List<String> labels;
  final CrudoColors colors;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('REPEATS ON', style: CrudoText.label),
            const Spacer(),
            Text(
              'TAP TO CHANGE',
              style: CrudoText.label.copyWith(color: colors.onSurfaceMut),
            ),
          ],
        ),
        const SizedBox(height: Spacing.sm),
        Row(
          children: [
            for (var i = 0; i < 7; i++) ...[
              if (i > 0) const SizedBox(width: Spacing.xs),
              Expanded(
                child: PlanDayChip(
                  key: ValueKey('day-chip-$i'),
                  label: labels[i],
                  selected: days.contains(i),
                  colors: colors,
                  onTap: () => onToggle(i),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Editable slot row: drag grip · tappable time · name + subtitle (tap opens
/// the read-only quick-info sheet) · remove. Zebra rows shift surface tone.
class _EditableSlotRow extends StatelessWidget {
  const _EditableSlotRow({
    required this.index,
    required this.slot,
    required this.subtitle,
    required this.zebra,
    required this.colors,
    required this.onTapTime,
    required this.onTapInfo,
    required this.onRemove,
    super.key,
  });

  final int index;
  final PlanSlotDraft slot;
  final String subtitle;
  final bool zebra;
  final CrudoColors colors;
  final VoidCallback onTapTime;
  final VoidCallback onTapInfo;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: Spacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.sm,
        vertical: Spacing.sm,
      ),
      decoration: BoxDecoration(
        color: zebra ? colors.surfaceLow : colors.surfaceLowest,
        borderRadius: Radii.all(Radii.md),
      ),
      child: Row(
        children: [
          // Drag grip (⠿) at the far left.
          ReorderableDragStartListener(
            index: index,
            child: Padding(
              padding: const EdgeInsets.only(right: Spacing.sm),
              child: Icon(
                Icons.drag_indicator,
                size: IconSizes.md,
                color: colors.onSurfaceMut,
              ),
            ),
          ),
          // Time — tappable text, no background.
          GestureDetector(
            key: ValueKey('slot-time-$index'),
            onTap: onTapTime,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
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
          // Name + subtitle — tap opens the read-only quick-info sheet.
          Expanded(
            child: GestureDetector(
              onTap: onTapInfo,
              behavior: HitTestBehavior.opaque,
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
          ),
          // Remove
          GestureDetector(
            key: ValueKey('slot-remove-$index'),
            onTap: onRemove,
            behavior: HitTestBehavior.opaque,
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

/// A single day-of-week chip. Selected = primary fill / white text; otherwise
/// a tonal surface shift — no 1px borders. Collisions are surfaced on Save.
class PlanDayChip extends StatelessWidget {
  const PlanDayChip({
    required this.label,
    required this.selected,
    required this.colors,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final CrudoColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? colors.primary : colors.surfaceHigh;
    final fg = selected ? colors.surfaceLowest : colors.onSurfaceVar;

    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 32, // chip height (width > height), 4px grid
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: Radii.all(Radii.sm),
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
      ),
    );
  }
}
