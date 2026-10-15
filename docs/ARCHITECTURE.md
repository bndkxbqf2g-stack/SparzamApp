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
- `PriceObservation` und die daraus projizierte `MarketPrice` bewahren
  zusätzlich eine optionale konkrete Adapterkennung (`sourceAdapter`).
  Dadurch bleibt etwa KaufDA als Herkunft sichtbar, ohne die stabile technische
  Quellenklasse oder ältere Speicherformate zu ändern.
- Externe Quellen werden über Adapter übersetzt. Provider sollen nur benötigte Produkte abfragen; Matching und Preisbewertung bleiben in gemeinsamen Diensten. Regalvideo bleibt entsprechend D010 zunächst reine Evaluation.
- Eine explizite Preis-Mengenangabe wird vor Anzeige und Route gegen die
  Produktpackung geprüft. Die gemeinsame Vergleichsgrenze nutzt die
  katalogisierte Packungsmenge oder eine eindeutig parsebare Einheit wie
  `500 g`, `4 x 125 g` oder `3er-Schale`; Variantenbereiche bleiben ohne
  Preisbasis. Legacy-Preise ohne Mengenangabe bleiben lesbar, werden aber
  nicht durch eine erfundene Packungsgröße ergänzt.
- Produktdatenquellen normalisieren dieselben Einheiten bereits an der
  Adaptergrenze. Beispielsweise wird `20 cl` aus Open Food Facts als `200 ml`
  gespeichert; unbekannte strukturierte Einheiten werden nicht als Packung
  übernommen.
- Auch die Katalog- und Filialabdeckung verwendet diese Grenze, sobald der
  Produktkatalog vorliegt. Abweichende Packungen und unbekannte Produkt-IDs
  erhöhen dann keine scheinbare Preisabdeckung; Diagnoseaufrufe ohne Katalog
  behalten ihre bisherige reine Quellenzählung. Bekannte, aber nicht
  vergleichbare Packungen werden separat als Datenlücke gezählt, damit die UI
  den Grund der geringeren Abdeckung erklären kann.
- Der Prospektfeed folgt der Reihenfolge Live-Quelle → lokaler Cache → versioniertes öffentliches App-Asset. Cache und Asset bleiben als nicht-live gekennzeichnet; Gültigkeit, Filiale und Nachweis werden im gemeinsamen Importpfad erneut geprüft.
- Das versionierte Prospekt-Asset wird zusätzlich als Fixture geprüft: jede
  konfigurierte Händlerquelle muss einen aktuell gültigen Zeitraum, eine
  konkrete Filiale und eine HTTPS-Coverseite mit Seitennummer 1 liefern. Die
  Prüfung bleibt auf den Assetbestand beschränkt und ersetzt keine Live-
  Quellenvalidierung.
- `safe_external_url.dart` bildet die gemeinsame Rendergrenze für lokale
  Bildreferenzen. Auch bereits gespeicherte Produkt- und Angebotsdaten werden
  vor `Image.network` auf absolute HTTP(S)-URLs mit Host begrenzt; diese
  Prüfung ersetzt keine Quellenvalidierung, verhindert aber, dass alte oder
  fremde URL-Schemata in UI-Netzwerkwidgets gelangen.
- Ein automatisch erzeugter Prospekt-Importer besitzt seinen HTTP-Client nur
  für einen Refresh und schließt ihn danach. Test- oder Host-Clients werden
  injiziert und bleiben im Besitz des Aufrufers.
- Die Shell vereinigt append-only `PriceObservation`-Reads nach ID, wenn Bon-,
  Prospekt- und allgemeines Preis-Laden parallel abgeschlossen werden. Ein
  älterer Lese-Callback kann dadurch keinen bereits sichtbaren Nachweis aus
  dem In-Memory-Stand entfernen.
- Ein Backup-Import invalidiert vor seinem ersten asynchronen Write die
  interne Shell-Datenrevision. Startup-, Prospekt- und Bon-Loader prüfen diese
  Revision vor State-Projektionen; Angebots- und Listen-Importe werden hinter
  ihren Schreibwarteschlangen ausgeführt, Beleg-Import und -Ersetzung teilen
  eine serialisierte Queue.
