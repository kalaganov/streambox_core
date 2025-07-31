import 'dart:async';

import 'package:streambox_core/src/common/data_state.dart';
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
      late DataSource<String, _Response> source;
      late Repo<String, String> repo;

      source = _MockDataSource();
      repo = _MockRepo(
        dataSource: source,
        interval: const Duration(milliseconds: 200),
      );

      final events = <DataState<String>>[];
      final sub = repo.stream.listen(events.add);

      repo.fetch('a');

      await Future<dynamic>.delayed(const Duration(milliseconds: 2000));
      expect(events, hasLength(3));
      for (final e in events) {
        expect(e, isA<DataSuccess<String>>());
        expect((e as DataSuccess<String>).value, 'mapped value: success');
      }

      await sub.cancel();
      await repo.dispose();
    });

    test('emits DataSuccess 2', () async {
      late DataSource<String, _Response> source;
      late Repo<String, String> repo;

      source = _MockDataSource();
      repo = _MockRepo(
        dataSource: source,
        interval: const Duration(milliseconds: 200),
        emitOnEachCycle: false,
      );

      final events = <DataState<String>>[];
      final sub = repo.stream.listen(events.add);

      repo.fetch('a');

      await Future<dynamic>.delayed(const Duration(milliseconds: 2000));
      expect(events, hasLength(1));
      for (final e in events) {
        expect(e, isA<DataSuccess<String>>());
        expect((e as DataSuccess<String>).value, 'mapped value: success');
      }

      await sub.cancel();
      await repo.dispose();
    });

    test('emits DataSuccess 3', () async {
      late DataSource<String, _Response> source;
      late Repo<String, String> repo;

      source = _MockDataSourceFail();
      repo = _MockRepoFailAfterFirstFetch(
        dataSource: source,
        interval: const Duration(milliseconds: 200),
      );

      final events = <DataState<String>>[];
      final sub = repo.stream.listen(events.add);

      repo.fetch('a');

      await Future<dynamic>.delayed(const Duration(milliseconds: 2000));
      expect(events, hasLength(1));
      expect(events.single, isA<DataError<String>>());
      expect((events.single as DataError<String>).error, same(_error));

      await sub.cancel();
      await repo.dispose();
    });

    test('emits DataSuccess 4', () async {
      late DataSource<String, _Response> source;
      late Repo<String, String> repo;

      source = _MockDataSourceFail();
      repo = _MockRepoFailAfterFirstFetch(
        dataSource: source,
        interval: const Duration(milliseconds: 200),
        emitOnEachCycle: false,
      );

      final events = <DataState<String>>[];
      final sub = repo.stream.listen(events.add);

      repo.fetch('a');

      await Future<dynamic>.delayed(const Duration(milliseconds: 2000));
      expect(events, hasLength(1));
      expect(events.single, isA<DataError<String>>());
      expect((events.single as DataError<String>).error, same(_error));

      await sub.cancel();
      await repo.dispose();
    });

    test('emits DataSuccess 5', () async {
      late DataSource<String, _Response> source;
      late Repo<String, String> repo;

      source = _MockDataSourceDelayed();
      repo = _MockRepo(
        dataSource: source,
        interval: const Duration(milliseconds: 200),
      );

      final events = <DataState<String>>[];
      final sub = repo.stream.listen(events.add);

      repo.fetch('a');

      await Future<dynamic>.delayed(const Duration(milliseconds: 100));
      await repo.dispose();

      expect(events, isEmpty);

      await sub.cancel();
      await repo.dispose();
    });
  });
}

class _Response {
  const _Response(this.value);

  final String value;
}

class _MockDataSource extends BaseDataSource<String, _Response> {
  _MockDataSource() : super(cacheStrategy: NoOpCacheStrategy());

  @override
  Future<_Response> request(String? params) {
    return Future.value(const _Response('success'));
  }
}

class _MockDataSourceDelayed extends BaseDataSource<String, _Response> {
  _MockDataSourceDelayed() : super(cacheStrategy: NoOpCacheStrategy());

  @override
  Future<_Response> request(String? params) {
    return Future.delayed(
      const Duration(milliseconds: 200),
      () => const _Response('success'),
    );
  }
}

class _MockDataSourceFail extends BaseDataSource<String, _Response> {
  _MockDataSourceFail() : super(cacheStrategy: NoOpCacheStrategy());

  @override
  Future<_Response> request(String? params) {
    throw _error;
  }
}

final _error = Exception('');

class _MockRepo extends PeriodicRepo<String, _Response, String> {
  _MockRepo({
    required super.dataSource,
    required super.interval,
    super.emitOnEachCycle,
  });

  @override
  String map(String? params, _Response value) => 'mapped value: ${value.value}';

  @override
  bool shouldContinue(int cycle, RequestPayload<String, _Response> payload) {
    return cycle < 4;
  }
}

class _MockRepoFailAfterFirstFetch
    extends PeriodicRepo<String, _Response, String> {
  _MockRepoFailAfterFirstFetch({
    required super.dataSource,
    required super.interval,
    super.emitOnEachCycle,
  });

  @override
  String map(String? params, _Response value) => 'mapped value: ${value.value}';

  @override
  bool shouldContinue(int cycle, RequestPayload<String, _Response> payload) {
    return payload is! RequestError;
  }
}
