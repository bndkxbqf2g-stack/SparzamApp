import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sparzamapp/features/offers/offers_screen.dart';
import 'package:sparzamapp/models/product.dart';
import 'package:sparzamapp/services/prospect_feed_service.dart';

void main() {
  testWidgets('zeigt Coverkarten im Angebote-Reiter und öffnet die Seitenansicht', (
    tester,
  ) async {
    final issue = ProspectIssue(
      storeName: 'Lidl',
      title: 'Aktionsprospekt',
      pages: const [
        ProspectPage(
          number: 1,
          imageUrl: 'https://example.test/lidl-cover.jpg',
        ),
      ],
      thumbnailUrl: 'https://example.test/lidl-cover.jpg',
      location: 'Thüngersheim',
      sourceStatus: 'ok',
      recordCount: 12,
      validFrom: DateTime(2026, 10, 12),
      validUntil: DateTime(2026, 10, 17),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: OffersScreen(
          catalogProducts: const <Product>[],
          prospectIssues: [issue],
          now: DateTime(2026, 10, 13),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Deine Favoriten'), findsOneWidget);
    expect(find.text('Weitere Prospekte'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('offer-cover-open-favorite-Lidl')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('offer-cover-open-favorite-Lidl')));
    await tester.pump();

    expect(find.text('Prospektseiten (1)'), findsOneWidget);
    expect(find.text('Aktionsprospekt'), findsOneWidget);
  });
}