- Lokale Einkaufslisten, Preis-/Bonbeobachtungen und Strecken-Caches verwenden
  je Speicherbereich einen `SequentialOperationQueue`. Reads werden dabei
  ebenso wie Writes eingereiht; Fehler erreichen den jeweiligen Aufrufer,
  blockieren aber keine nachfolgenden lokalen Operationen.
- Der Preisverlauf und der aktuelle `MarketPrice`-Bestand verwenden denselben
  lokalen Reihenfolgevertrag. Initialisierung, Backup-Ersetzung, Upsert und
  öffentlicher Read teilen je Storetyp eine Queue; die fachliche Projektion und
  die Branch-Slot-Regel bleiben davon getrennt.
- Kaufhistorie und Wiederkäufe verwenden denselben lokalen
  Reihenfolgevertrag. Reads, Ersetzungen und Read-Modify-Write-Aktionen lesen
  den gespeicherten Snapshot innerhalb der jeweiligen Store-Queue und bewahren
  dabei ID-Zusammenführung, Chronologie und die 30-Einträge-Begrenzung.
- Der `OfferStore` verwendet denselben lokalen Reihenfolgevertrag für
  Prospekt- und KaufDA-Imports. Die Zusammenführung läuft innerhalb der Queue;
  Demo-Bereinigung, Angebots-ID und Quellen-/Nachweisfelder bleiben dabei
  fachlich unverändert.
- Der `ProductCatalogStore` verwendet denselben lokalen Reihenfolgevertrag
  für eigene Stammdaten, Scanner- und EAN-Discovery-Imports. Die Queue schützt
  die Zusammenführung, während EAN, Varianten, Aliase und Favoriten fachlich
  getrennt und alphabetisch sortiert bleiben.
- Der `BudgetStore` liest und schreibt Monatsbudget, Lebensmittelbudget und
  Ausgaben innerhalb derselben lokalen Queue. Dadurch bleibt der Budget-
  Snapshot zwischen Einkaufsabschluss, Korrektur und Oberfläche konsistent;
  die Betragsvalidierung bleibt fachlich unverändert.
- Mobilitäts- und Preisquellen-Einstellungen verwenden je Storetyp denselben
  lokalen Reihenfolgevertrag. Startup, Backup und UI lesen dadurch denselben
  vollständigen Snapshot; die Queue schaltet keine externe Quelle selbsttätig
  ein.
- Das lokale Diagnoseprotokoll verwendet denselben Reihenfolgevertrag für
  Lesen, Hinzufügen und Löschen. Die Begrenzung auf 100 Einträge und die
  Fehlerisolation bleiben erhalten, damit Logging keinen Produktivpfad blockiert.
- Prospektfavoriten verwenden denselben lokalen Reihenfolgevertrag. Die
  normalisierte und sortierte Menge wird als Snapshot gespeichert; ein nicht
  verfügbarer Präferenzkanal bleibt weiterhin ein expliziter `null`-Fallback.
- Die Shared-Preferences-Fallbacks für Open Prices, Open Food Facts und den
  öffentlichen Prospektfeed verwenden je Cachetyp denselben lokalen
  Reihenfolgevertrag. Rohantworten bleiben best effort und werden nie als
  bestätigte Preis- oder Produktidentität ausgegeben.
- `ProspectFeedService` bündelt während eines laufenden Refreshes alle
  gleichzeitigen `load()`-Aufrufe in einer Future. Dadurch bleiben öffentliche
  Anfragefrequenz und Cache-/Asset-Fallback getrennt von der UI-Konkurrenz.
- Die Route bewertet konkurrierende bekannte Preise pro Markt anhand von Betrag und getrennter Quellen-/Altersunsicherheit. Fehlende Preisbereiche und dataGap-Priorisierung folgen in eigenen Paketen.
- Die Einkaufsliste übernimmt für `MarketPrice` dieselbe Identitäts-, Mengen-
  und Aktualitätsgrenze wie die Routenprojektion. Unsichere oder unbrauchbare
  Preisbelege werden nicht als exakte Quote angezeigt; alte, sichere Bonpreise
  bleiben als historische Orientierung gekennzeichnet.
