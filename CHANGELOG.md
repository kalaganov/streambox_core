## 1.4.4+2

- Exposed `clearLast()` as a public method on `BaseRepo` to allow manual invalidation of the replayed state.

## 1.4.4+1

- add flag to repos

## 1.4.4

- Add `resetOnFlush` flag for configurable flush behavior

## 1.4.3

- Enhance flush to clear replayed value

## 1.4.2

- Added skipErrors

## 1.4.1

- Added a global error handling mechanism
 
## 1.4.0

- Introduced `shouldSkipCache` to `BaseCacheStrategy` for fine-grained control over cache usage.
- Made all built-in cache strategies (`CacheFirstStrategy`, `CacheThenRefreshStrategy`, `NoOpCacheStrategy`) extensible by marking them as `abstract`.

## 1.3.2

- Added `fetchAwait` method to `Repo` for awaiting the first emitted state.

## 1.3.1

- fix README and example

## 1.3.0

- Introduced `RequestParams` abstraction for strongly typed request parameters.
- Unified APIs across `DataSource`, `Repo`, and `CacheStrategy` to require `RequestParams`.
- Refactored `BaseCacheStrategy` to automatically resolve cache keys.
- Simplified repository and data source generics for better type safety.
- Updated all tests to cover new APIs and edge cases.

## 1.2.0

- Moved all storage adapters into a separate package
  [`streambox_adapters`](https://pub.dev/packages/streambox_adapters).
- Updated documentation to reference the new package.
- Core library is now lighter with no direct dependency on storage backends.

## 1.1.0

- Added new storage adapters exports:
  - AsyncSharedPrefsStorageAdapter
  - CachedSharedPrefsStorageAdapter
  - FlutterSecureStorageAdapter
  - MemoryStoreAdapter
- Added example usage in `example/main.dart` demonstrating repository, caching, and DI setup.
- Updated documentation to clarify `DataInitial` behavior after flush/reset.

## 1.0.0

- Initial release of `streambox_core`.
- Implemented core repository and caching framework.
- Added built-in cache strategies:
  - CacheFirstStrategy
  - CacheThenRefreshStrategy
  - NoOpCacheStrategy
- Provided base repository implementations:
  - SingleSourceRepo
  - ChainedSourcesRepo
  - PeriodicRepo
- Introduced DataState lifecycle: Initial, Loading, Success, Error.
- Added ready-to-use storage adapters:
  - MemoryStoreAdapter
  - AsyncSharedPrefsStorageAdapter
  - CachedPrefsAdapter
  - FlutterSecureStorageAdapter