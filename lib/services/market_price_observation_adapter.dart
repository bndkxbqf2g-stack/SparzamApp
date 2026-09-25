import '../models/market_price.dart';
import '../models/price_observation.dart';
import '../models/product.dart';
import '../models/price_data_settings.dart';
import 'quantity_normalizer.dart';

/// Existing exact market prices can enter the history without changing their
/// current UI/storage contract. A location label is not assumed to be a unique
/// branch identifier.
PriceObservation observationFromMarketPrice(MarketPrice price) =>
    PriceObservation(
      id: [
        price.source.name,
        price.externalId?.toString() ?? '',
        price.productId,
        price.storeName,
        price.updatedAt.toIso8601String(),
        price.price.toStringAsFixed(4),
        price.discounted.toString(),
      ].join('|'),
      productId: price.productId,
      storeName: price.storeName,
      region: price.sourceLocationName,
      price: price.price,
      observedAt: price.updatedAt,
      source: switch (price.source) {
        MarketPriceSource.manual => PriceObservationSource.manual,
        MarketPriceSource.receipt => PriceObservationSource.receipt,
        MarketPriceSource.openPrices => PriceObservationSource.openPrices,
      },
      kind: price.discounted
          ? PriceObservationKind.offer
          : PriceObservationKind.unknown,
      proofRef: price.externalId == null
          ? null : 'open-prices:${price.externalId}',
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
  final productsById = {for (final product in products) product.id: product};
  return observations
        .where((entry) =>
            entry.isValid &&
            entry.productId?.isNotEmpty == true &&
            entry.identityConfidence >= 1 &&
            (entry.validFrom == null || !entry.validFrom!.isAfter(today)) &&
            (entry.validUntil == null || !entry.validUntil!.isBefore(today)) &&
            _sourceAllowed(entry, settings, today) &&
            _matchesProductPackage(entry, productsById[entry.productId]) &&
            _projectsToLegacyMarketPrice(entry.source))
        .map((entry) => MarketPrice(
              productId: entry.productId!,
              storeName: entry.storeName,
              price: entry.price,
              updatedAt: entry.observedAt,
              source: switch (entry.source) {
                PriceObservationSource.receipt => MarketPriceSource.receipt,
                PriceObservationSource.openPrices => MarketPriceSource.openPrices,
                _ => MarketPriceSource.manual,
              },
              externalId: _openPricesId(entry.proofRef),
              sourceLocationName: entry.region,
              discounted: entry.discounted ||
                  entry.kind == PriceObservationKind.offer,
            ))
        .toList();
}

bool _matchesProductPackage(PriceObservation observation, Product? product) {
  if (product == null) {
    return true;
  }
  final expectedAmount = product.packageAmount;
  final expectedUnit = product.packageUnit;
  final observedAmount = observation.quantity;
  final observedUnit = observation.unit;

  // Legacy observations without quantity metadata remain readable. Once an
  // observation declares a quantity, it must match the exact product package.
  if (observedAmount == null || observedUnit == null) {
    return true;
  }
  if (expectedAmount == null || expectedUnit == null) {
    return false;
  }
  final expected = normalizeQuantity(expectedAmount, expectedUnit);
  final observed = normalizeQuantity(observedAmount, observedUnit);
  if (expected == null || observed == null ||
      expected.dimension != observed.dimension) {
    return false;
  }
  return (expected.amount - observed.amount).abs() < 0.000001;
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
  return !observation.observedAt.isBefore(
    now.subtract(Duration(days: maxAgeDays)),
  );
}


bool _projectsToLegacyMarketPrice(PriceObservationSource source) => switch (source) {
      PriceObservationSource.manual ||
      PriceObservationSource.receipt ||
      PriceObservationSource.openPrices ||
      PriceObservationSource.retailer ||
      PriceObservationSource.retailerWebsite ||
      PriceObservationSource.leaflet =>
        true,
      _ => false,
    };
