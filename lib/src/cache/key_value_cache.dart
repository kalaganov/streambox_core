import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:streambox_core/streambox_core.dart';

/// Base implementation of a key-value cache
/// that uses a [KeyValueStoreInterface] for persistence.
///
/// Provides string-based serialization and deserialization mechanisms
/// for caching generic values. Classes extending this should implement
/// custom serialization logic for the target value type [R].
///
/// This class automatically applies a [keyPrefix] to all keys in order to
/// avoid collisions with other data in the same store.
@immutable
abstract class BaseKeyValueCache<R> implements Cache<R> {
  /// Creates a new cache with the provided [store].
  ///
  /// The [store] defines the underlying persistence mechanism.
  const BaseKeyValueCache({
    required this.store,
  });

  /// Underlying key-value store used for persistence.
  final KeyValueStoreInterface store;

  /// A prefix applied to all keys to isolate entries from other caches.
  @protected
  String get keyPrefix;

  /// Converts a serialized [String] back into a value of type [R].
  @protected
  R deserialize(String source);

  /// Converts a value of type [R] into a serialized [String].
  @protected
  String serialize(R value);

  /// Encodes a given [object] into a JSON string.
  ///
  /// Typically used as a helper for [serialize].
  @protected
  @nonVirtual
  String encode(Object object) => jsonEncode(object);

  /// Decodes a JSON string into a [Map<String, dynamic>].
  ///
  /// Useful for deserializing values stored as JSON maps.
  @protected
  @nonVirtual
  Map<String, dynamic> decodeAsMap(String source) =>
      jsonDecode(source) as Map<String, dynamic>;

  /// Decodes a JSON string into a list of values of type [R].
  ///
  /// Useful when storing multiple values in an array-like format.
  @protected
  @nonVirtual
  List<R> decodeAsList(String source) => (jsonDecode(source) as List).cast<R>();

  /// Retrieves the cached value for the given [key].
  ///
  /// Returns `null` if no entry exists for the key.
  @override
  Future<R?> get(String key) async {
    final raw = await store.read(keyPrefix + key);
    if (raw == null) return null;
    return deserialize(raw);
  }

  /// Stores the [value] under the given [key].
  ///
  /// Overwrites any existing entry and returns the stored [value].
  @override
  Future<R> set(String key, R value) async {
    final raw = serialize(value);
    await store.write(keyPrefix + key, raw);
    return value;
  }

  /// Clears all cached values with the current [keyPrefix].
  ///
  /// This operation only affects keys that start with the cache's prefix.
  @override
  Future<void> clear() async {
    final all = await store.readAll();
    final prefixed = _getPrefixedKeys(all.keys);
    for (final k in prefixed) {
      await store.delete(k);
    }
  }

  /// Filters and returns all keys that match the current [keyPrefix].
  List<String> _getPrefixedKeys(Iterable<String> keys) =>
      keys.where((k) => k.startsWith(keyPrefix)).toList();
}
