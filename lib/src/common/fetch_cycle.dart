/// A simple counter used to track the lifecycle of fetch operations.
///
/// Typically applied in caching or request strategies to distinguish
/// between consecutive fetch cycles and to reset when needed.
final class FetchCycle {
  int _counter = 1;

  /// Increments the cycle counter by one.
  void next() => ++_counter;

  /// Returns the current cycle number.
  int get current => _counter;

  /// Resets the cycle counter back to its initial value (1).
  void reset() => _counter = 1;
}
