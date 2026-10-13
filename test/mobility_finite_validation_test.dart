import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparzamapp/features/profile/mobility_settings_screen.dart';
import 'package:sparzamapp/models/mobility_settings.dart';

void main() {
  test(
    'defekte gespeicherte Zahlen fallen auf gültige Standardwerte zurück',
    () {
      final settings = MobilitySettings.fromJson({
        'euroPerKm': double.nan,
        'timeValuePerHour': double.infinity,
        'minExtraStoreSavings': double.infinity,
        'additionalStoreCost': double.infinity,
      });
      expect(settings.euroPerKm, 0.22);
      expect(settings.timeValuePerHour, 0);
      expect(settings.minExtraStoreSavings, 0.50);
      expect(settings.additionalStoreCost, 0);
    },
  );

  testWidgets('nicht endlicher Kraftstoffverbrauch kann nicht gespeichert werden', (
    tester,
  ) async {
    MobilitySettings? saved;
    await tester.pumpWidget(
      MaterialApp(
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
      ),
    );
    await tester.tap(find.text('Öffnen'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Verbrauch'),
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
    expect(
      find.text('Bitte einen Verbrauch zwischen 0 und 30 l eingeben'),
      findsOneWidget,
    );
  });

  testWidgets(
    'persönlicher Zeitwert wird in den Mobilitätseinstellungen gespeichert',
    (tester) async {
      MobilitySettings? saved;
      await tester.pumpWidget(
        MaterialApp(
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
        ),
      );
      await tester.tap(find.text('Öffnen'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Zeitwert für Wegezeit (optional)'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      final timeValue = find.byKey(const ValueKey('mobility-time-value'));
      expect(timeValue, findsOneWidget);
      await tester.enterText(timeValue, '12,50');
      await tester.scrollUntilVisible(
        find.text('Speichern'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();

      expect(saved?.timeValuePerHour, 12.50);
    },
  );
}

