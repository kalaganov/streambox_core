import 'package:streambox_core/streambox_core.dart';
import 'package:test/test.dart';

//
// ignore_for_file: cascade_invocations
void main() {
  group('NoOpCacheStrategy', () {
    late CacheStrategy<_MockRequestParams, int> strategy;

    setUp(() => strategy = NoOpCacheStrategy());
    tearDown(() => strategy.dispose());

    test('emits value returned by fetch', () {
      expectLater(
        strategy.stream,
        emitsThrough(
          isA<RequestSuccess<_MockRequestParams, int>>().having(
            (e) => e.value,
            'value',
            42,
          ),
        ),
      );

      strategy.request(const _MockRequestParams('param'), null, () async => 42);
    });

    test('flush emits RequestInitial', () {
      expectLater(
        strategy.stream,
        emits(isA<RequestInitial<_MockRequestParams, int>>()),
      );

      strategy.flush();
    });

    test('emits error if fetch throws', () {
      expectLater(
        strategy.stream,
        emitsThrough(
          isA<RequestError<_MockRequestParams, int>>().having(
            (e) => e.error,
            'error',
            isA<StateError>(),
          ),
        ),
      );

      strategy.request(const _MockRequestParams('param'), null, () async {
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

        strategy.request(const _MockRequestParams('a'), null, () async => 1);
        await Future<void>.delayed(Duration.zero);
        strategy.request(const _MockRequestParams('b'), null, () async => 2);
        await Future<void>.delayed(Duration.zero);
        strategy.request(const _MockRequestParams('c'), null, () async => 3);
        await Future<void>.delayed(Duration.zero);

        await sub.cancel();
        expect(emitted, [1, 2, 3]);
      },
    );

    test('does not cache values between requests', () async {
      final events = <RequestPayload<_MockRequestParams, int>>[];
      strategy.stream.listen(events.add);

      expectLater(
        strategy.stream,
        emitsInOrder([
          isA<RequestSuccess<_MockRequestParams, int>>().having(
            (e) => e.value,
            'value',
            1,
          ),
          isA<RequestSuccess<_MockRequestParams, int>>().having(
            (e) => e.value,
            'value',
            2,
          ),
          isA<RequestSuccess<_MockRequestParams, int>>().having(
            (e) => e.value,
            'value',
            3,
          ),
          isA<RequestSuccess<_MockRequestParams, int>>().having(
            (e) => e.value,
            'value',
            3,
          ),
        ]),
      ).ignore();

      strategy.request(const _MockRequestParams('param'), null, () async => 1);
      strategy.request(const _MockRequestParams('param'), null, () async => 2);
      strategy.request(const _MockRequestParams('param'), null, () async => 3);
      strategy.request(const _MockRequestParams('param'), null, () async => 3);
    });

    test('request after flush emits normally', () async {
      final emitted = <RequestPayload<_MockRequestParams, int>>[];
      strategy.stream.listen(emitted.add);

      strategy.request(const _MockRequestParams('p'), null, () async => 10);
      await strategy.flush();
      strategy.request(const _MockRequestParams('p'), null, () async => 20);
      await Future<void>.delayed(Duration.zero);

      expect(
        emitted.whereType<RequestSuccess<_MockRequestParams, int>>().map(
          (e) => e.value,
        ),
        [10, 20],
      );
    });

    test('request after dispose does nothing', () async {
      final emitted = <RequestPayload<_MockRequestParams, int>>[];
      final sub = strategy.stream.listen(emitted.add);

      await strategy.dispose();
      strategy.request(const _MockRequestParams('key'), null, () async => 42);
      await Future<void>.delayed(Duration.zero);

      await sub.cancel();
      expect(emitted, isEmpty);
    });
  });
}

class _MockRequestParams implements RequestParams {
  const _MockRequestParams(this.value);

  final String value;

  @override
  String get cacheKey => throw UnimplementedError();

  @override
  String toString() => value;
}
