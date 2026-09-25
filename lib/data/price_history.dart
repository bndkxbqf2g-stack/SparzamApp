import '../models/price_point.dart';

final samplePriceHistory = <PricePoint>[
  ..._weekly('butter_block', 'ALDI Süd', [1.79, 1.89, 1.69, 1.99, 1.79, 1.59]),
  ..._weekly('milch_35', 'Lidl', [1.19, 1.09, 1.19, 1.29, 1.09, 1.19]),
  ..._weekly('nudeln', 'Kaufland', [0.89, 0.99, 0.89, 0.79, 0.99, 0.89]),
];

List<PricePoint> _weekly(String productId, String storeName, List<double> prices) {
  final start = DateTime(2026, 8, 10);
  return [
    for (var i = 0; i < prices.length; i++)
      PricePoint(
        productId: productId,
        storeName: storeName,
        price: prices[i],
        date: start.add(Duration(days: i * 7)),
      ),
  ];
}
