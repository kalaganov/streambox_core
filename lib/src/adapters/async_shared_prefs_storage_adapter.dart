import 'package:meta/meta.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streambox_core/src/cache/key_value_store_interface.dart';

/// A [KeyValueStoreInterface] implementation backed by the asynchronous
/// [SharedPreferencesAsync] API.
///
/// Provides non-blocking operations for reading, writing, and deleting
/// key-value pairs. Suitable for cases where async access to preferences
/// is required without caching results in memory.
@immutable
final class AsyncSharedPrefsStorageAdapter implements KeyValueStoreInterface {
  final _prefs = SharedPreferencesAsync();

  /// Reads the value associated with the given [key].
  ///
  /// Returns `null` if the key does not exist.
  @override
  Future<String?> read(String key) => _prefs.getString(key);

  /// Writes the provided [value] for the given [key].
  ///
  /// Overwrites any existing value.
  @override
  Future<void> write(String key, String value) => _prefs.setString(key, value);

  /// Deletes the entry for the given [key].
  ///
  /// Does nothing if the key is not found.
  @override
  Future<void> delete(String key) => _prefs.remove(key);

  /// Reads and returns all key-value pairs from storage.
  ///
  /// Only string values are included. Keys with non-string values
  /// are ignored.
  @override
  Future<Map<String, String>> readAll() async {
    final keys = await _prefs.getKeys();
    final result = <String, String>{};
    for (final k in keys) {
      final v = await _prefs.getString(k);
      if (v != null) result[k] = v;
    }
    return result;
  }
}
