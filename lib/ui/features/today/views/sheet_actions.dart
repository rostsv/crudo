import 'package:flutter/material.dart';

import '../../../core/themes/colors.dart';
import '../../../core/themes/dimensions.dart';
import '../../../core/themes/typography.dart';
import '../../../core/widgets/toast.dart';

/// Runs a day-controller op from a sheet, popping on success when [pop] is
/// set. A StateError (domain guard rejection) surfaces as [guardMessage] in
/// a warn toast — the single place the read-only/guard error UX is defined.
Future<void> runDayOp(
  BuildContext context,
  Future<void> Function() op, {
  required String guardMessage,
  bool pop = false,
}) async {
  try {
    await op();
    if (pop && context.mounted) Navigator.of(context).pop();
  } on StateError {
    if (context.mounted) {
      showCrudoToast(context, guardMessage, kind: ToastKind.warn);
    }
  }
}

/// Tonal pill action for sheet footers (Skip / Snooze / Cancel) — the
/// secondary counterpart to PrimaryCta.
class SecondaryAction extends StatelessWidget {
  const SecondaryAction({
    required this.label,
    required this.onTap,
    this.enabled = true,
    super.key,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    return Opacity(
      opacity: enabled ? 1 : Opacities.disabled,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: Spacing.md),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.surfaceLow,
            borderRadius: Radii.all(Radii.full),
          ),
          child: Text(
            label,
            style: CrudoText.body.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
