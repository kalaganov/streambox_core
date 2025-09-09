import 'dart:async';

import 'package:streambox_core/src/common/request_params.dart';
import 'package:streambox_core/src/common/typedefs.dart';
import 'package:streambox_core/src/strategies/base/base_cache_strategy.dart';

/// A cache strategy that delivers cached data immediately (if available),
/// then refreshes it with a newly fetched value.
///
/// - On each request:
///   - If a cached value exists, it is emitted right away.
///   - Regardless of cache presence, `fetch` is always called to obtain
///     the latest value.
///   - If the new value differs from the cached one, the cache is updated
///     and the fresh value is emitted.
/// - Request results are validated against the current request version
///   to prevent outdated values from being delivered.
///
/// Useful when fast responses are desired while still ensuring that
/// consumers receive the most recent data once it becomes available.
///
/// Type Parameters:
/// - [P] – Request parameters extending [RequestParams].
/// - [R] – Type of cached or fetched value.
abstract class CacheThenRefreshStrategy<P extends RequestParams, R>
    extends BaseCacheStrategy<P, R> {
  /// Creates a [CacheThenRefreshStrategy] with the given [cache].
  ///
  /// Set [skipErrors] to `true` to silently ignore errors and prevent them
  /// from being emitted to the [stream].
  CacheThenRefreshStrategy({required super.cache, super.skipErrors = false});

  @override
  Future<void> performRequest(
    P? params,
    List<Object>? extras,
    ValueFetcher<R> fetch,
  ) async {
    final reqVersion = currentRequestVersion;
    final key = resolveKey(params);

    final cachedValue = await readCachedValue(key);
    if (reqVersion != currentRequestVersion) return;

    if (!shouldSkipCache(params, cachedValue)) {
      handleDataIfNotNull(params, extras, cachedValue);
    }

    final newValue = await fetch();
    if (reqVersion != currentRequestVersion) return;

    if (newValue != cachedValue) {
      await writeCachedValue(key, newValue);
      if (reqVersion != currentRequestVersion) return;
      handleData(params, extras, newValue);
    }
  }

  @override
  bool shouldSkipCache(P? params, R? value) => false;
}
