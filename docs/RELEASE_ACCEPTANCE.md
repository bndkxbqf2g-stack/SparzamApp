# Release-Abnahme SparzamApp

Diese Checkliste ergänzt die automatisierte CI. Sie wird auf mindestens einem
echten Android- oder iOS-Gerät ausgefüllt; ein Web-Build ersetzt weder den
Kamera- noch den Neustarttest.

## Testdaten und Vorbereitung

- Datum: `____________________`
- Gerät / OS: `____________________`
- App-Version / Commit: `____________________`
- Netzwerk: WLAN / Mobilfunk / offline (bitte markieren)
- Frische Installation verwendet: Ja / Nein

## Abnahmetests

| Nr. | Ablauf | Erwartung | Ergebnis / Beleg | Status |
|---:|---|---|---|---|
| 1 | Produkt ohne vorhandenen Katalogeintrag per Barcode scannen | Kamera-Berechtigung erscheint; nach Freigabe wird gesucht; bei Fehlschlag ist eine erneute Suche oder manuelle Eingabe möglich |  | ☐ |
| 2 | Gescanntes oder manuell angelegtes Produkt zur Liste hinzufügen, Menge ändern, abhaken und App neu starten | Produkt, Menge und Erledigt-Status bleiben erhalten |  | ☐ |
| 3 | Eigenen Marktpreis und ein Angebot mit Mehrfachkauf/Coupon anlegen; Route berechnen | Route zeigt nachvollziehbaren Preisvorteil und Effektivpreis; fehlende/veraltete Preise werden nicht als sicherer Preis dargestellt |  | ☐ |
| 4 | Einkauf bestätigen, bearbeiten, löschen und App jeweils neu starten | Kaufhistorie und Lebensmittelbudget bleiben konsistent; Bearbeiten/Löschen aktualisieren die Anzeige korrekt |  | ☐ |
| 5 | Während Produkt- oder Preisabruf Netzwerk deaktivieren, danach wieder aktivieren und erneut versuchen | Fehler wird verständlich angezeigt; Teilergebnisse bleiben erhalten; Wiederholung funktioniert |  | ☐ |
| 6 | Nach allen Änderungen App vollständig beenden und erneut öffnen | Einkaufsliste, eigene Produkte, Marktpreise, Angebote, Preisverlauf, Käufe und Einstellungen sind weiterhin vorhanden |  | ☐ |

## Freigabeentscheidung

- Alle sechs Tests bestanden: Ja / Nein
- Bekannte Abweichungen: `__________________________________________________`
- Entscheidung: Freigeben / Nacharbeit erforderlich
- Name / Datum: `__________________________________________________`

CI-Referenz: `flutter pub get`, `flutter analyze`, `flutter test` und
`flutter build web --release` müssen vor der Geräteabnahme erfolgreich sein.
