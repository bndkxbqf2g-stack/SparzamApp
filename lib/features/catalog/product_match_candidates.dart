import '../../models/product.dart';

enum CandidateRelation {
  sameBarcode,
  matchingLabel,
  relatedName,
  categoryOnly,
}

/// A suggestion is never a confirmed identity until the user verifies it.
class ProductCandidate {
  const ProductCandidate({
    required this.product,
    required this.relation,
    required this.reasons,
    required this.cautions,
  });

  final Product product;
  final CandidateRelation relation;
  final List<String> reasons;
  final List<String> cautions;
}

class ProductQuery {
  const ProductQuery({
    required this.label,
    this.ean,
    this.category,
    this.requiredBrand,
  });

  final String label;
  final String? ean;
  final String? category;
  final String? requiredBrand;
}

/// Suggests candidates without translating a category or alias into identity.
List<ProductCandidate> suggestProducts(
  ProductQuery query,
  List<Product> products,
) {
  final label = _normalize(query.label);
  final requestedBrand = _normalize(query.requiredBrand ?? '');
  final code = query.ean?.trim();
  final candidates = <ProductCandidate>[];
  for (final product in products) {
    final brand = _normalize(product.brand ?? '');
    if (requestedBrand.isNotEmpty && brand != requestedBrand) continue;
    final names = [product.name, ...product.aliases].map(_normalize).toList();
    final normalizedName = _normalize(product.name);
    final category = _normalize(query.category ?? query.label);
    final sameCode = code != null && code.isNotEmpty && code == product.ean;
    final sameLabel = label.isNotEmpty && normalizedName == label;
    final alias = label.isNotEmpty && names.skip(1).contains(label);
    final related = label.length >= 4 &&
        normalizedName.split(' ').contains(label);
    final sameCategory = category.isNotEmpty &&
        _normalize(product.group) == category;
    if (!sameCode && !sameLabel && !alias && !related && !sameCategory) {
      continue;
    }
    final relation = sameCode ? CandidateRelation.sameBarcode
        : sameLabel ? CandidateRelation.matchingLabel
        : alias || related ? CandidateRelation.relatedName
        : CandidateRelation.categoryOnly;
    candidates.add(ProductCandidate(
      product: product,
      relation: relation,
      reasons: [
        if (sameCode) 'Gleicher Barcode',
        if (sameLabel) 'Gleiche Bezeichnung',
        if (alias) 'Passender Alias',
        if (related && !sameLabel) 'Begriff im Produktnamen',
        if (sameCategory) 'Passende Kategorie',
      ],
      cautions: [
        if (!sameCode) 'Produktidentität nicht bestätigt',
        if (relation == CandidateRelation.categoryOnly)
          'Nur Kategoriezugehörigkeit belegt',
        if (product.packageAmount == null && !sameCode)
          'Packungsgröße nicht geprüft',
      ],
    ));
  }
  candidates.sort((a, b) =>
      a.relation.index.compareTo(b.relation.index));
  return candidates;
}

String _normalize(String value) => value.toLowerCase()
    .replaceAll('ä', 'ae')
    .replaceAll('ö', 'oe')
    .replaceAll('ü', 'ue')
    .replaceAll('ß', 'ss')
    .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
    .trim();
