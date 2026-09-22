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
  });

  final String id;
  final String name;
  final String unit;
  final String group;
  final int purchaseCount;
  final int totalQuantity;
  final String? ean;

  double get averageQuantity => totalQuantity / purchaseCount;

  factory RecentPurchase.fromProduct(Product product) => RecentPurchase(
        id: product.id,
        name: product.name,
        unit: product.unit,
        group: product.group,
        ean: product.ean,
      );

  factory RecentPurchase.fromJson(String value) {
    final json = jsonDecode(value) as Map<String, dynamic>;
    return RecentPurchase(
      id: json['id'] as String,
      name: json['name'] as String,
      unit: json['unit'] as String,
      group: json['group'] as String,
      purchaseCount: (json['purchaseCount'] as num?)?.toInt() ?? 1,
      totalQuantity: (json['totalQuantity'] as num?)?.toInt() ?? 1,
      ean: json['ean'] as String?,
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
      });

  Product toProduct() {
    final known = products.where((product) => product.id == id);
    if (known.isNotEmpty) return known.first;
    return Product(id: id, name: name, unit: unit, group: group, ean: ean);
  }
}
