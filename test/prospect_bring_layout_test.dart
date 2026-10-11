import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/prospects/prospects_screen.dart';
import 'package:sparzamapp/services/prospect_feed_service.dart';

void main() {
  testWidgets('renders the bring-style prospect overview from source data', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProspectsScreen(
            records: const [],
            prospects: [
              ProspectIssue(
                storeName: 'Lidl',
                title: 'Aktionsprospekt',
                pages: [
                  ProspectPage(
                    number: 1,
                    imageUrl: 'https://example.test/lidl-page.png',
                  ),
                ],
                location: 'Zellingen',
                address: 'Würzburger Str. 74, 97225 Zellingen',
                validFrom: DateTime(2026, 10, 12),
                validUntil: DateTime(2026, 10, 17),
              ),
              ProspectIssue(
                storeName: 'Netto',
                title: 'Aktionsprospekt',
                pages: [
                  ProspectPage(
                    number: 1,
                    imageUrl: 'https://example.test/netto-page.png',
                  ),
                ],
                validFrom: DateTime(2026, 10, 12),
                validUntil: DateTime(2026, 10, 18),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Angebote'), findsOneWidget);
    expect(find.text('Deine Favoriten'), findsOneWidget);
    await tester.drag(
      find.byKey(const ValueKey('prospect-bring-scroll')),
      const Offset(0, -480),
    );
    await tester.pumpAndSettle();
    expect(find.text('Weitere Prospekte'), findsOneWidget);
    expect(find.text('Alle Prospekte'), findsOneWidget);
    expect(find.byKey(const ValueKey('prospect-grid')), findsOneWidget);
    expect(find.byKey(const ValueKey('prospect-location-pill')), findsOneWidget);
    expect(find.text('97225'), findsOneWidget);
  });

  testWidgets('does not invent a location pill without a source postal code', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProspectsScreen(
            records: const [],
            prospects: const [
              ProspectIssue(
                storeName: 'Lidl',
                title: 'Aktionsprospekt',
                pages: [],
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Angebote'), findsOneWidget);
    expect(find.byKey(const ValueKey('prospect-location-pill')), findsNothing);
  });
}
