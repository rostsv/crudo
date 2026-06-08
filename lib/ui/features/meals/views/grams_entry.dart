import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../domain/meal/food_snapshot.dart';
import '../../../../domain/shared/grams.dart';
import '../../../core/themes/colors.dart';
import '../../../core/themes/dimensions.dart';
import '../../../core/themes/input_decoration.dart';
import '../../../core/themes/typography.dart';
import '../../../core/widgets/primary_cta.dart';
import '../../../core/widgets/sheet.dart';
import '../../../core/formatting.dart' show gramsText, parseGrams;

/// The canned portion presets (grams) — meal.jsx AddIngredientScreen.
const gramsPresets = <double>[50, 100, 150, 200, 250];

/// Quantity entry with presets and a live macro preview. Two consumers:
/// the add-ingredient picker's stage 2 (baseline = the picked food at 100g)
/// and the editor's grams re-edit sheet (baseline = the existing item).
/// Preview scales linearly from [baseline] (FoodSnapshot.scaledTo); the
/// parent owns the current value via [onChanged] (null = invalid input).
class GramsEntry extends StatefulWidget {
  const GramsEntry({
    required this.baseline,
    required this.initialGrams,
    required this.onChanged,
    super.key,
  });

  final FoodSnapshot baseline;
  final double initialGrams;
  final ValueChanged<double?> onChanged;

  @override
  State<GramsEntry> createState() => _GramsEntryState();
}

class _GramsEntryState extends State<GramsEntry> {
  late final _controller = TextEditingController(
    text: gramsText(widget.initialGrams),
  );
  late double? _grams = widget.initialGrams;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _set(double? g) {
    setState(() => _grams = g);
    widget.onChanged(g);
  }

  void _pickPreset(double g) {
    _controller.text = gramsText(g);
    _set(g);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CrudoColors>()!;
    final g = _grams;
    final preview = (g != null && g > 0)
        ? widget.baseline.scaledTo(Grams(g))
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('QUANTITY', style: CrudoText.label),
        const SizedBox(height: Spacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                key: const ValueKey('grams-input'),
                controller: _controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                ],
                style: CrudoText.stat,
                decoration: softInputDecoration(colors, hint: '100'),
                onChanged: (s) {
                  final v = parseGrams(s);
                  _set(v != null && v > 0 ? v : null);
                },
              ),
            ),
            const SizedBox(width: Spacing.sm),
            Padding(
              padding: const EdgeInsets.only(bottom: Spacing.md),
              child: Text(
                'grams',
                style: CrudoText.title.copyWith(color: colors.onSurfaceMut),
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.md),
        Wrap(
          spacing: Spacing.sm,
          runSpacing: Spacing.sm,
          children: [
            for (final p in gramsPresets)
              _PresetPill(
                key: ValueKey('grams-preset-${p.round()}'),
                grams: p,
                selected: _grams == p,
                colors: colors,
                onTap: () => _pickPreset(p),
              ),
          ],
        ),
        const SizedBox(height: Spacing.lg),
        Container(
          padding: const EdgeInsets.all(Spacing.md),
          decoration: BoxDecoration(
            color: colors.surfaceLow,
            borderRadius: Radii.all(Radii.lg),
          ),
          child: preview == null
              ? Text(
                  'Enter a quantity above zero.',
                  key: const ValueKey('grams-invalid'),
                  style: CrudoText.body.copyWith(color: colors.onSurfaceMut),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FOR ${gramsText(preview.grams.value).toUpperCase()}G',
                      style: CrudoText.label,
                    ),
                    const SizedBox(height: Spacing.xs),
                    Text(
                      '${preview.kcal.round()} kcal',
                      key: const ValueKey('grams-preview-kcal'),
                      style: CrudoText.displaySm,
                    ),
                    const SizedBox(height: Spacing.sm),
                    Text(
                      'P ${preview.protein.round()}g'
                      '  C ${preview.carbs.round()}g'
                      '  F ${preview.fats.round()}g',
                      style: CrudoText.body.copyWith(
                        color: colors.onSurfaceMut,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _PresetPill extends StatelessWidget {
  const _PresetPill({
    required this.grams,
    required this.selected,
    required this.colors,
    required this.onTap,
    super.key,
  });

  final double grams;
  final bool selected;
  final CrudoColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.sm,
          ),
          decoration: BoxDecoration(
            color: selected ? colors.primaryContainer : colors.surfaceLow,
            borderRadius: Radii.all(Radii.full),
          ),
          child: Text(
            '${grams.round()}g',
            style: CrudoText.labelMd.copyWith(
              color: selected ? colors.primary : colors.onSurfaceVar,
            ),
          ),
        ),
      ),
    );
  }
}

/// Grams re-edit sheet (editor ingredient row tap): GramsEntry seeded from the
/// existing item; confirms with the new Grams — the controller rescales via
/// scaledTo.
class GramsSheet extends StatefulWidget {
  const GramsSheet({required this.item, super.key});

  final FoodSnapshot item;

  @override
  State<GramsSheet> createState() => _GramsSheetState();
}

class _GramsSheetState extends State<GramsSheet> {
  late double? _grams = widget.item.grams.value;

  @override
  Widget build(BuildContext context) {
    return SheetScaffold(
      label: 'Quantity',
      title: widget.item.name,
      body: GramsEntry(
        baseline: widget.item,
        initialGrams: widget.item.grams.value,
        onChanged: (g) => setState(() => _grams = g),
      ),
      cta: PrimaryCta(
        key: const ValueKey('set-grams'),
        label: 'Set quantity',
        enabled: _grams != null && _grams! > 0,
        onPressed: () => Navigator.of(context).pop(Grams(_grams!)),
      ),
    );
  }
}
