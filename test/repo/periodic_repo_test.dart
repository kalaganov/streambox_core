import 'dart:async';

import 'package:streambox_core/src/common/data_state.dart';
import 'package:streambox_core/src/common/request_params.dart';
import 'package:streambox_core/src/common/request_payload.dart';
import 'package:streambox_core/src/data_sources/base_data_source.dart';
import 'package:streambox_core/src/data_sources/data_source_interface.dart';
import 'package:streambox_core/src/repo/periodic_repo.dart';
import 'package:streambox_core/src/repo/repo_interface.dart';
import 'package:streambox_core/src/strategies/impl/no_op_cache_strategy.dart';
import 'package:test/test.dart';

//
// ignore_for_file: cascade_invocations

void main() {
  group('PeriodicRepo', () {
    test('emits DataSuccess 1', () async {
      late DataSource<_MockRequestParams, _Response> source;
      late Repo<_MockRequestParams, String> repo;

      source = _MockDataSource();
      repo = _MockRepo(
        dataSource: source,
        interval: const Duration(milliseconds: 200),
      );

      final events = <DataState<String>>[];
      final sub = repo.stream.listen(events.add);

      repo.fetch(const _MockRequestParams('a'));

      await Future<dynamic>.delayed(const Duration(milliseconds: 2000));
      expect(events, hasLength(3));
      for (final e in events) {
        expect(e, isA<DataSuccess<String>>());
        expect(
          (e as DataSuccess<String>).value,
          'mapped value: success',
        );
      }

      await sub.cancel();
      await repo.dispose();
    });

    test('emits DataSuccess on fetchAwait', () async {
      late DataSource<_MockRequestParams, _Response> source;
      late Repo<_MockRequestParams, String> repo;

      source = _MockDataSource();
      repo = _MockRepo(
        dataSource: source,
        interval: const Duration(milliseconds: 200),
      );

      final events = <DataState<String>>[];
      final sub = repo.stream.listen(events.add);

      final result = await repo.fetchAwait(const _MockRequestParams('a'));

      expect(events, hasLength(1));
      expect(events.single, isA<DataSuccess<String>>());
      expect(
        (events.single as DataSuccess<String>).value,
        'mapped value: success',
      );
      expect(result, isA<DataSuccess<String>>());
      expect(
        (result as DataSuccess<String>).value,
        'mapped value: success',
      );

      await sub.cancel();
      await repo.dispose();
    });

    test('emits DataSuccess 2', () async {
      late DataSource<_MockRequestParams, _Response> source;
      late Repo<_MockRequestParams, String> repo;

      source = _MockDataSource();
      repo = _MockRepo(
        dataSource: source,
        interval: const Duration(milliseconds: 200),
        emitOnEachCycle: false,
      );

      final events = <DataState<String>>[];
      final sub = repo.stream.listen(events.add);

      repo.fetch(const _MockRequestParams('a'));

      await Future<dynamic>.delayed(const Duration(milliseconds: 2000));
      expect(events, hasLength(1));
      for (final e in events) {
        expect(e, isA<DataSuccess<String>>());
        expect(
          (e as DataSuccess<String>).value,
          'mapped value: success',
        );
      }

      await sub.cancel();
      await repo.dispose();
    });

    test('emits DataSuccess 3', () async {
      late DataSource<_MockRequestParams, _Response> source;
      late Repo<_MockRequestParams, String> repo;

      source = _MockDataSourceFail();
      repo = _MockRepoFailAfterFirstFetch(
        dataSource: source,
        interval: const Duration(milliseconds: 200),
      );

      final events = <DataState<String>>[];
      final sub = repo.stream.listen(events.add);

      repo.fetch(const _MockRequestParams('a'));

      await Future<dynamic>.delayed(const Duration(milliseconds: 2000));
      expect(events, hasLength(1));
      expect(events.single, isA<DataError<String>>());
      expect(
        (events.single as DataError<String>).error,
        same(_error),
      );

      await sub.cancel();
      await repo.dispose();
    });

    test('emits DataSuccess 4', () async {
      late DataSource<_MockRequestParams, _Response> source;
      late Repo<_MockRequestParams, String> repo;

      source = _MockDataSourceFail();
      repo = _MockRepoFailAfterFirstFetch(
        dataSource: source,
        interval: const Duration(milliseconds: 200),
        emitOnEachCycle: false,
      );

      final events = <DataState<String>>[];
      final sub = repo.stream.listen(events.add);

      repo.fetch(const _MockRequestParams('a'));

      await Future<dynamic>.delayed(const Duration(milliseconds: 2000));
      expect(events, hasLength(1));
      expect(events.single, isA<DataError<String>>());
      expect(
        (events.single as DataError<String>).error,
        same(_error),
      );

      await sub.cancel();
      await repo.dispose();
    });

    test('emits DataSuccess 5', () async {
      late DataSource<_MockRequestParams, _Response> source;
      late Repo<_MockRequestParams, String> repo;

      source = _MockDataSourceDelayed();
      repo = _MockRepo(
        dataSource: source,
        interval: const Duration(milliseconds: 200),
      );

      final events = <DataState<String>>[];
      final sub = repo.stream.listen(events.add);

      repo.fetch(const _MockRequestParams('a'));

      await Future<dynamic>.delayed(const Duration(milliseconds: 100));
      await repo.dispose();

      expect(events, isEmpty);

      await sub.cancel();
      await repo.dispose();
    });

    test('PeriodicRepo.flush delegates to dataSource.flush', () async {
      late DataSource<_MockRequestParams, _Response> source;
      late Repo<_MockRequestParams, String> repo;

      source = _MockDataSource();
      repo = _MockRepoFlushed(
        dataSource: source,
        interval: const Duration(milliseconds: 100),
      );

      final events = <DataState<String>>[];
      final sub = repo.stream.listen(events.add);

      repo.fetch(const _MockRequestParams('a'));
      await Future<dynamic>.delayed(const Duration(milliseconds: 150));
      await repo.flush();
      await Future<dynamic>.delayed(Duration.zero);

      expect(events.length, equals(2));
      expect(events[0], isA<DataSuccess<String>>());
      expect(events[1], isA<DataInitial<String>>());
      await sub.cancel();
    });
  });
}