- Prospektkarten und manuelle Seitenübernahmen prüfen nach Add-/Save-Callbacks
  den Widget-Lebenszyklus, bevor sie lokalen State oder die Elternliste ändern.
- Direkte `Offer`-Einträge dürfen nur dann eine Route beeinflussen, wenn sie
  manuell erfasst wurden oder bei einer externen Quelle einen vertrauenswürdigen
  `proofRef` tragen. Damit kann ein unvollständiger oder nachträglich veränderter
  gespeicherter Prospektdatensatz keinen unbelegten Routepreis erzeugen.
- Dieselbe Evidenzgrenze gilt für aktuelle Preisfenster, Suchvorschläge und
  Kandidatenkarten. Unbelegte externe Angebote bleiben dort aus der aktuellen
  Preiswahl heraus; die Angebotsübersicht kann sie weiterhin zur Prüfung mit
  sichtbarem Nachweisstatus anzeigen.
- Die Beobachtungsadapter verwenden dieselbe Fallunabhängigkeit für manuelle
  Angebote. Eine Nutzereingabe verliert beim Übergang in die Historie daher
  nicht versehentlich ihre bestätigte Identitätsstufe.
- Auch die zentrale Importauflösung erkennt `manual` unabhängig von der
  Groß-/Kleinschreibung; externe Quellen behalten weiterhin die Nachweispflicht.
- Ein gespeichertes `Offer` bewahrt bei vorhandener Quellenangabe zusätzlich
  Packungsmenge, Einheit und normalisierten Grundpreis. Beim Übergang in
  `PriceObservation` werden diese Felder weitergereicht; alte Angebote ohne
  Mengenbasis bleiben lesbar, erzeugen aber keine erfundene Vergleichbarkeit.
- Die zentrale `offerMatchesProduct`-Prüfung verwendet diese Basis vor
  Preisfenster, Suchkandidaten, Vorschlägen und Route. Ein explizit
  abweichendes Angebot bleibt damit eine sichtbare, aber nicht verwertbare
  Datenlücke; Legacy-Angebote ohne Mengenangabe bleiben rückwärtskompatibel.
- `OfferImportRecord.regionalOnly` wird bereits an der zentralen
  `resolveOfferImport`-Grenze abgewiesen. Damit kann ein regionaler KaufDA-
  Publisher-Treffer auch über direkte Importaufrufe nicht als exaktes Angebot
  in Preisbeobachtung oder Route gelangen.
- Für bereits gespeicherte Altangebote prüft `hasExactOfferBranch` zusätzlich
  die KaufDA-Adapterkennung. Fehlt dort die `locationId`, bleibt das Angebot
  sichtbar, wird aber aus Route, Preisfenster, Kandidaten und Vorschlägen
  ausgeschlossen; die Beobachtungs-Confidence wird nicht auf exakt gesetzt.
- `hasExactOfferRecordBranch` wiederholt dieselbe Prüfung für eingehende
  KaufDA-Records und den historischen Lernpfad. Ein fehlendes oder falsch
  gesetztes `regionalOnly`-Flag kann dadurch keine Publisher-Evidenz fördern.
- Filialgebundene Beobachtungen behalten ihre `sourceLocationId` bis zur Routenauflösung. Die Planungsprojektion bewahrt deshalb mehrere Filialen desselben Händlers; `RoutePriceResolver` verwendet für eine ausgewählte `Store.branchId` ausschließlich den passenden Standort und lässt standortlose Legacy-Belege nur als ausdrücklich nachrangigen Fallback zu. Angebote folgen derselben Regel über `Offer.locationId`.
- Die zentrale `matchesConfiguredBranch`-Prüfung gilt auch für
  Preisfenster, Suchkandidaten und Vorschläge. Ein Preis mit bekannter anderer
  Filiale wird damit nicht allein wegen desselben Händlernamen gerankt.
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
- `quantity_normalizer.dart` bildet g/kg, ml/cl/l und Stück auf gemeinsame
  Basiseinheiten ab. Vergleichbarkeit wird vor Preisranking geprüft.
