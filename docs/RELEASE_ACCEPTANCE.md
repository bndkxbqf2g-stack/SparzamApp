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
| 2 | Gescanntes oder manuell angelegtes Produkt zur Liste hinzufügen, Menge ändern, Notiz ergänzen, abhaken und App neu starten | Produkt, Menge, Notiz und Erledigt-Status bleiben erhalten |  | ☐ |
| 3 | Zweite Liste erstellen und wechseln; Kachelansicht aktivieren; Warengruppen umsortieren; App neu starten | Listeninhalte bleiben getrennt; Ansicht und Gruppenreihenfolge bleiben erhalten |  | ☐ |
| 4 | Eigenen Marktpreis und ein Angebot mit Mehrfachkauf/Coupon anlegen; Route berechnen | Route zeigt nachvollziehbaren Preisvorteil und Effektivpreis; fehlende/veraltete oder geschätzte Preise werden nicht als bestätigte Preise dargestellt |  | ☐ |
| 5 | TXT/CSV-Bon importieren und zusätzlich einen Bild- oder PDF-Bon auswählen; geprüfte Artikelzeilen speichern | TXT/CSV wird eingelesen; Bild/PDF bleibt als ausgewählte Referenz sichtbar; bestätigte Bonpreise erscheinen beim richtigen Markt und haben Vorrang |  | ☐ |
| 6 | Einkauf bestätigen, bearbeiten, löschen und App jeweils neu starten | Kaufhistorie und Lebensmittelbudget bleiben konsistent; Bearbeiten/Löschen aktualisieren die Anzeige korrekt |  | ☐ |
| 7 | Während Produkt- oder Preisabruf Netzwerk deaktivieren, danach wieder aktivieren und erneut versuchen | Fehler wird verständlich angezeigt; Teilergebnisse bleiben erhalten; Wiederholung funktioniert |  | ☐ |
| 8 | Einen Testfehler im Diagnoseprotokoll erfassen und Log kopieren; anschließend App vollständig beenden und erneut öffnen | Log ist kopierbar; Einkaufslisten, eigene Produkte, Marktpreise, Angebote, Preisverlauf, Käufe und Einstellungen sind weiterhin vorhanden |  | ☐ |

## Freigabeentscheidung

- Alle acht Tests bestanden: Ja / Nein
- Bekannte Abweichungen: `__________________________________________________`
- Entscheidung: Freigeben / Nacharbeit erforderlich
- Name / Datum: `__________________________________________________`

CI-Referenz: `flutter pub get`, `flutter analyze`, `flutter test` und
`flutter build web --release` müssen vor der Geräteabnahme erfolgreich sein.
