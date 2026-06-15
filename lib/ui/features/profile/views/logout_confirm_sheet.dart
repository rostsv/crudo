import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/themes/colors.dart';
import '../../../core/themes/dimensions.dart' as dim;
import '../../../core/themes/typography.dart';
import '../../../core/widgets/sheet.dart';
import '../../../core/widgets/toast.dart';
import '../../profile/view_models/profile_controller.dart';

Future<void> showLogoutConfirmSheet(BuildContext context) =>
    showCrudoSheet<void>(context, builder: (_) => const _LogoutConfirmSheet());

class _LogoutConfirmSheet extends ConsumerWidget {
  const _LogoutConfirmSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<CrudoColors>()!;

    return SheetScaffold(
      title: 'Sign out?',
      body: Text(
        'You can sign back in anytime. Your local data stays on this device.',
        style: CrudoText.body,
      ),
      cta: Row(
        children: [
          // Secondary Cancel button
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: dim.Spacing.md),
                decoration: BoxDecoration(
                  color: colors.surfaceHigh,
                  borderRadius: dim.Radii.all(dim.Radii.full),
                ),
                child: Text(
                  'Cancel',
                  textAlign: TextAlign.center,
                  style: CrudoText.title.copyWith(color: colors.onSurface),
                ),
              ),
            ),
          ),
          const SizedBox(width: dim.Spacing.md),
          // Destructive Sign out button
          Expanded(
            child: GestureDetector(
              onTap: () async {
                await ref.read(profileControllerProvider.notifier).signOut();
                if (context.mounted) {
                  Navigator.of(context).pop();
                  showCrudoToast(context, 'Signed out');
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: dim.Spacing.md),
                decoration: BoxDecoration(
                  color: colors.error,
                  borderRadius: dim.Radii.all(dim.Radii.full),
                ),
                child: Text(
                  'Sign out',
                  textAlign: TextAlign.center,
                  style: CrudoText.title.copyWith(color: colors.surfaceLowest),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
