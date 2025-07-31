import 'package:streambox_core/streambox_core.dart';
import 'package:test/test.dart';

import '../mock_memory_store_adapter/mock_memory_store_adapter.dart';

void main() {
  group('MemoryCacheThenRefreshStrategy', () {
    late CacheStrategy<String, int> strategy;

    setUp(() => strategy = _MockStrategy());

    tearDown(() async => strategy.dispose());

    test('emits only fetch value if cache is empty', () {
      expectLater(
        strategy.stream,
        emitsInOrder([
          isA<RequestSuccess<String, int>>().having(
            (e) => e.value,
            'value',
            42,
          ),
        ]),
      );

      strategy.request('key', null, () async => 42);
    });

    test('emits cached value then new value if different', () async {
      final events = <int>[];
      final sub = strategy.stream.listen((e) {
        if (e case RequestSuccess(:final value)) events.add(value);
      });

      strategy.request('key', null, () async => 1);
      await Future<void>.delayed(Duration.zero);
      strategy.request('key', null, () async => 2);
      await Future<void>.delayed(Duration.zero);

      await sub.cancel();
      expect(events, [1, 1, 2]);
    });

    test('emits only cached value if fetch returns same value', () async {
      final events = <int>[];
      final sub = strategy.stream.listen((e) {
        if (e case RequestSuccess(:final value)) events.add(value);
      });

      strategy.request('key', null, () async => 1);
      await Future<void>.delayed(Duration.zero);
      strategy.request('key', null, () async => 1);
      await Future<void>.delayed(Duration.zero);
      strategy.request('key', null, () async => 2);
      await Future<void>.delayed(Duration.zero);
      strategy.request('key', null, () async => 2);
      await Future<void>.delayed(Duration.zero);

      await sub.cancel();
      expect(events, [1, 1, 1, 2, 2]);
    });

    test('emits DataError if fetch throws', () {
      expectLater(
        strategy.stream,
        emits(
          isA<RequestError<String, int>>().having(
            (e) => e.error,
            'error',
            isA<Exception>(),
          ),
        ),
      );

      strategy.request(
        'key',
        null,
        () async => throw Exception('fail'),
      );
    });

    test('flush emits DataInitial and resets cache', () async {
      final events = <RequestPayload<String, int>>[];
      final sub = strategy.stream.listen(events.add);

      strategy.request('key', null, () async => 1);
      await Future<void>.delayed(Duration.zero);
      await strategy.flush();
      await Future<void>.delayed(Duration.zero);
      strategy.request('key', null, () async => 2);
      await Future<void>.delayed(Duration.zero);

      await sub.cancel();

      expect(events.length, equals(3));
      expect(events[0], isA<RequestSuccess<String, int>>());
      expect(
        (events[0] as RequestSuccess<String, int>).value,
        equals(1),
      );
      expect(events[1], isA<RequestInitial<String, int>>());
      expect(events[2], isA<RequestSuccess<String, int>>());
      expect(
        (events[2] as RequestSuccess<String, int>).value,
        equals(2),
      );
    });

    test('repeated flush resets cache each time', () async {
      final events = <RequestPayload<String, int>>[];
      final sub = strategy.stream.listen(events.add);

      strategy.request('key', null, () async => 10);
      await Future<void>.delayed(Duration.zero);
      await strategy.flush();
      await Future<void>.delayed(Duration.zero);
      await strategy.flush();
      await Future<void>.delayed(Duration.zero);

      await sub.cancel();

      expect(events.length, equals(3));
      expect(events[0], isA<RequestSuccess<String, int>>());
      expect(
        (events[0] as RequestSuccess<String, int>).value,
        equals(10),
      );
      expect(events[1], isA<RequestInitial<String, int>>());
      expect(events[2], isA<RequestInitial<String, int>>());
    });

    test('handles multiple keys independently', () async {
      final events = <int>[];
      final sub = strategy.stream.listen((e) {
        if (e case RequestSuccess(:final value)) events.add(value);
      });

      strategy.request('a', null, () async => 1);
      await Future<void>.delayed(Duration.zero);
      strategy.request('b', null, () async => 2);
      await Future<void>.delayed(Duration.zero);
      strategy.request('a', null, () async => 42);
      await Future<void>.delayed(Duration.zero);

      await sub.cancel();
      expect(events, [1, 2, 1, 42]);
    });

    test('after flush, same key emits new value again', () async {
      final events = <int>[];
      final sub = strategy.stream.listen((e) {
        if (e case RequestSuccess(:final value)) events.add(value);
      });

      strategy.request('key', null, () async => 1);
      await Future<void>.delayed(Duration.zero);
      await strategy.flush();
      await Future<void>.delayed(Duration.zero);
      strategy.request('key', null, () async => 2);
      await Future<void>.delayed(Duration.zero);

      await sub.cancel();
      expect(events, [1, 2]);
    });

    test('emits value after error on next request', () async {
      final events = <RequestPayload<String, int>>[];
      final sub = strategy.stream.listen(events.add);

      strategy.request(
        'key',
        null,
        () async => throw Exception('fail'),
      );
      await Future<void>.delayed(Duration.zero);

      strategy.request('key', null, () async => 5);
      await Future<void>.delayed(Duration.zero);

      await sub.cancel();

      expect(events.length, equals(2));
      expect(events[0], isA<RequestError<String, int>>());
      expect(events[1], isA<RequestSuccess<String, int>>());
      expect(
        (events[1] as RequestSuccess<String, int>).value,
        equals(5),
      );
    });

    test('request after dispose does nothing', () async {
      final events = <RequestPayload<String, int>>[];
      final sub = strategy.stream.listen(events.add);

      await strategy.dispose();
      strategy.request('key', null, () async => 42);
      await Future<void>.delayed(Duration.zero);

      await sub.cancel();
      expect(events, isEmpty);
    });

    test('flush without active subscription still works', () async {
      strategy.request('key', null, () async => 1);
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

class _MockStrategy extends CacheThenRefreshStrategy<String, int> {
  _MockStrategy() : super(cache: _MockMemoryCache());

  @override
  String resolveKey(String? params) => '${params.hashCode}';
}