- `product_family.dart` trennt breite Familie, generischen Familienwunsch und konkrete Variante. Familienfallback ist damit nicht automatisch Variantenidentität.
- Bon-Familienpreise dürfen nur mit sicher normalisierbarer Mengenbasis in die Planung einfließen; sonst bleiben sie Evidenz/Hinweis.
- Die Open-Prices-Pipeline arbeitet demand-driven von der aktuellen Einkaufsliste. Bekannte EANs können direkt abgefragt werden.
- Wenn das Katalogprodukt eine geprüfte Packungsmenge trägt, übernimmt der
  Open-Prices-Adapter diese Menge/Einheit samt normiertem Grundpreis in
  `MarketPrice` und `PriceObservation`; dadurch greift dieselbe zentrale
  Packungsprüfung wie bei manuellen und Prospektpreisen.
- `open_food_facts_product_discovery.dart` darf bei fehlender EAN konservativ einen Kandidaten zum Abruf finden. Ein Discovery-Treffer bestätigt die Produktidentität jedoch nicht und darf deshalb noch keinen exakten Routenpreis erzeugen.
- Automatische Bon-Reviews und externe Discovery folgen damit derselben Grenze: Erkennung/Recherche ist Evidenz, explizit bestätigte Identität ist Voraussetzung für exakte Preisprojektion.


## Bring-Prospektquelle – 29.09.2026
- Bring wird ausschließlich als optionaler serverseitiger Refresh-Adapter verwendet; Zugangsdaten gelangen weder in Flutter noch in das Repository.
- Geteilte Bring-URLs sind Ausgabe-Referenzen. Die dauerhafte Aktualisierung erfolgt über standortbezogene Ermittlung der jeweils aktuellen Prospekt-BRN.
- Die Adaptergrenze übersetzt strukturierte `discounts[]` in den bestehenden `OfferImportRecord`-/`PriceObservation`-Vertrag. Produkttext, Bild, Angebots-/Normalpreis, Gültigkeit und `proofRef` bleiben getrennt nachvollziehbar.
- Seitenbilder ohne strukturierten Hotspot werden im Prospektreader gezeigt, aber nicht automatisch als routenfähiger Preis interpretiert. Damit bleibt D028/D030/D031 erhalten.

## KaufDA-Prospektrecherche – 12.10.2026
- `tool/kaufda_prospects.py` ist ein eigener, kleiner Diagnose-/Refreshadapter. Er liest ausschließlich öffentlich eingebettete `__NEXT_DATA__`-Suchdaten, begrenzt Suchbegriffe und Abrufe, verwendet den lokalen Cache und übersetzt nur geprüfte Lebensmittelangebote in das vorhandene Prospektformat.
- KaufDA-Liveantworten werden erst nach erfolgreichem Parsing gecacht. Ein
  HTTP-200-Formatfehler fällt auf den letzten gültigen Cache zurück, ohne den
  individuellen Abrufzeitpunkt der alten Daten zu verjüngen.
- Ein Publishername ist noch keine Filialidentität. Ohne separat konfigurierte Branch-Assertion bleiben aktuelle Lebensmittel-Treffer regional-only; sie bleiben für Suche und Nachweis sichtbar, dürfen aber weder in Einkaufsliste, Preisbeobachtung noch Route übernommen werden. Mit exakter Filial-ID werden Standort, Prospekt-ID/-seite, Gültigkeit, Packungsgröße, Preis und Erfassungszeit als Provenienz weitergereicht.
- Eine Suchabfrage kann mehrere Publisher enthalten; `storeName` bleibt deshalb an jedem KaufDA-Prospektmetadatensatz erhalten und verhindert, dass Coverseiten oder Laufzeiten einem anderen Händler zugeordnet werden.
- Karten zeigen bei vorhandener KaufDA-Evidenz zusätzlich Erfassungszeitpunkt
  und Prospektseite; fehlende Metadaten bleiben leer und werden nicht ergänzt.
