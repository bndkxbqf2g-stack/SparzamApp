import '../../models/offer.dart';
import '../../models/product.dart';
import '../catalog/product_identity.dart';

class OfferImportRecord {
  const OfferImportRecord({
    required this.sourceId,
    required this.productLabel,
    required this.storeName,
    this.originalPrice,
    required this.offerPrice,
    required this.validUntil,
    this.validFrom,
    this.source = 'leaflet',
    this.proofRef,
    this.imageUrl,
  });

  final String sourceId;
  final String productLabel;
  final String storeName;
  final double? originalPrice;
  final double offerPrice;
  final DateTime validUntil;
  final DateTime? validFrom;
  final String source;
  final String? proofRef;
  final String? imageUrl;
}

class OfferImportResolution {
  const OfferImportResolution({
    required this.record,
    this.product,
    this.offer,
    this.reason,
  });

  final OfferImportRecord record;
  final Product? product;
  final Offer? offer;
  final String? reason;

  bool get isResolved => product != null && offer != null;
}

OfferImportResolution resolveOfferImport(
  OfferImportRecord record,
  Iterable<Product> catalogProducts,
) {
  if (!_validPrices(record)) {
    return OfferImportResolution(record: record, reason: 'invalid_price');
  }
  if (record.validFrom != null && record.validUntil.isBefore(record.validFrom!)) {
    return OfferImportResolution(record: record, reason: 'invalid_validity');
  }

  final normalizedLabel = normalizeIdentityText(record.productLabel);
  final products = catalogProducts.toList(growable: false);

  // Only the canonical product name may short-circuit identity resolution.
  // Generic aliases such as "Milch" can intentionally belong to multiple
  // variants and must therefore remain ambiguous.
  final exact = products
      .where((product) =>
          normalizeIdentityText(product.name) == normalizedLabel)
      .toList();

  final Product? product;
  if (exact.length == 1) {
    product = exact.single;
  } else if (exact.length > 1) {
    return OfferImportResolution(record: record, reason: 'ambiguous_identity');
  } else {
    final request = identifyProduct(record.productLabel);
    if (!request.isKnown) {
      return OfferImportResolution(record: record, reason: 'unknown_identity');
    }
    final compatible = products.where((candidate) {
      final identities = [candidate.name, ...candidate.aliases]
          .map(identifyProduct)
          .where((identity) => identity.isKnown);
      return identities.any(
        (identity) => compatibleProductIdentity(request, identity),
      );
    }).toList();
    if (compatible.length != 1) {
      return OfferImportResolution(
        record: record,
        reason: compatible.isEmpty ? 'unknown_identity' : 'ambiguous_identity',
      );
    }
    product = compatible.single;
  }

  if (record.source != 'manual' &&
      record.proofRef?.trim().isNotEmpty != true) {
    return OfferImportResolution(record: record, reason: 'missing_proof');
  }

  final offer = Offer(
    id: 'import|${record.source}|${record.sourceId}|${product.id}',
    productId: product.id,
    storeName: record.storeName,
    originalPrice: record.originalPrice ?? record.offerPrice,
    originalPriceVerified: record.originalPrice != null,
    offerPrice: record.offerPrice,
    validFrom: record.validFrom,
    validUntil: record.validUntil,
    source: record.source,
    proofRef: record.proofRef,
    imageUrl: record.imageUrl,
  );
  return OfferImportResolution(record: record, product: product, offer: offer);
}

bool _validPrices(OfferImportRecord record) {
  final regular = record.originalPrice;
  return record.offerPrice.isFinite &&
      record.offerPrice > 0 &&
      (regular == null ||
          (regular.isFinite && regular > 0 && record.offerPrice <= regular));
}
