import 'package:streambox_core/streambox_core.dart';
import 'package:test/test.dart';

import '../mock_memory_store_adapter/mock_memory_store_adapter.dart';

void main() {
  group('MemoryCacheThenRefreshStrategy', () {
    late CacheStrategy<_MockRequestParams, int> strategy;

    setUp(() => strategy = _MockCacheStrategy(cache: _MockMemoryCache()));

    tearDown(() async => strategy.dispose());

    test('emits only fetch value if cache is empty', () {
      expectLater(
        strategy.stream,
        emitsInOrder([
          isA<RequestSuccess<_MockRequestParams, int>>().having(
            (e) => e.value,
            'value',
            42,
          ),
        ]),
      );

      strategy.request(const _MockRequestParams('key'), null, () async => 42);
    });

    test('emits cached value then new value if different', () async {
      final events = <int>[];
      final sub = strategy.stream.listen((e) {
        if (e case RequestSuccess(:final value)) events.add(value);
      });

      strategy.request(const _MockRequestParams('key'), null, () async => 1);
      await Future<void>.delayed(Duration.zero);
      strategy.request(const _MockRequestParams('key'), null, () async => 2);
      await Future<void>.delayed(Duration.zero);

      await sub.cancel();
      expect(events, [1, 1, 2]);
    });

    test('emits only cached value if fetch returns same value', () async {
      final events = <int>[];
      final sub = strategy.stream.listen((e) {
        if (e case RequestSuccess(:final value)) events.add(value);
      });

      strategy.request(const _MockRequestParams('key'), null, () async => 1);
      await Future<void>.delayed(Duration.zero);
      strategy.request(const _MockRequestParams('key'), null, () async => 1);
      await Future<void>.delayed(Duration.zero);
      strategy.request(const _MockRequestParams('key'), null, () async => 2);
      await Future<void>.delayed(Duration.zero);
      strategy.request(const _MockRequestParams('key'), null, () async => 2);
      await Future<void>.delayed(Duration.zero);

      await sub.cancel();
      expect(events, [1, 1, 1, 2, 2]);
    });

    test('emits DataError if fetch throws', () {
      expectLater(
        strategy.stream,
        emits(
          isA<RequestError<_MockRequestParams, int>>().having(
            (e) => e.error,
            'error',
            isA<Exception>(),
          ),
        ),
      );

      strategy.request(
        const _MockRequestParams('key'),
        null,
        () async => throw Exception('fail'),
      );
    });

    test('flush emits DataInitial and resets cache', () async {
      final events = <RequestPayload<_MockRequestParams, int>>[];
      final sub = strategy.stream.listen(events.add);

      strategy.request(const _MockRequestParams('key'), null, () async => 1);
      await Future<void>.delayed(Duration.zero);
      await strategy.flush();
      await Future<void>.delayed(Duration.zero);
      strategy.request(const _MockRequestParams('key'), null, () async => 2);
      await Future<void>.delayed(Duration.zero);

      await sub.cancel();

      expect(events.length, equals(3));
      expect(events[0], isA<RequestSuccess<_MockRequestParams, int>>());
      expect(
        (events[0] as RequestSuccess<_MockRequestParams, int>).value,
        equals(1),
      );
      expect(events[1], isA<RequestInitial<_MockRequestParams, int>>());
      expect(events[2], isA<RequestSuccess<_MockRequestParams, int>>());
      expect(
        (events[2] as RequestSuccess<_MockRequestParams, int>).value,
        equals(2),
      );
    });

    test('repeated flush resets cache each time', () async {
      final events = <RequestPayload<_MockRequestParams, int>>[];
      final sub = strategy.stream.listen(events.add);

      strategy.request(const _MockRequestParams('key'), null, () async => 10);
      await Future<void>.delayed(Duration.zero);
      await strategy.flush();
      await Future<void>.delayed(Duration.zero);
      await strategy.flush();
      await Future<void>.delayed(Duration.zero);

      await sub.cancel();

      expect(events.length, equals(3));
      expect(events[0], isA<RequestSuccess<_MockRequestParams, int>>());
      expect(
        (events[0] as RequestSuccess<_MockRequestParams, int>).value,
        equals(10),
      );
      expect(events[1], isA<RequestInitial<_MockRequestParams, int>>());
      expect(events[2], isA<RequestInitial<_MockRequestParams, int>>());
    });

    test('handles multiple keys independently', () async {
      final events = <int>[];
      final sub = strategy.stream.listen((e) {
        if (e case RequestSuccess(:final value)) events.add(value);
      });

      strategy.request(const _MockRequestParams('a'), null, () async => 1);
      await Future<void>.delayed(Duration.zero);
      strategy.request(const _MockRequestParams('b'), null, () async => 2);
      await Future<void>.delayed(Duration.zero);
      strategy.request(const _MockRequestParams('a'), null, () async => 42);
      await Future<void>.delayed(Duration.zero);

      await sub.cancel();
      expect(events, [1, 2, 1, 42]);
    });

    test('after flush, same key emits new value again', () async {
      final events = <int>[];
      final sub = strategy.stream.listen((e) {
        if (e case RequestSuccess(:final value)) events.add(value);
      });

      strategy.request(const _MockRequestParams('key'), null, () async => 1);
      await Future<void>.delayed(Duration.zero);
      await strategy.flush();
      await Future<void>.delayed(Duration.zero);
      strategy.request(const _MockRequestParams('key'), null, () async => 2);
      await Future<void>.delayed(Duration.zero);

      await sub.cancel();
      expect(events, [1, 2]);
    });

    test('emits value after error on next request', () async {
      final events = <RequestPayload<_MockRequestParams, int>>[];
      final sub = strategy.stream.listen(events.add);

      strategy.request(
        const _MockRequestParams('key'),
        null,
        () async => throw Exception('fail'),
      );
      await Future<void>.delayed(Duration.zero);

      strategy.request(const _MockRequestParams('key'), null, () async => 5);
      await Future<void>.delayed(Duration.zero);

      await sub.cancel();

      expect(events.length, equals(2));
      expect(events[0], isA<RequestError<_MockRequestParams, int>>());
      expect(events[1], isA<RequestSuccess<_MockRequestParams, int>>());
      expect(
        (events[1] as RequestSuccess<_MockRequestParams, int>).value,
        equals(5),
      );
    });

    test('request after dispose does nothing', () async {
      final events = <RequestPayload<_MockRequestParams, int>>[];
      final sub = strategy.stream.listen(events.add);

      await strategy.dispose();
      strategy.request(const _MockRequestParams('key'), null, () async => 42);
      await Future<void>.delayed(Duration.zero);

      await sub.cancel();
      expect(events, isEmpty);
    });

    test('flush without active subscription still works', () async {
      strategy.request(const _MockRequestParams('key'), null, () async => 1);
      await strategy.flush();
    });

    test('calling dispose twice is safe', () async {
      await strategy.dispose();
      await strategy.dispose();
    });
  });
}

class _MockMemoryCache extends BaseKeyValueCache<int> {
  _MockMemoryCache() : super(store: MockMemoryStoreAdapter());

  @override
  String get keyPrefix => 'foo';

  @override
  int deserialize(String source) => int.parse(source);

  @override
  String serialize(int value) => '$value';
}

class _MockRequestParams implements RequestParams {
  const _MockRequestParams(this.value);

  final String value;

  @override
  String get cacheKey => 'cacheKey_$value}';

  @override
  String toString() => value;
}

class _MockCacheStrategy
    extends CacheThenRefreshStrategy<_MockRequestParams, int> {
  _MockCacheStrategy({required super.cache});
}
