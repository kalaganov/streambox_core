import 'dart:async';

import 'package:streambox_core/src/common/request_params.dart';
import 'package:streambox_core/src/common/typedefs.dart';
import 'package:streambox_core/src/strategies/base/base_cache_strategy.dart';

/// A cache strategy that always attempts to serve data from cache first.
///
/// - On the first request, checks if a cached value exists:
///   - If found, the cached value is returned immediately.
///   - If not found, a new value is fetched, stored in cache, and returned.
/// - On repeated requests with the same `params`:
///   - If a cached value exists, it is returned without calling `fetch`.
///   - If the cache is empty or flushed, `fetch` is invoked again.
/// - Request results are validated against the current request version
///   to ensure outdated values are not emitted.
///
/// Type Parameters:
/// - [P] – Request parameters extending [RequestParams].
/// - [R] – Type of cached or fetched value.
abstract class CacheFirstStrategy<P extends RequestParams, R>
    extends BaseCacheStrategy<P, R> {
  /// Creates a [CacheFirstStrategy] with the given [cache].
  CacheFirstStrategy({required super.cache});

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

    if (cachedValue != null && !shouldSkipCache(params, cachedValue)) {
      handleData(params, extras, cachedValue);
      return;
    }

    final newValue = await fetch();
    if (reqVersion != currentRequestVersion) return;

    await writeCachedValue(key, newValue);
    if (reqVersion != currentRequestVersion) return;

    handleData(params, extras, newValue);
  }

  @override
  bool shouldSkipCache(P? params, R? value) => false;
}
