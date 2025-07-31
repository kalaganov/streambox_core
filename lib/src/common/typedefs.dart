/// A function type that defines an asynchronous value fetcher.
///
/// Typically used in caching or data source strategies to provide
/// a way of retrieving values on demand.
///
/// Type Parameters:
/// - [R] – Type of the fetched value.
typedef ValueFetcher<R> = Future<R> Function();
