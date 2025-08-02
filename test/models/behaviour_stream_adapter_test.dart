import 'package:streambox_core/src/common/adapter/behavior_stream_adapter.dart';
import 'package:test/test.dart';

void main() {
  group('BehaviorStreamAdapter', () {
    test('close closes all proxies', () async {
      final adapter = BehaviorStreamAdapter<int>();
      final valuesA = <int>[];
      final valuesB = <int>[];

      adapter.stream.listen(valuesA.add);
      adapter.stream.listen(valuesB.add);

      adapter
        ..add(1)
        ..add(2);

      await adapter.close();

      expect(adapter.isClosed, isTrue);
    });
  });
}
