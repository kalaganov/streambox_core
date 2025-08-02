import 'package:streambox_core/src/common/request_params.dart';
import 'package:test/test.dart';

void main() {
  test('RequestParams subclass has cacheKey', () {
    const params = _TestParams(123);
    expect(params.cacheKey, 'id:123');
  });
}

class _TestParams implements RequestParams {
  const _TestParams(this.id);

  final int id;

  @override
  String get cacheKey => 'id:$id';
}
