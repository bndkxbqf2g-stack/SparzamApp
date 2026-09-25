import '../../models/product.dart';
import '../catalog/product_identity.dart';
import 'receipt_ledger.dart';
import 'receipt_observation_builder.dart';

/// Builds a conservative catalog identity for a real receipt item that has no
/// safer catalog match yet. No variant detail is invented beyond the receipt.
Product buildAutomaticReceiptProduct({
  required ReceiptRow row,
  required String id,
}) {
  final family = inferReceiptFamily(row.label);
  return Product(
    id: id,
    name: receiptProductDisplayName(row.label),
    unit: row.quantityUnit == 'kg' ? 'kg' : 'Stück',
    group: receiptProductDisplayName(family),
    aliases: [row.label],
  );
}

/// Reuses only an exact normalized receipt alias/name. This prevents repeated
/// imports from creating duplicate provisional products without merging merely
/// similar variants.
Product? findExistingReceiptProduct(
  String rawLabel,
  List<Product> products,
) {
  final key = normalizeReceiptProductLabel(rawLabel);
  for (final product in products) {
    if (normalizeReceiptProductLabel(product.name) == key) return product;
    if (product.aliases.any(
      (alias) => normalizeReceiptProductLabel(alias) == key,
    )) {
      return product;
    }
  }
  return null;
}

String normalizeReceiptProductLabel(String value) => value
    .toLowerCase()
    .replaceAll(RegExp(r'[._-]+'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

String receiptProductDisplayName(String value) {
  final cleaned = value.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (cleaned.isEmpty) return cleaned;
  return cleaned[0].toUpperCase() + cleaned.substring(1);
}


/// Known product families should stay as receipt observations until they can
/// be matched to an actual catalog product. Creating a provisional catalog
/// product for every known-family receipt label pollutes suggestions with
/// retailer wording such as "GL H-Milch 3,5% 1 L".
bool shouldCreateAutomaticReceiptProduct(String rawLabel) =>
    !identifyProduct(rawLabel).isKnown;
