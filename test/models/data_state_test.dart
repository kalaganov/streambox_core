import 'package:streambox_core/streambox_core.dart';
import 'package:test/test.dart';

void main() {
  group('DataSuccess', () {
    test('equality and hashCode', () {
      const a = DataSuccess(42);
      const b = DataSuccess(42);
      const c = DataSuccess(43);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('toString returns correct format', () {
      const state = DataSuccess('ok');
      expect(state.toString(), 'DataSuccess<String>{value: ok}');
    });
  });

  group('DataLoading', () {
    test('equality with same generic type', () {
      const a = DataLoading<int>();
      const b = DataLoading<int>();

      expect(a, equals(b));
      expect(b, equals(a));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('inequality with different generic types', () {
      const a = DataLoading<int>();
      const b = DataLoading<String>();

      expect(a, isNot(equals(b)));
      expect(a.hashCode, isNot(equals(b.hashCode)));
    });

    test('toString includes generic type', () {
      const state = DataLoading<double>();
      expect(state.toString(), equals('DataLoading<double>{}'));
    });
  });

  group('DataInitial', () {
    test('equality with same generic type', () {
      const a = DataInitial<int>();
      const b = DataInitial<int>();

      expect(a, equals(b));
      expect(b, equals(a));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('inequality with different generic types', () {
      const a = DataInitial<int>();
      const b = DataInitial<String>();

      expect(a, isNot(equals(b)));
      expect(a.hashCode, isNot(equals(b.hashCode)));
    });

    test('self equality', () {
      const a = DataInitial<double>();
      expect(a, equals(a));
    });

    test('hashCode is consistent', () {
      const a = DataInitial<bool>();
      final hash1 = a.hashCode;
      final hash2 = a.hashCode;
      expect(hash1, equals(hash2));
    });

    test('toString includes generic type', () {
      const a = DataInitial<num>();
      expect(a.toString(), equals('DataInitial<num>{}'));
    });
  });

  group('DataError', () {
    test('equality and hashCode', () {
      final error = Exception('boom');
      final trace = StackTrace.current;

      final a = DataError<int>(error, trace);
      final b = DataError<int>(error, trace);
      final c = DataError<int>(error);
      final d = DataError<int>(Exception('boom'), trace);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
      expect(a, isNot(equals(d)));
    });

    test('toString returns correct format', () {
      final err = ArgumentError('invalid');
      final trace = StackTrace.current;
      final state = DataError<int>(err, trace);

      expect(
        state.toString(),
        'DataError<int>{error: $err, stackTrace: $trace}',
      );
    });
  });

  test('DataError allows null stackTrace', () {
    final error = Exception('fail');
    final state = DataError<int>(error);
    expect(state.stackTrace, isNull);
    expect(state.error, same(error));
  });

  test('different subclasses are not equal when cast to DataState', () {
    const DataState<int> s = DataSuccess(1);
    const DataState<int> l = DataLoading();
    const DataState<int> e = DataInitial();
    final DataState<int> d = DataError(Exception('x'));

    expect(s == l, isFalse);
    expect(l == e, isFalse);
    expect(e == d, isFalse);
  });

  test('subclass type check with is', () {
    final states = <DataState<Object>>[
      const DataSuccess('ok'),
      const DataLoading(),
      const DataInitial(),
      DataError(Exception('e')),
    ];

    expect(states[0], isA<DataSuccess<Object>>());
    expect(states[1], isA<DataLoading<Object>>());
    expect(states[2], isA<DataInitial<Object>>());
    expect(states[3], isA<DataError<Object>>());
  });

  group('DataState polymorphism', () {
    test('can be assigned to supertype', () {
      const success = DataSuccess(123);
      const empty = DataInitial<int>();
      final error = DataError<int>(Exception('fail'));

      final list = <DataState<int>>[success, empty, error];

      expect(list, hasLength(3));
      expect(list[0], isA<DataSuccess<int>>());
      expect(list[1], isA<DataInitial<int>>());
      expect(list[2], isA<DataError<int>>());
    });
  });
}
