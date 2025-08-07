import 'dart:async';

import 'package:streambox_core/src/common/data_state.dart';
import 'package:streambox_core/src/common/request_params.dart';
import 'package:streambox_core/src/data_sources/base_data_source.dart';
import 'package:streambox_core/src/data_sources/data_source_interface.dart';
import 'package:streambox_core/src/repo/repo_interface.dart';
import 'package:streambox_core/src/repo/single_source_repo.dart';
import 'package:streambox_core/src/strategies/impl/no_op_cache_strategy.dart';
import 'package:test/test.dart';

void main() {
  group('SingleSourceRepo', () {
    test('emits DataSuccess', () async {
      late DataSource<_MockRequestParams, _Response> source;
      late Repo<_MockRequestParams, String> repo;

      source = _MockDataSource();
      repo = _MockRepoImpl(dataSource: source);

      final events = <DataState<String>>[];
      final sub = repo.stream.listen(events.add);

      repo.fetch(const _MockRequestParams('a'));
      await Future<dynamic>.delayed(Duration.zero);

      expect(events.length, 1);
      expect(events.last, isA<DataSuccess<String>>());
      expect(
        (events.last as DataSuccess<String>).value,
        equals('mapped value: success'),
      );

      await sub.cancel();
      await repo.dispose();
    });

    test('emits DataSuccess on fetchAwait', () async {
      late DataSource<_MockRequestParams, _Response> source;
      late Repo<_MockRequestParams, String> repo;

      source = _MockDataSource();
      repo = _MockRepoImpl(dataSource: source);

      final events = <DataState<String>>[];
      final sub = repo.stream.listen(events.add);

      final result = await repo.fetchAwait(const _MockRequestParams('a'));

      expect(events.length, 1);
      expect(events.last, isA<DataSuccess<String>>());
      expect(
        (events.last as DataSuccess<String>).value,
        equals('mapped value: success'),
      );
      expect(result, isA<DataSuccess<String>>());
      expect(
        (result as DataSuccess<String>).value,
        equals('mapped value: success'),
      );

      await sub.cancel();
      await repo.dispose();
    });

    test('emits DataSuccess initial fetch', () async {
      late DataSource<_MockRequestParams, _Response> source;
      late Repo<_MockRequestParams, String> repo;

      source = _MockDataSourceInitial();
      repo = _MockRepoInitial(dataSource: source);

      final events = <DataState<String>>[];
      final sub = repo.stream.listen(events.add);

      repo.fetch(const _MockRequestParams('success'));
      await Future<dynamic>.delayed(Duration.zero);

      expect(events.length, 2);
      expect(events.first, isA<DataSuccess<String>>());
      expect(
        (events.first as DataSuccess<String>).value,
        equals('mapped value: response: initial params'),
      );

      expect(events.last, isA<DataSuccess<String>>());
      expect(
        (events.last as DataSuccess<String>).value,
        equals('mapped value: response: success'),
      );

      await sub.cancel();
      await repo.dispose();
    });

    test('emits DataSuccess initial fetch only', () async {
      late DataSource<_MockRequestParams, _Response> source;
      late Repo<_MockRequestParams, String> repo;

      source = _MockDataSourceInitial();
      repo = _MockRepoInitial(dataSource: source);

      final events = <DataState<String>>[];
      final sub = repo.stream.listen(events.add);

      await Future<dynamic>.delayed(Duration.zero);

      expect(events.length, 1);
      expect(events.first, isA<DataSuccess<String>>());
      expect(
        (events.first as DataSuccess<String>).value,
        equals('mapped value: response: initial params'),
      );

      await sub.cancel();
      await repo.dispose();
    });

    test('emits DataError if mapper throws', () async {
      late DataSource<_MockRequestParams, _Response> source;
      late Repo<_MockRequestParams, String> repo;

      source = _MockDataSource();
      repo = _MockRepoFail(dataSource: source);

      final events = <DataState<String>>[];
      final sub = repo.stream.listen(events.add);

      repo.fetch(const _MockRequestParams('a'));
      await Future<dynamic>.delayed(Duration.zero);

      expect(events.length, 1);
      expect(events.last, isA<DataError<String>>());
      expect((events.last as DataError<String>).error, isA<_MyException>());
      expect((events.last as DataError<String>).stackTrace, isNotNull);

      await sub.cancel();
      await repo.dispose();
    });

    test('emits DataError if fetch throws', () async {
      late DataSource<_MockRequestParams, _Response> source;
      late Repo<_MockRequestParams, String> repo;

      source = _MockDataSourceFail();
      repo = _MockRepoImpl(dataSource: source);

      final events = <DataState<String>>[];
      final sub = repo.stream.listen(events.add);

      repo.fetch(const _MockRequestParams('a'));
      await Future<dynamic>.delayed(Duration.zero);

      expect(events.length, 1);
      expect(events.last, isA<DataError<String>>());
      expect((events.last as DataError<String>).error, same(_error));
      expect((events.last as DataError<String>).stackTrace, isNotNull);

      await sub.cancel();
      await repo.dispose();
    });

    test('emits DataInitial', () async {
      late DataSource<_MockRequestParams, _Response> source;
      late Repo<_MockRequestParams, String> repo;

      source = _MockDataSource();
      repo = _MockRepoImpl(dataSource: source);

      final events = <DataState<String>>[];
      final sub = repo.stream.listen(events.add);

      await repo.flush();
      await Future<dynamic>.delayed(Duration.zero);

      expect(events.length, 1);
      expect(events.last, isA<DataInitial<String>>());

      await sub.cancel();
      await repo.dispose();
    });

    test('fetch after dispose does nothing', () async {
      late DataSource<_MockRequestParams, _Response> source;
      late Repo<_MockRequestParams, String> repo;

      source = _MockDataSource();
      repo = _MockRepoImpl(dataSource: source);

      final events = <DataState<String>>[];
      final sub = repo.stream.listen(events.add);

      await repo.dispose();
      await Future<dynamic>.delayed(Duration.zero);

      expect(events, isEmpty);

      await sub.cancel();
      await repo.dispose();

      expectLater(repo.stream, emitsDone).ignore();
    });
  });
}

