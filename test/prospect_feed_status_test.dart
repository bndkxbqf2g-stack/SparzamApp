import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/prospects/prospect_feed_status.dart';

void main() {
  test('formats the feed timestamp for users', () {
    expect(
      formatProspectFeedTimestamp(DateTime(2026, 10, 1, 12, 2)),
      '01.10.2026 · 12:02 Uhr',
    );
    expect(formatProspectFeedTimestamp(null), 'Zeitpunkt unbekannt');
  });

  testWidgets('shows current and cached provenance distinctly', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            ProspectFeedStatusCard(generatedAt: DateTime(2026, 10, 1, 12, 2)),
            ProspectFeedStatusCard(fromCache: true),
          ],
        ),
      ),
    );

    expect(find.text('Aktueller Prospektstand'), findsOneWidget);
    expect(find.text('Letzter geprüfter Prospektstand'), findsOneWidget);
    expect(find.textContaining('01.10.2026 · 12:02 Uhr'), findsOneWidget);
    expect(
      find.textContaining('abgelaufene Angebote bleiben ausgeblendet'),
      findsOneWidget,
    );
  });
}
