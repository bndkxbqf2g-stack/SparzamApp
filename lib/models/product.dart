class Product {
  const Product({
    required this.id,
    required this.name,
    required this.unit,
    required this.group,
    this.aliases = const [],
    this.isFavorite = false,
    this.ean,
    this.brand,
  });

  final String id;
  final String name;
  final String unit;
  final String group;
  final List<String> aliases;
  final bool isFavorite;
  final String? ean;
  final String? brand;

  Product copyWith({
    String? id,
    String? name,
    String? unit,
    String? group,
    List<String>? aliases,
    bool? isFavorite,
    String? ean,
    String? brand,
  }) =>
      Product(
        id: id ?? this.id,
        name: name ?? this.name,
        unit: unit ?? this.unit,
        group: group ?? this.group,
        aliases: aliases ?? this.aliases,
        isFavorite: isFavorite ?? this.isFavorite,
        ean: ean ?? this.ean,
        brand: brand ?? this.brand,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'unit': unit,
        'group': group,
        'aliases': aliases,
        'isFavorite': isFavorite,
        'ean': ean,
        'brand': brand,
      };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String,
        name: json['name'] as String,
        unit: json['unit'] as String,
        group: json['group'] as String,
        aliases: (json['aliases'] as List<dynamic>?)
                ?.whereType<String>()
                .toList() ??
            const <String>[],
        isFavorite: json['isFavorite'] as bool? ?? false,
        ean: json['ean'] as String?,
        brand: json['brand'] as String?,
      );
}
