import 'package:flutter/material.dart';

import '../themes/dimensions.dart';
import '../themes/typography.dart';
import 'primary_cta.dart';
import 'sheet.dart';
import 'sheet_actions.dart';

/// Confirms an action that takes a done meal back to not-done.
/// Returns `true` when the user chooses the primary action, `false` for Cancel,
/// and `null` if the sheet is dismissed by other means.
Future<bool?> showDoneMealConfirmSheet(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
}) {
  return showCrudoSheet<bool>(
    context,
    builder: (sheetCtx) => SheetScaffold(
      title: title,
      body: Text(body, style: CrudoText.body),
      cta: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PrimaryCta(
            label: confirmLabel,
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

/// Confirms undoing a done meal from the Today status circle.
Future<bool?> showUndoMealConfirmSheet(BuildContext context) =>
    showDoneMealConfirmSheet(
      context,
      title: 'Undo this meal?',
      body: "It's marked done. Undoing removes it from today's progress.",
      confirmLabel: 'Undo',
    );

/// Confirms updating a done meal from the meal detail screen.
Future<bool?> showModifyDoneMealConfirmSheet(BuildContext context) =>
    showDoneMealConfirmSheet(
      context,
      title: 'Modify this meal?',
      body:
          "This meal was already logged. Changes can impact today's progress.",
      confirmLabel: 'Modify',
    );