- Wenn ein zusammengeführter Händlerfeed ausschließlich regionale KaufDA-
  Datensätze enthält, leiten Angebots- und Prospektübersicht den
  `regional_only`-Hinweis aus den Datensätzen ab; ein offizieller Quellstatus
  `ok` verdeckt diese Einschränkung nicht.
- Externe Prospektlinks werden auch in der Angebotsübersicht vor dem Öffnen auf
  HTTP(S) und einen Host begrenzt; ungültige oder alte Feedfelder erzeugen
  keinen ausführbaren Link.
- `MarketPriceStore` hält Marktpreis-Slots nach Händler, Produkt und
  kanonischer `sourceLocationId` getrennt. Standortlose Legacy-Einträge bleiben
  als Fallback lesbar; der Routenresolver bevorzugt bei bekannter Filiale den
  exakten Standort.
- Der Feed-Parser vererbt Filialkontext nur an bestätigte Datensätze;
  `regionalOnly`-Angebote behalten ausschließlich explizit mitgelieferte
  Standortfelder. Auch ein fehlerhaftes `regionalOnly: false` kann einen
  KaufDA-Datensatz ohne eigene Branch-ID nicht routefähig machen.
- KaufDA bleibt optional und standardmäßig deaktiviert. Offizielle Händlerquellen bleiben führend; der Adapter ersetzt keine bestehende Quelle und besitzt keine Flutter-Laufzeitabhängigkeit.
- Die Refresh-Konfiguration kann eine explizite Umgebungsabbildung erhalten;
  ein leerer Test-/Job-Kontext liest keine zufälligen Prozessflags und löst
  dadurch niemals unbeabsichtigt einen KaufDA-Abruf aus.
- Beim Übergang eines importierten Datensatzes in das gespeicherte `Offer` bleibt
  die optionale `sourceAdapter`-Kennung getrennt von der technischen
  `source`-Klasse erhalten. So kann die Oberfläche KaufDA als konkrete Herkunft
  ausweisen, ohne die bestehende Preisquellenlogik oder ältere JSON-Formate zu
  verändern. Ein vorhandener `capturedAt`-Zeitpunkt wird ebenfalls erhalten;
  die Angebotsgültigkeit bleibt davon getrennt.
- Beim Überführen eines gespeicherten Angebots in `PriceObservation` verwendet
  die Shell diesen `capturedAt`-Zeitpunkt. Nur Angebote ohne Quellzeitpunkt
  erhalten den lokalen Speichermoment als Fallback; ein späteres Öffnen oder
  Bearbeiten datiert einen KaufDA-Nachweis nicht künstlich neu.
- Die zentrale Importauflösung prüft eine explizite Packungsgröße gegen die
  Katalogmenge. Abweichende oder mehrdeutige Mengen bleiben offen und werden
  nicht als konkrete Variante in die Einkaufsliste übernommen.
- Beim manuellen Bearbeiten eines importierten Angebots bleiben Quelle,
  Adapter, Erfassungszeitpunkt, Nachweis und Filialkontext nur bei derselben
  Filiale und Produktidentität erhalten; bei einem Identitätswechsel werden
  diese Belege gelöscht, damit kein Nachweis auf ein anderes Produkt wandert.

- AppShell bündelt lokale Mutationen aus Backup, Preisen, Angeboten, Katalog
  und Listen in einer gemeinsamen `SequentialWriteQueue`. Die Datenrevision
  verhindert zusätzlich, dass ein bereits überholter asynchroner Vorgang sein
  Ergebnis wieder in den sichtbaren Zustand projiziert.

- Prospektdaten werden zweimal gegen Non-Food geschützt: `refresh_prospects.py`
  bereinigt den versionierten Bestand und `ProspectFeedService` prüft auch
  ältere Cache-/Assetstände. Starke Händlerkategorien für Tierbedarf werden
  berücksichtigt, ohne fehlerhaft einsortierte Lebensmittel wie Proteinriegel
  oder Shakes aus dem Feed zu entfernen.

- Die Routen- und Filialansichten behandeln Straßenstrecken als versionierte,
  fehlertolerante Projektion. Ein neuer Adress- oder Aktualisierungsvorgang
  invalidiert ältere Antworten; Cache-/Routingfehler verlassen den Ladezustand
  kontrolliert und verändern keine bestehende Fallback-Entfernung.

