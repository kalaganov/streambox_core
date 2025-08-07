import 'dart:async';

import 'package:meta/meta.dart';
import 'package:streambox_core/src/cache/cache_interface.dart';
import 'package:streambox_core/src/common/const.dart';
import 'package:streambox_core/src/common/controller_extension.dart';
import 'package:streambox_core/src/common/request_params.dart';
import 'package:streambox_core/src/common/request_payload.dart';
import 'package:streambox_core/src/common/request_version.dart';
import 'package:streambox_core/src/common/typedefs.dart';
import 'package:streambox_core/src/strategies/base/cache_strategy_interface.dart';

/// A base implementation of a cache strategy that integrates a [Cache]
/// with a request/response stream mechanism.
///
/// Handles caching, versioning, and streaming of request states. Subclasses
/// should provide their own [performRequest] implementation to define how
/// data is fetched and cached.
///
/// Type Parameters:
/// - [P] – Request parameters extending [RequestParams].
/// - [R] – Type of the cached value.
@immutable
abstract class BaseCacheStrategy<P extends RequestParams, R>
    implements CacheStrategy<P, R> {
  /// Creates a cache strategy with the given [cache].
  ///
  /// The [cache] provides the persistence mechanism for storing values.
  BaseCacheStrategy({required Cache<R> cache}) : _cache = cache;

  final Cache<R> _cache;

  final _requestVersion = RequestVersion();

  final _controller = StreamController<RequestPayload<P, R>>.broadcast();

  /// A broadcast stream that emits [RequestPayload]s representing the state
  /// of requests, including initial, success, and error states.
  @override
  @nonVirtual
  Stream<RequestPayload<P, R>> get stream => _controller.stream;

  /// Resolves a cache key for the given [params].
  ///
  /// Defaults to `params.cacheKey` if provided, otherwise uses
  /// [kDefaultCacheKey].
  @protected
  @nonVirtual
  String resolveKey(P? params) => params?.cacheKey ?? kDefaultCacheKey;

  /// Determines whether the cache should be skipped for the given request.
  ///
  /// Called before returning a cached value. If this method returns `true`,
  /// the cached value (if any) will be ignored, and a new fetch will be
  /// performed instead.
  ///
  /// This allows for dynamic, per-request decisions about whether to
  /// trust the cache. For example, you might skip cache if:
  ///
  /// - The cached value is too old or invalid.
  /// - The business logic requires always up-to-date data in certain cases.
  ///
  /// Implementations should ensure that the logic here is lightweight,
  /// as it may be called frequently for each request.
  ///
  /// - [params] – Parameters of the request (may be `null`).
  /// - [cachedValue] – Value retrieved from cache (may be `null`).
  ///
  /// Returns `true` to skip the cache and perform a new fetch,
  /// or `false` to use the cached value if available.
  @protected
  bool shouldSkipCache(P? params, R? cachedValue);

  /// Clears all cached values and resets the request version.
  ///
  /// After flushing, an initial request state is emitted to the [stream].
  @override
  @nonVirtual
  Future<void> flush() async {
    increaseRequestVersion();
    await _cache.clear();
    _controller.safeAdd(RequestInitial<P, R>(params: null));
  }

  /// Disposes the underlying resources of this strategy.
  ///
  /// Closes the internal stream controller. Must be called when
  /// the strategy is no longer needed to free resources.
  @override
  @mustCallSuper
  Future<void> dispose() => _controller.close();

  /// Executes a request using the provided [params], [extras], and [fetch].
  ///
  /// Results are streamed via [stream]. If an error occurs, [handleError]
  /// is called to emit an error state.
  @override
  @nonVirtual
  void request(P? params, List<Object>? extras, ValueFetcher<R> fetch) =>
      performRequest(
        params,
        extras,
        fetch,
      ).catchError((Object e, StackTrace? st) => handleError(params, e, st));

  /// Defines the request execution logic.
  ///
  /// Subclasses must implement this method to perform the actual data fetch
  /// and caching. Typically, results should be emitted via [handleData].
  @protected
  Future<void> performRequest(
    P? params,
    List<Object>? extras,
    ValueFetcher<R> fetch,
  );

  /// Emits a successful request state with the given [value].
  ///
  /// Appends [value] to [extras] before broadcasting the payload.
  @protected
  @nonVirtual
  void handleData(P? params, List<Object>? extras, R value) {
    _controller.safeAdd(
      RequestSuccess(
        params: params,
        value: value,
        extras: [...?extras, value as Object],
      ),
    );
  }

  /// Emits a successful request state if [value] is not `null`.
  ///
  /// Does nothing if [value] is `null`.
  @protected
  @nonVirtual
  void handleDataIfNotNull(P? params, List<Object>? extras, R? value) {
    if (value == null) return;
    _controller.safeAdd(
      RequestSuccess(
        params: params,
        value: value,
        extras: [...?extras, value as Object],
      ),
    );
  }

  /// Emits an error state for the given [error] and optional [stackTrace].
  @protected
  @nonVirtual
  void handleError(P? params, Object error, [StackTrace? stackTrace]) {
    _controller.safeAdd(
      RequestError(params: params, error: error, stackTrace: stackTrace),
    );
  }

  /// Returns the current request version used for invalidation checks.
  @protected
  int get currentRequestVersion => _requestVersion.current;

  /// Increments the current request version.
  ///
  /// Typically used to invalidate outdated requests.
  @protected
  void increaseRequestVersion() => _requestVersion.next();

  /// Reads a cached value by its [key].
  ///
  /// Returns the value if present, or `null` otherwise.
  @protected
  @nonVirtual
  Future<R?> readCachedValue(String key) => _cache.get(key);

  /// Writes a [value] into the cache under the given [key].
  @protected
  @nonVirtual
  Future<void> writeCachedValue(String key, R value) => _cache.set(key, value);
}
