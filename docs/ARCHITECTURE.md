# SparzamApp – Architektur

## Grundprinzip
SparzamApp bleibt konsequent modular. Dateien sollen klein, verständlich und klar verantwortlich sein. Keine unnötigen Mega-Dateien, keine doppelte Geschäftslogik und keine künstliche Fragmentierung.

## Technologie
- Flutter / Dart
- Lokale Speicherung derzeit über shared_preferences
- Externe Quellen u. a. Open Food Facts, Open Prices, OpenStreetMap/Nominatim und OSRM
- GitHub Actions für Analyse, Tests und Web-Build

## Verantwortlichkeiten
- lib/features/: UI und anwendungsnahe Feature-Logik
- lib/models/: Datenmodelle
- lib/services/: Speicherung und externe Datenquellen
- Tests passend zu den jeweiligen Modulen

## Datenmodell – Zielrichtung
Produktidentität und Preisbeobachtung sollen getrennt gedacht werden.

Produkt:
- stabile Identität
- EAN, falls vorhanden
- Marke
- Produktname
- Variante
- Packungsgröße / Einheit
- Kategorie
- bekannte Händlerbezeichnungen/Aliase

Preisbeobachtung:
- Produktreferenz
- Markt
- Preis
- Einheit/Grundpreis
- Zeitpunkt
- Quelle
- Angebotsstatus
- Bestätigungs-/Vertrauensstatus

### Stand und nächste Schnittstelle (hybride Preisbasis)
- `ReceiptObservationStore` hält Bonzeilen und deren Zuordnung; `MarketPriceStore` bislang nur die aktuelle Markt-Produkt-Projektion. `PriceHistoryStore` hält einen einfachen Tagesverlauf ohne alle Beleg-/Filialdaten. Angebote bleiben gesondert, da Mengen-/Couponregeln eigene Berechnung brauchen.
- Gemeinsamer `PriceObservation`-Datensatz: append-only Historie für manuelle Preise und Open Prices mit Quelle, Produkt/Variante/Familie, Filiale/Region, Menge/Grundpreis, Rabatt/Angebotszeitraum, Zeitpunkt, Confidence und optionalem Nachweis. Bisherige Speicherformate bleiben lesbar; aktuelle Marktpreise bleiben vorerst eine schnelle Projektion für UI und Route.
- Externe Quellen werden über Adapter übersetzt. Provider sollen nur benötigte Produkte abfragen; Matching und Preisbewertung bleiben in gemeinsamen Diensten. Regalvideo bleibt entsprechend D010 zunächst reine Evaluation.
- Die Route bewertet konkurrierende bekannte Preise pro Markt anhand von Betrag und getrennter Quellen-/Altersunsicherheit. Fehlende Preisbereiche und dataGap-Priorisierung folgen in eigenen Paketen.
- Rückgabe eigener Beobachtungen an Open Prices oder Community-Dienste ist später eine separate, ausdrücklich aktivierte Aktion mit Prüfung von Beleg, personenbezogenen Daten und Lizenz.

Zuordnungswissen:
- Rohtext/Bonbezeichnung
- Händlerkontext
- mögliche Produktreferenz
- Confidence
- explizite Nutzerbestätigung
- Historie, damit falsche Zuordnungen korrigierbar bleiben

## Priorität der Preisquellen
Bestätigte reale Einkaufs-/Bonpreise sind besonders wertvoll. Externe Quellen und Schätzungen bleiben hinsichtlich Herkunft und Qualität unterscheidbar. Schätzungen dürfen nicht stillschweigend zu bestätigten Preisen werden.

## UI
Zielrichtung: modern, harmonisch, warmweiß/salbeigrün. Separate Hauptbereiche; Einkaufsliste mit schneller, alltagstauglicher Bedienung ähnlich dem Bedienprinzip moderner Einkaufslisten-Apps.

## Änderungsregel
Vor neuen Modulen prüfen, ob eine bestehende Verantwortung erweitert werden kann. Neue Geschäftslogik nicht direkt in große Widgets schreiben. Tests für Parsing, Matching und Preislogik bevorzugen.
