import 'package:meta/meta.dart';

/// Base interface for defining request parameters.
///
/// Implementations must provide a unique [cacheKey] used for
/// caching and request identification.
///
/// Classes implementing [RequestParams] should be immutable.
@immutable
abstract interface class RequestParams {
  /// A unique key representing the request.
  ///
  /// Used to identify cached values for this request.
  String get cacheKey;
}
