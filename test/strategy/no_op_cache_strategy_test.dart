import 'package:streambox_core/streambox_core.dart';
import 'package:test/test.dart';

//
// ignore_for_file: cascade_invocations
void main() {
  group('NoOpCacheStrategy', () {
    late CacheStrategy<String, int> strategy;

    setUp(() => strategy = NoOpCacheStrategy());
    tearDown(() => strategy.dispose());

    test('emits value returned by fetch', () {
      expectLater(
        strategy.stream,
        emitsThrough(
          isA<RequestSuccess<String, int>>().having(
            (e) => e.value,
            'value',
            42,
          ),
        ),
      );

      strategy.request('param', null, () async => 42);
    });

    test('flush emits RequestInitial', () {
      expectLater(strategy.stream, emits(isA<RequestInitial<String, int>>()));

      strategy.flush();
    });

    test('emits error if fetch throws', () {
      expectLater(
        strategy.stream,
        emitsThrough(
          isA<RequestError<String, int>>().having(
            (e) => e.error,
            'error',
            isA<StateError>(),
          ),
        ),
      );

      strategy.request('param', null, () async {
        throw StateError('fetch failed');
      });
    });

    test(
      'independent requests with different keys emit independently',
      () async {
        final emitted = <int>[];
        final sub = strategy.stream.listen((e) {
          if (e case RequestSuccess(:final value)) emitted.add(value);
        });

        strategy.request('a', null, () async => 1);
        await Future<void>.delayed(Duration.zero);
        strategy.request('b', null, () async => 2);
        await Future<void>.delayed(Duration.zero);
        strategy.request('c', null, () async => 3);
        await Future<void>.delayed(Duration.zero);

        await sub.cancel();
        expect(emitted, [1, 2, 3]);
      },
    );

    test('does not cache values between requests', () async {
      final events = <RequestPayload<String, int>>[];
      strategy.stream.listen(events.add);

      expectLater(
        strategy.stream,
        emitsInOrder([
          isA<RequestSuccess<String, int>>().having((e) => e.value, 'value', 1),
          isA<RequestSuccess<String, int>>().having((e) => e.value, 'value', 2),
          isA<RequestSuccess<String, int>>().having((e) => e.value, 'value', 3),
          isA<RequestSuccess<String, int>>().having((e) => e.value, 'value', 3),
        ]),
      ).ignore();

      strategy.request('param', null, () async => 1);
      strategy.request('param', null, () async => 2);
      strategy.request('param', null, () async => 3);
      strategy.request('param', null, () async => 3);
    });

    test('request after flush emits normally', () async {
      final emitted = <RequestPayload<String, int>>[];
      strategy.stream.listen(emitted.add);

      strategy.request('p', null, () async => 10);
      await strategy.flush();
      strategy.request('p', null, () async => 20);
      await Future<void>.delayed(Duration.zero);

      expect(
        emitted.whereType<RequestSuccess<String, int>>().map((e) => e.value),
        [10, 20],
      );
    });

    test('request after dispose does nothing', () async {
      final emitted = <RequestPayload<String, int>>[];
      final sub = strategy.stream.listen(emitted.add);

      await strategy.dispose();
      strategy.request('key', null, () async => 42);
      await Future<void>.delayed(Duration.zero);

      await sub.cancel();
      expect(emitted, isEmpty);
    });
  });
}
