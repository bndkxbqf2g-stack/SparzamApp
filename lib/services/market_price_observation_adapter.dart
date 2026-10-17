import '../models/market_price.dart';
import '../models/price_observation.dart';
import '../models/product.dart';
import '../models/price_data_settings.dart';
import 'market_price_comparability.dart';

/// Existing exact market prices can enter the history without changing their
/// current UI/storage contract. A location label is not assumed to be a unique
/// branch identifier.
PriceObservation observationFromMarketPrice(MarketPrice price) =>
    PriceObservation(
      id: [
        price.source.name,
        price.externalId?.toString() ?? '',
        price.sourceLocationId ?? '',
        price.productId,
        price.storeName,
        price.updatedAt.toIso8601String(),
        price.price.toStringAsFixed(4),
        price.discounted.toString(),
      ].join('|'),
      productId: price.productId,
      storeName: price.storeName,
      locationId: price.sourceLocationId,
      region: price.sourceLocationName,
      price: price.price,
      observedAt: price.updatedAt,
      source: switch (price.source) {
        MarketPriceSource.manual => PriceObservationSource.manual,
        MarketPriceSource.receipt => PriceObservationSource.receipt,
        MarketPriceSource.openPrices => PriceObservationSource.openPrices,
        MarketPriceSource.prospect => PriceObservationSource.leaflet,
      },
      sourceAdapter: price.sourceAdapter,
      kind: price.kind == PriceObservationKind.unknown && price.discounted
          ? PriceObservationKind.offer
          : price.kind,
      proofRef: price.proofRef ??
          (price.externalId == null
              ? null
              : 'open-prices:${price.externalId}'),
      quantity: price.quantity,
      unit: price.unit,
      unitPrice: price.unitPrice,
      identityConfidence: price.identityConfidence,
      evidenceConfidence: price.evidenceConfidence,
      discounted: price.discounted,
    );

/// Projects exact, route-usable observations back into the legacy MarketPrice
/// contract. The append-only observation history remains the source evidence;
/// this projection exists only while route/UI contracts still use MarketPrice.
List<MarketPrice> marketPricesFromObservations(
  Iterable<PriceObservation> observations, {
  Iterable<Product> products = const <Product>[],
  PriceDataSettings settings = const PriceDataSettings(),
  DateTime? now,
}) {
  final today = now ?? DateTime.now();
  final currentDay = DateTime(today.year, today.month, today.day);
  final productsById = {for (final product in products) product.id: product};
  final eligible = observations
      .where(
        (entry) =>
            entry.isValid &&
            entry.productId?.isNotEmpty == true &&
            entry.identityConfidence >= 1 &&
            !_day(entry.observedAt).isAfter(currentDay) &&
            (entry.validFrom == null ||
                !_day(entry.validFrom!).isAfter(currentDay)) &&
            (entry.validUntil == null ||
                !_day(entry.validUntil!).isBefore(currentDay)) &&
            _sourceAllowed(entry, settings, today) &&
            _matchesProductPackage(entry, productsById[entry.productId]) &&
            _hasProspectValidity(entry) &&
            // A successful feed refresh can retain superseded rows for
            // history; only current prospect regular evidence may route.
            (entry.kind != PriceObservationKind.regular ||
                !_isProspectSource(entry.source) ||
                entry.isCurrent) &&
            _hasExactProspectBranch(entry) &&
            _projectsToLegacyMarketPrice(entry.source) &&
            !_isProspectOffer(entry),
      )
      .toList(growable: false);
  final selected = _latestCurrentProspectRegular(eligible);
  return selected
      .map(
        (entry) => MarketPrice(
          productId: entry.productId!,
          storeName: entry.storeName,
          price: entry.price,
          updatedAt: entry.observedAt,
          source: switch (entry.source) {
            PriceObservationSource.receipt => MarketPriceSource.receipt,
            PriceObservationSource.openPrices => MarketPriceSource.openPrices,
            PriceObservationSource.retailer ||
            PriceObservationSource.retailerWebsite ||
            PriceObservationSource.leaflet => MarketPriceSource.prospect,
            _ => MarketPriceSource.manual,
          },
          externalId: _openPricesId(entry.proofRef),
          sourceLocationId: entry.locationId,
          sourceLocationName: entry.region,
          sourceAdapter: entry.sourceAdapter,
          discounted:
              entry.discounted || entry.kind == PriceObservationKind.offer,
          proofRef: entry.proofRef,
          quantity: entry.quantity,
          unit: entry.unit,
          unitPrice: entry.unitPrice,
          identityConfidence: entry.identityConfidence,
          kind: entry.kind,
          evidenceConfidence: entry.evidenceConfidence,
        ),
      )
      .toList();
}

