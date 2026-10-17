# Web-Abnahme Prospekt-, Preise- und Routen-Reiter (2026-10-17)

Diese Abnahme dokumentiert den sichtbaren Web-Stand von `main` am Commit
`241d0f5db739abe2d36a0037a3ce74d4b552ffff` unter
`https://bndkxbqf2g-stack.github.io/SparzamApp/?v=4401a8ea`.

## GETESTET

- **Prospekte:** Die aktuelle Übersicht zeigt sechs Märkte mit exakter Filiale:
  ALDI Süd (75 Angebote, 36/36 Seiten), EDEKA (17, 40/40), Kaufland (342,
  74/74), Lidl (48, 73/73), PENNY (201, Coverstand) und Netto (4, 70/70).
  Die Abdeckung weist 687/687 Artikelbilder, 591/687 Kategorien, sechs
  Gültigkeitszeiträume und vier ausdrücklich belegte beziehungsweise gespeicherte
  Normalpreisstände aus.
- **Cover und Seitenviewer:** Die Lidl-Karte öffnet den Viewer mit Ort, Adresse,
  Gültigkeit und Seitenzahl. Die Cover-/Seitenliste lässt sich bis zu späteren
  Seiten scrollen; der Seitenviewer zeigt die Aktion für „Artikel von
  Prospektseite hinzufügen“ mit Produktname, Angebotspreis, optionalem
  Normalpreis und „Gültig bis“. Der Dialog wurde geöffnet und ohne Speicherung
  geschlossen, damit keine Testzeile in lokale Nutzerdaten gelangt.
- **Preise:** Der Preise-Reiter weist 483 automatisch gespeicherte reguläre
  Prospekt-Normalpreise aus. Aktionspreise werden separat als Angebotsevidenz
  beschrieben. Der aktuelle lokale Belegstand zeigt 194/194 aktuelle,
  routenfähige Belege.
- **Route:** Für zwei vorhandene Listenpositionen werden 100 % Preisabdeckung,
  ein Markt (Lidl Zellingen), 5,57 € Warenwert, 0,20 € Fahrtkosten und 5,77 €
  erwartete Gesamtkosten angezeigt. Filiale, 2,4 km Fallback-Distanz und
  geschätzte 3 Minuten Wegezeit bleiben sichtbar.
- **Scrollstabilität:** Mehrere schnelle Scrolls in Cover-/Seitenviewer,
  Angebote und Route zeigten keinen sichtbaren App-Abbruch. Eine ältere
  Browser-Sitzung verlor danach die CDP-Accessibility-Verbindung; eine frische
  Sitzung lud den Stand und die Route korrekt. Das wird als Testumgebungsgrenze
  und nicht als bestätigter Flutter-Crash gewertet.

## OFFEN

- Diese Abnahme betrifft den Web-Stand im verbundenen Browser. Sie ersetzt keinen
  nativen iOS-/Android-Test für Kamera, Neustart, Offline-Speicher und lokale OCR.
- Der Web-Stand wurde mit vorhandenen lokalen Beispieldaten geprüft; es wurden
  keine persönlichen Belege, Logins oder externen Schreibzugriffe verwendet.
- Lokale Flutter-/Dart-Kommandos konnten auf dem Windows-Arbeitsrechner nicht
  ausgeführt werden, weil das SDK nicht installiert ist. Die produktiven
  Analyse-, Test- und Web-Build-Prüfungen bleiben die PR-CI.

Die Abnahme bestätigt die sichtbaren Prospekt-, Normalpreis- und Routenpfade,
markiert die native Geräteabnahme aber weiterhin ausdrücklich als offen.
