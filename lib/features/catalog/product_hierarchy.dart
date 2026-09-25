import '../../models/product.dart';
import 'product_identity.dart';

class ProductHierarchyLabel {
  const ProductHierarchyLabel({
    required this.family,
    this.variant,
  });

  final String family;
  final String? variant;

  String get path => variant == null ? family : '$family › $variant';
}

/// Presentation-only hierarchy derived from the existing identity resolver.
/// It never upgrades identity confidence or changes matching behavior.
ProductHierarchyLabel productHierarchyLabel(Product product) {
  final identities = <ProductIdentity>[
    identifyProduct(product.name),
    ...product.aliases.map(identifyProduct),
  ].where((identity) => identity.isKnown).toList();

  if (identities.isEmpty) {
    return ProductHierarchyLabel(family: _fallbackLabel(product.group));
  }

  final identity = identities.firstWhere(
    (candidate) => !candidate.isGeneric,
    orElse: () => identities.first,
  );
  return ProductHierarchyLabel(
    family: _familyLabel(identity.familyKey!),
    variant: _variantLabel(identity),
  );
}

String? productHierarchyRoot(ProductIdentity identity) => switch (identity.familyKey) {
      'tomaten' ||
      'tomatenmark' ||
      'tomatenkonserve' ||
      'tomatensauce' =>
        'tomate',
      final family => family,
    };

bool sharesProductHierarchy(
  ProductIdentity left,
  ProductIdentity right,
) {
  final leftRoot = productHierarchyRoot(left);
  final rightRoot = productHierarchyRoot(right);
  return leftRoot != null && leftRoot == rightRoot;
}

String _familyLabel(String key) => switch (key) {
      'aepfel' => 'Äpfel',
      'kaese' => 'Käse',
      'fischstäbchen' => 'Fischstäbchen',
      'tomatenkonserve' => 'Tomatenkonserve',
      'tomatensauce' => 'Tomatensauce',
      'tomatenmark' => 'Tomatenmark',
      _ => _fallbackLabel(key),
    };

String? _variantLabel(ProductIdentity identity) {
  final parts = <String>[
    if (identity.variant != null) _prettyVariant(identity.variant!),
    if (identity.productType != null &&
        identity.productType != identity.variant &&
        identity.familyKey != 'tomatenmark' &&
        identity.familyKey != 'tomatensauce' &&
        identity.familyKey != 'tomatenkonserve')
      _prettyVariant(identity.productType!),
    if (identity.fatPercent != null)
      '${_number(identity.fatPercent!)} %',
    if (identity.color != null) _prettyVariant(identity.color!),
    if (identity.shape != null) _prettyVariant(identity.shape!),
    if (identity.meatType != null) _prettyVariant(identity.meatType!),
  ];
  return parts.isEmpty ? null : parts.join(' · ');
}

String _prettyVariant(String value) => switch (value) {
      'h' => 'H-Milch',
      'rispe' => 'Rispe',
      'party' => 'Party',
      'cherry' => 'Cherry',
      'cocktail' => 'Cocktail',
      'rind' => 'Rind',
      'gemischt' => 'Gemischt',
      'gruen' => 'Grün',
      'bergkaese' => 'Bergkäse',
      'butterkaese' => 'Butterkäse',
      _ => _fallbackLabel(value),
    };

String _number(double value) {
  final whole = value.roundToDouble() == value;
  return (whole ? value.toStringAsFixed(0) : value.toString())
      .replaceAll('.', ',');
}

String _fallbackLabel(String value) {
  final clean = value
      .replaceAll('_', ' ')
      .replaceAll('-', ' ')
      .trim();
  if (clean.isEmpty) return 'Sonstiges';
  return clean
      .split(RegExp(r'\s+'))
      .map((part) => part.isEmpty
          ? part
          : '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
