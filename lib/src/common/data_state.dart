import 'package:meta/meta.dart';

/// Represents the state of data in a repository or request flow.
///
/// Used to model different stages of data loading and handling,
/// such as initial, loading, success, or error.
///
/// Type Parameters:
/// - [E] – Type of the data entity.
@immutable
sealed class DataState<E> {
  /// Creates a new [DataState] instance.
  const DataState();
}

/// Indicates that data is currently being loaded.
final class DataLoading<E> extends DataState<E> {
  /// Creates a loading state.
  const DataLoading();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DataLoading<E> && runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'DataLoading<$E>{}';
}

/// Indicates that data has been successfully loaded.
///
/// Contains the loaded [value].
final class DataSuccess<E> extends DataState<E> {
  /// Creates a success state with the given [value].
  const DataSuccess(this.value);

  /// The successfully loaded data entity.
  final E value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DataSuccess<E> &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'DataSuccess<$E>{value: $value}';
}

/// Indicates that the repository's data has been explicitly cleared
/// via a flush operation, and no data is currently available.
final class DataInitial<E> extends DataState<E> {
  /// Creates an initial state.
  const DataInitial();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DataInitial<E> && runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'DataInitial<$E>{}';
}

/// Indicates that an error occurred while loading data.
///
/// Contains the [error] and an optional [stackTrace].
final class DataError<E> extends DataState<E> {
  /// Creates an error state with the given [error] and optional [stackTrace].
  const DataError(this.error, [this.stackTrace]);

  /// The error encountered during data loading.
  final Object error;

  /// The associated stack trace, if available.
  final StackTrace? stackTrace;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DataError<E> &&
          runtimeType == other.runtimeType &&
          error == other.error &&
          stackTrace == other.stackTrace;

  @override
  int get hashCode => error.hashCode ^ (stackTrace?.hashCode ?? 0);

  @override
  String toString() => 'DataError<$E>{error: $error, stackTrace: $stackTrace}';
}
