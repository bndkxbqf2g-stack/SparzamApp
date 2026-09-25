class ReceiptAlias {
  const ReceiptAlias({
    required this.storeName,
    required this.normalizedLabel,
    required this.productId,
    required this.confirmations,
    required this.updatedAt,
  });

  final String storeName;
  final String normalizedLabel;
  final String productId;
  final int confirmations;
  final DateTime updatedAt;

  String get key => '${storeName.toLowerCase()}|$normalizedLabel';

  Map<String, dynamic> toJson() => {
        'storeName': storeName,
        'normalizedLabel': normalizedLabel,
        'productId': productId,
        'confirmations': confirmations,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory ReceiptAlias.fromJson(Map<String, dynamic> json) => ReceiptAlias(
        storeName: json['storeName'] as String,
        normalizedLabel: json['normalizedLabel'] as String,
        productId: json['productId'] as String,
        confirmations: (json['confirmations'] as num?)?.toInt() ?? 1,
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
