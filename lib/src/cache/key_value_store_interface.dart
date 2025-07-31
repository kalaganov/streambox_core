/// A simple interface for key-value storage systems.
///
/// Designed as a low-level abstraction for persisting data by string keys.
/// This interface allows reading, writing, and deleting entries, as well as
/// retrieving all stored values.
abstract interface class KeyValueStoreInterface {
  /// Reads a value associated with the provided [key].
  ///
  /// Returns `null` if no entry exists for the given key.
  Future<String?> read(String key);

  /// Writes a [value] under the given [key].
  ///
  /// If a value already exists, it will be overwritten.
  Future<void> write(String key, String value);

  /// Deletes the entry associated with the provided [key].
  ///
  /// Does nothing if the key does not exist.
  Future<void> delete(String key);

  /// Reads and returns all key-value pairs from the storage.
  ///
  /// The returned [Map] includes all keys and their corresponding values.
  Future<Map<String, String>> readAll();
}
