import 'dart:async';

import 'package:streambox_core/src/common/data_state.dart';
import 'package:streambox_core/src/common/request_params.dart';
import 'package:streambox_core/src/common/request_payload.dart';

/// Extension for safely adding [DataState] events
/// to a [StreamController].
/// Prevents errors when the controller is already closed.
///
/// Type Parameters:
/// - [P] – Request parameters extending [RequestParams].
/// - [V] – Value type carried inside [DataState].
extension StreamControllerExt<P extends RequestParams, V>
    on StreamController<DataState<V>> {
  /// Safely adds a [DataState] to the controller if it is not closed.
  void safeStateAdd(DataState<V> state) {
    if (isClosed) return;
    add(state);
  }
}

/// Extension for safely adding [RequestPayload] events
/// to a [StreamController].
/// Prevents errors when the controller is already closed.
///
/// Type Parameters:
/// - [P] – Request parameters extending [RequestParams].
/// - [V] – Value type carried inside [RequestPayload].
extension StrategyStreamControllerExt<P extends RequestParams, V>
    on StreamController<RequestPayload<P, V>> {
  /// Safely adds a [RequestPayload] to the controller if it is not closed.
  void safeAdd(RequestPayload<P, V> state) {
    if (isClosed) return;
    add(state);
  }
}

/// Extension for safely adding mapped [DataState] events
/// to a [StreamController].
/// Prevents errors when the controller is already closed.
///
/// Type Parameters:
/// - [S] – Value type carried inside [DataState].
extension StreamControllerMappedExt<S> on StreamController<DataState<S>> {
  /// Safely adds a [DataState] to the controller if it is not closed.
  void safeAddMapped(DataState<S> state) {
    if (isClosed) return;
    add(state);
  }
}
