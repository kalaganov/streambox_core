import 'dart:async';

import 'package:streambox_core/src/common/data_state.dart';
import 'package:streambox_core/src/common/request_payload.dart';

/// Extensions that provide safe methods for adding events
/// to [StreamController]s, preventing errors if the controller
/// has already been closed.
extension StreamControllerExt<P, V> on StreamController<DataState<V>> {
  /// Safely adds a [DataState] to the controller if it is not closed.
  void safeStateAdd(DataState<V> state) {
    if (isClosed) return;
    add(state);
  }
}

/// Extension for safely adding [RequestPayload] events
/// to a [StreamController] without risking errors if closed.
extension StrategyStreamControllerExt<P, V>
    on StreamController<RequestPayload<P, V>> {
  /// Safely adds a [RequestPayload] to the controller if it is not closed.
  void safeAdd(RequestPayload<P, V> state) {
    if (isClosed) return;
    add(state);
  }
}

/// Extension for safely adding mapped [DataState] events
/// to a [StreamController].
extension StreamControllerMappedExt<S> on StreamController<DataState<S>> {
  /// Safely adds a [DataState] to the controller if it is not closed.
  void safeAddMapped(DataState<S> state) {
    if (isClosed) return;
    add(state);
  }
}