class _Response {
  const _Response(this.value);

  final String value;
}

class _MockDataSource extends BaseDataSource<_MockRequestParams, _Response> {
  _MockDataSource() : super(cacheStrategy: NoOpCacheStrategy());

  @override
  Future<_Response> request(_MockRequestParams? params) {
    return Future.value(const _Response('success'));
  }
}

class _MockDataSourceDelayed
    extends BaseDataSource<_MockRequestParams, _Response> {
  _MockDataSourceDelayed() : super(cacheStrategy: NoOpCacheStrategy());

  @override
  Future<_Response> request(_MockRequestParams? params) {
    return Future.delayed(
      const Duration(milliseconds: 200),
      () => const _Response('success'),
    );
  }
}

class _MockDataSourceFail
    extends BaseDataSource<_MockRequestParams, _Response> {
  _MockDataSourceFail() : super(cacheStrategy: NoOpCacheStrategy());

  @override
  Future<_Response> request(_MockRequestParams? params) {
    throw _error;
  }
}

final _error = Exception('');

class _MockRepo extends PeriodicRepo<_MockRequestParams, _Response, String> {
  _MockRepo({
    required super.dataSource,
    required super.interval,
    super.emitOnEachCycle,
  });

  @override
  String map(_MockRequestParams? params, _Response value) =>
      'mapped value: ${value.value}';

  @override
  bool shouldContinue(
    int cycle,
    RequestPayload<_MockRequestParams, _Response> payload,
  ) {
    return cycle < 4;
  }
}

class _MockRepoFailAfterFirstFetch
    extends PeriodicRepo<_MockRequestParams, _Response, String> {
  _MockRepoFailAfterFirstFetch({
    required super.dataSource,
    required super.interval,
    super.emitOnEachCycle,
  });

  @override
  String map(_MockRequestParams? params, _Response value) =>
      'mapped value: ${value.value}';

  @override
  bool shouldContinue(
    int cycle,
    RequestPayload<_MockRequestParams, _Response> payload,
  ) {
    return payload is! RequestError;
  }
}

class _MockRepoFlushed
    extends PeriodicRepo<_MockRequestParams, _Response, String> {
  _MockRepoFlushed({
    required super.dataSource,
    required super.interval,
  });

  @override
  String map(_MockRequestParams? params, _Response value) =>
      'mapped value: ${value.value}';

  @override
  bool shouldContinue(
    int cycle,
    RequestPayload<_MockRequestParams, _Response> payload,
  ) {
    return false;
  }
}

class _MockRequestParams implements RequestParams {
  const _MockRequestParams(this.value);

  final String value;

  @override
  String get cacheKey => throw UnimplementedError();

  @override
  String toString() => value;
}
