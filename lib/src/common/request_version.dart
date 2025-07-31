/// A simple counter used to track request versions.
///
/// Primarily utilized in caching strategies to invalidate outdated requests
/// when a new request cycle begins.
final class RequestVersion {
  int _counter = 0;

  /// Increments the version counter by one.
  void next() => ++_counter;

  /// Returns the current version number.
  int get current => _counter;
}
