import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sparzamapp/features/offers/offer_import.dart';
import 'package:sparzamapp/features/offers/prospect_regular_price_persistence.dart';
import 'package:sparzamapp/models/price_observation.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/services/price_observation_store.dart';
import 'package:sparzamapp/services/prospect_feed_service.dart';

void main() {
  setUp(
    () => SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty(),
  );
  tearDown(() => SharedPreferencesAsyncPlatform.instance = null);

  test('Prospektrefresh speichert nur den regulären Normalpreis lokal', () async {
    final now = DateTime(2026, 10, 15, 12);
    const coffee = Product(
      id: 'persistence-coffee-500',
      name: 'Jacobs Kaffee Crema 500 g',
      unit: '500 g',
      group: 'Kaffee & Snacks',
    );
    final record = OfferImportRecord(
      sourceId: 'persistence-regular-only',
      productLabel: coffee.name,
      storeName: 'Lidl',
      originalPrice: 7.99,
      regularPriceSource: 'originalPrice',
      offerPrice: 4.99,
      validFrom: DateTime(2026, 10, 12),
      validUntil: DateTime(2026, 10, 17),
      source: 'retailerWebsite',
      sourceAdapter: 'kaufda',
      branchId: 'lidl-branch-1',
      proofRef: 'https://example.test/lidl/coffee',
      capturedAt: now,
    );
    var raw = <String>[];
    final store = PriceObservationStore(
      readRaw: () async => List<String>.of(raw),
      writeRaw: (values) async => raw = List<String>.of(values),
    );

    final result = await persistCurrentProspectRegularPrices(
      store: store,
      records: [record],
      catalogProducts: const [coffee],
      observedAt: now,
      now: now,
      refreshedStores: const ['Lidl'],
    );

    expect(result.learned, hasLength(1));
    expect(result.learned.single.kind, PriceObservationKind.regular);
    expect(result.learned.single.price, 7.99);
    expect(result.learned.single.discounted, isFalse);
    expect(result.learned.single.locationId, 'lidl-branch-1');
    expect(result.learned.single.sourceAdapter, 'kaufda');
    expect(result.stored, hasLength(1));
    expect(result.stored.single.price, 7.99);
    expect(result.stored.single.price, isNot(4.99));
    expect(result.stored.single.kind, isNot(PriceObservationKind.offer));
    expect(await store.load(), hasLength(1));
  });

  test('persists only the regular price from the refreshed exact branch', () async {
    final now = DateTime(2026, 10, 17, 12);
    const coffee = Product(
      id: 'branch-scoped-coffee',
      name: 'Jacobs Kaffee Crema 500 g',
      unit: '500 g',
      group: 'Kaffee & Snacks',
    );
    OfferImportRecord record(String id, String branch) => OfferImportRecord(
          sourceId: id,
          productLabel: coffee.name,
          storeName: 'Lidl',
          originalPrice: 7.99,
          regularPriceSource: 'originalPrice',
          offerPrice: 4.99,
          validFrom: DateTime(2026, 10, 12),
          validUntil: DateTime(2026, 10, 18),
          source: 'retailerWebsite',
          sourceAdapter: 'structured_api',
          branchId: branch,
          proofRef: 'https://example.test/lidl/$branch',
          capturedAt: now,
        );
    var raw = <String>[];
    final store = PriceObservationStore(
      readRaw: () async => List<String>.of(raw),
      writeRaw: (values) async => raw = List<String>.of(values),
    );

    final result = await persistCurrentProspectRegularPrices(
      store: store,
      records: [
        record('zellingen', 'lidl-zellingen'),
        record('wuerzburg', 'lidl-wuerzburg'),
      ],
      catalogProducts: const [coffee],
      observedAt: now,
      now: now,
      refreshedStores: const ['Lidl'],
      refreshedStoreScopes: const [
        ProspectRefreshScope(
          storeName: 'Lidl',
          branchId: 'lidl-zellingen',
        ),
      ],
    );

    expect(result.learned, hasLength(1));
    expect(result.learned.single.locationId, 'lidl-zellingen');
    expect(result.stored, hasLength(1));
    expect(result.stored.single.kind, PriceObservationKind.regular);
    expect(result.stored.single.price, 7.99);
  });

}
