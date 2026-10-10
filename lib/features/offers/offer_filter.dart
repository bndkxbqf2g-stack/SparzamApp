import '../../data/products.dart';
import '../../data/offers.dart';
import '../../models/offer.dart';
import '../../models/product.dart';

enum OfferStatusFilter { active, all, expired }

List<Offer> filterOffers(
  List<Offer> offers, {
  required OfferStatusFilter status,
  String query = '',
  DateTime? now,
  List<Product> catalogProducts = products,
}) {
  final today = _day(now ?? DateTime.now());
  final normalizedQuery = query.trim().toLowerCase();

  final result = offers.where((offer) {
    final active = isOfferDateRangeActive(
      validFrom: offer.validFrom,
      validUntil: offer.validUntil,
      now: now,
    );
    if (status == OfferStatusFilter.active && !active) return false;
    if (status == OfferStatusFilter.expired &&
        !_day(offer.validUntil).isBefore(today)) {
      return false;
    }
    if (normalizedQuery.isEmpty) return true;

    final product = catalogProducts
        .where((item) => item.id == offer.productId)
        .firstOrNull;
    final searchable = <String>[
      offer.storeName,
      offer.productId,
      product?.name ?? '',
      ...?product?.aliases,
    ].join(' ').toLowerCase();

    return searchable.contains(normalizedQuery);
  }).toList();

  result.sort((a, b) {
    final aActive = isOfferDateRangeActive(
      validFrom: a.validFrom,
      validUntil: a.validUntil,
      now: now,
    );
    final bActive = isOfferDateRangeActive(
      validFrom: b.validFrom,
      validUntil: b.validUntil,
      now: now,
    );

    if (status == OfferStatusFilter.all && aActive != bActive) {
      return aActive ? -1 : 1;
    }
    return aActive
        ? a.validUntil.compareTo(b.validUntil)
        : b.validUntil.compareTo(a.validUntil);
  });

  return result;
}

bool isOfferDateRangeActive({
  DateTime? validFrom,
  required DateTime validUntil,
  DateTime? now,
}) {
  final today = _day(now ?? DateTime.now());
  final startsTodayOrEarlier =
      validFrom == null || !_day(validFrom).isAfter(today);
  final endsTodayOrLater = !_day(validUntil).isBefore(today);
  return startsTodayOrEarlier && endsTodayOrLater;
}

/// Demo offers are seeded only for legacy installations and must never become
/// route or shopping evidence. Keep this check next to the shared offer
/// filtering rules so every consumer applies the same identity check.
bool isSampleOffer(Offer offer) => sampleOffers.any(
  (sample) =>
      sample.id == offer.id &&
      sample.productId == offer.productId &&
      sample.storeName == offer.storeName &&
      sample.offerPrice == offer.offerPrice,
);

DateTime _day(DateTime date) => DateTime(date.year, date.month, date.day);

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
