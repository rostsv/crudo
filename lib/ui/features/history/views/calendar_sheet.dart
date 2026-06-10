import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:crudo/domain/shared/enums.dart';

import '../../../core/themes/colors.dart';
import '../../../core/themes/dimensions.dart';
import '../../../core/themes/typography.dart';
import '../../../core/widgets/sheet.dart';
import '../../today/view_models/today_providers.dart';
import '../view_models/history_providers.dart';
import 'history_ui.dart';

/// Opens the month Calendar sheet.
Future<void> showCalendarSheet(BuildContext context) =>
    showCrudoSheet<void>(context, builder: (_) => const CalendarSheet());

/// Month calendar sheet with day grid, detail card, and monthly summary.
class CalendarSheet extends ConsumerStatefulWidget {
  const CalendarSheet({super.key});

  @override
  ConsumerState<CalendarSheet> createState() => _CalendarSheetState();
}

class _CalendarSheetState extends ConsumerState<CalendarSheet> {
  static const _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  late DateTime _month;
  DateTime? _selected;

  @override
  void initState() {
    super.initState();
    final today = ref.read(todayProvider);
    _month = DateTime.utc(today.year, today.month, 1);
    _selected = today;
  }

  String _monthYear(DateTime d) => '${_monthNames[d.month - 1]} ${d.year}';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    final gridAsync = ref.watch(monthGridProvider(_month));

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceLowest,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(Radii.lg),
        ),
        boxShadow: Shadows.cloud,
      ),
      padding: const EdgeInsets.all(Spacing.md),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Grabber
            Center(
              child: Container(
                width: 40,
                height: Spacing.xs,
                decoration: BoxDecoration(
                  color: colors.surfaceHighest,
                  borderRadius: Radii.all(Radii.full),
                ),
              ),
            ),
            const SizedBox(height: Spacing.md),
            // Kicker
            Text('LAST 30 DAYS', style: CrudoText.label),
            const SizedBox(height: Spacing.xs),
            // Title row with close button
            Row(
              children: [
                Expanded(
                  child: Text(_monthYear(_month), style: CrudoText.headline),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: colors.onSurface,
                    size: IconSizes.lg,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: Spacing.md),
            // Scrollable body
            Flexible(
              child: gridAsync.when(
                loading: () => const Center(
                  child: SizedBox(
                    height: 200,
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, s) => Text('Error: $e', style: CrudoText.body),
                data: (grid) => SingleChildScrollView(
                  child: _CalendarBody(
                    grid: grid,
                    colors: colors,
                    selected: _selected,
                    onSelect: (date) => setState(() => _selected = date),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarBody extends StatelessWidget {
  const _CalendarBody({
    required this.grid,
    required this.colors,
    required this.selected,
    required this.onSelect,
  });

  final List<CalendarCell?> grid;
  final CrudoColors colors;
  final DateTime? selected;
  final ValueChanged<DateTime> onSelect;

  static const _weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  CalendarCell? _findCell(DateTime date) {
    for (final cell in grid) {
      if (cell != null && cell.date == date) return cell;
    }
    return null;
  }

  int _countState(DayState state) {
    return grid.where((c) => c?.state == state).length;
  }

  @override
  Widget build(BuildContext context) {
    final selectedCell = selected != null ? _findCell(selected!) : null;
    final greenCount = _countState(DayState.green);
    final yellowCount = _countState(DayState.yellow);
    final redCount = _countState(DayState.red);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Weekday headers
        Row(
          children: [
            for (final label in _weekdayLabels)
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: CrudoText.label.copyWith(color: colors.onSurfaceMut),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: Spacing.sm),
        // Day grid
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1,
          children: [
            for (final cell in grid)
              _DayCell(
                cell: cell,
                colors: colors,
                isSelected: cell != null && selected == cell.date,
                onTap: cell?.kind != DayCellKind.future
                    ? () => onSelect(cell!.date)
                    : null,
              ),
          ],
        ),
        const SizedBox(height: Spacing.md),
        // Detail card
        if (selectedCell != null) ...[
          Container(
            padding: const EdgeInsets.all(Spacing.md),
            decoration: BoxDecoration(
              color: colors.surfaceLow,
              borderRadius: Radii.all(Radii.md),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${selectedCell.done}/${selectedCell.total} meals',
                  style: CrudoText.body.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  '${selectedCell.kcal} kcal',
                  style: CrudoText.body.copyWith(color: colors.onSurfaceMut),
                ),
                const SizedBox(height: Spacing.sm),
                AdherenceBar(
                  value: selectedCell.adherencePct / 100.0,
                  color: dayStateColor(selectedCell.state!, colors),
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  '${selectedCell.adherencePct}%',
                  style: CrudoText.bodyLg.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.md),
        ],
        // Monthly summary
        Row(
          children: [
            Expanded(
              child: _SummaryBadge(
                label: 'KEPT',
                count: greenCount,
                textColor: colors.success,
                colors: colors,
              ),
            ),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: _SummaryBadge(
                label: 'PARTIAL',
                count: yellowCount,
                textColor: colors.gold,
                colors: colors,
              ),
            ),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: _SummaryBadge(
                label: 'MISSED',
                count: redCount,
                textColor: colors.error,
                colors: colors,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.md),
        // Legend
        _LegendRow(color: colors.success, label: 'Done'),
        const SizedBox(height: Spacing.xs),
        _LegendRow(color: colors.gold, label: 'Partial'),
        const SizedBox(height: Spacing.xs),
        _LegendRow(color: colors.error, label: 'Missed'),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.cell,
    required this.colors,
    required this.isSelected,
    this.onTap,
  });

  final CalendarCell? cell;
  final CrudoColors colors;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isToday = cell?.kind == DayCellKind.today;
    final hasState = cell?.state != null;
    final bgColor = hasState
        ? dayStateColor(cell!.state!, colors)
        : Colors.transparent;
    final textColor = cell != null ? colors.onSurface : colors.onSurfaceMut;

    Widget child = Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgColor,
        border: isSelected
            ? Border.all(color: colors.onSurface, width: 2)
            : isToday
            ? Border.all(color: colors.onSurfaceMut, width: 2)
            : null,
      ),
      child: Center(
        child: Text(
          cell != null ? '${cell!.date.day}' : '',
          style: CrudoText.body.copyWith(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );

    if (cell?.kind == DayCellKind.future || cell == null) {
      child = Opacity(opacity: 0.35, child: child);
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(padding: const EdgeInsets.all(Spacing.xs), child: child),
    );
  }
}

class _SummaryBadge extends StatelessWidget {
  const _SummaryBadge({
    required this.label,
    required this.count,
    required this.textColor,
    required this.colors,
  });

  final String label;
  final int count;
  final Color textColor;
  final CrudoColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: Spacing.sm,
        horizontal: Spacing.md,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceLow,
        borderRadius: Radii.all(Radii.sm),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            key: ValueKey('summary-$label'),
            style: CrudoText.title.copyWith(color: textColor),
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            label,
            style: CrudoText.label.copyWith(color: colors.onSurfaceMut),
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;

    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: Spacing.sm),
        Text(label, style: CrudoText.body.copyWith(color: colors.onSurfaceVar)),
      ],
    );
  }
}
