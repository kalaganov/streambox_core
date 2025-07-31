import 'dart:async';

import 'package:streambox_core/streambox_core.dart';
import 'package:test/test.dart';

void main() {
  group('BaseRepo with external stream datasource', () {
    test('does nothing after fetch', () async {
      late DataSource<String, _Response> source;

      final controller = StreamController<_Response>.broadcast();

      source = _MockDataSource(sourceStream: controller.stream);

      final events = <RequestPayload<String, _Response>>[];
      final sub = source.stream.listen(events.add);

      source.fetch('a');
      await Future<dynamic>.delayed(Duration.zero);

      expect(events, isEmpty);

      await sub.cancel();
      await source.dispose();
    });

    test('emits DataSuccess after fetch', () async {
      late DataSource<String, _Response> source;

      final controller = StreamController<_Response>.broadcast();

      source = _MockDataSource(
        sourceStream: controller.stream,
      );

      final events = <RequestPayload<String, _Response>>[];
      final sub = source.stream.listen(events.add);

      source.fetch('a');
      await Future<dynamic>.delayed(const Duration(milliseconds: 500));
      controller.add(const _Response('stream response'));
      await Future<dynamic>.delayed(Duration.zero);

      expect(events.length, 1);
      expect(events.last, isA<RequestPayload<String, _Response>>());
      expect(
        (events.last as RequestSuccess<String, _Response>).value.value,
        equals('stream response'),
      );

      await sub.cancel();
      await source.dispose();
    });
    test('emits DataInitial', () async {
      late DataSource<String, _Response> source;

      final controller = StreamController<_Response>.broadcast();

      source = _MockDataSource(
        sourceStream: controller.stream,
      );
      final events = <RequestPayload<String, _Response>>[];
      final sub = source.stream.listen(events.add);

      await source.flush();
      await Future<dynamic>.delayed(Duration.zero);

      expect(events.length, 1);
      expect(events.last, isA<RequestPayload<String, _Response>>());

      await sub.cancel();
      await source.dispose();
    });

    test('fetch after dispose does nothing', () async {
      late DataSource<String, _Response> source;

      final controller = StreamController<_Response>.broadcast();

      source = _MockDataSource(
        sourceStream: controller.stream,
      );
      final events = <RequestPayload<String, _Response>>[];
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

class _MockDataSource extends BaseExternalStreamDataSource<String, _Response> {
  _MockDataSource({
    required super.sourceStream,
  });

  @override
  void fetch([String? params, List<Object>? extras]) {}
}
