# Externe Datenquellen und Lizenzgrenzen

Stand: 2026-10-19

SparzamApp verwendet externe Quellen nur über kleine, austauschbare Adapter.
Antworten werden lokal zwischengespeichert, können über den jeweiligen
Adapter deaktiviert werden und werden vor der Routenplanung erneut auf
Identität, Filiale, Aktualität und Vergleichbarkeit geprüft. Es werden keine
privaten Belege, Konten oder Zugangsdaten an diese Quellen übertragen.
HTTP-403-Antworten werden als Quellenfehler behandelt und nicht mit einem
anderen User-Agent wiederholt.

Der zuletzt geprüfte öffentliche Prospektfeed liegt zusätzlich als
versioniertes App-Asset vor. Er ist ausschließlich ein datierter Offline-/Kalt-
Fallback; seine Angebote werden vor Anzeige und Planung weiterhin auf den
Gültigkeitszeitraum geprüft und niemals als frischer Live-Abruf ausgegeben.
Der Refresh-Workflow bewahrt bei einem vollständigen Quellfehler außerdem den
ursprünglichen `generatedAt`-Zeitpunkt. Ein fehlgeschlagener Abruf verjüngt
übernommene, noch gültige Vorperiodendaten damit nicht künstlich.
Händlerfeeds werden vor der Speicherung außerdem auf den Sparzam-Lebensmittel-
vertrag begrenzt; Haushalts-, Körperpflege-, Kleidungs-, Pflanzen- und
Spielzeugkampagnen bleiben als Rohquellen nicht routenfähig. Der App-Parser
wiederholt diese Sperre für ältere Cache-/Asset-Stände.

## Tatsächlich integrierte Adapter

### REWE-Filialfeed Veitshöchheim

- Die optionale REWE-Quelle ist als eigener, abschaltbarer Adapter in
  tool/refresh_prospects.py registriert. Produktiv wird ausschließlich die
  offizielle Angebotsseite der exakten Filiale 461683 gelesen. Der vorhandene
  strukturierte API-Parser bleibt auf anonymisierte Offline-Fixtures begrenzt;
  der nicht dokumentierte Endpunkt wird nicht produktiv verwendet.
- Übernommen werden nur Artikel mit Preis und einem expliziten
  Gültigkeitsfenster. Produktname, EAN, Packungsgröße, Grundpreis und Bild
  bleiben unbekannt, wenn die offizielle Seite sie nicht ausdrücklich liefert.
  Ein fehlender Normalpreis verhindert den Angebotsimport nicht.
- Die Zieladresse ist Pont-l'Eveque-Allee 1, 97209 Veitshöchheim. Jede Zeile
  und der Quellenknoten erhalten Branch-ID, Ort, Adresse, Nachweis und
  Erfassungszeitpunkt. Alte oder nicht aktuelle Datensätze werden durch dieselben
  Gültigkeits- und Lebensmittelprüfungen wie bei den übrigen offiziellen
  Quellen ausgeschlossen.
- Ein begrenzter read-only Abruf am 19.10.2026 erhielt von der REWE-Seite nur
  eine WAF-/Cloudflare-Challenge. Es wurde kein Zugriffsschutz umgangen und es
  werden keine Challenge-Parameter wiederholt. Der versionierte Feed enthält
  deshalb bis zu einer zulässigen Seitenantwort nur einen transparenten
  Quellenfehler ohne REWE-Preise. Ein Quellfehler lässt die übrigen Händler
  weiterlaufen.
- Die offizielle Marktseite ist der Nachweis für den Filialbezug:
  https://www.rewe.de/angebote/veitshoechheim/461683/rewe-markt-pont-leveque-allee-1.

### Netto-Filialprospekt

- Der bestehende offizielle Netto-Adapter liest zusätzlich den öffentlichen
  Wochenprospekt-Link der exakt konfigurierten Filiale und dessen
  `Filial-Angebote`-Cover.
- Das Cover wird als eine nachweisbare Prospektseite mit URL, Bildreferenz,
  Gültigkeitszeitraum und Filialkontext gespeichert. Der HTML-Parser und der
  begrenzte Jina-Reader-Fallback akzeptieren nur dieses konkrete Merkmal; Shop-
  und allgemeine Kampagnenbilder werden nicht als Prospekt übernommen.
