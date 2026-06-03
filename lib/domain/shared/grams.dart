/// A quantity in grams. Must be positive — this constructor is the only door,
/// so a non-positive quantity is unrepresentable (forms validate input first).
class Grams implements Comparable<Grams> {
  const Grams(this.value) : assert(value > 0, 'grams must be > 0');

  final double value;

  @override
  int compareTo(Grams other) => value.compareTo(other.value);

  @override
  bool operator ==(Object other) => other is Grams && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Grams($value)';
}
