import 'dart:async';

import 'package:meta/meta.dart';
import 'package:streambox_core/src/common/adapter/adapter_extension.dart';
import 'package:streambox_core/src/common/adapter/behavior_stream_adapter.dart';
import 'package:streambox_core/src/common/adapter/broadcast_stream_adapter.dart';
import 'package:streambox_core/src/common/adapter/stream_adapter.dart';
import 'package:streambox_core/src/common/data_state.dart';
import 'package:streambox_core/src/common/request_params.dart';
import 'package:streambox_core/src/observer/stream_box_error_observer.dart';
import 'package:streambox_core/src/repo/repo_interface.dart';

/// A base implementation of the [Repo] interface.
///
/// Provides common logic for managing data state streaming, including
/// replaying the last state, handling loading, success, error, and flush
/// events. Subclasses are expected to implement the [fetch] method.
///
/// Type Parameters:
/// - [P] – Request parameters extending [RequestParams].
/// - [E] – Type of data entity.
@immutable
abstract class BaseRepo<P extends RequestParams, E> implements Repo<P, E> {
  /// Creates a new [BaseRepo].
  ///
  /// - [initialFetchParams]: parameters to pass for the first fetch.
  /// - [fetchOnInit]: if `true`, initiates a fetch immediately.
  /// - [replayLast]: if `true`, replays the last emitted state to new
  ///   subscribers; otherwise uses a broadcast stream.
  /// - [tag]: optional identifier for this repository instance.
  BaseRepo({
    P? initialFetchParams,
    bool fetchOnInit = false,
    bool replayLast = false,
    this.tag,
  }) {
    _streamAdapter = replayLast
        ? BehaviorStreamAdapter<DataState<E>>()
        : BroadcastStreamAdapter<DataState<E>>();

    if (fetchOnInit) fetch(initialFetchParams);
  }

  /// Optional identifier for this repository.
  final String? tag;

  late final StreamAdapter<DataState<E>> _streamAdapter;

  /// A stream of [DataState] objects representing repository states.
  ///
  /// This includes loading, success, error, and initial states.
  @override
  @nonVirtual
  Stream<DataState<E>> get stream => _streamAdapter.stream;

  /// Initiates a fetch and awaits the first emitted state.
  ///
  /// This method ensures safe sequencing by subscribing to [stream]
  /// before invoking [fetch]. It returns the first [DataState] emitted
  /// by the repository after the fetch begins.
  ///
  /// Use this when you need to synchronously await the result of a fetch
  /// rather than subscribing manually to the [stream].
  ///
  /// Example:
  /// ```dart
  /// final state = await repo.fetchAwait(params);
  /// if (state is DataSuccess<MyEntity>) {
  ///   // handle successful data
  /// }
  /// ```
  @override
  @nonVirtual
  Future<DataState<E>> fetchAwait([P? p]) {
    final future = stream.first;
    fetch(p);
    return future;
  }

  /// Emits a loading state to the stream.
  @protected
  void handleLoading() => _streamAdapter.safeAddMapped(DataLoading<E>());

  /// Emits a success state with the provided [mapperValue].
  @protected
  void handleData(E mapperValue) =>
      _streamAdapter.safeAddMapped(DataSuccess(mapperValue));

  /// Emits an error state with the given `error` and optional `stackTrace`.
  /// Notifies global error observers.
  @protected
  void handleError(Object error, StackTrace? st) {
    _streamAdapter.safeAddMapped(DataError(error, st));
    StreamBoxErrorObservers.instance.notifyError(
      tag ?? runtimeType.toString(),
      error,
      st,
    );
  }

  /// Emits an initial (flush) state to the stream, and if a
  /// `BehaviorStreamAdapter` is used, immediately clears this state
  /// to prevent it from being replayed to new subscribers.
  @protected
  void handleFlush() {
    _streamAdapter.safeAddMapped(DataInitial<E>());

    final adapter = _streamAdapter;
    if (adapter is BehaviorStreamAdapter<DataState<E>>) {
      adapter.clearLast();
    }
  }

  /// Returns whether the repository has been disposed.
  @protected
  bool get isDisposed => _streamAdapter.isClosed;

  /// Disposes the repository by closing the underlying stream adapter.
  ///
  /// Must be called to free resources when the repository is no longer used.
  @override
  @mustCallSuper
  Future<void> dispose() => _streamAdapter.close();
}
