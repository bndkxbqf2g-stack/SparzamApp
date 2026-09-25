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

- Die Planungsprojektion liest nun zusätzlich die append-only `PriceObservation`-Historie. Nur exakte Produktidentitäten mit voller Identitäts-Confidence aus den bereits unterstützten Quellen manuell/Bon/Open Prices werden in den bestehenden `MarketPrice`-Vertrag zurückprojiziert; Familien- und unsichere Beobachtungen bleiben außerhalb der exakten Route.

- Bon- und Angebotsdaten besitzen nun Adapter in das gemeinsame `PriceObservation`-Modell. Die ursprünglichen Stores bleiben vorerst bestehen; die Beobachtungshistorie ist die gemeinsame Evidenzschicht. Bon-Familienzuordnungen werden nicht künstlich zu exakten Produktidentitäten. Angebote tragen ein Gültigkeitsende und werden nach Ablauf nicht in die exakte Routenprojektion übernommen.
- Nächste Architekturschnittstelle: Vergleichbarkeit muss vor Preisranking geprüft werden. Packungsgröße, Einheit und Variante sind Teil der fachlichen Identität; ein niedriger absoluter Preis darf nur bei gleicher bzw. sicher normalisierbarer Mengenbasis konkurrieren.


## Entwicklungsprozess
Technische Wahrheit bleibt GitHub. Kleine Änderungen werden inkrementell umgesetzt. Größere Querschnittsarbeiten werden in der `WORK QUEUE` der Roadmap gesammelt, damit Work sie später mit vollständigem Repo-Kontext selbstständig ausführen kann. Dadurch soll dieselbe Analyse nicht mehrfach bezahlt bzw. durchgeführt werden.

## Preisvergleichbarkeit und externe Discovery – Stand 24.09.2026
- `quantity_normalizer.dart` bildet g/kg, ml/l und Stück auf gemeinsame Basiseinheiten ab. Vergleichbarkeit wird vor Preisranking geprüft.
- `product_family.dart` trennt breite Familie, generischen Familienwunsch und konkrete Variante. Familienfallback ist damit nicht automatisch Variantenidentität.
- Bon-Familienpreise dürfen nur mit sicher normalisierbarer Mengenbasis in die Planung einfließen; sonst bleiben sie Evidenz/Hinweis.
- Die Open-Prices-Pipeline arbeitet demand-driven von der aktuellen Einkaufsliste. Bekannte EANs können direkt abgefragt werden.
- `open_food_facts_product_discovery.dart` darf bei fehlender EAN konservativ einen Kandidaten zum Abruf finden. Ein Discovery-Treffer bestätigt die Produktidentität jedoch nicht und darf deshalb noch keinen exakten Routenpreis erzeugen.
- Automatische Bon-Reviews und externe Discovery folgen damit derselben Grenze: Erkennung/Recherche ist Evidenz, explizit bestätigte Identität ist Voraussetzung für exakte Preisprojektion.
