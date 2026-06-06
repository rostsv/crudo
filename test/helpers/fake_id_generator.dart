import 'package:crudo/data/services/id_generator.dart';

/// Deterministic ids for tests: sm-0, sm-1, …
class FakeIdGenerator implements IdGenerator {
  int _n = 0;
  @override
  String newId() => 'sm-${_n++}';
}
