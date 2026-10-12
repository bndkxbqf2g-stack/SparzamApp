# Externe Datenquellen und Lizenzgrenzen

Stand: 2026-10-12

SparzamApp verwendet externe Quellen nur über kleine, austauschbare Adapter.
Antworten werden lokal zwischengespeichert, können über den jeweiligen
Adapter deaktiviert werden und werden vor der Routenplanung erneut auf
Identität, Filiale, Aktualität und Vergleichbarkeit geprüft. Es werden keine
privaten Belege, Konten oder Zugangsdaten an diese Quellen übertragen.

## Tatsächlich integrierte Adapter

### Open Food Facts

- Recherche: [openfoodfacts/openfoodfacts-dart](https://github.com/openfoodfacts/openfoodfacts-dart)
  (Apache-2.0) und die dokumentierte [Open Food Facts API](https://world.openfoodfacts.org/data).
- SparzamApp verwendet weiterhin eine eigene schlanke HTTP-Abstraktion:
  `ProductDataSource` → `OpenFoodFactsProductSource`.
- Der Adapter liest nur EAN-gebundene Produktstammdaten (Name, Marke,
  Kategorie, Packungsgröße und Bildreferenz). Er bestätigt keine Variante und
  liefert keinen Preis.
- EAN-Antworten werden lokal als Produktmetadaten gecacht. Ein Offline-Treffer
  bleibt eine Stammdatenhilfe; die zentrale Preis- und Identitätsprüfung bleibt
  unverändert.
- Der User-Agent identifiziert SparzamApp. Upload-, Login- und
  Änderungsfunktionen des Fremdprojekts werden nicht verwendet.
- Es wurde kein Quelltext aus dem Dart-Repository kopiert und keine
  Fremdbibliothek hinzugefügt.

### Open Prices

- Recherche: [openfoodfacts/open-prices](https://github.com/openfoodfacts/open-prices),
  [API-Dokumentation](https://github.com/openfoodfacts/open-prices/blob/main/API.md)
  und das dokumentierte [Datenmodell](https://openfoodfacts.github.io/open-prices/topics/core/).
- SparzamApp verwendet den eigenen Adapter
  `PriceSource` → `OpenPricesSource` (Kompatibilitätsname:
  `OpenPricesService`).
- EAN, EUR, Normalpreis, Datum, Produkt-Typ, Duplikatstatus und
  `UNIT`-Basis werden geprüft. Ein konfigurierter Open-Prices-Standort bzw.
  dessen ID bleibt am `MarketPrice` und an der `PriceObservation` erhalten.
- Ein lokaler Rohantwort-Cache dient nur dem Offline-Fallback. Solche Daten
  können als veraltet sichtbar bleiben, qualifizieren sich aber über die
  zentrale Altersprüfung nicht als aktueller Routenpreis.
- Die Quelle ist über `enabled` abschaltbar. Fehlende oder unbekannte Daten
  werden nicht zu 0 €.
- Die Open-Prices-Software steht unter AGPL-3.0; die öffentlichen Daten
  unterliegen den von Open Prices dokumentierten ODbL-Bedingungen. SparzamApp
  kopiert keine Serverlogik und lädt keine Datenbestände in das Repository.
  Eine spätere Rückgabe eigener Belege bleibt eine getrennte, ausdrücklich
  freizugebende Funktion.

### OSRM / OpenStreetMap

- Recherche: [Project-OSRM/osrm-backend](https://github.com/Project-OSRM/osrm-backend)
  (BSD-2-Clause) und die [Table-API](https://project-osrm.org/docs/v5.24.0/api/#table-service).
- Der bestehende `RoadDistanceService` bleibt die fachliche
  Distanz-/Fahrtkosten-Schnittstelle; die Routenoptimierung bleibt in
  `RouteOptimizer`.
- Die aktuelle App nutzt die öffentliche OSRM-Demo nur best effort. Die
  Providergrenze bleibt HTTP-Client-injizierbar und liefert bei Timeout,
  Fehler oder deaktivierter Quelle `null`; gespeicherte Matrix- und
  Distanzwerte bleiben der Offline-Fallback. Ein eigener OSRM-Host kann ohne
  Änderung der Optimierungslogik eingesetzt werden.
- OSRM-Code wird nicht kopiert. Für OpenStreetMap-Daten gelten deren
  Quellen-/ODbL-Hinweise; die Anwendung speichert nur die für die lokale
  Route nötigen Distanzwerte.

## Bewusst nur analysiert

- **OR-Tools** ([google/or-tools](https://github.com/google/or-tools),
  Apache-2.0): geeignete Vergleichsbasis für VRP/Constraint-Modelle, aber
  keine Flutter-Laufzeitabhängigkeit. Der vorhandene deterministische
  `RouteOptimizer` bleibt fachliche Quelle.
- **VROOM** ([VROOM-Project/vroom](https://github.com/VROOM-Project/vroom),
  BSD-2-Clause): möglicher Backend-/Performancevergleich mit eigener
  Kostenmatrix; keine Kopplung und kein kopierter Code.
- **EvickaStudio/lidl-discounts** und
  **EvickaStudio/kaufland-discounts** (jeweils als Apache-2.0 ausgewiesen):
  nützliche Recherche für read-only Filial-/Angebotsfelder, aber inoffizielle
  und formatinstabile App-Endpunkte. SparzamApp übernimmt weder Endpunkte noch
  Login-, Loyalty-, Coupon- oder Zahlungsfunktionen. Die bestehende
  validierte Prospektquelle bleibt führend.
- **mreimbold/kaufda-cli**: nur Recherche; keine belastbare, dauerhafte
  öffentliche Händler-API für die App.
- **knipknap/receiptparser** und
  **ReceiptManager/receipt-parser-legacy**: Parser-/Fixture-Ideen wurden
  geprüft. ReceiptManager weist Apache-2.0 aus; der Code wird nicht
  übernommen. Der vorhandene deutsche Bon-/OCR-Review bleibt die
  kontrollierte Implementierung.
- **PaddleOCR**: für eine spätere Offline-OCR-Evaluation geeignet, aber für
  Flutter/Android-Größe und Datenschutz derzeit nicht notwendig.
- **zsz13/storesplit-backend**: ausschließlich Architekturlektüre. Wegen der
  Evaluation Licence wird kein Code, keine Datenbankstruktur und kein
  Datensatz übernommen.

## Noch offene technische Grenzen

- Open Food Facts und Open Prices liefern keine vollständige lokale
  Händlerverfügbarkeit. Fehlende Filialpreise bleiben unbekannt.
- OSRM-Demo, Nominatim und inoffizielle Händlerendpunkte haben keine
  dauerhafte Verfügbarkeits- oder Antwortformatgarantie; lokale Cache- und
  manuelle Werte verhindern daraus keine falschen Preise.
- Für eine langfristige Produktion ist ein selbst betriebener bzw. vertraglich
  gesicherter Routing-/Datenprovider zu konfigurieren. Das ist eine
  Betriebsentscheidung und kein Grund, den fachlichen Optimierer zu ersetzen.