class _Response {
  const _Response(this.value);

  final String value;
}

final class _MyException implements Exception {
  const _MyException();

  @override
  String toString() => '_MyException{}';
}

class _MockDataSource extends BaseDataSource<_MockRequestParams, _Response> {
  _MockDataSource() : super(cacheStrategy: _MockNoOpCacheStrategy());

  @override
  Future<_Response> request(_MockRequestParams? params) {
    return Future.value(const _Response('success'));
  }
}

class _MockDataSourceInitial
    extends BaseDataSource<_MockRequestParams, _Response> {
  _MockDataSourceInitial() : super(cacheStrategy: _MockNoOpCacheStrategy());

  @override
  Future<_Response> request(_MockRequestParams? params) {
    return Future.value(_Response('response: $params'));
  }
}

class _MockDataSourceFail
    extends BaseDataSource<_MockRequestParams, _Response> {
  _MockDataSourceFail() : super(cacheStrategy: _MockNoOpCacheStrategy());

  @override
  Future<_Response> request(_MockRequestParams? params) {
    return throw _error;
  }
}

class _MockRepoImpl
    extends SingleSourceRepo<_MockRequestParams, _Response, String> {
  _MockRepoImpl({required super.dataSource});

  @override
  String map(_MockRequestParams? params, _Response value) =>
      'mapped value: ${value.value}';
}

class _MockRepoInitial
    extends SingleSourceRepo<_MockRequestParams, _Response, String> {
  _MockRepoInitial({required super.dataSource})
    : super(initialFetchParams: _initialParams, fetchOnInit: true);

  @override
  String map(_MockRequestParams? params, _Response value) =>
      'mapped value: ${value.value}';
}

class _MockRepoFail
    extends SingleSourceRepo<_MockRequestParams, _Response, String> {
  _MockRepoFail({required super.dataSource});

  @override
  String map(_MockRequestParams? params, _Response value) =>
      throw const _MyException();
}

final _error = Exception('fetch error');
const _initialParams = _MockRequestParams('initial params');

class _MockRequestParams implements RequestParams {
  const _MockRequestParams(this.value);

  final String value;

  @override
  String get cacheKey => throw UnimplementedError();

  @override
  String toString() => value;
}

class _MockNoOpCacheStrategy
    extends NoOpCacheStrategy<_MockRequestParams, _Response> {
  _MockNoOpCacheStrategy();
}
