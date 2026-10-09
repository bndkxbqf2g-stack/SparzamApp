import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/data/stores.dart';
import 'package:sparzamapp/features/offers/offer_import.dart';
import 'package:sparzamapp/features/offers/prospect_offer_products.dart';
import 'package:sparzamapp/features/offers/prospect_price_learning.dart';
import 'package:sparzamapp/features/offers/prospect_product_match.dart';
import 'package:sparzamapp/features/catalog/product_identity.dart';
import 'package:sparzamapp/models/list_item.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/features/route/route_price_resolver.dart';
import 'package:sparzamapp/services/prospect_feed_service.dart';

void main() {
  test('versionierter Prospektfeed deckt sechs Märkte durchgängig ab', () {
    final raw = File('assets/prospects/current.json').readAsStringSync();
    final feed = parseProspectFeed(raw);
    final observedAt = feed.generatedAt;

    expect(observedAt, isNotNull);
    expect(
      feed.prospects.map((issue) => issue.storeName).toSet(),
      containsAll(configuredProspectStores),
    );
    expect(
      feed.records.map((record) => record.storeName).toSet(),
      containsAll(configuredProspectStores),
    );

    final current = currentProspectRecords(feed.records, now: observedAt);
    expect(
      current.map((record) => record.storeName).toSet(),
      containsAll(configuredProspectStores),
    );
    expect(current, isNotEmpty);

    // Every market must carry a current, source-backed offer through the
    // learning path. Unknown labels remain historical evidence with zero
    // identity confidence; they are still usable as visible offer-backed
    // products until the shopper confirms an identity.
    for (final storeName in configuredProspectStores) {
      final record = current.firstWhere(
        (entry) => entry.storeName == storeName,
      );
      final evidence = datedProspectPriceObservations(
        records: [record],
        catalogProducts: const [],
        observedAt: observedAt,
        refreshedStores: configuredProspectStores,
      );
      expect(evidence, isNotEmpty, reason: storeName);
      expect(
        evidence.every((entry) => entry.validUntil == record.validUntil),
        isTrue,
      );
      expect(evidence.every((entry) => entry.identityConfidence == 0), isTrue);

      final offerProducts = prospectOfferProducts(
        records: [record],
        catalogProducts: const [],
        now: observedAt,
      );
      expect(offerProducts, hasLength(1), reason: storeName);
      final imported = offerProducts.single;
      final store = stores.singleWhere((entry) => entry.name == storeName);
      final quote = RoutePriceResolver([
        imported.offer,
      ], now: observedAt).quote(store, ListItem(product: imported.product));
      expect(quote, isNotNull, reason: storeName);
      expect(quote!.total, imported.offer.offerPrice);

      // Where the feed label contains a package basis, the same observation
      // can be upgraded to exact identity evidence only with an exact catalog
      // name and matching package. Labels without that basis stay uncertain.
      final package = prospectPackage(record.productLabel);
      if (package != null) {
        final exactProduct = Product(
          id: 'feed-matrix-${normalizeIdentityText(record.productLabel)}',
          name: record.productLabel,
          unit: '${package.amount} ${package.unit}',
          group: 'fixture',
          packageAmount: package.amount,
          packageUnit: package.unit,
        );
        final exactEvidence = datedProspectPriceObservations(
          records: [record],
          catalogProducts: [exactProduct],
          observedAt: observedAt,
          refreshedStores: configuredProspectStores,
        );
        expect(exactEvidence, isNotEmpty, reason: storeName);
        expect(
          exactEvidence.every((entry) => entry.productId == exactProduct.id),
          isTrue,
          reason: storeName,
        );
        expect(
          exactEvidence.every((entry) => entry.identityConfidence == 1),
          isTrue,
          reason: storeName,
        );
      }
    }
  });

  test('abgelaufene Feedzeilen bleiben Historie und werden nicht aktuell', () {
    final raw = File('assets/prospects/current.json').readAsStringSync();
    final feed = parseProspectFeed(raw);
    final first = feed.records.first;
    final afterExpiry = first.validUntil.add(const Duration(days: 1));

    expect(currentProspectRecords([first], now: afterExpiry), isEmpty);
    expect(
      datedProspectPriceObservations(
        records: [first],
        catalogProducts: const [],
        observedAt: feed.generatedAt,
      ),
      isNotEmpty,
    );
  });
}
