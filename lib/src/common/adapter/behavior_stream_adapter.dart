import 'dart:async';

import 'package:streambox_core/src/common/adapter/stream_adapter.dart';

/// A [StreamAdapter] that replays the most recent event to
/// new subscribers upon subscription.
///
/// Internally uses a broadcast controller and proxy streams
/// to ensure each subscriber receives the last emitted value.
final class BehaviorStreamAdapter<T> implements StreamAdapter<T> {
  final _main = StreamController<T>.broadcast();
  final _proxies = <StreamController<T>>[];
  T? _last;
  bool _has = false;

  @override
  void add(T event) {
    _last = event;
    _has = true;
    _main.add(event);
  }

  @override
  Stream<T> get stream {
    final proxy = StreamController<T>();

    if (_has) proxy.add(_last as T);

    final sub = _main.stream.listen(proxy.add);
    proxy.onCancel = () {
      sub.cancel();
      _proxies.remove(proxy);
    };

    _proxies.add(proxy);
    return proxy.stream;
  }

  bool _closed = false;

  @override
  bool get isClosed => _closed;

  @override
  Future<void> close() async {
    _closed = true;
    for (final p in _proxies) {
      await p.close();
    }
    await _main.close();
  }
}
