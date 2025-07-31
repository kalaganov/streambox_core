import 'dart:async';

import 'package:streambox_core/src/common/adapter/stream_adapter.dart';

/// A [StreamAdapter] that broadcasts events to all subscribers
/// without replaying the last emitted value.
///
/// Useful when consumers should only receive new events
/// after they subscribe.
final class BroadcastStreamAdapter<T> implements StreamAdapter<T> {
  final _controller = StreamController<T>.broadcast();

  @override
  void add(T event) => _controller.add(event);

  @override
  Stream<T> get stream => _controller.stream;

  bool _closed = false;

  @override
  bool get isClosed => _closed;

  @override
  Future<void> close() {
    _closed = true;
    return _controller.close();
  }
}
