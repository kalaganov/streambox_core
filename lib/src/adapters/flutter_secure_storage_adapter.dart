import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:meta/meta.dart';
import 'package:streambox_core/streambox_core.dart';

/// A [KeyValueStoreInterface] implementation backed by
/// [FlutterSecureStorage].
///
/// Provides secure, encrypted key-value storage suitable for storing
/// sensitive data such as tokens, credentials, or secrets.
///
/// - On Android, uses [AndroidOptions] with `encryptedSharedPreferences`
///   enabled for maximum security.
/// - On iOS, relies on the Keychain for secure storage.
///
/// Example:
/// ```dart
/// final storage = FlutterSecureStorageAdapter();
/// await storage.write('token', 'abc123');
/// final token = await storage.read('token');
/// ```
@immutable
final class FlutterSecureStorageAdapter implements KeyValueStoreInterface {
  /// Creates a [FlutterSecureStorageAdapter] with the given [storage].
  ///
  /// Defaults to using [FlutterSecureStorage] with secure Android options.
  const FlutterSecureStorageAdapter({
    FlutterSecureStorage storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(
        resetOnError: true,
        encryptedSharedPreferences: true,
      ),
    ),
  }) : _storage = storage;

  final FlutterSecureStorage _storage;

  /// Reads the value associated with the given [key].
  ///
  /// Returns `null` if the key does not exist.
  @override
  Future<String?> read(String key) => _storage.read(key: key);

  /// Writes the provided [value] for the given [key].
  ///
  /// Overwrites any existing value.
  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  /// Deletes the entry for the given [key].
  ///
  /// Does nothing if the key is not found.
  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  /// Reads and returns all key-value pairs from secure storage.
  @override
  Future<Map<String, String>> readAll() => _storage.readAll();
}
