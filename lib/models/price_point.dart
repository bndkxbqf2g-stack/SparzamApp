import 'dart:convert';

enum PricePointSource { sample, manual, openPrices }

extension PricePointSourceLabel on PricePointSource {
  String get label => switch (this) {
        PricePointSource.sample => 'Beispieldaten',
        PricePointSource.manual => 'Eigener Preis',
        PricePointSource.openPrices => 'Open Prices',
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
    return PricePoint(
      productId: json['productId'] as String,
      storeName: json['storeName'] as String,
      price: (json['price'] as num).toDouble(),
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
