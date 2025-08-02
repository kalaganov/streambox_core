import 'dart:async';

import 'package:meta/meta.dart';
import 'package:streambox_core/src/common/controller_extension.dart';
import 'package:streambox_core/src/common/request_params.dart';
import 'package:streambox_core/src/common/request_payload.dart';
import 'package:streambox_core/src/data_sources/data_source_interface.dart';

/// A base implementation of [DataSource] that integrates with an
/// external [Stream] of values instead of performing direct requests.
///
/// Automatically listens to the provided `sourceStream` and converts
/// its events into [RequestPayload]s, emitting them to consumers.
///
/// Subclasses must implement [fetch] to define how fetch operations
/// are initiated.
///
/// Type Parameters:
/// - [P] – Request parameters extending [RequestParams].
/// - [R] – Type of streamed value.
@immutable
abstract class BaseExternalStreamDataSource<P extends RequestParams, R>
    implements DataSource<P, R> {
  /// Creates a data source bound to the given [sourceStream].
  ///
  /// The [sourceStream] provides external values that will be mapped
  /// to request payloads and broadcast to consumers.
  BaseExternalStreamDataSource({
    required Stream<R> sourceStream,
  }) {
    _subscription = sourceStream.listen(_onData, onError: _onError);
  }

  late final StreamSubscription<R> _subscription;

  final _controller = StreamController<RequestPayload<P, R>>.broadcast();

  void _onData(R value) =>
      _controller.safeAdd(RequestSuccess(params: null, value: value));

  void _onError(Object error, StackTrace st) => _controller.safeAdd(
    RequestError(params: null, error: error, stackTrace: st),
  );

  /// A broadcast stream of [RequestPayload]s representing the current
  /// state of the external stream, including success and error events.
  @override
  @nonVirtual
  Stream<RequestPayload<P, R>> get stream => _controller.stream;

  /// Defines how a fetch operation should be triggered.
  ///
  /// Subclasses must implement this to decide how to initiate
  /// or influence the external stream.
  @override
  @protected
  void fetch([P? params, List<Object>? extras]);

  /// Emits an initial state, effectively flushing the stream.
  @override
  @nonVirtual
  Future<void> flush() async =>
      _controller.safeAdd(RequestInitial<P, R>(params: null));

  /// Disposes the data source by canceling the external stream
  /// subscription and closing the internal controller.
  @override
  @nonVirtual
  Future<void> dispose() async {
    await _subscription.cancel();
    await _controller.close();
  }
}
