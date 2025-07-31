import 'package:meta/meta.dart';
import 'package:streambox_core/streambox_core.dart';
import 'package:test/test.dart';

import '../mock_memory_store_adapter/mock_memory_store_adapter.dart';

void main() {
  group('MemoryCache', () {
    late Cache<_Response> cache;

    setUp(() {
      cache = _MockMemoryCache(store: MockMemoryStoreAdapter());
    });
    tearDown(() => cache.clear());

    test('set and get', () async {
      const r = _Response('1');

      await cache.set('a', r);
      final value = await cache.get('a');
      expect(value, equals(r));
    });

    test('set, update and get', () async {
      const rA = _Response('1');
      const rB = _Response('42');
      await cache.set('a', rA);
      await cache.set('a', rB);
      final value = await cache.get('a');
      expect(value, equals(rB));
    });

    test('get returns null for missing key', () async {
      final value = await cache.get('missing');
      expect(value, isNull);
    });

    test('clear removes all keys', () async {
      const rA = _Response('1');
      const rB = _Response('42');
      await cache.set('a', rA);
      await cache.set('b', rB);
      await cache.clear();
      expect(await cache.get('a'), isNull);
      expect(await cache.get('b'), isNull);
    });
  });
}

class _MockMemoryCache extends BaseKeyValueCache<_Response> {
  const _MockMemoryCache({required super.store});

  @override
  String get keyPrefix => 'foo';

  @override
  _Response deserialize(String raw) => _Response.fromJson(decodeAsMap(raw));

  @override
  String serialize(_Response value) => encode(value.toJson());
}

@immutable
class _Response {
  const _Response(this.value);

  factory _Response.fromJson(Map<String, dynamic> map) {
    return _Response(map['value']! as String);
  }

  final String value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _Response &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  Map<String, dynamic> toJson() => {'value': value};
}
