import 'dart:convert';

import 'list_item.dart';
import 'route_plan.dart';

class PurchaseRecord {
  const PurchaseRecord({
    required this.id,
    required this.createdAt,
    required this.storeNames,
    required this.items,
    required this.basket,
    required this.travel,
    required this.total,
    required this.baselineTotal,
  });

  final String id;
  final DateTime createdAt;
  final List<String> storeNames;
  final List<PurchaseLine> items;
  final double basket;
  final double travel;
  final double total;
  final double baselineTotal;

  double get savings => (baselineTotal - total).clamp(0.0, double.infinity).toDouble();
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  PurchaseRecord copyWith({
    DateTime? createdAt,
    List<String>? storeNames,
    List<PurchaseLine>? items,
    double? basket,
    double? travel,
    double? total,
    double? baselineTotal,
  }) =>
      PurchaseRecord(
        id: id,
        createdAt: createdAt ?? this.createdAt,
        storeNames: storeNames ?? this.storeNames,
        items: items ?? this.items,
        basket: basket ?? this.basket,
        travel: travel ?? this.travel,
        total: total ?? this.total,
        baselineTotal: baselineTotal ?? this.baselineTotal,
      );

  factory PurchaseRecord.fromPlan({
    required RoutePlan plan,
    required double baselineTotal,
    required List<ListItem> items,
    DateTime? createdAt,
  }) {
    final date = createdAt ?? DateTime.now();
    return PurchaseRecord(
      id: date.microsecondsSinceEpoch.toString(),
      createdAt: date,
      storeNames: plan.stores.map((store) => store.name).toList(),
      items: items
          .map((item) => PurchaseLine(
                productId: item.product.id,
                name: item.product.name,
                quantity: item.quantity,
              ))
          .toList(),
      basket: plan.basket,
      travel: plan.travel,
      total: plan.total,
      baselineTotal: baselineTotal,
    );
  }

  factory PurchaseRecord.fromJson(String value) {
    final json = jsonDecode(value) as Map<String, dynamic>;
    return PurchaseRecord(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      storeNames: (json['storeNames'] as List).cast<String>(),
      items: (json['items'] as List)
          .map((item) => PurchaseLine.fromMap((item as Map).cast<String, dynamic>()))
          .toList(),
      basket: (json['basket'] as num).toDouble(),
      travel: (json['travel'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      baselineTotal: (json['baselineTotal'] as num).toDouble(),
    );
  }

  String toJson() => jsonEncode({
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'storeNames': storeNames,
        'items': items.map((item) => item.toMap()).toList(),
        'basket': basket,
        'travel': travel,
        'total': total,
        'baselineTotal': baselineTotal,
      });
}

class PurchaseLine {
  const PurchaseLine({required this.productId, required this.name, required this.quantity});

  final String productId;
  final String name;
  final int quantity;

  factory PurchaseLine.fromMap(Map<String, dynamic> map) => PurchaseLine(
        productId: map['productId'] as String,
        name: map['name'] as String,
        quantity: (map['quantity'] as num).toInt(),
      );

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'name': name,
        'quantity': quantity,
      };
}
