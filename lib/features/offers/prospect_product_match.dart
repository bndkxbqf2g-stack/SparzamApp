import '../../models/product.dart';
import '../../services/quantity_normalizer.dart';
import '../catalog/product_identity.dart';

typedef ProspectPackage = ({double amount, String unit});

/// Family similarity alone is not exact price identity. A prospect label may
/// reuse a catalog ID only when name and package basis are both explicit.
Product? exactProspectProduct(
  String label,
  Iterable<Product> catalogProducts, {
  String? packageSize,
}) {
  final normalized = normalizeIdentityText(label);
  final observedPackage = prospectPackage(packageSize ?? label);
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
  if (_hasAmbiguousPackage(text)) return null;

  final multi = RegExp(
    r'(\d+)\s*[x×]\s*(\d+(?:[,.]\d+)?)\s*-?\s*'
    r'(kg|g|ml|cl|l|stk|st|stück|stueck)\b',
  ).firstMatch(text);
  if (multi != null) {
    final count = double.tryParse(multi.group(1)!);
    final amount = double.tryParse(multi.group(2)!.replaceAll(',', '.'));
    if (count != null && amount != null && count > 0 && amount > 0) {
      return (amount: count * amount, unit: multi.group(3)!);
    }
  }

  final countPack = RegExp(
    r'\b(\d+)\s*er\s*[- ]?(?:schale|pack(?:ung)?|becher|dose|flasche)\b',
  ).firstMatch(text);
  if (countPack != null) {
    final count = double.tryParse(countPack.group(1)!);
    if (count != null && count > 0) {
      return (amount: count, unit: 'Stück');
    }
  }

  final match = RegExp(r'(\d+(?:[,.]\d+)?)\s*(kg|g|ml|cl|l|stk|st|stück|stueck)\b')
      .firstMatch(text);
  if (match == null) return null;
  final amount = double.tryParse(match.group(1)!.replaceAll(',', '.'));
  if (amount == null || amount <= 0) return null;
  return (amount: amount, unit: match.group(2)!);
}

bool _hasAmbiguousPackage(String text) {
  // A slash or a numeric range describes several possible variants. Picking
  // one of them would create a false unit price and could merge identities.
  if (RegExp(
    r'\d+(?:[,.]\d+)?\s*(?:kg|g|ml|cl|l)\s*(?:/|-|–)\s*'
    r'\d+(?:[,.]\d+)?\s*(?:kg|g|ml|cl|l)?\b',
  ).hasMatch(text)) {
    return true;
  }
  if (RegExp(
    r'\d+(?:[,.]\d+)?\s*/\s*\d+(?:[,.]\d+)?\s*'
    r'(?:kg|g|ml|cl|l)\b',
  ).hasMatch(text)) {
    return true;
  }
  return false;
}

bool sameProspectPackage(ProspectPackage left, ProspectPackage right) {
  final normalizedLeft = normalizeQuantity(left.amount, left.unit);
  final normalizedRight = normalizeQuantity(right.amount, right.unit);
  return normalizedLeft != null &&
      normalizedRight != null &&
      normalizedLeft.dimension == normalizedRight.dimension &&
      (normalizedLeft.amount - normalizedRight.amount).abs() < 0.000001;
}
