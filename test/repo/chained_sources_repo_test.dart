import 'package:streambox_core/src/cache/key_value_cache.dart';
import 'package:streambox_core/src/common/data_state.dart';
import 'package:streambox_core/src/common/request_params.dart';
import 'package:streambox_core/src/data_sources/base_data_source.dart';
import 'package:streambox_core/src/data_sources/data_source_interface.dart';
import 'package:streambox_core/src/repo/base_repo.dart';
import 'package:streambox_core/src/repo/chained_sources_repo.dart';
import 'package:streambox_core/src/strategies/impl/cache_first_strategy.dart';
import 'package:streambox_core/src/strategies/impl/no_op_cache_strategy.dart';
import 'package:test/test.dart';

import '../mock_memory_store_adapter/mock_memory_store_adapter.dart';

//
// ignore_for_file: cascade_invocations

void main() {
  group('ChainedSourcesRepo integration tests', () {
    late _ProductsRepoBase repo;
    late _PrimarySource primarySource;
    late _DependentSource dependentSource;

    setUp(() {
      primarySource = _BackendProductsDataSource(
        cacheStrategy: _MockCacheFirstStrategy(cache: _MockMemoryCache()),
      );
      dependentSource = _InAppPurchasesProductDetailsDataSource(
        cacheStrategy: _MockNoOpCacheStrategy(),
      );
      repo = _ProductsRepo(
        primarySource: primarySource,
        dependentSource: dependentSource,
      );
    });

    tearDown(() async => repo.dispose());

    test(
      'returns ProductModel list when both fetches succeed (same params)',
      () async {
        final emitted = <DataState<List<_ProductModel>>>[];
        final sub = repo.stream.listen(emitted.add);
        _primaryFetchThrow = false;
        _dependentFetchThrow = false;
        _mapperFetchThrow = false;

        repo.fetch(const _MockRequestParams('req-id-001', 'test-brand'));
        repo.fetch(const _MockRequestParams('req-id-001', 'test-brand'));
        await Future<void>.delayed(Duration.zero);

        expect(emitted.length, equals(2));
        expect(emitted[0], isA<DataSuccess<List<_ProductModel>>>());
        expect(
          (emitted[0] as DataSuccess<List<_ProductModel>>).value.first,
          isA<_ProductModel>(),
        );
        expect(emitted[1], isA<DataSuccess<List<_ProductModel>>>());
        expect(
          (emitted[1] as DataSuccess<List<_ProductModel>>).value.first,
          isA<_ProductModel>(),
        );

        await sub.cancel();
      },
    );

    test(
      'returns ProductModel list on fetchAwait',
      () async {
        final emitted = <DataState<List<_ProductModel>>>[];
        final sub = repo.stream.listen(emitted.add);
        _primaryFetchThrow = false;
        _dependentFetchThrow = false;
        _mapperFetchThrow = false;

        final result = await repo.fetchAwait(
          const _MockRequestParams('req-id-001', 'test-brand'),
        );

        expect(emitted.length, equals(1));
        expect(emitted[0], isA<DataSuccess<List<_ProductModel>>>());
        expect(
          (emitted[0] as DataSuccess<List<_ProductModel>>).value.first,
          isA<_ProductModel>(),
        );
        expect(result, isA<DataSuccess<List<_ProductModel>>>());
        expect(
          (result as DataSuccess<List<_ProductModel>>).value.first,
          isA<_ProductModel>(),
        );

        await sub.cancel();
      },
    );

    test(
      'returns ProductModel list when fetches use different params',
      () async {
        final emitted = <DataState<List<_ProductModel>>>[];
        final sub = repo.stream.listen(emitted.add);
        _primaryFetchThrow = false;
        _dependentFetchThrow = false;
        _mapperFetchThrow = false;

        repo.fetch(const _MockRequestParams('req-id-001', 'test-brand'));
        repo.fetch(const _MockRequestParams('req-id-002', 'test-brand'));
        await Future<void>.delayed(Duration.zero);

        expect(emitted.length, equals(2));
        expect(emitted[0], isA<DataSuccess<List<_ProductModel>>>());
        expect(
          (emitted[0] as DataSuccess<List<_ProductModel>>).value.first,
          isA<_ProductModel>(),
        );
        expect(emitted[1], isA<DataSuccess<List<_ProductModel>>>());
        expect(
          (emitted[1] as DataSuccess<List<_ProductModel>>).value.first,
          isA<_ProductModel>(),
        );

        await sub.cancel();
      },
    );

    test('emits DataError if primary source throws', () async {
      final emitted = <DataState<List<_ProductModel>>>[];
      final sub = repo.stream.listen(emitted.add);
      _primaryFetchThrow = true;
      _dependentFetchThrow = false;
      _mapperFetchThrow = false;

      repo.fetch(const _MockRequestParams('req-id-001', 'test-brand'));
      await Future<void>.delayed(Duration.zero);

      expect(emitted.length, equals(1));
      expect(emitted.single, isA<DataError<List<_ProductModel>>>());
      expect(
        (emitted.single as DataError<List<_ProductModel>>).error,
        equals(_primaryFetchError),
      );

      await sub.cancel();
    });

    test('emits DataError if dependent source throws', () async {
      final emitted = <DataState<List<_ProductModel>>>[];
      final sub = repo.stream.listen(emitted.add);
      _primaryFetchThrow = false;
      _dependentFetchThrow = true;
      _mapperFetchThrow = false;

      repo.fetch(const _MockRequestParams('req-id-001', 'test-brand'));
      await Future<void>.delayed(Duration.zero);

      expect(emitted.length, equals(1));
      expect(emitted.single, isA<DataError<List<_ProductModel>>>());
      expect(
        (emitted.single as DataError<List<_ProductModel>>).error,
        equals(_dependentFetchError),
      );

      await sub.cancel();
    });

    test('emits DataError if mapper throws', () async {
      final emitted = <DataState<List<_ProductModel>>>[];
      final sub = repo.stream.listen(emitted.add);
      _primaryFetchThrow = false;
      _dependentFetchThrow = false;
      _mapperFetchThrow = true;

      repo.fetch(const _MockRequestParams('req-id-001', 'test-brand'));
      await Future<void>.delayed(Duration.zero);

      expect(emitted.length, equals(1));
      expect(emitted.single, isA<DataError<List<_ProductModel>>>());
      expect(
        (emitted.single as DataError<List<_ProductModel>>).error,
        equals(_mapperError),
      );

      await sub.cancel();
    });

    test('emits DataInitial on flush', () async {
      final emitted = <DataState<List<_ProductModel>>>[];
      final sub = repo.stream.listen(emitted.add);
      _primaryFetchThrow = false;
      _dependentFetchThrow = false;
      _mapperFetchThrow = false;

      await repo.flush();
      await Future<void>.delayed(Duration.zero);

      expect(emitted.length, equals(1));
      expect(emitted.single, isA<DataInitial<List<_ProductModel>>>());

      await sub.cancel();
    });

    test('ignores fetch after dispose', () async {
      final emitted = <DataState<List<_ProductModel>>>[];
      final sub = repo.stream.listen(emitted.add);

      repo.fetch(const _MockRequestParams('req-id-001', 'test-brand'));

      await repo.dispose();
      await repo.flush();
      await Future<void>.delayed(Duration.zero);

      expect(emitted, isEmpty);

      await sub.cancel();
    });
  });
}

