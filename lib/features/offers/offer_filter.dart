import '../../data/products.dart';
import '../../models/offer.dart';

enum OfferStatusFilter { active, all, expired }

List<Offer> filterOffers(
  List<Offer> offers, {
  required OfferStatusFilter status,
  String query = '',
  DateTime? now,
}) {
  final today = _day(now ?? DateTime.now());
  final normalizedQuery = query.trim().toLowerCase();

  final result = offers.where((offer) {
    final active = !_day(offer.validUntil).isBefore(today);
    if (status == OfferStatusFilter.active && !active) return false;
    if (status == OfferStatusFilter.expired && active) return false;
    if (normalizedQuery.isEmpty) return true;

    final product = products.where((item) => item.id == offer.productId).firstOrNull;
    final searchable = <String>[
      offer.storeName,
      offer.productId,
      product?.name ?? '',
      ...?product?.aliases,
    ].join(' ').toLowerCase();

    return searchable.contains(normalizedQuery);
  }).toList();

  result.sort((a, b) {
    final aActive = !_day(a.validUntil).isBefore(today);
    final bActive = !_day(b.validUntil).isBefore(today);

    if (status == OfferStatusFilter.all && aActive != bActive) {
      return aActive ? -1 : 1;
    }
    return aActive
        ? a.validUntil.compareTo(b.validUntil)
        : b.validUntil.compareTo(a.validUntil);
  });

  return result;
}

DateTime _day(DateTime date) => DateTime(date.year, date.month, date.day);

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
