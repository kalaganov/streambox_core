/// A generic cache interface for storing and retrieving values by key.
///
/// Used to abstract the underlying caching mechanism in data layers or
/// caching strategies.
///
/// Type Parameters:
/// - [R] – Type of cached value.
abstract interface class Cache<R> {
  /// Returns the cached value associated with the provided [key],
  /// or `null` if no value exists.
  ///
  /// Typically used to retrieve data before performing expensive operations.
  Future<R?> get(String key);

  /// Stores the [value] in the cache under the given [key].
  ///
  /// Returns the same [value] after storing. Overwrites existing entry
  /// if one is already associated with the key.
  Future<R> set(String key, R value);

  /// Removes all entries from the cache.
  ///
  /// After calling this method, the cache will be empty.
  Future<void> clear();
}