- Der versionierte Offline-Stand enthält eine am 12.10.2026 verifizierte
  Coverreferenz für die Filiale 4371; der reguläre Refresh ersetzt sie bei
  erfolgreicher Händlerantwort. Eine nicht belegte Coverseite bleibt sichtbar
  unbekannt.

### ALDI-Süd-Prospekt

- Der strukturierte ALDI-Refresh liest den aktuellen öffentlichen
  Prospektlink und die zugehörige Coverreferenz aus der offiziellen
  ALDI-Süd-Startseite; die Kalenderwoche wird in den deutschen Zeitraum
  Montag bis Samstag aufgelöst.
- Es wird nur die verifizierte Seite 1 als `thumbnailUrl` und
  `pageSamples[0]` übernommen. Der eigentliche Preisimport bleibt an die
  strukturierte, filialbezogene Produktquelle gebunden.
- Der versionierte Offline-Stand enthält die am 12.10.2026 verifizierte
  Coverreferenz für B384 in Zellingen. Die externe Bild-URL wird nicht in das
  Repository kopiert; bei einer Seitenänderung bleibt der Preisimport
  unabhängig nutzbar.

### PENNY-Prospekt

- Der strukturierte PENNY-Adapter liest den aktuellen Handout-Bereich der
  offiziellen Angebotsseite und akzeptiert nur den Wrapper
  `handout-current-week` mit ausgewiesenem Zeitraum und CMS-Bild.
- Das aktuelle Cover wird als `thumbnailUrl` und `pageSamples[0]` für den
  konfigurierten Markt 230061 gespeichert; Kategorieangebote und Cover bleiben
  getrennte Datenpfade.
- Der versionierte Offline-Stand enthält die am 12.10.2026 verifizierte
  Coverreferenz für Zellingen. Die externe Bilddatei wird nicht kopiert und
  ein fehlender Handout-Abruf lässt den Preisimport weiterlaufen.

### EDEKA-Filialprospekt

- Der EDEKA-Adapter liest aus der Marktseite 023738 nur den branchenspezifischen
  Prospektlink, den ausgewiesenen Zeitraum und die öffentliche
  Blätterkatalog-Seite `bk_1.jpg`.
- Die Coverreferenz wird als `thumbnailUrl` und `pageSamples[0]` gespeichert;
  Bilder aus dem allgemeinen Seitenaufbau oder andere Märkte werden nicht
  übernommen.
- Der versionierte Offline-Stand enthält die am 12.10.2026 verifizierte
  Titelseite für Zellingen. Bei geändertem Markup bleibt der API-Preisimport
  unabhängig nutzbar.

### Kaufland-Filialprospekt

- Der strukturierte Kaufland-Adapter liest für die Filiale DE5103 die aktuelle
  öffentliche Leaflet-Verknüpfung und deren Laufzeit.
- Aus dem öffentlichen Viewer wird ausschließlich die nachweisbare Coverseite
  als `thumbnailUrl` und `pageSamples[0]` übernommen. Viewerfehler lassen den
  bereits validierten Angebotsimport weiterlaufen.
- Der versionierte Offline-Stand enthält die am 12.10.2026 verifizierte Seite
  1 für Würzburg-Grombühl. Die Bildreferenz bleibt eine externe Quelle und
  wird nicht in das Repository kopiert.

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
- Bei einem bekannten Katalogprodukt werden Packungsmenge/-einheit und der
  daraus berechnete Grundpreis ebenfalls am Preisbeleg erhalten. So kann eine
  abweichende oder unbekannte Packung an der gemeinsamen Vergleichbarkeits-
  grenze als Datenlücke behandelt werden.
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

### OfferSource-Vertrag für Händlerangebote

- `OfferObservation` hält Markt, exakte Filiale, Produktfamilie, Variante,
  Packungsgröße, Normal-/Angebotspreis, Einheitspreis, Gültigkeit, Quelle und
  Erfassungszeit getrennt und nullable. Fehlende Preise oder Zeiträume bleiben
  unbekannt.
- `OfferSource` mit `LidlOfferSource` und `KauflandOfferSource` ist
  vorhanden, aber standardmäßig deaktiviert. Die beiden Klassen erzeugen
  keine Netzwerkabfrage; eine nicht konfigurierte Quelle liefert explizit
  `available=false`.