// --------------------------------------------
var _primaryFetchThrow = false;
var _dependentFetchThrow = false;
var _mapperFetchThrow = false;

final _primaryFetchError = Exception('primary fetch error');
final _dependentFetchError = Exception('dependent fetch error');
final _mapperError = Exception('mapper error');

typedef _PrimarySource = DataSource<_MockRequestParams, _BackendResponse>;

typedef _DependentSource = DataSource<_StoreParams, List<_StoreProductDetails>>;

typedef _ProductsRepoBase = BaseRepo<_MockRequestParams, List<_ProductModel>>;

class _ProductsRepo
    extends
        ChainedSourcesRepo<
          _MockRequestParams,
          _StoreParams,
          _BackendResponse,
          List<_StoreProductDetails>,
          List<_ProductModel>
        > {
  _ProductsRepo({
    required super.primarySource,
    required super.dependentSource,
  });

  @override
  List<_ProductModel> map(
    _BackendResponse primaryValue,
    List<_StoreProductDetails> dependentValue,
  ) {
    if (_mapperFetchThrow) throw _mapperError;

    return List.generate(primaryValue.products.length, (i) {
      return _ProductModel(
        uuid: primaryValue.products[i].uuid,
        storeId: primaryValue.products[i].storeId,
        title: primaryValue.products[i].title,
        price: dependentValue[i].price,
        currencySign: dependentValue[i].currencySign,
      );
    });
  }

  @override
  _StoreParams? resolveParamsForDependentFetch(
    _MockRequestParams? params,
    _BackendResponse value,
  ) {
    final ids = value.products.map((p) => p.storeId).toSet();
    return _StoreParams(ids);
  }
}

class _MockMemoryCache extends BaseKeyValueCache<_BackendResponse> {
  _MockMemoryCache() : super(store: MockMemoryStoreAdapter());

  @override
  String get keyPrefix => 'foo';

  @override
  _BackendResponse deserialize(String source) =>
      _BackendResponse.fromJson(decodeAsMap(source));

