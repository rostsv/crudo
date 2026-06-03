import 'package:checks/checks.dart';
import 'package:crudo/data/services/id_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('generates unique uuid-shaped v7 ids', () {
    final gen = IdGenerator();
    final ids = {for (var i = 0; i < 100; i++) gen.newId()};
    check(ids.length).equals(100); // no collisions
    final uuidShape = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[0-9a-f]{4}-[0-9a-f]{12}$',
    );
    for (final id in ids) {
      check(uuidShape.hasMatch(id)).isTrue();
    }
  });
}
