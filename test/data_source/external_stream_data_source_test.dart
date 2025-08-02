import 'dart:async';

import 'package:streambox_core/streambox_core.dart';
import 'package:test/test.dart';

void main() {
  group('BaseRepo with external stream datasource', () {
    test('does nothing after fetch', () async {
      late DataSource<_MockRequestParams, _Response> source;

      final controller = StreamController<_Response>.broadcast();

      source = _MockDataSource(sourceStream: controller.stream);

      final events = <RequestPayload<_MockRequestParams, _Response>>[];
      final sub = source.stream.listen(events.add);

      source.fetch(const _MockRequestParams('a'));
      await Future<dynamic>.delayed(Duration.zero);

      expect(events, isEmpty);

      await sub.cancel();
      await source.dispose();
    });

    test('emits DataSuccess after fetch', () async {
      late DataSource<_MockRequestParams, _Response> source;

      final controller = StreamController<_Response>.broadcast();

      source = _MockDataSource(
        sourceStream: controller.stream,
      );

      final events = <RequestPayload<_MockRequestParams, _Response>>[];
      final sub = source.stream.listen(events.add);

      source.fetch(const _MockRequestParams('a'));
      await Future<dynamic>.delayed(const Duration(milliseconds: 500));
      controller.add(const _Response('stream response'));
      await Future<dynamic>.delayed(Duration.zero);

      expect(events.length, 1);
      expect(events.last, isA<RequestPayload<_MockRequestParams, _Response>>());
      expect(
        (events.last as RequestSuccess<_MockRequestParams, _Response>)
            .value
            .value,
        equals('stream response'),
      );

      await sub.cancel();
      await source.dispose();
    });
    test('emits DataInitial', () async {
      late DataSource<_MockRequestParams, _Response> source;

      final controller = StreamController<_Response>.broadcast();

      source = _MockDataSource(
        sourceStream: controller.stream,
      );
      final events = <RequestPayload<_MockRequestParams, _Response>>[];
      final sub = source.stream.listen(events.add);

      await source.flush();
      await Future<dynamic>.delayed(Duration.zero);

      expect(events.length, 1);
      expect(events.last, isA<RequestPayload<_MockRequestParams, _Response>>());

      await sub.cancel();
      await source.dispose();
    });

    test('BaseExternalStreamDataSource _onError adds RequestError', () async {
      final controller = StreamController<int>();
      final ds = _TestExternalStreamThrowErrorDataSource(
        sourceStream: controller.stream,
      );
      final events = <RequestPayload<_MockRequestParams, int>>[];
      ds.stream.listen(events.add);
      controller.addError(_error);
      await Future<dynamic>.delayed(Duration.zero);
      final event = events.single;
      expect(event, isA<RequestError<_MockRequestParams, int>>());
      expect((event as RequestError).error, equals(_error));
    });

    test('fetch after dispose does nothing', () async {
      late DataSource<_MockRequestParams, _Response> source;

      final controller = StreamController<_Response>.broadcast();

      source = _MockDataSource(
        sourceStream: controller.stream,
      );
      final events = <RequestPayload<_MockRequestParams, _Response>>[];
      final sub = source.stream.listen(events.add);

      await source.dispose();
      await Future<dynamic>.delayed(Duration.zero);

      expect(events, isEmpty);

      await sub.cancel();
      await source.dispose();

      expectLater(source.stream, emitsDone).ignore();
    });
  });
}

class _Response {
  const _Response(this.value);

  final String value;
}

class _MockDataSource
    extends BaseExternalStreamDataSource<_MockRequestParams, _Response> {
  _MockDataSource({
    required super.sourceStream,
  });

  @override
  void fetch([_MockRequestParams? params, List<Object>? extras]) {}
}

class _MockRequestParams implements RequestParams {
  const _MockRequestParams(this.value);

  final String value;

  @override
  String get cacheKey => throw UnimplementedError();

  @override
  String toString() => value;
}

final _error = Exception('stream error');

class _TestExternalStreamThrowErrorDataSource
    extends BaseExternalStreamDataSource<_MockRequestParams, int> {
  _TestExternalStreamThrowErrorDataSource({required super.sourceStream});

  @override
  void fetch([_MockRequestParams? params, List<Object>? extras]) {}
}
