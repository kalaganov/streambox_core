import 'package:streambox_core/src/common/data_state.dart';
import 'package:streambox_core/src/common/request_params.dart';

/// A generic repository interface for managing data fetching,
/// state streaming, and lifecycle control.
///
/// Provides a unified contract for repositories that fetch and deliver
/// data entities, while exposing their states through a stream.
///
/// Type Parameters:
/// - [P] – Request parameters extending [RequestParams].
/// - [E] – Type of data entity returned.
abstract interface class Repo<P extends RequestParams, E> {
  /// Initiates a data fetch with optional [p] parameters.
  ///
  /// Implementations should push resulting states to the [stream].
  void fetch([P? p]);

  /// Initiates a data fetch and awaits the first emitted state.
  ///
  /// Use this when synchronous-like behavior is needed: the method
  /// subscribes to [stream], triggers [fetch] with optional [p],
  /// and returns the first emitted [DataState].
  ///
  /// Unlike [fetch], this method provides a [Future] that resolves
  /// once the repository emits its first state. This avoids common
  /// race conditions that may occur if listening to [stream] and
  /// calling [fetch] separately.
  ///
  /// Example:
  /// ```dart
  /// final result = await repo.fetchAwait(params);
  /// if (result is DataSuccess) {
  ///   // handle success
  /// }
  /// ```
  Future<DataState<E>> fetchAwait([P? p]);

  /// A stream of [DataState] objects representing the current
  /// state of the data flow, such as loading, success, or error.
  Stream<DataState<E>> get stream;

  /// Clears cached or stored data.
  ///
  /// Typically used to reset the repository's state.
  Future<void> flush();

  /// Disposes of repository resources.
  ///
  /// Must be called when the repository is no longer needed to free
  /// associated resources such as streams or controllers.
  Future<void> dispose();
}
