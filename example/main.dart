/// Example usage of streambox_core
///
/// ```dart
/// // 📂 data layer
/// @RestApi()
/// abstract interface class ExampleApiInterface {
///   factory ExampleApiInterface(Dio dio) = _ExampleApiInterface;
///
///   @GET('items')
///   Future<ItemResponse> fetchItems({
///     @Query('page') required int page,
///     @Query('size') required int size,
///   });
/// }
///
/// final class ExampleDataSource
///     extends BaseDataSource<FetchParams, ItemResponse> {
///   ExampleDataSource({
///     required ExampleApiInterface api,
///     required super.cacheStrategy,
///   }) : _api = api;
///
///   final ExampleApiInterface _api;
///
///   @override
///   Future<ItemResponse> request(FetchParams? params) {
///     assert(params != null);
///     return _api.fetchItems(page: params!.page, size: params.size);
///   }
/// }
///
/// final class ExampleCacheStrategy
///     extends CacheThenRefreshStrategy<FetchParams, ItemResponse> {
///   ExampleCacheStrategy({required super.cache});
///
///   @override
///   String resolveKey(FetchParams? params) =>
///       '${params?.page}-${params?.size}';
/// }
///
/// final class ExampleCache extends BaseKeyValueCache<ItemResponse> {
///   const ExampleCache({required super.store});
///
///   @override
///   String get keyPrefix => 'items';
///
///   @override
///   ItemResponse deserialize(String source) =>
///       ItemResponse.fromJson(decodeAsMap(source));
///
///   @override
///   String serialize(ItemResponse value) => encode(value.toJson());
/// }
///
/// final class ExampleRepoImpl extends SingleSourceRepo<
///     FetchParams, ItemResponse, ExampleEntity>
///     implements ExampleRepo {
///   ExampleRepoImpl({required super.dataSource});
///
///   @override
///   ExampleEntity map(FetchParams? params, ItemResponse value) =>
///       ExampleMapper(value).toEntity();
/// }
///
/// // 📂 domain layer
/// abstract interface class ExampleRepo
///     implements Repo<FetchParams, ExampleEntity> {}
///
/// // 📂 di module
/// final exampleRepo = ExampleRepoImpl(
///   dataSource: ExampleDataSource(
///     api: ExampleApiInterface(dio),
///     cacheStrategy: ExampleCacheStrategy(
///       cache: ExampleCache(store: MemoryStoreAdapter()),
///     ),
///   ),
/// );
/// ```
void main() {}
