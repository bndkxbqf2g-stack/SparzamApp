import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/offers/prospect_price_statistics.dart';
import 'package:sparzamapp/features/shopping_list/shopping_candidate_selector.dart';
import 'package:sparzamapp/models/price_observation.dart';
import 'package:sparzamapp/models/product.dart';

void main() {
  testWidgets('shows learned prospect median and its observation date', (
    tester,
  ) async {
    late BuildContext hostContext;
    const gouda = Product(
      id: 'gouda',
      name: 'Gouda',
      unit: '250 g',
      group: 'milch',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            hostContext = context;
            return const Scaffold(body: SizedBox.shrink());
          },
        ),
      ),
    );

    final selection = showShoppingCandidateSelector(
      context: hostContext,
      request: 'Käse',
      catalogProducts: const [gouda],
      offers: const [],
      marketPrices: const [],
      receiptPriceStats: const [],
      prospectPriceHistory: {
        gouda.id: ProspectPriceHistorySummary(
          productId: 'gouda',
          storeName: 'Lidl',
          medianPrice: 1.19,
          latestValidUntil: DateTime(2026, 9, 20),
          kind: PriceObservationKind.offer,
          observationCount: 2,
        ),
      },
      enabledStores: const [],
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Früheres Angebot (Median)'), findsOneWidget);
    expect(find.textContaining('Stand 20.09.2026'), findsOneWidget);

    Navigator.of(hostContext).pop();
    await selection;
  });
}
