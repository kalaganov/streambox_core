import 'dart:async';

import 'package:streambox_core/src/common/data_state.dart';
import 'package:streambox_core/src/data_sources/base_external_stream_data_source.dart';
import 'package:streambox_core/src/repo/single_source_repo.dart';
import 'package:test/test.dart';

void main() {
  group('SingleSourceRepo with external stream datasource', () {
    test('does nothing after fetch', () async {
      final controller = StreamController<_Response>.broadcast();

      final source = _MockDataSource(sourceStream: controller.stream);
      final repo = _MockRepo(dataSource: source);

      final events = <DataState<String>>[];
      final sub = repo.stream.listen(events.add);

      repo.fetch('a');
      await Future<dynamic>.delayed(Duration.zero);

      expect(events, isEmpty);

      await sub.cancel();
      await repo.dispose();
    });

    test('emits DataSuccess after fetch', () async {
      final controller = StreamController<_Response>.broadcast();

      final source = _MockDataSource(sourceStream: controller.stream);
      final repo = _MockRepo(dataSource: source);

      final events = <DataState<String>>[];
      final sub = repo.stream.listen(events.add);

      repo.fetch('a');
      await Future<dynamic>.delayed(const Duration(milliseconds: 500));
      controller.add(const _Response('stream response'));
      await Future<dynamic>.delayed(Duration.zero);

      expect(events.length, 1);
      expect(events.last, isA<DataSuccess<String>>());
      expect(
        (events.last as DataSuccess<String>).value,
        'mapped value: stream response',
      );

      await sub.cancel();
      await repo.dispose();
    });

    test('emits DataError if mapper throws', () async {
      final controller = StreamController<_Response>.broadcast();

      final source = _MockDataSource(sourceStream: controller.stream);
      final repo = _MockRepoFail(dataSource: source);

      final events = <DataState<String>>[];
      final sub = repo.stream.listen(events.add);

      repo.fetch('a');
      await Future<dynamic>.delayed(const Duration(milliseconds: 500));
      controller.add(const _Response('stream response'));
      await Future<dynamic>.delayed(Duration.zero);

      expect(events.length, 1);
      expect(events.last, isA<DataError<String>>());
      expect((events.last as DataError<String>).error, isA<_MyException>());
      expect((events.last as DataError<String>).stackTrace, isNotNull);

      await sub.cancel();
      await repo.dispose();
    });

    test('emits DataInitial', () async {
      final controller = StreamController<_Response>.broadcast();

      final source = _MockDataSource(sourceStream: controller.stream);
      final repo = _MockRepo(dataSource: source);

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
      final controller = StreamController<_Response>.broadcast();

      final source = _MockDataSource(sourceStream: controller.stream);
      final repo = _MockRepo(dataSource: source);

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

class _MockDataSource extends BaseExternalStreamDataSource<String, _Response> {
  _MockDataSource({
    required super.sourceStream,
  });

  @override
  void fetch([String? params, List<Object>? extras]) {}
}

class _MockRepo extends SingleSourceRepo<String, _Response, String> {
  _MockRepo({required super.dataSource});

  @override
  String map(String? params, _Response value) => 'mapped value: ${value.value}';
}

class _MockRepoFail extends SingleSourceRepo<String, _Response, String> {
  _MockRepoFail({required super.dataSource});

  @override
  String map(String? params, _Response value) => throw const _MyException();
}

final class _MyException implements Exception {
  const _MyException();

  @override
  String toString() => '_MyException{}';
}
