import 'package:streambox_core/src/common/adapter/stream_adapter.dart';
import 'package:streambox_core/src/common/data_state.dart';

/// Extension providing a safe method to add [DataState] events
/// into a [StreamAdapter], ensuring no errors occur if it is closed.
extension StreamAdapterMappedExt<S> on StreamAdapter<DataState<S>> {
  /// Safely adds the given [state] if the adapter is not closed.
  void safeAddMapped(DataState<S> state) {
    if (isClosed) return;
    add(state);
  }
}
