import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/shopping_list/replenishment_card.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/models/replenishment_suggestion.dart';

void main() {
  testWidgets('zeigt die Evidenzquelle und fügt den Vorschlag hinzu', (
    tester,
  ) async {
    const product = Product(
      id: 'milk',
      name: 'Milch',
      unit: '1 l',
      group: 'milch',
    );
    final suggestion = ReplenishmentSuggestion(
      product: product,
      purchaseCount: 2,
      averageQuantity: 1,
      intervalDays: 7,
      lastPurchasedAt: DateTime(2026, 9, 8),
      dueAt: DateTime(2026, 9, 15),
      daysUntilDue: 0,
      urgency: ReplenishmentUrgency.overdue,
      fromPurchaseHistory: false,
      fromConfirmedReceipts: true,
    );
    ReplenishmentSuggestion? added;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReplenishmentCard(
            suggestions: [suggestion],
            onAdd: (value) => added = value,
          ),
        ),
      ),
    );

    expect(find.textContaining('bestätigte Bons'), findsOneWidget);
    await tester.tap(find.byTooltip('Zur Liste hinzufügen'));
    expect(added, suggestion);
  });

  testWidgets('zeigt den aktuellen Preis-Hinweis vor dem Hinzufügen', (
    tester,
  ) async {
    const product = Product(
      id: 'milk',
      name: 'Milch',
      unit: '1 l',
      group: 'milch',
    );
    final suggestion = ReplenishmentSuggestion(
      product: product,
      purchaseCount: 2,
      averageQuantity: 1,
      intervalDays: 7,
      lastPurchasedAt: DateTime(2026, 9, 8),
      dueAt: DateTime(2026, 9, 15),
      daysUntilDue: 0,
      urgency: ReplenishmentUrgency.overdue,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReplenishmentCard(
            suggestions: [suggestion],
            onAdd: (_) {},
            priceHintFor: (_) => 'Angebot ALDI Süd 0,95 € · bis 02.10.2026',
          ),
        ),
      ),
    );

    expect(
      find.text('Angebot ALDI Süd 0,95 € · bis 02.10.2026'),
      findsOneWidget,
    );
  });

  testWidgets('öffnet die Angebots- und Variantenprüfung', (tester) async {
    const product = Product(
      id: 'milk',
      name: 'Milch',
      unit: '1 l',
      group: 'milch',
    );
    final suggestion = ReplenishmentSuggestion(
      product: product,
      purchaseCount: 2,
      averageQuantity: 1,
      intervalDays: 7,
      lastPurchasedAt: DateTime(2026, 9, 8),
      dueAt: DateTime(2026, 9, 15),
      daysUntilDue: 0,
      urgency: ReplenishmentUrgency.overdue,
    );
    ReplenishmentSuggestion? reviewed;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReplenishmentCard(
            suggestions: [suggestion],
            onAdd: (_) {},
            onReview: (value) => reviewed = value,
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Angebote und Varianten prüfen'));
    expect(reviewed, suggestion);
  });
}
