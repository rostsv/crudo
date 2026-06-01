import 'package:flutter_test/flutter_test.dart';
import 'package:crudo/ui/core/themes/dimensions.dart';

void main() {
  test('spacing & radii scales', () {
    expect(Spacing.md, 16.0);
    expect(Spacing.xl, 32.0);
    expect(Radii.lg, 32.0);
    expect(Radii.full, 9999.0);
  });
  test('cloud shadow defined', () {
    expect(Shadows.cloud, isNotEmpty);
    expect(Shadows.cloud.first.blurRadius, 40.0);
  });
}