- Die untersuchten inoffiziellen GitHub-Wrapper bleiben damit Vorlage und
  werden nicht als Händler-API verwendet. Der validierte interne Prospektfeed
  bleibt die führende Angebotsquelle.

### OSRM / OpenStreetMap

- Recherche: [Project-OSRM/osrm-backend](https://github.com/Project-OSRM/osrm-backend)
  (BSD-2-Clause) und die [Table-API](https://project-osrm.org/docs/v5.24.0/api/#table-service).
- `TravelMatrixProvider` → `RoadDistanceService` liefert getrennt
  Entfernungen und Matrizen; `RouteOptimizer` bleibt die fachliche
  Optimierungsquelle.
- OSRM-/Nominatim-Basis-URLs, HTTP-Client, Timeouts und die Quelle selbst sind
  injizierbar bzw. über `enabled` abschaltbar. Timeout, HTTP-Fehler und
  fehlende Geocodes ergeben `null` oder einen validierten lokalen
  Matrix-Fallback, niemals einen erfundenen Preis.
- `TravelMatrixCache` nutzt die bestehende lokale
  `RoadRouteMatrixStore`-Struktur. Die App kann damit offline weiterplanen;
  ein eigener OSRM-Host kann ohne Änderung der Optimierungslogik eingesetzt
  werden.
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
- **mreimbold/kaufda-cli**: Der technische Ansatz ist als eigener, kleiner
  Parser in `tool/kaufda_prospects.py` nachvollzogen. Der Adapter liest nur
  öffentlich eingebettete `__NEXT_DATA__`-Suchdaten, begrenzt Suchbegriffe und
  Anfragen, speichert Antworten lokal zwischen und überführt aktuelle
  Lebensmittelangebote in das bestehende Prospektformat. Das aktuelle
  `parentContent.page.number`-Format, ausgewiesene reguläre Preise und
  Kategoriepfade werden berücksichtigt; UVP-Werte und explizite
  Nicht-Lebensmittel-Taxonomien werden nicht als Normalpreis bzw. Lebensmittel
  übernommen. Er ist ausschließlich ein opt-in, read-only
  Refresh-/Diagnoseadapter und läuft nicht als Flutter-Laufzeitquelle.

  Der Adapter bleibt standardmäßig deaktiviert. Für eine Aktivierung müssen
  `SPARZAM_KAUFDA_ENABLED`, eine begrenzte Suchliste und eine separat geprüfte
  Zuordnung von Händler zu exakter Filiale gesetzt werden. Treffer ohne diese
  Filialassertion bleiben `regional_only`, werden für Suche und Nachweis im
  Feed sichtbar gehalten, aber nicht routenfähig. Ablauf, Quelle,
  Prospekt-ID/-seite, Preis und Erfassungszeit bleiben am Datensatz
  nachvollziehbar; Cache- und Parserfehler isolieren die Quelle vom übrigen
  Feed. Die bestehenden autoritativen Händler-/Bring-Quellen werden weder
  ersetzt noch überschrieben.

  Der gemeinsame Refresh wählt bei konkurrierenden aktuell gültigen
  Zeiträumen zuerst einen Zeitraum mit mindestens einem offiziellen
  Händlernachweis. Ein größerer KaufDA-Trefferbestand kann dadurch keine
  offizielle Periode verdrängen; KaufDA ergänzt nur den ausgewählten Zeitraum
  oder bleibt bei fehlender offizieller Periode ein regionaler Nachweis.

  Ein kontrollierter Lauf verwendet beispielsweise ausschließlich öffentliche
  Suchseiten und eine bekannte Filiale:

  ```text
  SPARZAM_KAUFDA_ENABLED=1
  SPARZAM_KAUFDA_CITY=Wuerzburg
  SPARZAM_KAUFDA_QUERIES="Butter,Milch,Kaffee,Nudeln,Tomaten"
  SPARZAM_KAUFDA_BRANCHES='{"Lidl":{"branchId":"lidl_zellingen","location":"Zellingen"}}'
  ```

  Ohne `SPARZAM_KAUFDA_ENABLED=1` wird keine Anfrage ausgeführt.
  `SPARZAM_KAUFDA_MAX_QUERIES=0` ist zusätzlich eine harte Nullgrenze und
  verhindert jeden Abruf auch dann, wenn das Feature-Flag und Suchbegriffe
  gesetzt sind.

  Die Abfrage bleibt zusätzlich auf eine kleine Zahl von Suchbegriffen, eine
  4-MB-Antwortgröße, einen Timeout und einen lokalen Cache begrenzt. Wiederholte
  Treffer mit anderer transienter kaufDA-ID werden nur dann zusammengeführt,
  wenn Händler, Label, Preis, Zeitraum und Prospektseite identisch sind;
  unterschiedliche Seiten oder Zeiträume bleiben getrennt.

  Der Parser kennt neben dem aktuellen Pfad auch eine begrenzte, feldgeprüfte
  Suche nach umbenannten Ergebniscontainern in `__NEXT_DATA__`. Beliebige
  verschachtelte JSON-Listen werden nicht als Angebote übernommen.

  Ein Treffer aus einem zulässigen kaufDA-Cache trägt zusätzlich seinen
  tatsächlichen Abrufzeitpunkt am einzelnen Angebot. Der Preislern-Pfad
  verwendet diesen Zeitpunkt vor dem zusammengeführten Feedzeitpunkt, damit
  ein anderer, später aktualisierter Händlerfeed die kaufDA-Evidenz nicht
  künstlich verjüngt.

  Die MIT-Lizenz des GitHub-Projekts betrifft dessen Quelltext, nicht die
  Angebotsdaten oder die Nutzungsbedingungen von kaufDA. Eine produktive,
  automatisierte Nutzung fremder kaufDA-Daten braucht daher weiterhin eine
  gesonderte rechtliche Freigabe. Es werden keine Logos, Grafiken, Login-,
  Coupon- oder Zahlungsfunktionen und kein fremder Quelltext übernommen.
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

## KaufDA-Parser – Taxonomie- und Medienalias

Der optionale SparzamApp-eigene KaufDA-Adapter berücksichtigt zusätzlich
singuläre \`categoryPath\`-Formen und explizite Produktbildlisten. Die
Lebensmittelprüfung trennt Produkttext von Sammelkategorien: Ein offizieller
Bereich wie „Obst/Gemüse/Pflanzen“ bleibt für Lebensmittel nutzbar, während
Haushalts- und Pflanzenartikel im Produkttext ausgeschlossen werden. Die
Änderung erweitert keine Händlerrechte und übernimmt weiterhin weder fremden
Quellcode noch Markenmedien.


Die KaufDA-Gruppierung bewahrt den neuesten Erfassungszeitpunkt über mehrere
begrenzte Suchbegriffe. Einzelne Angebote bleiben mit ihrem eigenen
Erfassungszeitpunkt nachvollziehbar; bei gemischtem Live-/Cache-Stand bleibt
die Cache-Nutzung als Diagnosesignal erhalten.

## KaufDA-Parser – verschachtelte Gültigkeit und Mengen

Der optionale Adapter liest verschachtelte Gültigkeitsfelder nur aus
ausdrücklich benannten öffentlichen Schlüsseln und verlangt weiterhin ein
gültiges Start-/Endpaar. Mengenobjekte werden nur bei belegtem Betrag und
Einheit als Packungsgröße übernommen. Die Ergänzung nutzt keine zusätzliche
kaufDA-Schnittstelle und ändert die bestehende Abschaltbarkeit, Cachegrenzen
oder regionale Filialprüfung nicht.

## KaufDA-Parser – öffentliche Feldaliasse

Der optionale Adapter erkennt einige klar benannte öffentliche Händler-,
Angebots-ID- und Preisfelder auch in verschachtelter Form. Diese Toleranz
ändert weder die Abschaltbarkeit noch die Cache- und Branchgrenzen und ist
keine Nutzung einer privaten Händlerfunktion.

## Lokale Preisbeobachtungen – aktuelle Projektion

Die Kompaktierung automatischer Belege bevorzugt innerhalb eines bestehenden
exakten Schlüssels aktuelle Zeilen. Das ändert keine Quelle, keinen Nachweis
und keine Preisrolle; es verhindert nur, dass der aktuelle reguläre Prospektwert
durch reine Verlaufseinträge aus dem begrenzten Speicher fällt.
