import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/themes/colors.dart';
import '../../../core/themes/dimensions.dart';
import '../../../core/themes/typography.dart';

/// "Calculated kcal" card with the optional override input and the
/// mismatch banner (errorText != null → banner shown; SAVE gating happens
/// in the form, not here).
class KcalCard extends StatelessWidget {
  const KcalCard({
    required this.calculated,
    required this.overrideController,
    required this.onOverrideChanged,
    this.errorText,
    super.key,
  });

  final double calculated;
  final TextEditingController overrideController;
  final ValueChanged<String> onOverrideChanged; // raw text; form parses
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceLow,
        borderRadius: Radii.all(Radii.md),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CALCULATED KCAL', style: CrudoText.label),
                  Text('${calculated.round()}', style: CrudoText.displaySm),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('OVERRIDE (OPTIONAL)', style: CrudoText.label),
                  SizedBox(
                    width: 100, // matches prototype input width; FittedBox ok
                    child: TextField(
                      key: const ValueKey('kcal-override'),
                      controller: overrideController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        // Strip negatives and non-numeric chars; comma
                        // decimal locales are normalised in the onChanged
                        // callback via parseGrams.
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      textAlign: TextAlign.right,
                      style: CrudoText.displaySm,
                      // Deliberately NOT softInputDecoration: this field lives
                      // inside a filled card and uses an underline/borderless
                      // style to blend with the card surface.
                      decoration: InputDecoration(
                        hintText: 'auto',
                        hintStyle: CrudoText.displaySm.copyWith(
                          color: colors.onSurfaceMut,
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: Spacing.xs,
                        ),
                        border: const UnderlineInputBorder(
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: onOverrideChanged,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (errorText != null) ...[
            const SizedBox(height: Spacing.sm),
            Container(
              key: const ValueKey('kcal-mismatch'),
              padding: const EdgeInsets.all(Spacing.sm),
              decoration: BoxDecoration(
                color: colors.errorSoft,
                borderRadius: Radii.all(Radii.sm),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: IconSizes.md,
                    color: colors.error,
                  ),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mismatch',
                          style: CrudoText.body.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colors.error,
                          ),
                        ),
                        Text(errorText!, style: CrudoText.body),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
