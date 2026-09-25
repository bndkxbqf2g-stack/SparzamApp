import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/profile/mobility_settings_screen.dart';
import 'package:sparzamapp/models/mobility_settings.dart';

void main() {
  test('defekte gespeicherte Zahlen fallen auf gültige Standardwerte zurück', () {
    final settings = MobilitySettings.fromJson({
      'euroPerKm': double.nan,
      'minExtraStoreSavings': double.infinity,
    });
    expect(settings.euroPerKm, 0.22);
    expect(settings.minExtraStoreSavings, 0.50);
  });

  testWidgets('nicht endliche Fahrtkosten können nicht gespeichert werden',
      (tester) async {
    MobilitySettings? saved;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async {
              saved = await Navigator.of(context).push<MobilitySettings>(
                MaterialPageRoute(
                  builder: (_) => const MobilitySettingsScreen(
                    initialSettings: MobilitySettings(),
                  ),
                ),
              );
            },
            child: const Text('Öffnen'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Öffnen'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Fahrtkosten pro km'),
      'NaN',
    );
    await tester.scrollUntilVisible(
      find.text('Speichern'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Speichern'));
    await tester.pump();

    expect(saved, isNull);
    expect(find.text('Bitte gültigen Wert zwischen 0 und 5 € eingeben'),
        findsOneWidget);
  });
}