## Lokale Preisbeobachtung und Browser-Speicher
Automatisch erzeugte externe Preisbeobachtungen aus Prospekten, Händlerquellen,
Open Prices und Schätzquellen werden bei der lokalen Persistenz begrenzt: pro
exakter Produkt-/Markt-/Quell-/Variantenbasis bleiben die neuesten drei
Beobachtungen erhalten, insgesamt höchstens 2.000 automatische Einträge. Bei
einem Browser-Quota-Fehler erfolgt ein kleinerer Wiederherstellungsversuch.
Bon-, manuelle, Bild- und sonstige nutzernahe Belege werden nicht durch diese
Verdichtung entfernt.


### Lifecycle-Refresh des Prospektfeeds

`AppShell` beobachtet das Fortsetzen der Anwendung. Wenn der letzte validierte
Prospektstand älter als sechs Stunden ist oder kein Erfassungszeitpunkt vorliegt,
startet ein Hintergrund-Refresh über denselben `ProspectImportModule`- und
`PriceObservation`-Pfad wie der Kaltstart. Der vorhandene Feed bleibt während
des Abrufs sichtbar; die kurze Ereignisdrossel verhindert doppelte Requests. Im aktiven Lebenszyklus plant AppShell höchstens einen sechsstündigen Timer und beendet ihn beim Pausieren.

### Prospect-Seitenabdeckung und Artikel-Provenienz

Der Refresh-Adapter liest zuerst die offizielle strukturierte Händlerquelle.
Wenn ein Händler einen öffentlichen Katalog-Reader liefert, wird dessen
veröffentlichte Seitenliste vollständig in `pageSamples` abgelegt. Die
gemeinsame Seitenhülle schreibt zusätzlich:

| Feld | Bedeutung |
| --- | --- |
| `pageCount` | vom Publisher erklärte oder aus einer verifizierten Seitenliste abgeleitete Gesamtzahl |
| `loadedPageCount` | tatsächlich mit einer gültigen HTTP(S)-Bildquelle geladene Seiten |
| `missingPageNumbers` | erklärte, aber nicht geladene Seitennummern |
| `pageStatus` | `complete`, `partial`, `cover_only` oder `unavailable` |
| `pageCountKnown` | ob die Quelle eine belastbare Gesamtzahl veröffentlicht |
| `pageSource` | konkreter Nachweis des Seitenkatalogs |

Publitas wird über `data.json` und den daraus gelieferten `cacheToken` auf
`spreads.json` begrenzt. EDEKA verwendet `catalog.xml`, Kaufland und Lidl die
öffentliche Schwarz-Leaflets-v4-API. Regionale oder thematische
Drogerie-/Non-Food-Blätter verdrängen dabei keinen branchennahen
Lebensmittelprospekt. Bei fehlender Seitenquelle bleibt die einzelne belegte
Coverseite sichtbar und der Status bleibt unvollständig; Seiten, Artikel oder
Preise werden nicht aus Dateinamen, Seitenlücken oder Rabattanzeigen erfunden.

Die aus strukturierten Händlerdaten gewonnenen Artikel bleiben im bestehenden
`OfferImportRecord`-Vertrag. Explizite Streich-/Normalpreise bleiben
`originalPrice`, zeitlich begrenzte Werte `offerPrice`; beide werden über
`PriceObservation` weitergereicht. Bildseiten ohne strukturierte Artikelzeile
bleiben visuelle/OCR-Evidenz und werden erst nach Identitätsbestätigung als
exakter Preis übernommen.

`ProspectFeedService` dedupliziert Seitennummern beim Parsen erneut. Der
Filial-Resolver kopiert sämtliche Abdeckungsdiagnostik, und der
Feed-Fingerprint berücksichtigt sie, damit neue Seiten nach einem Refresh
nicht vom bisherigen Tagesstand unterdrückt werden. `SharedPreferences` hält
nur den einen austauschbaren Feed-Key und begrenzt dessen UTF-8-Größe.
