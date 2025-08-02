import 'dart:async';

import 'package:meta/meta.dart';
import 'package:streambox_core/src/common/adapter/adapter_extension.dart';
import 'package:streambox_core/src/common/adapter/behavior_stream_adapter.dart';
import 'package:streambox_core/src/common/adapter/broadcast_stream_adapter.dart';
import 'package:streambox_core/src/common/adapter/stream_adapter.dart';
import 'package:streambox_core/src/common/data_state.dart';
import 'package:streambox_core/src/common/request_params.dart';
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
  BaseRepo({
    P? initialFetchParams,
    bool fetchOnInit = false,
    bool replayLast = false,
  }) {
    _streamAdapter = replayLast
        ? BehaviorStreamAdapter<DataState<E>>()
        : BroadcastStreamAdapter<DataState<E>>();

    if (fetchOnInit) fetch(initialFetchParams);
  }

  late final StreamAdapter<DataState<E>> _streamAdapter;

  /// A stream of [DataState] objects representing repository states.
  ///
  /// This includes loading, success, error, and initial states.
  @override
  @nonVirtual
  Stream<DataState<E>> get stream => _streamAdapter.stream;

  /// Emits a loading state to the stream.
  @protected
  void handleLoading() => _streamAdapter.safeAddMapped(DataLoading<E>());

  /// Emits a success state with the provided [mapperValue].
  @protected
  void handleData(E mapperValue) =>
      _streamAdapter.safeAddMapped(DataSuccess(mapperValue));

  /// Emits an error state with the given `error` and optional `stackTrace`.
  @protected
  void handleError(Object error, StackTrace? st) =>
      _streamAdapter.safeAddMapped(DataError(error, st));

  /// Emits an initial (flush) state to the stream.
  @protected
  void handleFlush() => _streamAdapter.safeAddMapped(DataInitial<E>());

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
