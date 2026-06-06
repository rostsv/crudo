import 'package:flutter/material.dart';

/// All dimensions sit on a 4px grid. Paddings/gaps come from [Spacing],
/// icons from [IconSizes]; component-intrinsic sizes (circles, bars) are
/// named widget constants that still snap to the grid.
abstract final class Spacing {
  static const double xs = 4, sm = 8, md = 16, lg = 24, xl = 32, xxl = 48;
}

abstract final class IconSizes {
  static const double sm = 16, md = 20, lg = 24, xl = 32;
}

abstract final class Radii {
  static const double sm = 12, md = 20, lg = 32, xl = 48, full = 9999;
  static BorderRadius all(double r) => BorderRadius.circular(r);
}

abstract final class Shadows {
  static const cloud = <BoxShadow>[
    BoxShadow(color: Color(0x0A1A1C1A), offset: Offset(0, 20), blurRadius: 40),
  ];
  static const cloudDeep = <BoxShadow>[
    BoxShadow(color: Color(0x0F1A1C1A), offset: Offset(0, 24), blurRadius: 60),
  ];
}

abstract final class Durations {
  static const fast = Duration(milliseconds: 150);
  static const base = Duration(milliseconds: 200);
}

/// Alpha levels for derived colors — never inline a raw alpha in a widget.
abstract final class Opacities {
  /// Secondary/supporting text rendered over tonal or colored fills.
  static const double muted = 0.7;

  /// Disabled interactive elements (secondary actions, preset tiles).
  static const double disabled = 0.4;
}
