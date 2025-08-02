import 'dart:async';
import 'package:streambox_core/src/common/controller_extension.dart';
import 'package:streambox_core/src/common/data_state.dart';
import 'package:test/test.dart';

void main() {
  group('controller_extension', () {
    test('safeStateAdd adds when not closed', () async {
      final controller = StreamController<DataState<int>>()
        ..safeStateAdd(const DataSuccess(42));

      final event = await controller.stream.first;
      expect(event, isA<DataSuccess<int>>());
      await controller.close();
    });

    test('safeAddMapped adds when not closed', () async {
      final controller = StreamController<DataState<String>>()
        ..safeAddMapped(const DataSuccess('ok'));

      final event = await controller.stream.first;
      expect(event, isA<DataSuccess<String>>());
      await controller.close();
    });
  });
}
