import 'dart:async';

import 'package:meta/meta.dart';
import 'package:streambox_core/src/common/request_params.dart';
import 'package:streambox_core/src/common/request_payload.dart';
import 'package:streambox_core/src/data_sources/data_source_interface.dart';
import 'package:streambox_core/src/repo/base_repo.dart';

/// A repository implementation that chains two [DataSource]s,
/// where the second source depends on the result of the first.
///
/// The `primarySource` fetches an initial value, and once successful,
/// its result is transformed into parameters for the `dependentSource`.
/// The results of both sources are combined into a final mapped entity [E].
///
/// Type Parameters:
/// - [P1] – Type of parameters for the primary source.
/// - [P2] – Type of parameters for the dependent source.
/// - [R1] – Type of value returned by the primary source.
/// - [R2] – Type of value returned by the dependent source.
/// - [E] – Type of the final mapped entity exposed by the repository.
@immutable
abstract class ChainedSourcesRepo<
  P1 extends RequestParams,
  P2 extends RequestParams,
  R1,
  R2,
  E
>
    extends BaseRepo<P1, E> {
  /// Creates a chained repository with the given [primarySource]
  /// and [dependentSource].
  ///
  /// - [initialFetchParams] may be provided to trigger an immediate fetch
  ///   if [fetchOnInit] is set to `true`.
  ChainedSourcesRepo({
    required DataSource<P1, R1> primarySource,
    required DataSource<P2, R2> dependentSource,
    super.initialFetchParams,
    super.fetchOnInit,
    super.replayLast,
    super.resetOnFlush,
  }) : _primarySource = primarySource,
       _dependentSource = dependentSource {
    _primarySourceSubscription = primarySource.stream.listen(_onPrimaryData);
    _dependentSourceSubscription = dependentSource.stream.listen(
      _onDependentData,
    );
  }

  final DataSource<P1, R1> _primarySource;
  final DataSource<P2, R2> _dependentSource;

  late final StreamSubscription<RequestPayload<P1, R1>>
  _primarySourceSubscription;
  late final StreamSubscription<RequestPayload<P2, R2>>
  _dependentSourceSubscription;

  /// Initiates a fetch request using the `primarySource`.
  @override
  @nonVirtual
  void fetch([P1? params]) => _primarySource.fetch(params);

  void _onPrimaryData(RequestPayload<P1, R1> payload) => switch (payload) {
    RequestLoading<P1, R1>() => handleLoading(),
    RequestSuccess<P1, R1>(:final params, :final value, :final extras) =>
      _dependentFetch(params, value, extras),
    RequestInitial<P1, R1>() => null,
    RequestError<P1, R1>(:final error, :final stackTrace) => handleError(
      error,
      stackTrace,
    ),
  };

  void _dependentFetch(P1? primaryParams, R1 value, List<Object>? extras) {
    final params = resolveParamsForDependentFetch(primaryParams, value);
    _dependentSource.fetch(params, extras);
  }

  /// Resolves parameters for the `dependentSource` fetch
  /// based on the result from the `primarySource`.
  @protected
  P2? resolveParamsForDependentFetch(P1? params, R1 value);

  void _onDependentData(RequestPayload<P2, R2> payload) => switch (payload) {
    RequestLoading<P2, R2>() => handleLoading(),
    RequestSuccess<P2, R2>(:final value, :final extras) => _tryMapValue(
      extras![0] as R1,
      value,
    ),
    RequestInitial<P2, R2>() => null,
    RequestError<P2, R2>(:final error, :final stackTrace) => handleError(
      error,
      stackTrace,
    ),
  };

  void _tryMapValue(R1 primaryValue, R2 dependentValue) {
    try {
      handleData(map(primaryValue, dependentValue));
    } on Object catch (error, st) {
      handleError(error, st);
    }
  }

  /// Maps the results from both sources into the final entity [E].
  @protected
  E map(R1 primaryValue, R2 dependentValue);

  /// Flushes both the primary and dependent sources
  /// and resets the repository state.
  @override
  Future<void> flush() async {
    await Future.wait([_primarySource.flush(), _dependentSource.flush()]);
    handleFlush();
  }

  /// Disposes the repository and both underlying sources.
  @override
  @nonVirtual
  Future<void> dispose() async {
    await super.dispose();
    await _primarySourceSubscription.cancel();
    await _dependentSourceSubscription.cancel();
    await _primarySource.dispose();
    await _dependentSource.dispose();
  }
}
