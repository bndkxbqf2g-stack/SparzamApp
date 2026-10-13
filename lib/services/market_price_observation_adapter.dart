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
  return observations
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
            _projectsToLegacyMarketPrice(entry.source) &&
            !_isProspectOffer(entry),
      )
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
        ),
      )
      .toList();
}

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
      PriceObservationSource.openPrices => true,
      _ => false,
    };
