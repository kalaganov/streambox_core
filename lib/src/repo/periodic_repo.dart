import 'dart:async';

import 'package:meta/meta.dart';
import 'package:streambox_core/src/common/fetch_cycle.dart';
import 'package:streambox_core/src/common/payload_handler_delegate.dart';
import 'package:streambox_core/src/common/request_params.dart';
import 'package:streambox_core/src/common/request_payload.dart';
import 'package:streambox_core/src/data_sources/data_source_interface.dart';
import 'package:streambox_core/src/repo/base_repo.dart';

/// A repository implementation that periodically fetches data from
/// a [DataSource] at a fixed `interval`.
///
/// The fetch cycle is managed using a [FetchCycle] counter, allowing
/// logic to determine whether to continue fetching using [shouldContinue].
/// Subclasses must provide mapping logic via [map] and a continuation
/// policy via [shouldContinue].
///
/// Type Parameters:
/// - [P] – Request parameters extending [RequestParams].
/// - [R] – Type of values returned by the data source.
/// - [E] – Type of mapped entity exposed by the repository.
@immutable
abstract class PeriodicRepo<P extends RequestParams, R, E>
    extends BaseRepo<P, E> {
  /// Creates a [PeriodicRepo] with the given [dataSource], [interval],
  /// and configuration options.
  ///
  /// - [dataSource]: the underlying source providing request payloads.
  /// - [interval]: delay between consecutive fetch cycles.
  /// - [emitOnEachCycle]: if true, emits payloads every cycle; otherwise,
  ///   payloads are conditionally emitted based on [shouldContinue].
  /// - [replayLast]: if true, replays the last emitted state
  ///   to new subscribers.
  PeriodicRepo({
    required DataSource<P, R> dataSource,
    required Duration interval,
    bool emitOnEachCycle = true,
    super.replayLast,
  }) : _dataSource = dataSource,
       _interval = interval,
       _emitOnEachCycle = emitOnEachCycle {
    _payloadHandler = PayloadHandlerDelegate(
      map: map,
      onData: handleData,
      onError: handleError,
      onLoading: handleLoading,
      onFlush: handleFlush,
    );
    _subscription = dataSource.stream.listen(_onData);
  }

  final DataSource<P, R> _dataSource;
  final Duration _interval;
  final bool _emitOnEachCycle;
  final _fetchCycle = FetchCycle();

  late final PayloadHandlerDelegate<P, R, E> _payloadHandler;
  late final StreamSubscription<RequestPayload<P, R>> _subscription;

  void _onData(RequestPayload<P, R> payload) {
    final currentCycle = _fetchCycle.current;
    final shouldContinue = this.shouldContinue(currentCycle, payload);

    if (_emitOnEachCycle && shouldContinue) {
      _payloadHandler.handle(payload);
    } else if (!shouldContinue && !_emitOnEachCycle) {
      _payloadHandler.handle(payload);
    } else if (currentCycle == 1 && !shouldContinue) {
      _payloadHandler.handle(payload);
    }

    if (shouldContinue) {
      Future.delayed(_interval, () {
        if (isDisposed) return;
        _scheduledFetch(payload.params);
      });
    }
  }

  void _scheduledFetch(P? params) {
    _fetchCycle.next();
    _dataSource.fetch(params);
  }

  /// Maps a data source value [value] and its optional [params]
  /// into the final entity type [E].
  @protected
  E map(P? params, R value);

  /// Determines whether the repository should continue fetching
  /// during the given [cycle], based on the [payload].
  @protected
  bool shouldContinue(int cycle, RequestPayload<P, R> payload);

  /// Initiates the first fetch and resets the fetch cycle counter.
  @override
  @nonVirtual
  void fetch([P? params]) {
    _fetchCycle.reset();
    _dataSource.fetch(params);
  }

  /// Flushes the underlying data source.
  @override
  Future<void> flush() => _dataSource.flush();

  /// Disposes of the repository, canceling the subscription and
  /// releasing resources of both the base repo and the data source.
  @override
  @nonVirtual
  Future<void> dispose() async {
    await super.dispose();
    await _subscription.cancel();
    await _dataSource.dispose();
  }
}
