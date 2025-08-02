import 'dart:async';

import 'package:streambox_core/src/common/adapter/stream_adapter.dart';

/// A [StreamAdapter] that replays the most recent event to
/// new subscribers upon subscription.
///
/// Internally uses a broadcast controller and proxy streams
/// to ensure each subscriber receives the last emitted value.
final class BehaviorStreamAdapter<T> implements StreamAdapter<T> {
  final _main = StreamController<T>.broadcast();
  final _proxies = <_Proxy<T>>[];
  T? _last;
  bool _has = false;
  bool _closed = false;

  @override
  void add(T event) {
    _last = event;
    _has = true;
    _main.add(event);
  }

  @override
  Stream<T> get stream {
    final proxyController = StreamController<T>();

    if (_has) proxyController.add(_last as T);

    late final StreamSubscription<T> sub;
    sub = _main.stream.listen(proxyController.add);

    proxyController.onCancel = () async {
      await sub.cancel();
      _proxies.removeWhere((p) => p.controller == proxyController);
    };

    _proxies.add(_Proxy(proxyController, sub));
    return proxyController.stream;
  }

  @override
  bool get isClosed => _closed;

  @override
  Future<void> close() async {
    _closed = true;
    final proxiesCopy = List.of(_proxies);

    for (final proxy in proxiesCopy) {
      await proxy.sub.cancel();
      await proxy.controller.close();
    }

    _proxies.clear();
    await _main.close();
  }
}

class _Proxy<T> {
  _Proxy(this.controller, this.sub);

  final StreamController<T> controller;
  final StreamSubscription<T> sub;
}
