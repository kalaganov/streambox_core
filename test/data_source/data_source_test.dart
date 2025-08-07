import 'dart:async';

import 'package:streambox_core/streambox_core.dart';
import 'package:test/test.dart';

import '../mock_memory_store_adapter/mock_memory_store_adapter.dart';

void main() {
  group('BaseDataSource', () {
    late DataSource<_MockRequestParams, String> dataSource;

    setUp(() {
      dataSource = _MockDataSource(
        cacheStrategy: _MockCacheThenRefreshStrategy(cache: _MockMemoryCache()),
      );
    });

    tearDown(() async => dataSource.dispose());

    test('emits DataSuccess on successful fetch', () async {
      final events = <RequestPayload<_MockRequestParams, String>>[];
      final sub = dataSource.stream.listen(events.add);

      dataSource.fetch(const _MockRequestParams(2));

      await Future<void>.delayed(Duration.zero);
      expect(events.last, isA<RequestPayload<_MockRequestParams, String>>());
      expect((events.last as RequestSuccess).value, 'something: 2');

      await sub.cancel();
    });

    test('emits DataError on fetch exception', () async {
      final events = <RequestPayload<_MockRequestParams, String>>[];
      final sub = dataSource.stream.listen(events.add);

      dataSource.fetch(const _MockRequestParams(404));

      await Future<void>.delayed(Duration.zero);
      expect(events.last, isA<RequestError<_MockRequestParams, String>>());
      expect((events.last as RequestError).error, isA<_MyApiException>());

      await sub.cancel();
    });

    test('emits DataInitial after flush', () async {
      final events = <RequestPayload<_MockRequestParams, String>>[];
      final sub = dataSource.stream.listen(events.add);

      dataSource.fetch(const _MockRequestParams(2));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await dataSource.flush();

      await Future<void>.delayed(Duration.zero);
      expect(events.first, isA<RequestPayload<_MockRequestParams, String>>());
      expect(events.length, equals(2));
      expect(
        (events.first as RequestSuccess<_MockRequestParams, String>).value,
        equals('something: 2'),
      );
      expect(events.last, isA<RequestInitial<_MockRequestParams, String>>());

      await sub.cancel();
    });

    test('emits updated data on second fetch if strategy allows', () async {
      final events = <RequestPayload<_MockRequestParams, String>>[];
      final sub = dataSource.stream.listen(events.add);

      dataSource.fetch(const _MockRequestParams(2));
      await Future<void>.delayed(Duration.zero);

      (dataSource as _MockDataSource).api.overrideResponse = 'updated: 2';
      dataSource.fetch(const _MockRequestParams(2));
      await Future<void>.delayed(Duration.zero);

      expect(
        events.whereType<RequestPayload<_MockRequestParams, String>>().length,
        greaterThan(1),
      );
      expect(events.last, isA<RequestPayload<_MockRequestParams, String>>());
      expect((events.last as RequestSuccess).value, 'updated: 2');

      await sub.cancel();
    });

    test('fetch after dispose does nothing', () async {
      final events = <RequestPayload<_MockRequestParams, String>>[];
      final sub = dataSource.stream.listen(events.add);

      await dataSource.dispose();
      await Future<void>.delayed(Duration.zero);
      dataSource.fetch(const _MockRequestParams(2));
      await Future<void>.delayed(Duration.zero);

      await sub.cancel();
      expect(events, isEmpty);
    });

    test('RequestLoading constructor works', () {
      const params = _MockRequestParams(123);
      const loading = RequestLoading<_MockRequestParams, int>(params: params);

      expect(loading.params, params);
      expect(loading, isA<RequestLoading<_MockRequestParams, int>>());
    });
  });
}

class _MockRequestParams implements RequestParams {
  const _MockRequestParams(this.id);

  final int id;

  @override
  String get cacheKey => '$id';

  @override
  String toString() => '$id';
}

class _MyApi {
  String? overrideResponse;

  Future<String> fetchSomething(_MockRequestParams? params) async {
    if (params == null) throw StateError('');
    if (params.id == 404) throw _MyApiException('Not found');
    return overrideResponse ?? 'something: ${params.id}';
  }
}

class _MyApiException implements Exception {
  _MyApiException(this.message);

  final String message;

  @override
  String toString() => 'API error: $message';
}

class _MockDataSource extends BaseDataSource<_MockRequestParams, String> {
  _MockDataSource({required super.cacheStrategy});

  final api = _MyApi();

  @override
  Future<String> request(_MockRequestParams? params) {
    return api.fetchSomething(params);
  }
}

class _MockMemoryCache extends BaseKeyValueCache<String> {
  _MockMemoryCache() : super(store: MockMemoryStoreAdapter());

  @override
  String get keyPrefix => 'foo';

  @override
  String deserialize(String source) => source;

  @override
  String serialize(String value) => value;
}

class _MockCacheThenRefreshStrategy
    extends CacheThenRefreshStrategy<_MockRequestParams, String> {
  _MockCacheThenRefreshStrategy({required super.cache});
}
