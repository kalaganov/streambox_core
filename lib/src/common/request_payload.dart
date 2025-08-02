import 'package:meta/meta.dart';
import 'package:streambox_core/src/common/request_params.dart';

/// Represents the base class for all request states.
///
/// Each subclass describes a different stage of a request lifecycle,
/// such as initial, loading, success, or error.
///
/// Type Parameters:
/// - [P] – Request parameters extending [RequestParams].
/// - [R] – Value type returned by the request.
@immutable
sealed class RequestPayload<P extends RequestParams, R> {
  /// Creates a new request payload with optional [params].
  const RequestPayload({
    required this.params,
  });

  /// The parameters used for the request, if provided.
  ///
  /// Used for request identification and caching.
  final P? params;
}

/// Indicates the initial state before any request has been made.
final class RequestInitial<P extends RequestParams, R>
    extends RequestPayload<P, R> {
  /// Creates an initial request state with optional [params].
  const RequestInitial({required super.params});
}

/// Indicates that a request is currently in progress.
final class RequestLoading<P extends RequestParams, R>
    extends RequestPayload<P, R> {
  /// Creates a loading request state with optional [params].
  const RequestLoading({required super.params});
}

/// Indicates that a request has successfully completed.
///
/// Contains the resulting [value] and optional [extras] metadata.
final class RequestSuccess<P extends RequestParams, R>
    extends RequestPayload<P, R> {
  /// Creates a success request state with the given [value].
  ///
  /// Optionally, [extras] may contain additional context or metadata.
  const RequestSuccess({
    required super.params,
    required this.value,
    this.extras,
  });

  /// The successfully fetched value.
  final R value;

  /// Additional context or metadata associated with the request.
  final List<Object>? extras;
}

/// Indicates that a request has failed.
///
/// Contains the encountered [error] and optional [stackTrace].
final class RequestError<P extends RequestParams, R>
    extends RequestPayload<P, R> {
  /// Creates an error request state with the given [error].
  ///
  /// Optionally, a [stackTrace] may provide more debugging details.
  const RequestError({
    required super.params,
    required this.error,
    this.stackTrace,
  });

  /// The error that occurred during the request.
  final Object error;

  /// The stack trace associated with the error, if available.
  final StackTrace? stackTrace;
}
