import 'dart:convert';

import '../data/products.dart';
import 'product.dart';

class RecentPurchase {
  const RecentPurchase({
    required this.id,
    required this.name,
    required this.unit,
    required this.group,
    this.purchaseCount = 1,
    this.totalQuantity = 1,
    this.ean,
    this.aliases = const <String>[],
    this.isFavorite = false,
    this.isStaple = false,
    this.brand,
    this.packageAmount,
    this.packageUnit,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String unit;
  final String group;
  final int purchaseCount;
  final int totalQuantity;
  final String? ean;
  final List<String> aliases;
  final bool isFavorite;
  final bool isStaple;
  final String? brand;
  final double? packageAmount;
  final String? packageUnit;
  final String? imageUrl;

  double get averageQuantity => totalQuantity / purchaseCount;

  factory RecentPurchase.fromProduct(Product product) => RecentPurchase(
        id: product.id,
        name: product.name,
        unit: product.unit,
        group: product.group,
        ean: product.ean,
        aliases: List<String>.of(product.aliases, growable: false),
        isFavorite: product.isFavorite,
        isStaple: product.isStaple,
        brand: product.brand,
        packageAmount: product.packageAmount,
        packageUnit: product.packageUnit,
        imageUrl: product.imageUrl,
      );

  factory RecentPurchase.fromJson(String value) {
    final json = jsonDecode(value) as Map<String, dynamic>;
    final id = json['id'] as String?;
    final name = json['name'] as String?;
    final unit = json['unit'] as String?;
    final group = json['group'] as String?;
    final purchaseCount = (json['purchaseCount'] as num?)?.toInt() ?? 1;
    final totalQuantity = (json['totalQuantity'] as num?)?.toInt() ?? 1;
    final aliases = (json['aliases'] as List<dynamic>?)
            ?.whereType<String>()
            .toList(growable: false) ??
        const <String>[];
    if (id == null ||
        id.trim().isEmpty ||
        name == null ||
        name.trim().isEmpty ||
        unit == null ||
        unit.trim().isEmpty ||
        group == null ||
        group.trim().isEmpty ||
        purchaseCount <= 0 ||
        totalQuantity <= 0) {
      throw const FormatException('Ungültiger letzter Einkauf');
    }
    return RecentPurchase(
      id: id,
      name: name,
      unit: unit,
      group: group,
      purchaseCount: purchaseCount,
      totalQuantity: totalQuantity,
      ean: json['ean'] as String?,
      aliases: aliases,
      isFavorite: json['isFavorite'] as bool? ?? false,
      isStaple: json['isStaple'] as bool? ?? false,
      brand: json['brand'] as String?,
      packageAmount: (json['packageAmount'] as num?)?.toDouble(),
      packageUnit: json['packageUnit'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  String toJson() => jsonEncode({
        'id': id,
        'name': name,
        'unit': unit,
        'group': group,
        'purchaseCount': purchaseCount,
        'totalQuantity': totalQuantity,
        'ean': ean,
        'aliases': aliases,
        'isFavorite': isFavorite,
        'isStaple': isStaple,
        'brand': brand,
        'packageAmount': packageAmount,
        'packageUnit': packageUnit,
        'imageUrl': imageUrl,
      });

  Product toProduct() {
    final known = products.where((product) => product.id == id);
    if (known.isNotEmpty) return known.first;
    return Product(
      id: id,
      name: name,
      unit: unit,
      group: group,
      ean: ean,
      aliases: aliases,
      isFavorite: isFavorite,
      isStaple: isStaple,
      brand: brand,
      packageAmount: packageAmount,
      packageUnit: packageUnit,
      imageUrl: imageUrl,
    );
  }
}
