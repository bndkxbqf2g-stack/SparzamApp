import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/data/products.dart';
import 'package:sparzamapp/features/catalog/product_identity.dart';
import 'package:sparzamapp/features/offers/offer_import.dart';
import 'package:sparzamapp/features/offers/prospect_offer_products.dart';
import 'package:sparzamapp/features/route/route_optimizer.dart';
import 'package:sparzamapp/features/shopping_list/shopping_suggestions.dart';
import 'package:sparzamapp/models/list_item.dart';
import 'package:sparzamapp/services/prospect_feed_service.dart';

void main() {
  test('aktueller Feed führt Milchsuche bis zur günstigen Route', () {
    final feed = parseProspectFeed(
      File('assets/prospects/current.json').readAsStringSync(),
    );
    final observedAt = feed.generatedAt!;
    final current = currentProspectRecords(feed.records, now: observedAt);
    final milkRecords = current
        .where(
          (record) => identifyProduct(record.productLabel).familyKey == 'milch',
        )
        .toList(growable: false);

    expect(milkRecords, isNotEmpty);
    final imported = prospectOfferProducts(
      records: milkRecords,
      catalogProducts: products,
      now: observedAt,
    );
    expect(imported, isNotEmpty);
    expect(imported.every((entry) => entry.offer.proofRef != null), isTrue);

    final offers = imported.map((entry) => entry.offer).toList(growable: false);
    final catalog = [...products, ...imported.map((entry) => entry.product)];
    final suggestions = buildSuggestions(
      query: 'Milch',
      knownItems: const [],
      recentPurchases: const [],
      preferredProductByGroup: const {},
      catalogProducts: catalog,
      offers: offers,
      enabledStores: configuredProspectStores,
      now: observedAt,
    );
    final offerProducts = suggestions
        .where(
          (product) => offers.any((offer) => offer.productId == product.id),
        )
        .toList(growable: false);

    expect(offerProducts, isNotEmpty);
    final chosen = offerProducts.first;
    final hint = shoppingSuggestionPriceForProduct(
      chosen,
      offers: offers,
      enabledStores: configuredProspectStores,
      now: observedAt,
    );
    expect(hint, isNotNull);
    expect(hint!.isOffer, isTrue);

    final route = RouteOptimizer(
      [ListItem(product: chosen)],
      offers,
      enabledStoreNames: configuredProspectStores,
      maxStores: 1,
      now: observedAt,
    ).bestSingleStorePlan();

    expect(route, isNotNull);
    expect(route!.unassigned, isEmpty);
    expect(route.basket, closeTo(hint.price, 0.001));
    expect(route.stores, hasLength(1));
  });
}
