<!-- Logo -->

<img src="https://raw.githubusercontent.com/kalaganov/streambox_core/main/assets/streambox_logo.webp" width="200" alt="streambox logo"/>

# streambox_core

A lightweight and extensible caching and repository framework for Dart & Flutter.\
`streambox_core` helps you manage **data fetching**, **caching**, and **reactive streams**\
with clean abstractions and powerful strategies.

[![Build Status](https://img.shields.io/badge/build-success-brightgreen)]()
[![pub package](https://img.shields.io/pub/v/streambox_core.svg)](https://pub.dev/packages/streambox_core)
[![codecov](https://codecov.io/gh/kalaganov/streambox_core/branch/main/graph/badge.svg?flag=streambox_core)](https://codecov.io/gh/kalaganov/streambox_core/tree/main/packages/streambox_core)
[![style: very good analysis](https://img.shields.io/badge/style-very_good_analysis-B22C89.svg)](https://pub.dev/packages/very_good_analysis)
[![Verified Publisher](https://img.shields.io/pub/publisher/streambox_core)](https://pub.dev/packages/streambox_core)

---

## ✨ Features

- **Repository Pattern** out of the box
- Built-in **cache strategies**:
  - Cache First
  - Cache Then Refresh
  - No-Op (no caching)
- **Composable data sources**:
  - Single source
  - Chained sources
  - Periodic fetch
  - External stream integration
- **Reactive state management** via `Stream<DataState<T>>`
- **Strongly typed request payloads**: initial, loading, success, error
- **Behavior & Broadcast stream adapters**
- Easy to extend and integrate with your networking or persistence layer

---

## 📦 Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  streambox_core: ^1.0.0
```

---

## 🧩 Core Concepts

### DataState

Represents the state of data flow:

- `DataInitial` — no data yet
- `DataLoading` — loading in progress
- `DataSuccess` — data successfully loaded
- `DataError` — an error occurred

### Cache Strategies

- **CacheFirstStrategy** — returns cached data if available; fetches otherwise.
- **CacheThenRefreshStrategy** — returns cached data immediately and refreshes with a new fetch.
- **NoOpCacheStrategy** — always fetches fresh data without caching.

### Repositories

- **SingleSourceRepo** — wraps a single data source
- **ChainedSourcesRepo** — combines two dependent data sources
- **PeriodicRepo** — refetches data at a given interval
- **BaseRepo** — provides loading/error/flush helpers

Repositories optionally support:

- `initialFetchParams` to perform an immediate request with parameters
- `fetchOnInit` to trigger the first request on creation
- `replayLast` to replay the last emitted state to new subscribers

---

## 🗄️ Storage Adapters

`streambox_core` provides several ready-to-use implementations of `KeyValueStoreInterface`, allowing you to plug in different storage backends depending on your requirements.

### MemoryStoreAdapter

- **Description**: Stores values in memory only.
- **Use cases**: Testing, prototyping, ephemeral caches.
- **Persistence**: ❌ (cleared when app restarts).

### AsyncSharedPrefsStorageAdapter

- **Description**: Uses the asynchronous `SharedPreferencesAsync` API.
- **Use cases**: General persistent storage where async access is acceptable.
- **Persistence**: ✅ (backed by shared preferences).

### CachedPrefsAdapter

- **Description**: Backed by `SharedPreferencesWithCache`, minimizing disk I/O with an in-memory cache.
- **Use cases**: Persistent storage with improved performance by caching reads.
- **Persistence**: ✅ (cached + disk-backed).

### FlutterSecureStorageAdapter

- **Description**: Backed by `flutter_secure_storage` for encrypted key-value storage.
- **Use cases**: Securely storing sensitive data such as tokens, credentials, or secrets.
- **Persistence**: ✅ (secure and encrypted).

---

## 📘 Example Setup

Below is an abstract example showing how to wire together a data source, a cache strategy, and a repository. Each component belongs to a specific application layer.

```dart
// 📂 data layer
@RestApi()
abstract interface class ExampleApiInterface {
  factory ExampleApiInterface(Dio dio) = _ExampleApiInterface;

  @GET('items')
  Future<ItemResponse> fetchItems({
    @Query('page') required int page,
    @Query('size') required int size,
  });
}

final class ExampleDataSource
    extends BaseDataSource<FetchParams, ItemResponse> {
  ExampleDataSource({
    required ExampleApiInterface api,
    required super.cacheStrategy,
  }) : _api = api;

  final ExampleApiInterface _api;

  @override
  Future<ItemResponse> request(FetchParams? params) {
    assert(params != null);
    return _api.fetchItems(page: params!.page, size: params.size);
  }
}

final class ExampleCacheStrategy
    extends CacheThenRefreshStrategy<FetchParams, ItemResponse> {
  ExampleCacheStrategy({required super.cache});

  @override
  String resolveKey(FetchParams? params) => '${params?.page}-${params?.size}';
}

final class ExampleCache extends BaseKeyValueCache<ItemResponse> {
  const ExampleCache({required super.store});

  @override
  String get keyPrefix => 'items';

  @override
  ItemResponse deserialize(String source) =>
      ItemResponse.fromJson(decodeAsMap(source));

  @override
  String serialize(ItemResponse value) => encode(value.toJson());
}

final class ExampleRepoImpl
    extends SingleSourceRepo<FetchParams, ItemResponse, ExampleEntity>
    implements ExampleRepo {
  ExampleRepoImpl({required super.dataSource});

  @override
  ExampleEntity map(FetchParams? params, ItemResponse value) =>
      ExampleMapper(value).toEntity();
}

// 📂 domain layer
abstract interface class ExampleRepo
    implements Repo<FetchParams, ExampleEntity> {}

// 📂 di module
final exampleRepo = ExampleRepoImpl(
  dataSource: ExampleDataSource(
    api: ExampleApiInterface(dio),
    cacheStrategy: ExampleCacheStrategy(
      cache: ExampleCache(store: MemoryStoreAdapter()),
    ),
  ),
);
```

If you don't need caching, simply replace the cache strategy with:

```dart
cacheStrategy: NoOpCacheStrategy(),
```

---

## 🛠 Extensibility

You can implement:

- Custom `Cache` backends
- Your own `CacheStrategy`
- Specialized `DataSource` integrations
- Custom storage adapters

---

