import 'dart:async';

import 'package:streambox_core/src/common/data_state.dart';
import 'package:streambox_core/src/repo/base_repo.dart';
import 'package:test/test.dart';

void main() {
  group('BaseRepo', () {
    test('emits DataLoading', () async {
      final repo = _TestRepo();
      final events = <DataState<String>>[];
      final sub = repo.stream.listen(events.add);

      repo.emitLoading();
      await Future<void>.delayed(Duration.zero);

      expect(events.last, isA<DataLoading<String>>());

      await sub.cancel();
      await repo.dispose();
    });

    test('emits DataSuccess', () async {
      final repo = _TestRepo();
      final events = <DataState<String>>[];
      final sub = repo.stream.listen(events.add);

      repo.emitSuccess('ok');
      await Future<void>.delayed(Duration.zero);

      expect(events.last, isA<DataSuccess<String>>());
      expect((events.last as DataSuccess<String>).value, 'ok');

      await sub.cancel();
      await repo.dispose();
    });

    test('emits DataError', () async {
      final repo = _TestRepo();
      final events = <DataState<String>>[];
      final sub = repo.stream.listen(events.add);

      final err = Exception('test');
      repo.emitError(err);
      await Future<void>.delayed(Duration.zero);

      expect(events.last, isA<DataError<String>>());
      expect((events.last as DataError<String>).error, same(err));

      await sub.cancel();
      await repo.dispose();
    });

    test('emits DataInitial', () async {
      final repo = _TestRepo();
      final events = <DataState<String>>[];
      final sub = repo.stream.listen(events.add);

      await repo.flush();
      await Future<void>.delayed(Duration.zero);

      expect(events.last, isA<DataInitial<String>>());

      await sub.cancel();
      await repo.dispose();
    });

    test('stream closes on dispose', () async {
      final repo = _TestRepo();
      final sub = repo.stream.listen(null);

      await repo.dispose();

      expectLater(repo.stream, emitsDone).ignore();
      await sub.cancel();
    });

    test('replay last', () async {
      final repo = _TestRepoWithReplay();
      final eventsA = <DataState<String>>[];
      final subA = repo.stream.listen(eventsA.add);

      repo.emitSuccess('ok');
      await Future<void>.delayed(Duration.zero);

      final eventsB = <DataState<String>>[];
      final subB = repo.stream.listen(eventsB.add);
      await Future<void>.delayed(Duration.zero);

      expect(eventsA.last, isA<DataSuccess<String>>());
      expect((eventsA.last as DataSuccess<String>).value, 'ok');

      expect(eventsB.last, isA<DataSuccess<String>>());
      expect((eventsB.last as DataSuccess<String>).value, 'ok');

      await subA.cancel();
      await subB.cancel();
      await repo.dispose();
    });
  });
}

class _TestRepo extends BaseRepo<String, String> {
  void emitLoading() => handleLoading();

  void emitSuccess(String val) => handleData(val);

  void emitError(Object err) => handleError(err, StackTrace.current);

  @override
  Future<void> flush() async => handleFlush();

  @override
  void fetch([String? p]) {}
}

class _TestRepoWithReplay extends BaseRepo<String, String> {
  _TestRepoWithReplay() : super(replayLast: true);

  void emitSuccess(String val) => handleData(val);

  @override
  Future<void> flush() async => handleFlush();

  @override
  void fetch([String? p]) {}
}
