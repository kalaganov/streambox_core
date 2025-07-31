/// Defines the interface for stream adapters that manage event delivery.
///
/// Provides a uniform contract for adding events, exposing a stream,
/// checking closed state, and performing cleanup.
abstract class StreamAdapter<T> {
  /// Adds an [event] to the stream.
  void add(T event);

  /// Exposes the stream of events to subscribers.
  Stream<T> get stream;

  /// Indicates whether this adapter has been closed.
  bool get isClosed;

  /// Closes the adapter and releases resources.
  Future<void> close();
}
