import 'package:streambox_core/streambox_core.dart';
import 'package:test/test.dart';

import '../mock_memory_store_adapter/mock_memory_store_adapter.dart';

void main() {
  group('MemoryCacheFirstStrategy', () {
    late CacheStrategy<String, int> strategy;

    setUp(() => strategy = _MockStrategy());

    tearDown(() => strategy.dispose());

    test('emits fetch value if cache is empty', () async {
      final events = <RequestPayload<String, int>>[];
      strategy.stream.listen(events.add);

      strategy.request('key', null, () async => 1);
      await Future<void>.delayed(Duration.zero);

      expect(events.length, equals(1));
      expect(events.single, isA<RequestSuccess<String, int>>());
      expect(
        (events.single as RequestSuccess<String, int>).value,
        equals(1),
      );
    });

    test(
      'emits cached value on second request even if fetch returns different',
      () async {
        final events = <RequestPayload<String, int>>[];
        strategy.stream.listen(events.add);

        strategy.request('key', null, () async => 1);
        await Future<void>.delayed(Duration.zero);

        expect(events.length, equals(1));
        expect(events.single, isA<RequestSuccess<String, int>>());
        expect(
          (events.single as RequestSuccess<String, int>).value,
          equals(1),
        );

        strategy.request('key', null, () async => 2);
        await Future<void>.delayed(Duration.zero);

        expect(events.length, equals(2));
        expect(events[0], isA<RequestSuccess<String, int>>());
        expect(
          (events[0] as RequestSuccess<String, int>).value,
          equals(1),
        );
        expect(events[1], isA<RequestSuccess<String, int>>());
        expect(
          (events[1] as RequestSuccess<String, int>).value,
          equals(1),
        );
      },
    );

    test('emits empty after flush and new value after re-request', () async {
      final events = <RequestPayload<String, int>>[];
      strategy.stream.listen(events.add);

      strategy.request('key', null, () async => 1);
      await Future<void>.delayed(Duration.zero);

      expect(events.length, equals(1));
      expect(events.single, isA<RequestSuccess<String, int>>());
      expect(
        (events.single as RequestSuccess<String, int>).value,
        equals(1),
      );

      strategy.request('key', null, () async => 2);
      await Future<void>.delayed(Duration.zero);

      expect(events.length, equals(2));
      expect(events[0], isA<RequestSuccess<String, int>>());
      expect(
        (events[0] as RequestSuccess<String, int>).value,
        equals(1),
      );
      expect(events[1], isA<RequestSuccess<String, int>>());
      expect(
        (events[1] as RequestSuccess<String, int>).value,
        equals(1),
      );

      await strategy.flush();
      await Future<void>.delayed(Duration.zero);

      expect(events.length, equals(3));
      expect(events[0], isA<RequestSuccess<String, int>>());
      expect(
        (events[0] as RequestSuccess<String, int>).value,
        equals(1),
      );
      expect(events[1], isA<RequestSuccess<String, int>>());
      expect(
        (events[1] as RequestSuccess<String, int>).value,
        equals(1),
      );
      expect(events[2], isA<RequestInitial<String, int>>());

      strategy.request('key', null, () async => 2);
      await Future<void>.delayed(Duration.zero);
      expect(events.length, equals(4));
      expect(events[0], isA<RequestSuccess<String, int>>());
      expect(
        (events[0] as RequestSuccess<String, int>).value,
        equals(1),
      );
      expect(events[1], isA<RequestSuccess<String, int>>());
      expect(
        (events[1] as RequestSuccess<String, int>).value,
        equals(1),
      );
      expect(events[2], isA<RequestInitial<String, int>>());
      expect(events[3], isA<RequestSuccess<String, int>>());
      expect(
        (events[3] as RequestSuccess<String, int>).value,
        equals(2),
      );
    });

    test('emits RequestError if fetch throws', () {
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

    test('request after dispose does nothing', () async {
      final emitted = <RequestPayload<String, int>>[];
      strategy.stream.listen(emitted.add);

      await strategy.dispose();
      strategy.request('key', null, () async => 42);
      await Future<void>.delayed(Duration.zero);
      expect(emitted, isEmpty);
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

class _MockStrategy extends CacheFirstStrategy<String, int> {
  _MockStrategy() : super(cache: _MockMemoryCache());

  @override
  String resolveKey(String? params) => '${params.hashCode}';
}
