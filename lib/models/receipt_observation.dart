class ReceiptObservation {
  const ReceiptObservation({
    required this.id,
    required this.receiptFingerprint,
    required this.rowLine,
    required this.rawLabel,
    required this.familyKey,
    required this.storeName,
    required this.observedAt,
    required this.totalPrice,
    required this.quantity,
    required this.quantityUnit,
    required this.unitPrice,
    required this.discounted,
    this.productId,
    this.identityConfirmed = false,
  });

  final String id;
  final String receiptFingerprint;
  final int rowLine;
  final String rawLabel;
  final String familyKey;
  final String storeName;
  final DateTime observedAt;
  final double totalPrice;
  final num? quantity;
  final String quantityUnit;
  final double? unitPrice;
  final bool discounted;
  final String? productId;
  /// True only when the concrete catalog identity was explicitly confirmed
  /// (directly or through previously learned confirmations).
  final bool identityConfirmed;

  Map<String, dynamic> toJson() => {
        'id': id,
        'receiptFingerprint': receiptFingerprint,
        'rowLine': rowLine,
        'rawLabel': rawLabel,
        'familyKey': familyKey,
        'storeName': storeName,
        'observedAt': observedAt.toIso8601String(),
        'totalPrice': totalPrice,
        'quantity': quantity,
        'quantityUnit': quantityUnit,
        'unitPrice': unitPrice,
        'discounted': discounted,
        'productId': productId,
        'identityConfirmed': identityConfirmed,
      };

  factory ReceiptObservation.fromJson(Map<String, dynamic> json) {
    final productId = json['productId'] as String?;
    // Legacy automatic receipt products used this stable ID prefix. Keep those
    // conservative when migrating records that predate identityConfirmed.
    final legacyConfirmed = productId != null &&
        !productId.startsWith('receipt_auto_');
    return ReceiptObservation(
      id: json['id'] as String,
      receiptFingerprint: json['receiptFingerprint'] as String,
      rowLine: (json['rowLine'] as num).toInt(),
      rawLabel: json['rawLabel'] as String,
      familyKey: json['familyKey'] as String? ?? '',
      storeName: json['storeName'] as String,
      observedAt: DateTime.parse(json['observedAt'] as String),
      totalPrice: (json['totalPrice'] as num).toDouble(),
      quantity: json['quantity'] as num?,
      quantityUnit: json['quantityUnit'] as String? ?? 'Stück',
      unitPrice: (json['unitPrice'] as num?)?.toDouble(),
      discounted: json['discounted'] as bool? ?? false,
      productId: productId,
      identityConfirmed:
          json['identityConfirmed'] as bool? ?? legacyConfirmed,
    );
  }
}
