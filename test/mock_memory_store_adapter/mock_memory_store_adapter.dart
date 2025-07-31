import 'package:meta/meta.dart';
import 'package:streambox_core/streambox_core.dart';

@immutable
final class MockMemoryStoreAdapter implements KeyValueStoreInterface {
  final Map<String, String> _map = {};

  @override
  Future<String?> read(String key) async => _map[key];

  @override
  Future<void> write(String key, String value) async {
    _map[key] = value;
  }

  @override
  Future<void> delete(String key) async => _map.remove(key);

  @override
  Future<Map<String, String>> readAll() =>
      Future.value(Map<String, String>.from(_map));
}
