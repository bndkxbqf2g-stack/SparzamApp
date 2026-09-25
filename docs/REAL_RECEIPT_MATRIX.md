# Reale Bon-Testmatrix

Stand: 2026-09-25

## Zweck
Diese Matrix enthält ausschließlich Boninformationen, die im Repository eindeutig durch vorhandene Test-Fixtures oder dokumentierte Originaldaten belegt sind. Fehlende Originalbelege werden nicht durch angenommene Produkte, Märkte oder Preise ergänzt.

## Aktuell belegte Matrix

| Bon | Markt / Datum | Belegte Position | Betrag | Besonderheit | Pipeline-Test |
| --- | --- | --- | ---: | --- | --- |
| 1 | Kaufland · 23.07.2026 | K.Frischer Schmand | 0,79 € | nachfolgender K-Card-Artikelrabatt; Produktzeilenpreis bleibt historische Evidenz | `test/real_receipt_evidence_e2e_test.dart` |

Der End-to-End-Test verfolgt den belegten Schmand-Fall durch:
`ReceiptObservation → PriceObservation → MarketPrice → planningMarketPrices → RoutePriceResolver → RouteOptimizer`.

Er prüft außerdem die 30-Tage-Grenze: derselbe historische Bon bleibt als Evidenz erhalten, darf nach Ablauf des Routenfensters aber nicht mehr als exakter aktueller Routenpreis projiziert werden.

## Fehlende Originalbelege

Für Bon 2 bis Bon 7 ist im aktuellen Repository kein vollständiger Originalbeleg bzw. keine eindeutig rekonstruierbare vollständige Fixture vorhanden, aus der eine belastbare Produkt×Markt-Matrix ohne Annahmen aufgebaut werden könnte.

Daher gilt bis zur Bereitstellung der Originaldaten:
- keine fehlenden Produkte ergänzen,
- keine Preise schätzen,
- keine Märkte oder Daten aus Beispielen als reale Bonwerte übernehmen,
- vorhandene synthetische Regressionstests nicht als Originalbon deklarieren.

Sobald die sechs fehlenden Originalbelege verfügbar sind, werden sie in dieselbe Matrix aufgenommen und jeweils bis zur Preis- und Routenlogik abgesichert.
