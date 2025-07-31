import 'package:streambox_core/src/common/data_state.dart';

/// A generic repository interface for managing data fetching,
/// state streaming, and lifecycle control.
///
/// Provides a unified contract for repositories that fetch and deliver
/// data entities, while exposing their states through a stream.
///
/// Type Parameters:
/// - [P] – Type of request parameters.
/// - [E] – Type of data entity returned.
abstract interface class Repo<P, E> {
  /// Initiates a data fetch with optional [p] parameters.
  ///
  /// Implementations should push resulting states to the [stream].
  void fetch([P? p]);

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
