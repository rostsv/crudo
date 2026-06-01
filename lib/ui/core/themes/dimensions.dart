import 'package:flutter/material.dart';

abstract final class Spacing {
  static const double xs = 4, sm = 8, md = 16, lg = 24, xl = 32, xxl = 48;
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