  @override
  String serialize(_BackendResponse value) => encode(value.toJson());
}

class _BackendProductsDataSource
    extends BaseDataSource<_MockRequestParams, _BackendResponse> {
  _BackendProductsDataSource({required super.cacheStrategy});

  final _api = _FakeRetrofitBackendProductsApi();

  @override
  Future<_BackendResponse> request(_MockRequestParams? params) {
    if (params == null) {
      throw StateError('Params cannot be null');
    }
    if (_primaryFetchThrow) {
      throw _primaryFetchError;
    } else {
      return _api.fetchProducts(reqId: params.reqId, brand: params.brand);
    }
  }
}

class _InAppPurchasesProductDetailsDataSource
    extends BaseDataSource<_StoreParams, List<_StoreProductDetails>> {
  _InAppPurchasesProductDetailsDataSource({required super.cacheStrategy});

  final _api = _FakeInAppPurchasesProductDetailsApi();

  @override
  Future<List<_StoreProductDetails>> request(_StoreParams? params) {
    if (params == null) {
      throw StateError('Params cannot be null');
    }
    if (_dependentFetchThrow) {
      throw _dependentFetchError;
    } else {
      return Future.value(_api.queryProductDetails(identifiers: params.ids));
    }
  }
}

class _FakeInAppPurchasesProductDetailsApi {
  Future<List<_StoreProductDetails>> queryProductDetails({
    required Set<String> identifiers,
  }) => Future.value(_storeResponse);
}

class _FakeRetrofitBackendProductsApi {
  Future<_BackendResponse> fetchProducts({
    required String reqId,
    required String brand,
  }) => Future.value(_backendResponse);
}

class _MockRequestParams implements RequestParams {
  const _MockRequestParams(this.reqId, this.brand);

  final String reqId;
  final String brand;

  @override
  String get cacheKey => brand;

  @override
  String toString() => '_MockRequestParams{reqId: $reqId, brand: $brand}';
}

class _StoreParams implements RequestParams {
  const _StoreParams(this.ids);

  final Set<String> ids;

  @override
  String get cacheKey => throw UnimplementedError();
}

class _ProductModel {
  const _ProductModel({
    required this.uuid,
    required this.storeId,
    required this.title,
    required this.price,
    required this.currencySign,
  });

  final String uuid;
  final String storeId;
  final String title;
  final double price;
  final String currencySign;
}

class _BackendResponse {
  const _BackendResponse(this.products);

  factory _BackendResponse.fromJson(Map<String, Object?> map) {
    return _BackendResponse(
      (map['products']! as List)
          .map((e) => _BackendProduct.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<Object, Object?> toJson() => {
    'products': products.map((p) => p.toJson()).toList(),
  };

  final List<_BackendProduct> products;
}

class _BackendProduct {
  const _BackendProduct({
    required this.uuid,
    required this.storeId,
    required this.title,
  });

  factory _BackendProduct.fromJson(Map<String, Object?> map) {
    return _BackendProduct(
      uuid: map['uuid']! as String,
      storeId: map['storeId']! as String,
      title: map['title']! as String,
    );
  }

  final String uuid;
  final String storeId;
  final String title;

  Map<Object, Object?> toJson() => {
    'uuid': uuid,
    'storeId': storeId,
    'title': title,
  };
}

class _StoreProductDetails {
  const _StoreProductDetails({
    required this.id,
    required this.price,
    required this.currencySign,
  });

  final String id;
  final double price;
  final String currencySign;
}

const _backendResponse = _BackendResponse([
  _BackendProduct(
    uuid: '0000000000001',
    storeId: 'premium_product_1',
    title: 'premium feature 1',
  ),
  _BackendProduct(
    uuid: '0000000000003',
    storeId: 'premium_product_3',
    title: 'premium feature 3',
  ),
  _BackendProduct(
    uuid: '0000000000005',
    storeId: 'premium_product_5',
    title: 'premium feature 5',
  ),
]);

const _storeResponse = [
  _StoreProductDetails(
    id: 'premium_product_1',
    price: 9.99,
    currencySign: r'$',
  ),
  _StoreProductDetails(
    id: 'premium_product_3',
    price: 19.99,
    currencySign: r'$',
  ),
  _StoreProductDetails(
    id: 'premium_product_5',
    price: 59.95,
    currencySign: r'$',
  ),
];

class _MockCacheFirstStrategy
    extends CacheFirstStrategy<_MockRequestParams, _BackendResponse> {
  _MockCacheFirstStrategy({required super.cache});
}

class _MockNoOpCacheStrategy
    extends NoOpCacheStrategy<_StoreParams, List<_StoreProductDetails>> {
  _MockNoOpCacheStrategy();
}
