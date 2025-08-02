import 'package:streambox_core/src/common/request_params.dart';
import 'package:streambox_core/src/common/request_payload.dart';

/// A generic data source interface for executing requests,
/// managing lifecycle, and exposing request states.
///
/// Provides a unified contract for components that fetch data,
/// emit request payloads, and support flushing and disposal.
///
/// Type Parameters:
/// - [P] – Request parameters extending [RequestParams].
/// - [R] – Type of request result value.
abstract interface class DataSource<P extends RequestParams, R> {
  /// Initiates a data fetch with optional [params] and [extras].
  ///
  /// Implementations should push resulting payloads to the [stream].
  void fetch([P? params, List<Object>? extras]);

  /// Clears cached or stored data and resets the state.
  Future<void> flush();

  /// A stream of [RequestPayload] objects representing request states.
  ///
  /// Includes initial, loading, success, and error events.
  Stream<RequestPayload<P, R>> get stream;

  /// Disposes of data source resources.
  ///
  /// Must be called when the data source is no longer needed to free
  /// associated resources such as streams or controllers.
  Future<void> dispose();
}
