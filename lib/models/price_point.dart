import 'dart:convert';

enum PricePointSource { sample, manual, openPrices, receipt }

extension PricePointSourceLabel on PricePointSource {
  String get label => switch (this) {
        PricePointSource.sample => 'Beispieldaten',
        PricePointSource.manual => 'Eigener Preis',
        PricePointSource.openPrices => 'Open Prices',
        PricePointSource.receipt => 'Kassenbon',
      };
}

class PricePoint {
  const PricePoint({
    required this.productId,
    required this.storeName,
    required this.price,
    required this.date,
    this.source = PricePointSource.sample,
  });

  final String productId;
  final String storeName;
  final double price;
  final DateTime date;
  final PricePointSource source;

  String get observationKey {
    final day = DateTime(date.year, date.month, date.day);
    return '$productId|$storeName|${day.toIso8601String()}|${source.name}';
  }

  factory PricePoint.fromJson(String value) {
    final json = jsonDecode(value) as Map<String, dynamic>;
    final sourceName = json['source'] as String?;
    final source = PricePointSource.values
        .where((item) => item.name == sourceName)
        .firstOrNull;
    final productId = json['productId'] as String?;
    final storeName = json['storeName'] as String?;
    final rawPrice = json['price'];
    final price = rawPrice is num ? rawPrice.toDouble() : double.nan;
    if (productId == null ||
        productId.trim().isEmpty ||
        storeName == null ||
        storeName.trim().isEmpty ||
        !price.isFinite ||
        price <= 0) {
      throw const FormatException('Ungültiger Preisverlauf-Eintrag');
    }
    return PricePoint(
      productId: productId,
      storeName: storeName,
      price: price,
      date: DateTime.parse(json['date'] as String),
      source: source ?? PricePointSource.sample,
    );
  }

  String toJson() => jsonEncode({
        'productId': productId,
        'storeName': storeName,
        'price': price,
        'date': date.toIso8601String(),
        'source': source.name,
      });
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
