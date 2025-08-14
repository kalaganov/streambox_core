<!-- Logo -->

<img
src="https://raw.githubusercontent.com/kalaganov/streambox_core/main/assets/streambox_logo.webp"
width="200"
alt="streambox logo"
style="border-radius: 24px;"
/>

# streambox_core

A lightweight and extensible caching and repository framework for Dart & Flutter.\
`streambox_core` helps you manage **data fetching**, **caching**, and **reactive streams**\
with clean abstractions and powerful strategies.

[![Build Status](https://img.shields.io/badge/build-success-brightgreen)]()
[![pub package](https://img.shields.io/pub/v/streambox_core.svg)](https://pub.dev/packages/streambox_core)
[![codecov](https://codecov.io/gh/kalaganov/streambox_core/branch/main/graph/badge.svg)](https://codecov.io/gh/kalaganov/streambox_core)
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
- **Strongly typed request payloads**: loading, success, error, initial
- **Behavior & Broadcast stream adapters**
- Easy to extend and integrate with your networking or persistence layer

---

## 📦 Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  streambox_core: ^latest_version
  streambox_adapters: ^latest_version
```

---

## 🧩 Core Concepts

### DataState

Represents the state of data flow:

- `DataLoading` — loading in progress
- `DataSuccess` — data successfully loaded
- `DataError` — an error occurred
- `DataInitial` — The state that indicates a repository's data has been cleared (flushed)

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
- `fetchAwait` to perform a fetch and await the first emitted state
---

## 🗄️ Storage Adapters

Starting from version **1.2.0**, storage adapters were moved into a separate 
package [`streambox_adapters`](https://pub.dev/packages/streambox_adapters).  
This keeps `streambox_core` lightweight and lets adapters evolve independently.

### Available adapters in `streambox_adapters`

- **MemoryStoreAdapter** — in-memory only, ideal for tests and prototyping
- **AsyncSharedPrefsStorageAdapter** — backed by SharedPreferencesAsync
- **CachedSharedPrefsStorageAdapter** — SharedPreferences with in-memory caching
- **FlutterSecureStorageAdapter** — secure encrypted storage

---

## 📘 Example Setup

Below is an abstract example showing how to wire together a data source, a cache strategy, and a repository. Each component belongs to a specific application layer.

```dart
// 📂 data layer
class ItemResponse {
  // fromJson...
  // toJson...
}

@RestApi()
abstract interface class ExampleApiInterface {
  factory ExampleApiInterface(Dio dio) = _ExampleApiInterface;

  @GET('items')
  Future<ItemResponse> fetchItems({
    @Query('page') required int page,
    @Query('size') required int size,
  });
}

final class ExampleDataSource extends BaseDataSource<FetchParams, ItemResponse> {
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

final class ExampleRepoImpl extends SingleSourceRepo<FetchParams, ItemResponse, ExampleEntity>
    implements ExampleRepo {
  ExampleRepoImpl({required super.dataSource});

  @override
  ExampleEntity map(FetchParams? params, ItemResponse value) =>
      ExampleMapper(value).toEntity();
}

// 📂 domain layer
abstract interface class ExampleRepo
    implements Repo<FetchParams, ExampleEntity> {}

class FetchParams implements RequestParams {
  FetchParams({required this.page, required this.size});

  final int page;
  final int size;

  @override
  String get cacheKey => 'cacheKey: $page-$size';
}

// 📂 di module
final exampleRepo = ExampleRepoImpl(
  dataSource: ExampleDataSource(
    api: ExampleApiInterface(dio),
    cacheStrategy: CacheThenRefreshStrategy(
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
## 🛠 Global Error Handling

Provides a mechanism for global error observation and handling. You can register an `StreamBoxErrorObserver` to be notified of any errors that occur within your repositories. This is useful for centralized logging, analytics, or displaying toast notifications to the user without needing to handle errors in every single repository subscription.

The `StreamBoxErrorObservers` singleton manager allows you to easily register and unregister observers.

Example

This example shows how to create a custom error observer for logging errors.
```dart
final class AnalyticsErrorObserver implements StreamBoxErrorObserver {
  const AnalyticsErrorObserver();

  @override
  void onError(String repo, Object error, StackTrace? stackTrace) {
    // Log the error to your analytics service
    AnalyticsService.instance.logError(
      'Repo: $repo',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

// Register the observer in your app's main function or DI module
void main() {
  StreamBoxErrorObservers.instance.register(const AnalyticsErrorObserver());
  // ... rest of your app setup
}
```

---