List<PriceObservation> _latestCurrentProspectRegular(
  List<PriceObservation> input,
) {
  final result = <PriceObservation>[];
  final indexByKey = <String, int>{};
  for (final entry in input) {
    final isProspectRegular =
        entry.kind == PriceObservationKind.regular &&
        _isProspectSource(entry.source);
    if (!isProspectRegular) {
      result.add(entry);
      continue;
    }
    final key = _prospectRegularProjectionKey(entry);
    final previousIndex = indexByKey[key];
    if (previousIndex == null) {
      indexByKey[key] = result.length;
      result.add(entry);
      continue;
    }
    final previous = result[previousIndex];
    if (_isNewerPriceObservation(entry, previous)) {
      result[previousIndex] = entry;
    }
  }
  return result;
}

String _prospectRegularProjectionKey(PriceObservation entry) => [
      entry.source.name,
      entry.sourceAdapter?.trim().toLowerCase() ?? '',
      entry.storeName.trim().toLowerCase(),
      entry.locationId?.trim().toLowerCase() ?? '',
      entry.productId?.trim() ?? '',
      entry.familyKey?.trim().toLowerCase() ?? '',
      entry.variant?.trim().toLowerCase() ?? '',
      entry.quantity?.toStringAsFixed(6) ?? '',
      entry.unit?.trim().toLowerCase() ?? '',
      // Validity is deliberately not part of the projection identity. A
      // refreshed brochure can move the same product into a new, overlapping
      // period; the newest current claim must replace the older claim instead
      // of leaving two simultaneous regular prices for one exact branch slot.
      // proofRef remains on the projected price for traceability, but it is
      // not part of the current identity. A refreshed leaflet may use a new
      // page/URL for the same product and branch.
    ].join('\u001f');

bool _isNewerPriceObservation(
  PriceObservation candidate,
  PriceObservation previous,
) => candidate.observedAt.isAfter(previous.observedAt) ||
    (candidate.observedAt.isAtSameMomentAs(previous.observedAt) &&
        candidate.id.compareTo(previous.id) > 0);
DateTime _day(DateTime value) => DateTime(value.year, value.month, value.day);

bool _matchesProductPackage(PriceObservation observation, Product? product) {
  if (product == null) {
    return true;
  }
  return quantityMatchesProduct(
    quantity: observation.quantity,
    unit: observation.unit,
    product: product,
  );
}

int? _openPricesId(String? proofRef) {
  if (proofRef == null || !proofRef.startsWith('open-prices:')) return null;
  return int.tryParse(proofRef.substring('open-prices:'.length));
}

bool _sourceAllowed(
  PriceObservation observation,
  PriceDataSettings settings,
  DateTime now,
) {
  final maxAgeDays = switch (observation.source) {
    PriceObservationSource.receipt => 30,
    PriceObservationSource.openPrices => settings.openPricesMaxAgeDays,
    _ => null,
  };
  if (observation.source == PriceObservationSource.openPrices &&
      !settings.openPricesEnabled) {
    return false;
  }
  if (maxAgeDays == null) return true;
  final currentDay = DateTime(now.year, now.month, now.day);
  final observedDay = DateTime(
    observation.observedAt.year,
    observation.observedAt.month,
    observation.observedAt.day,
  );
  return !observedDay.isBefore(currentDay.subtract(Duration(days: maxAgeDays)));
}

bool _projectsToLegacyMarketPrice(PriceObservationSource source) =>
    switch (source) {
      PriceObservationSource.manual ||
      PriceObservationSource.receipt ||
      PriceObservationSource.openPrices ||
      PriceObservationSource.retailer ||
      PriceObservationSource.retailerWebsite ||
      PriceObservationSource.leaflet => true,
      _ => false,
    };

bool _isProspectSource(PriceObservationSource source) =>
    source == PriceObservationSource.retailer ||
    source == PriceObservationSource.retailerWebsite ||
    source == PriceObservationSource.leaflet;

/// A prospect price without an exact branch remains historical evidence.
/// A visible city/store label is not a unique location and must never become
/// a routeable MarketPrice slot.
bool _hasExactProspectBranch(PriceObservation observation) {
  if (!_isProspectSource(observation.source)) return true;
  return observation.locationId?.trim().isNotEmpty == true;
}

bool _hasProspectValidity(PriceObservation observation) {
  if (observation.kind != PriceObservationKind.regular) return true;
  final isProspect = switch (observation.source) {
    PriceObservationSource.retailer ||
    PriceObservationSource.retailerWebsite ||
    PriceObservationSource.leaflet => true,
    _ => false,
  };
  // A regular prospect amount is only current evidence when the source
  // supplies an explicit end date. Legacy records without a validity window
  // remain historical evidence and cannot enter route planning.
  return !isProspect || observation.validUntil != null;
}

bool _isProspectOffer(PriceObservation observation) =>
    (observation.kind == PriceObservationKind.offer || observation.discounted) &&
    switch (observation.source) {
      PriceObservationSource.retailer ||
      PriceObservationSource.retailerWebsite ||
      PriceObservationSource.leaflet => true,
      _ => false,
    };
