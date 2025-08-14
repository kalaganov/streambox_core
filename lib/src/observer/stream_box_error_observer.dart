/// Interface for observing errors emitted by repositories.
abstract class StreamBoxErrorObserver {
  /// Called when an error occurs in a repository.
  ///
  /// [repo] is the name or identifier of the repository.
  /// [error] is the thrown object.
  /// [stackTrace] is the optional stack trace associated with the error.
  void onError(String repo, Object error, StackTrace? stackTrace);
}

/// Singleton manager for global error observers.
final class StreamBoxErrorObservers {
  StreamBoxErrorObservers._();

  /// The single shared instance of the manager.
  static final instance = StreamBoxErrorObservers._();

  final _observers = <StreamBoxErrorObserver>{};

  /// Registers a new global error observer.
  void register(StreamBoxErrorObserver observer) => _observers.add(observer);

  /// Unregisters a previously registered observer.
  void unregister(StreamBoxErrorObserver observer) =>
      _observers.remove(observer);

  /// Removes all registered observers.
  void clear() => _observers.clear();

  /// Notifies all registered observers about an error from [repo].
  void notifyError(String repo, Object error, StackTrace? stackTrace) {
    for (final o in _observers) {
      o.onError(repo, error, stackTrace);
    }
  }

  /// Returns true if [observer] is currently registered.
  bool contains(StreamBoxErrorObserver observer) =>
      _observers.contains(observer);

  /// Returns true if there is at least one registered observer.
  bool get hasObservers => _observers.isNotEmpty;
}
