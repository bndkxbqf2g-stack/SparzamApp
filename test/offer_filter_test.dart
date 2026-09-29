import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/offers/offer_import.dart';
import 'package:sparzamapp/features/offers/offer_filter.dart';
import 'package:sparzamapp/models/offer.dart';

void main() {
  final now = DateTime(2026, 9, 22);
  final offers = [
    Offer(
      id: 'a',
      productId: 'milch_35',
      storeName: 'Lidl',
      originalPrice: 1.49,
      offerPrice: 0.99,
      validUntil: DateTime(2026, 9, 24),
    ),
    Offer(
      id: 'b',
      productId: 'bananen',
      storeName: 'ALDI Süd',
      originalPrice: 1.59,
      offerPrice: 1.19,
      validUntil: DateTime(2026, 9, 23),
    ),
    Offer(
      id: 'c',
      productId: 'nudeln',
      storeName: 'PENNY',
      originalPrice: 1.29,
      offerPrice: 0.79,
      validUntil: DateTime(2026, 9, 20),
    ),
  ];

  test('aktive Angebote werden nach Ablaufdatum sortiert', () {
    final result = filterOffers(
      offers,
      status: OfferStatusFilter.active,
      now: now,
    );

    expect(result.map((offer) => offer.id), ['b', 'a']);
  });

  test('abgelaufene Angebote werden getrennt', () {
    final result = filterOffers(
      offers,
      status: OfferStatusFilter.expired,
      now: now,
    );

    expect(result.map((offer) => offer.id), ['c']);
  });

  test('Suche findet Produkt, Alias und Markt', () {
    expect(
      filterOffers(
        offers,
        status: OfferStatusFilter.all,
        query: 'milch',
        now: now,
      ).single.id,
      'a',
    );
    expect(
      filterOffers(
        offers,
        status: OfferStatusFilter.all,
        query: 'pasta',
        now: now,
      ).single.id,
      'c',
    );
    expect(
      filterOffers(
        offers,
        status: OfferStatusFilter.all,
        query: 'aldi',
        now: now,
      ).single.id,
      'b',
    );
  });

  test('aktive Angebote berücksichtigen Beginn und Ende des Zeitraums', () {
    final future = Offer(
      id: 'future',
      productId: 'milch_35',
      storeName: 'Lidl',
      originalPrice: 1.49,
      offerPrice: 0.99,
      validFrom: DateTime(2026, 9, 23),
      validUntil: DateTime(2026, 9, 30),
    );
    final active = Offer(
      id: 'active',
      productId: 'milch_35',
      storeName: 'Lidl',
      originalPrice: 1.49,
      offerPrice: 0.99,
      validFrom: DateTime(2026, 9, 22),
      validUntil: DateTime(2026, 9, 22),
    );

    expect(
      filterOffers(
        [future, active],
        status: OfferStatusFilter.active,
        now: now,
      ).map((offer) => offer.id),
      ['active'],
    );
  });

  test('currentProspectRecords excludes expired records', () {
    final records = [
      OfferImportRecord(
        sourceId: 'current',
        productLabel: 'Milch',
        storeName: 'Lidl',
        offerPrice: 0.99,
        validFrom: DateTime(2026, 9, 22),
        validUntil: DateTime(2026, 9, 29),
      ),
      OfferImportRecord(
        sourceId: 'expired',
        productLabel: 'Butter',
        storeName: 'Lidl',
        offerPrice: 1.49,
        validUntil: DateTime(2026, 9, 28),
      ),
    ];

    expect(
      currentProspectRecords(records, now: now).map((record) => record.sourceId),
      ['current'],
    );
  });
}
