import 'package:streambox_core/src/common/request_params.dart';
import 'package:streambox_core/src/common/request_payload.dart';
import 'package:streambox_core/src/common/typedefs.dart';

/// Defines a strategy for handling requests with caching support.
///
/// A [CacheStrategy] determines how data is fetched, cached, and
/// delivered to consumers via a [stream]. It provides methods for
/// generating cache keys, executing requests, and managing lifecycle.
///
/// Type Parameters:
/// - [P] – Request parameters extending [RequestParams].
/// - [R] – Type of cached or fetched value.
abstract interface class CacheStrategy<P extends RequestParams, R> {
  /// Initiates a request with the given [params], optional [extras],
  /// and a [fetch] function for retrieving values.
  ///
  /// Implementations decide whether to return cached data or
  /// perform a new fetch.
  void request(P? params, List<Object>? extras, ValueFetcher<R> fetch);

  /// Clears all cached data associated with this strategy.
  Future<void> flush();

  /// A stream of [RequestPayload]s representing the request lifecycle.
  ///
  /// Emits loading, success, error, and initial states.
  Stream<RequestPayload<P, R>> get stream;

  /// Disposes the strategy and releases any associated resources.
  Future<void> dispose();
}
