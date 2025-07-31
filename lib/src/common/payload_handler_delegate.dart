import 'package:streambox_core/src/common/request_payload.dart';

/// A delegate that handles different [RequestPayload] states by
/// invoking the provided callbacks.
///
/// Maps successful request values to a new type [E] before passing them
/// to the data callback.
///
/// Type Parameters:
/// - [P] – Type of request parameters.
/// - [R] – Type of request value.
/// - [E] – Type of mapped data delivered to the data callback.
class PayloadHandlerDelegate<P, R, E> {
  /// Creates a new handler delegate with the given callbacks.
  ///
  /// - [map] transforms a successful `value` into a type [E].
  /// - [onData] is called when a successful payload is received.
  /// - [onError] is called when an error payload is received.
  /// - [onLoading] is called when a loading payload is received.
  /// - [onFlush] is called when an initial payload is received.
  PayloadHandlerDelegate({
    required E Function(P? params, R value) map,
    required void Function(E data) onData,
    required void Function(Object error, StackTrace? st) onError,
    required void Function() onLoading,
    required void Function() onFlush,
  }) : _map = map,
       _onData = onData,
       _onError = onError,
       _onLoading = onLoading,
       _onFlush = onFlush;

  final E Function(P? params, R value) _map;
  final void Function(E data) _onData;
  final void Function(Object error, StackTrace? st) _onError;
  final void Function() _onLoading;
  final void Function() _onFlush;

  /// Handles the given [payload] by dispatching it to the
  /// appropriate callback.
  void handle(RequestPayload<P, R> payload) => switch (payload) {
    RequestLoading<P, R>() => _onLoading(),
    RequestSuccess<P, R>(:final params, :final value) => _handleSuccess(
      params,
      value,
    ),
    RequestInitial<P, R>() => _onFlush(),
    RequestError<P, R>(:final error, :final stackTrace) => _onError(
      error,
      stackTrace,
    ),
  };

  /// Handles a successful payload by mapping its value and
  /// delivering the mapped result to the `onData` callback.
  ///
  /// If an error occurs during mapping, `onError` is invoked.
  void _handleSuccess(P? params, R value) {
    try {
      final mapped = _map(params, value);
      _onData(mapped);
    } on Object catch (error, st) {
      _onError(error, st);
    }
  }
}
