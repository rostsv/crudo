// test/architecture/dependency_rules_test.dart
import 'dart:io';

import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';

/// The Clean dependency rule, executable (architecture.md §2).
/// Maps layer directory -> allowed `package:` import prefixes.
/// Relative imports (non-package URIs) are always allowed within a layer.
const Map<String, List<String>> allowedPackageImports = {
  'lib/domain': [
    'dart:',
    'package:freezed_annotation/',
    'package:crudo/domain/',
  ],
  'lib/utils': ['dart:'],
  'lib/data': [
    'dart:',
    'package:crudo/domain/',
    'package:crudo/data/',
    'package:flutter/services.dart', // rootBundle (seed asset)
    'package:flutter_riverpod/',
    'package:uuid/',
  ],
  'lib/config': [
    'dart:',
    'package:crudo/', // composition root may see all layers
    'package:flutter/',
    'package:flutter_riverpod/',
  ],
};

void main() {
  allowedPackageImports.forEach((dir, allowlist) {
    test('$dir respects the dependency rule', () {
      final layer = Directory(dir);
      if (!layer.existsSync()) return; // layer not created yet

      final violations = <String>[];
      final files = layer
          .listSync(recursive: true)
          .whereType<File>()
          .where(
            (f) =>
                f.path.endsWith('.dart') && !f.path.endsWith('.freezed.dart'),
          );

      for (final file in files) {
        final imports = RegExp(
          r'''^import\s+['"]([^'"]+)['"]''',
          multiLine: true,
        ).allMatches(file.readAsStringSync()).map((m) => m.group(1)!);
        for (final uri in imports) {
          final isRelative = !uri.contains(':');
          final isAllowed = isRelative || allowlist.any(uri.startsWith);
          if (!isAllowed) violations.add('${file.path} -> $uri');
        }
      }

      check(
        because: 'forbidden imports:\n${violations.join('\n')}',
        violations,
      ).isEmpty();
    });
  });
}
