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
    validUntil: DateTime.now().add(const Duration(days: 7)),
  );

  Widget screen({
    required Future<List<Offer>> Function(Offer) onSave,
    required Future<List<Offer>> Function(Offer) onDelete,
  }) => MaterialApp(
        home: OffersScreen(
          offers: [offer],
          priceHistory: const [],
          catalogProducts: const [product],
          onSave: onSave,
          onDelete: onDelete,
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
