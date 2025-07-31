import 'package:meta/meta.dart';
import 'package:streambox_core/streambox_core.dart';

/// A simple in-memory implementation of [KeyValueStoreInterface].
///
/// Stores key-value pairs in a local [Map].
/// Useful for testing, prototyping, or scenarios where persistence
/// is not required.
///
/// ⚠️ Values are lost when the app is restarted.
@immutable
final class MemoryStoreAdapter implements KeyValueStoreInterface {
  final Map<String, String> _map = {};

  /// Reads the value associated with the given [key].
  ///
  /// Returns `null` if the key does not exist.
  @override
  Future<String?> read(String key) async => _map[key];

  /// Writes the provided [value] for the given [key].
  ///
  /// Overwrites any existing value.
  @override
  Future<void> write(String key, String value) async {
    _map[key] = value;
  }

  /// Deletes the entry for the given [key].
  ///
  /// Does nothing if the key does not exist.
  @override
  Future<void> delete(String key) async => _map.remove(key);

  /// Reads and returns all key-value pairs from memory.
  @override
  Future<Map<String, String>> readAll() =>
      Future.value(Map<String, String>.from(_map));
}
