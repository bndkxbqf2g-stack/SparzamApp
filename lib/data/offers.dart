import '../models/offer.dart';

final sampleOffers = <Offer>[
  Offer(
    id: 'aldi_butter_20260926',
    productId: 'butter_block',
    storeName: 'ALDI Süd',
    originalPrice: 1.99,
    offerPrice: 1.49,
    validUntil: DateTime(2026, 9, 26),
    cashbackPercent: 20,
  ),
  Offer(
    id: 'lidl_milch_20260926',
    productId: 'milch_35',
    storeName: 'Lidl',
    originalPrice: 1.29,
    offerPrice: 0.99,
    validUntil: DateTime(2026, 9, 26),
    coupon: true,
    couponPercent: 10,
  ),
  Offer(
    id: 'kaufland_nudeln_20260930',
    productId: 'nudeln',
    storeName: 'Kaufland',
    originalPrice: 0.99,
    offerPrice: 0.79,
    validUntil: DateTime(2026, 9, 30),
    buyQuantity: 3,
    payQuantity: 2,
    cashbackAmount: 0.20,
  ),
];
