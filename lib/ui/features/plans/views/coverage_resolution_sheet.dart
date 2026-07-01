import 'package:flutter/material.dart';

import '../../../../domain/plan/plan_template.dart';
import '../../../core/themes/colors.dart';
import '../../../core/themes/dimensions.dart';
import '../../../core/themes/typography.dart';
import '../../../core/widgets/sheet.dart';
import '../../../core/widgets/sheet_actions.dart';

/// User's pick from the coverage-resolution sheet. [assignToId] non-null →
/// absorb the orphaned days into that plan; [create] → open a new plan seeded
/// with the days. Sheet dismissed → null (cancel).
typedef CoverageChoice = ({bool create, String? assignToId});

const _weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// Shown when pausing/deleting a plan would leave weekdays uncovered. Lists the
/// orphaned days, offers to fold them into an existing active plan or spin up a
/// new one, and Cancel. Returns the [CoverageChoice] or null on cancel.
Future<CoverageChoice?> showCoverageResolutionSheet(
  BuildContext context, {
  required List<int> orphanedDays,
  required List<PlanTemplate> candidates,
}) {
  final label = orphanedDays.map((d) => _weekdayNames[d]).join(', ');
  return showCrudoSheet<CoverageChoice>(
    context,
    builder: (sheetCtx) {
      final colors = Theme.of(sheetCtx).extension<CrudoColors>()!;
      return SheetScaffold(
        title: '$label ${orphanedDays.length == 1 ? 'needs' : 'need'} a plan',
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Keep every weekday covered — move these days to another plan '
              'or create one for them.',
              style: CrudoText.body.copyWith(color: colors.onSurfaceVar),
            ),
            const SizedBox(height: Spacing.md),
            for (final p in candidates)
              SheetActionRow(
                key: ValueKey('assign-${p.id}'),
                icon: Icons.playlist_add,
                label: 'Add to ${p.name}',
                onTap: () => Navigator.of(
                  sheetCtx,
                ).pop((create: false, assignToId: p.id)),
              ),
            SheetActionRow(
              key: const ValueKey('coverage-create'),
              icon: Icons.add_circle_outline,
              label: 'Create a plan for them',
              onTap: () =>
                  Navigator.of(sheetCtx).pop((create: true, assignToId: null)),
            ),
          ],
        ),
        cta: SecondaryAction(
          label: 'Cancel',
          onTap: () => Navigator.of(sheetCtx).pop(),
        ),
      );
    },
  );
}
