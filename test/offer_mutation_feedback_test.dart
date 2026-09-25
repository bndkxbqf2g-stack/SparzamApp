import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/offers/offers_screen.dart';
import 'package:sparzamapp/models/offer.dart';
import 'package:sparzamapp/models/product.dart';

void main() {
  const product = Product(
    id: 'milk',
    name: 'Milch',
    unit: 'Artikel',
    group: 'Milch',
  );
  final offer = Offer(
    id: 'test',
    productId: product.id,
    storeName: 'Lidl',
    originalPrice: 2,
    offerPrice: 1,
    validFrom: DateTime(2026, 9, 21),
    validUntil: DateTime(2026, 9, 27),
    source: 'leaflet',
    proofRef: 'prospekt-kw39',
  );

  Widget screen({
    required Future<List<Offer>> Function(Offer) onSave,
    required Future<List<Offer>> Function(Offer) onDelete,
    ValueChanged<Product>? onAddToShoppingList,
  }) => MaterialApp(
        home: OffersScreen(
          offers: [offer],
          priceHistory: const [],
          catalogProducts: const [product],
          onSave: onSave,
          onDelete: onDelete,
          onAddToShoppingList: onAddToShoppingList,
        ),
      );

  Future<void> choose(WidgetTester tester, String action) async {
    await tester.scrollUntilVisible(
      find.byTooltip('Angebotsoptionen'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byTooltip('Angebotsoptionen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(action).last);
    await tester.pumpAndSettle();
  }

  testWidgets('Angebot zeigt Quelle, Beleg und Gültigkeitszeitraum', (tester) async {
    await tester.pumpWidget(screen(
      onSave: (_) async => [offer],
      onDelete: (_) async => [],
    ));

    expect(find.text('Quelle: Prospekt'), findsOneWidget);
    expect(find.text('Gültig 21.09.2026–27.09.2026'), findsOneWidget);
    expect(find.text('Beleg: prospekt-kw39'), findsOneWidget);
  });

  testWidgets('Angebot kann kanonischen Artikel zur Einkaufsliste hinzufügen', (tester) async {
    Product? added;
    await tester.pumpWidget(screen(
      onSave: (_) async => [offer],
      onDelete: (_) async => [],
      onAddToShoppingList: (product) => added = product,
    ));

    await tester.ensureVisible(find.text('Zur Einkaufsliste'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(FilledButton, 'Zur Einkaufsliste'),
    );
    await tester.pump();

    expect(added?.id, product.id);
  });

  testWidgets('fehlgeschlagenes Löschen erhält das Angebot', (tester) async {
    final pending = Completer<List<Offer>>();
    var calls = 0;
    await tester.pumpWidget(screen(
      onSave: (_) async => [offer],
      onDelete: (_) {
        calls++;
        return pending.future;
      },
    ));
    await choose(tester, 'Löschen');
    await tester.tap(find.text('Löschen').last);
    await tester.pump();
    expect(calls, 1);
    expect(find.byTooltip('Angebotsoptionen'), findsNothing);

    pending.completeError(StateError('storage failed'));
    await tester.pump();
    expect(find.text('Angebot konnte nicht gelöscht werden.'), findsOneWidget);
    expect(find.text('Milch'), findsOneWidget);
    expect(find.byTooltip('Angebotsoptionen'), findsOneWidget);
  });

  testWidgets('fehlgeschlagenes Speichern meldet Fehler', (tester) async {
    await tester.pumpWidget(screen(
      onSave: (_) async => throw StateError('storage failed'),
      onDelete: (_) async => [],
    ));
    await choose(tester, 'Bearbeiten');
    await tester.scrollUntilVisible(
      find.text('Angebot speichern'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Angebot speichern'));
    await tester.pumpAndSettle();
    expect(find.text('Angebot konnte nicht gespeichert werden.'), findsOneWidget);
    expect(find.text('Milch'), findsOneWidget);
  });
}
