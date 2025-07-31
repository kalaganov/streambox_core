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