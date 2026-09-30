import '../../models/product.dart';
import '../../services/quantity_normalizer.dart';
import '../catalog/product_identity.dart';

typedef ProspectPackage = ({double amount, String unit});

/// Family similarity alone is not exact price identity. A prospect label may
/// reuse a catalog ID only when name and package basis are both explicit.
Product? exactProspectProduct(String label, Iterable<Product> catalogProducts) {
  final normalized = normalizeIdentityText(label);
  final observedPackage = prospectPackage(label);
  if (normalized.isEmpty || observedPackage == null) return null;
  final exactNames = catalogProducts
      .where((product) => normalizeIdentityText(product.name) == normalized)
      .toList(growable: false);
  if (exactNames.length != 1) return null;
  final product = exactNames.single;
  final expectedPackage =
      product.packageAmount != null && product.packageUnit != null
      ? (amount: product.packageAmount!, unit: product.packageUnit!)
      : prospectPackage(product.unit);
  if (expectedPackage == null ||
      !sameProspectPackage(observedPackage, expectedPackage)) {
    return null;
  }
  return product;
}

ProspectPackage? prospectPackage(String label) {
  final text = label.toLowerCase();
  if (RegExp(r'\d\s*[x×]\s*\d').hasMatch(text)) return null;
  final match = RegExp(r'(\d+(?:[,.]\d+)?)\s*(kg|g|ml|l|stk|st|stück|stueck)\b')
      .firstMatch(text);
  if (match == null) return null;
  final amount = double.tryParse(match.group(1)!.replaceAll(',', '.'));
  if (amount == null || amount <= 0) return null;
  return (amount: amount, unit: match.group(2)!);
}

bool sameProspectPackage(ProspectPackage left, ProspectPackage right) {
  final normalizedLeft = normalizeQuantity(left.amount, left.unit);
  final normalizedRight = normalizeQuantity(right.amount, right.unit);
  return normalizedLeft != null &&
      normalizedRight != null &&
      normalizedLeft.dimension == normalizedRight.dimension &&
      (normalizedLeft.amount - normalizedRight.amount).abs() < 0.000001;
}
