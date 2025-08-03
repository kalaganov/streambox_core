import 'dart:async';

import 'package:streambox_core/src/common/controller_extension.dart';
import 'package:streambox_core/src/common/request_params.dart';
import 'package:streambox_core/src/common/request_payload.dart';
import 'package:streambox_core/src/common/typedefs.dart';
import 'package:streambox_core/src/strategies/base/cache_strategy_interface.dart';

/// A no-op cache strategy that performs no caching at all.
///
/// Each request always invokes the provided `fetch` function
/// and immediately emits its result. No values are stored or reused.
///
/// - On success: emits a [RequestSuccess] payload.
/// - On error: emits a [RequestError] payload.
/// - On [flush]: emits a [RequestInitial] payload.
///
/// Type Parameters:
/// - [P] – Request parameters extending [RequestParams].
/// - [R] – Type of request value.
final class NoOpCacheStrategy<P extends RequestParams, R>
    implements CacheStrategy<P, R> {
  final _controller = StreamController<RequestPayload<P, R>>.broadcast();

  /// A broadcast stream of request payloads representing
  /// the results of fetch operations.
  @override
  Stream<RequestPayload<P, R>> get stream => _controller.stream;

  /// Executes the request using the provided [fetch] function.
  ///
  /// Always performs a fresh fetch; no caching is applied.
  @override
  Future<void> request(
    P? params,
    List<Object>? extras,
    ValueFetcher<R> fetch,
  ) async {
    try {
      final result = await fetch();
      _controller.safeAdd(
        RequestSuccess(
          params: params,
          value: result,
          extras: [...?extras, result as Object],
        ),
      );
    } on Object catch (e, st) {
      _controller.safeAdd(
        RequestError(params: params, error: e, stackTrace: st),
      );
    }
  }

  /// Emits an initial state to reset the stream.
  @override
  Future<void> flush() async =>
      _controller.safeAdd(RequestInitial<P, R>(params: null));

  /// Disposes the strategy by closing the underlying stream controller.
  @override
  Future<void> dispose() => _controller.close();
}
