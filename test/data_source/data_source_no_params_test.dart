import 'dart:async';

import 'package:streambox_core/streambox_core.dart';
import 'package:test/test.dart';

import '../mock_memory_store_adapter/mock_memory_store_adapter.dart';

void main() {
  group('BaseDataSource no params', () {
    late DataSource<void, String> dataSource;

    setUp(() {
      dataSource = _MockDataSource(
        cacheStrategy: _MockCacheStrategy(),
      );
    });

    tearDown(() async => dataSource.dispose());

    test('emits DataSuccess on successful fetch', () async {
      final events = <RequestPayload<void, String>>[];
      final sub = dataSource.stream.listen(events.add);

      dataSource.fetch();

      await Future<void>.delayed(Duration.zero);
      expect(events.last, isA<RequestPayload<void, String>>());
      expect((events.last as RequestSuccess).value, 'something: _');

      await sub.cancel();
    });

    test('emits DataError on fetch exception', () async {
      final events = <RequestPayload<void, String>>[];
      final sub = dataSource.stream.listen(events.add);

      (dataSource as _MockDataSource).api.success = false;
      dataSource.fetch();

      await Future<void>.delayed(Duration.zero);
      expect(events.last, isA<RequestPayload<void, String>>());
      expect((events.last as RequestError).error, isA<_MyApiException>());

      await sub.cancel();
    });

    test('emits DataInitial after flush', () async {
      final events = <RequestPayload<void, String>>[];
      final sub = dataSource.stream.listen(events.add);

      dataSource.fetch();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await dataSource.flush();

      await Future<void>.delayed(Duration.zero);
      expect(events.length, equals(2));
      expect(events.first, isA<RequestPayload<void, String>>());
      expect(
        (events.first as RequestSuccess<void, String>).value,
        equals('something: _'),
      );
      expect(events.last, isA<RequestInitial<void, String>>());

      await sub.cancel();
    });

    test('emits updated data on second fetch if strategy allows', () async {
      final events = <RequestPayload<void, String>>[];
      final sub = dataSource.stream.listen(events.add);

      dataSource.fetch();
      await Future<void>.delayed(Duration.zero);

      (dataSource as _MockDataSource).api.overrideResponse = 'updated: 2';
      dataSource.fetch();
      await Future<void>.delayed(Duration.zero);

      expect(events.length, equals(3));
      expect(events.last, isA<RequestPayload<void, String>>());
      expect((events.last as RequestSuccess).value, 'updated: 2');

      await sub.cancel();
    });

    test('fetch after dispose does nothing', () async {
      final events = <RequestPayload<void, String>>[];
      final sub = dataSource.stream.listen(events.add);

      await dataSource.dispose();
      await Future<void>.delayed(Duration.zero);
      dataSource.fetch();
      await Future<void>.delayed(Duration.zero);

      await sub.cancel();
      expect(events, isEmpty);
    });
  });
}

class _MyApi {
  String? overrideResponse;
  bool success = true;

  Future<String> fetchSomething() async {
    if (!success) throw _MyApiException('Not found');
    return overrideResponse ?? 'something: _';
  }
}

class _MyApiException implements Exception {
  _MyApiException(this.message);

  final String message;

  @override
  String toString() => 'API error: $message';
}

class _MockDataSource extends BaseDataSource<void, String> {
  _MockDataSource({required super.cacheStrategy});

  final api = _MyApi();

  @override
  Future<String> request(void params) {
    return api.fetchSomething();
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

class _MockCacheStrategy extends CacheThenRefreshStrategy<String, String> {
  _MockCacheStrategy() : super(cache: _MockMemoryCache());

  @override
  String resolveKey(String? params) => 'static key';
}
