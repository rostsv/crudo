import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/themes/colors.dart';
import '../../../core/themes/dimensions.dart';
import '../../../core/themes/input_decoration.dart';
import '../../../core/themes/typography.dart';
import 'formatting.dart';

/// Labeled per-100g macro input with a colored accent bar (prototype
/// AddCustomFoodScreen rows). Accent bar 8×36 — recorded in
/// design_system.md §5.
class MacroField extends StatelessWidget {
  const MacroField({
    required this.label,
    required this.accent,
    required this.controller,
    required this.onChanged,
    super.key,
  });

  static const _barWidth = 8.0; // §5: macro accent bar
  static const _barHeight = 36.0;

  final String label; // 'PROTEIN' etc — rendered CrudoText.label
  final Color accent;
  final TextEditingController controller;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    return Row(
      children: [
        Container(
          width: _barWidth,
          height: _barHeight,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: Radii.all(Radii.full),
          ),
        ),
        const SizedBox(width: Spacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: CrudoText.label),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  // Strip everything except digits, period, and comma.
                  // This prevents negatives being typed/pasted; the controller
                  // also clamps to 0 as defense in depth.
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                style: CrudoText.headlineSm,
                decoration: softInputDecoration(
                  colors,
                  hint: '0',
                  hintStyle: CrudoText.headlineSm.copyWith(
                    color: colors.onSurfaceMut,
                  ),
                  isDense: true,
                ),
                onChanged: (s) => onChanged(parseGrams(s) ?? 0),
              ),
            ],
          ),
        ),
        Text('g', style: CrudoText.body.copyWith(color: colors.onSurfaceMut)),
      ],
    );
  }
}
