import 'package:shared_preferences/shared_preferences.dart';
import 'package:streambox_core/src/cache/key_value_store_interface.dart';

/// A [KeyValueStoreInterface] implementation backed by
/// [SharedPreferencesWithCache].
///
/// Provides a synchronous-like caching layer using
/// `SharedPreferencesWithCache` to minimize disk I/O.
/// The adapter initializes lazily on first access.
final class CachedPrefsAdapter implements KeyValueStoreInterface {
  late SharedPreferencesWithCache? _prefs;
  bool _needsInit = true;

  /// Initializes the [SharedPreferencesWithCache] instance if not yet ready.
  Future<void> _initPrefs() async {
    if (_needsInit) {
      _prefs = await SharedPreferencesWithCache.create(
        cacheOptions: const SharedPreferencesWithCacheOptions(),
      );
      _needsInit = false;
    }
  }

  /// Reads the value associated with the given [key].
  ///
  /// Returns `null` if the key does not exist.
  @override
  Future<String?> read(String key) async {
    if (_needsInit) await _initPrefs();
    return _prefs!.getString(key);
  }

  /// Writes the provided [value] for the given [key].
  ///
  /// Overwrites any existing value.
  @override
  Future<void> write(String key, String value) async {
    if (_needsInit) await _initPrefs();
    await _prefs!.setString(key, value);
  }

  /// Deletes the entry for the given [key].
  ///
  /// Does nothing if the key is not found.
  @override
  Future<void> delete(String key) async {
    if (_needsInit) await _initPrefs();
    await _prefs!.remove(key);
  }

  /// Reads and returns all key-value pairs from storage.
  ///
  /// Only string values are included. Keys with non-string values
  /// are ignored.
  @override
  Future<Map<String, String>> readAll() async {
    if (_needsInit) await _initPrefs();
    final result = <String, String>{};
    for (final k in _prefs!.keys) {
      final v = _prefs!.getString(k);
      if (v != null) result[k] = v;
    }
    return result;
  }
}
