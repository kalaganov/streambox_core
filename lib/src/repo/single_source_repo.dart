import 'dart:async';

import 'package:meta/meta.dart';
import 'package:streambox_core/src/common/payload_handler_delegate.dart';
import 'package:streambox_core/src/common/request_params.dart';
import 'package:streambox_core/src/common/request_payload.dart';
import 'package:streambox_core/src/data_sources/data_source_interface.dart';
import 'package:streambox_core/src/repo/base_repo.dart';

/// A repository implementation that consumes a single [DataSource]
/// and exposes mapped entities of type [E].
///
/// Subclasses must implement [map] to transform raw values [R]
/// from the data source into entities of type [E].
///
/// Type Parameters:
/// - [P] – Request parameters extending [RequestParams].
/// - [R] – Type of values returned by the data source.
/// - [E] – Type of mapped entity exposed by the repository.
@immutable
abstract class SingleSourceRepo<P extends RequestParams, R, E>
    extends BaseRepo<P, E> {
  /// Creates a [SingleSourceRepo] with the given [dataSource].
  ///
  /// - [initialFetchParams]: parameters for the first fetch,
  ///   if [fetchOnInit] is `true`.
  /// - [fetchOnInit]: if true, performs an initial fetch immediately.
  /// - [replayLast]: if true, replays the last emitted state to
  ///   new subscribers.
  SingleSourceRepo({
    required DataSource<P, R> dataSource,
    super.initialFetchParams,
    super.fetchOnInit,
    super.replayLast,
    super.resetOnFlush,
  }) : _dataSource = dataSource {
    final payloadHandler = PayloadHandlerDelegate(
      map: map,
      onData: handleData,
      onError: handleError,
      onLoading: handleLoading,
      onFlush: handleFlush,
    );

    _subscription = dataSource.stream.listen(payloadHandler.handle);
  }

  final DataSource<P, R> _dataSource;

  late final StreamSubscription<RequestPayload<P, R>> _subscription;

  /// Maps a data source value [value] and optional [params]
  /// into the final entity type [E].
  @protected
  E map(P? params, R value);

  /// Initiates a fetch request using the underlying data source.
  @override
  @nonVirtual
  void fetch([P? params]) => _dataSource.fetch(params);

  /// Flushes the underlying data source.
  @override
  Future<void> flush() => _dataSource.flush();

  /// Disposes the repository by canceling the data source subscription,
  /// releasing base repo resources, and disposing the data source.
  @override
  @nonVirtual
  Future<void> dispose() async {
    await super.dispose();
    await _subscription.cancel();
    await _dataSource.dispose();
  }
}
