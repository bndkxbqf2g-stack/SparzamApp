class Product {
  const Product({
    required this.id,
    required this.name,
    required this.unit,
    required this.group,
    this.aliases = const [],
    this.isFavorite = false,
    this.ean,
  });

  final String id;
  final String name;
  final String unit;
  final String group;
  final List<String> aliases;
  final bool isFavorite;
  final String? ean;
}
