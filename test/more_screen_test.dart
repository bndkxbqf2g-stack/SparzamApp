import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/shell/more_screen.dart';

void main() {
  testWidgets('route, receipt and profile remain reachable', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: MoreScreen(
          routePage: Text('Routeninhalt'),
          receiptPage: Text('Boninhalt'),
          profilePage: Text('Profilinhalt'),
        ),
      ),
    ));

    for (final (label, destination) in [
      ('Einkaufsroute', 'Routeninhalt'),
      ('Bons und Einkäufe', 'Boninhalt'),
      ('Profil und Einstellungen', 'Profilinhalt'),
    ]) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(find.text(destination), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
    }
  });
}
