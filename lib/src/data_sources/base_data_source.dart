import 'dart:async';

import 'package:meta/meta.dart';
import 'package:streambox_core/src/common/controller_extension.dart';
import 'package:streambox_core/src/common/request_payload.dart';
import 'package:streambox_core/src/data_sources/data_source_interface.dart';
import 'package:streambox_core/src/strategies/base/cache_strategy_interface.dart';

/// A base implementation of the [DataSource] interface that uses a
/// [CacheStrategy] to manage requests, caching, and state streaming.
///
/// Subclasses must implement the [request] method to define how data
/// is fetched. This class automatically handles request forwarding,
/// stream broadcasting, and lifecycle management.
///
/// Type Parameters:
/// - [P] – Type of request parameters.
/// - [R] – Type of request result value.
@immutable
abstract class BaseDataSource<P, R> implements DataSource<P, R> {
  /// Creates a data source with the provided [cacheStrategy].
  ///
  /// The [cacheStrategy] defines how requests are handled, cached,
  /// and emitted to the [stream].
  BaseDataSource({
    required CacheStrategy<P, R> cacheStrategy,
  }) : _cacheStrategy = cacheStrategy {
    _strategySubscription = _cacheStrategy.stream.listen(_onData);
  }

  late final StreamSubscription<RequestPayload<P, R>> _strategySubscription;

  final CacheStrategy<P, R> _cacheStrategy;
  final _controller = StreamController<RequestPayload<P, R>>.broadcast();

  /// A broadcast stream of [RequestPayload] objects representing
  /// the current request state, including initial, loading,
  /// success, and error events.
  @override
  @nonVirtual
  Stream<RequestPayload<P, R>> get stream => _controller.stream;

  void _onData(RequestPayload<P, R> value) => _controller.safeAdd(value);

  /// Initiates a fetch request with optional [params] and [extras].
  ///
  /// Delegates the request handling to the underlying [CacheStrategy].
  @override
  @nonVirtual
  void fetch([P? params, List<Object>? extras]) {
    _cacheStrategy.request(params, extras, () => request(params));
  }

  /// Performs the actual data fetch for the given [params].
  ///
  /// Subclasses must implement this method to provide their
  /// specific request logic.
  @protected
  Future<R> request(P? params);

  /// Clears all cached data using the underlying [CacheStrategy].
  @override
  @nonVirtual
  Future<void> flush() => _cacheStrategy.flush();

  /// Disposes the data source by canceling the strategy subscription,
  /// disposing the [CacheStrategy], and closing the internal stream.
  @override
  @nonVirtual
  Future<void> dispose() async {
    await _strategySubscription.cancel();
    await _cacheStrategy.dispose();
    await _controller.close();
  }
}
