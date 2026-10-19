## Update 19.10.2026 – REWE-Adapter und siebter Markt

- Die Python-Regressionen decken den vorhandenen REWE-API-Parser weiterhin mit
  anonymisiertem Fixture ab; produktiv ist dieser nicht dokumentierte Endpunkt
  nicht registriert und der Adapter nutzt im normalen Testlauf keine
  Live-Abfrage.
- Feed- und Branch-Regressionen erwarten sieben eindeutige Quellen bzw.
  konfigurierte Märkte. Ein leerer REWE-Quellenstand bleibt als Fehlerstatus
  sichtbar und erzeugt keinen Preis.
- Die Einkaufsmatrix- und Markt-ID-Tests prüfen die siebte Standardfiliale.
  Die bestehende synthetische Sechs-Markt-Kombinationsprüfung bleibt als
  unabhängiger Grenzfall erhalten.
- PR-CI (Python-Parser, flutter analyze, flutter test und
  flutter build web --release) ist vor dem Merge auszuführen.


## Update 18.10.2026 – Reguläres Preisfeld bleibt nachvollziehbar

`offer_import_test.dart` und `prospect_offer_products_test.dart` prüfen den
Marker vom Feed bis zum gespeicherten `Offer`. `prospect_price_learning_test.dart`
prüft die Weitergabe in die reguläre `PriceObservation`;
`price_observation_store_test.dart` schützt den JSON-Roundtrip. Der Preise-Reiter
zeigt das Feld im aktuellen Normalpreisledger an. Alle Fixtures bleiben offline.

## Update 18.10.2026 – MarketPrice-Projektion bewahrt Quellenfeld

`price_observation_store_test.dart` prüft JSON-Roundtrip, Beobachtungsadapter
und Projektion eines regulären Prospektpreises. Der Marker bleibt dabei vom
gespeicherten `PriceObservation` bis zur routenfähigen `MarketPrice` erhalten.
Die Fixture bleibt vollständig offline.
## Update 17.10.2026 – Coverbild-Kandidaten

`offers_cover_section_test.dart` prüft, dass die explizite Thumbnail-URL
bevorzugt bleibt und eine andere validierte Prospektseite als Ersatzkandidat
am adaptiven Bild anliegt. Der Test erzeugt keine Netzwerkanfrage und verändert
keine Preis- oder Filialdaten.

## Update 17.10.2026 – Cache-Grenze für große Angebote-Feeds

offers_screen_test.dart prüft den 180-Pixel-Vorlauf für kleine Feeds und die
Nullgrenze des äußeren Scroll-Caches ab 48 aktuellen Prospektzeilen.

## Update 17.10.2026 – Kompakte Prospektbilder

prospect_offer_card_test.dart prüft, dass die 88-Pixel-Listenbilder mit einer
begrenzten 192×192-Auflösung dekodiert werden; die ausführliche Ansicht behält
ihre größere Vorschaugröße.

## Update 17.10.2026 – Separate Coverseite vor Interiorseiten

prospects_screen_test.dart prüft einen Feed mit eigener Cover-URL und einer Seitenliste ab Seite 2. Der Viewer zeigt die Coverseite als Seite 1 und behält die originale Seite 2.
## Update 17.10.2026 – Seitenviewer trennt Listenübernahme und Preisablage

prospects_screen_test.dart prüft jetzt den Fehlerpfad eines manuell geprüften Seitenartikels: Der Artikel wird trotz fehlgeschlagener Angebotsablage in die Einkaufsliste übernommen, während die Preisablage als Warnung sichtbar bleibt.
## Update 17.10.2026 – Reguläre Prospektpreis-Provenienz

Die Parserregressionen prüfen jetzt das Herkunftsfeld des regulären Preises für
KaufDA-, Bring- und offizielle Feedzeilen. Der Dart-Feedtest verwirft einen
unbekannten `regularPriceSource`-Marker; der Preislern-Test stellt sicher,
dass eine konkrete Adapterzeile ohne Herkunftsfeld keine automatische reguläre
PriceObservation erzeugt. Alle Fälle bleiben synthetisch und offline.

## Update 17.10.2026 – Capture-Zeitpunkt bleibt offline erhalten

Der Prospektcache speichert den HTTP-Zeitpunkt separat und bindet ihn an den
identischen Feedtext. Der Offline-Start kann deshalb weiterhin nur mit einem
belegten Quellenzeitpunkt automatisch reguläre Prospektpreise speichern;
veraltete Metadaten werden bei einem anderen Feedtext verworfen.

## Update 17.10.2026 – HTTP-Zeitstempel als Prospekt-Fallback

prospect_feed_cache_test.dart prüft jetzt Last-Modified und Date für
Feeds ohne generatedAt. Diese expliziten Antwortzeitpunkte werden als
capturedAt an die automatische Speicherung weitergereicht; die lokale Uhr
wird nicht als Quellenzeitpunkt eingesetzt. Offline-/Cachepfad und reguläre
Preisregeln bleiben unverändert.

## Update 17.10.2026 – Preis-Mutation liefert Beobachtungssnapshot

Der Test shell_price_coordinator_test.dart prüft jetzt, dass Einzelpreis, Batch und Open-Prices-Sync neben Marktpreis und Verlauf auch den vollständigen gespeicherten Beobachtungsstand liefern. CI 5631 lief mit Analyse, Flutter-Tests und Web-Release-Build erfolgreich.

## Update 17.10.2026 – Listen-Metadaten werden nach Feed-Updates aktualisiert

Der neue Helper in `shopping_list_updates.dart` wird durch einen lokalen Test mit geänderter Marke, Packungsgröße, Alias und Bild geprüft. Die Regression bestätigt, dass Menge, Notiz und Abhakstatus erhalten bleiben; Netzwerkanfragen und echte Nutzerdaten werden nicht verwendet.

## Update 17.10.2026 – Einkaufslisten-Metadaten-Roundtrip

`scan_to_list_flow_test.dart` prüft jetzt zusätzlich Aliase, Favoriten-/Stammartikelstatus, Marke, Packungsmenge/-einheit und Bild nach dem Speichern und Laden über den Legacy-Schlüssel. Der Test verwendet ausschließlich synthetische lokale Daten.

## Update 17.10.2026 – Frische vor Quellenpriorität in der Preis-Matrix

'shopping_price_quotes_test.dart' prüft, dass bei gleichem
qualitätsbereinigtem Betrag der neuere Open-Prices-Beleg vor einem älteren
Receipt-Beleg in der Marktzeile und im hervorgehobenen Einkaufslistenpreis
erscheint. Angebots- und historische Preisregeln bleiben durch die vorhandenen
Tests abgedeckt. CI 5579 (Flutter CI) lief mit Analyse, vollständigen
Flutter-Tests und Web-Release-Build erfolgreich durch.

## Update 17.10.2026 – Prospekt-/Angebotsstatus-Cache

Die bestehenden `prospects_screen_test.dart`- und
`offers_screen_test.dart`-Widgettests prüfen weiterhin aktuelle, abgelaufene,
regionale und fehlgeschlagene Feedzustände. Der neue Cache verwendet getrennte
Schlüssel für Coverauswahl und Statushinweise; CI bestätigt Analyse,
Fluttertests und Web-Build.

## Update 17.10.2026 – Einkaufsvorschlags-Cache

Die vorhandenen Shopping-Flow-, Such- und Produktidentitätstests laufen mit der
memoisierten Vorschlagsberechnung. Der Cache wird bei geändertem Suchtext,
Quelllisten oder Tagesgrenze neu aufgebaut; ein Tageswechsel verhindert
veraltete Angebots-/Preisvorschläge.

## Update 17.10.2026 – Routen-Cache

`route_planning_cache_test.dart` prüft, dass wiederholte Aufrufe derselben
geordneten Filialauswahl dasselbe `OptimizedTravelRoute`-Ergebnis verwenden.
Die Signatur enthält die exakte Filialidentität und Distanz; bestehende
Routen-, Preis- und Tie-Breaker-Regressionen bleiben unverändert. CI führt
weiterhin Analyse, Flutter-Tests und den Web-Release-Build aus.

## Update 17.10.2026 – Favoritenindex in Prospektansichten

`prospect_favorites_store_test.dart` prüft den konstanten Set-Lookup
für exakte Branch-Favoriten, die Legacy-Händlerkompatibilität und die
Isolation eines gleichnamigen anderen Marktes. Die UI-Toggle-Regression bleibt
bestehen; Cover- und Prospektkarten verwenden denselben Index.

## Update 17.10.2026 – KaufDA-Batchgrenze

tool/tests/test_kaufda_prospects.py prüft die konfigurierbare Obergrenze,
deterministische URL-Reihenfolge und die Pause zwischen öffentlichen
KaufDA-Batches. Tests verwenden ausschließlich ein anonymisiertes HTML-Fixture;
es gibt keine Live-Abfrage.

## Update 17.10.2026 – Angebotspreise ohne Normalpreis

prices_hub_screen_test.dart prüft, dass ein aktueller importierter Angebotspreis
mit unverifiziertem Normalpreis sichtbar als getrennte Evidenz erscheint und
nicht als gespeicherte reguläre Preisbasis beschrieben wird.

## Update 17.10.2026 – Preise-Reiter-Refresh

prices_hub_screen_test.dart prüft den direkten Refresh-Knopf für den
Prospektpreisstand. Der Test stellt sicher, dass der Callback ausgelöst wird
und die Oberfläche ausdrücklich nur reguläre Normalpreise als Speicherziel
beschreibt; die bestehende Trennung von Angebots- und Normalpreis bleibt damit
sichtbar.

## Update 17.10.2026 – Seitenviewer-Fallback

prospect_image_fallback_budget_test.dart prüft weiterhin das begrenzte,
freigebende Plattform-View-Budget. Der Seitenviewer verwendet dieses Budget
für alle validierten Seiten statt einer festen Seitenindex-Grenze; dadurch kann
auch eine später geladene Seite nach einem Canvas/CORS-Fehler sichtbar werden.
Ein Web-Renderer-/Gerätetest mit echten Händler-CDNs bleibt weiterhin offen.

## Update 17.10.2026 – Open-Prices-Batchgrenze

open_prices_sync_service_test.dart deckt weiterhin deduplizierte EANs,
Fortschritt, Abbruch und Fehlerfortsetzung ab. Zusätzlich prüft die Regression
den injizierten Live-Discovery-Pfad mit begrenzter Parallelität und geordneter
Ausgabe. Der Live-Adapter begrenzt
parallele Abrufe auf eine kleine konfigurierbare Batchgröße; Reihenfolge,
Fehlerliste und Fortschritt werden erst nach der geordneten Batchauswertung
sichtbar. Ein Live-Netzwerktest bleibt ausgeschlossen.

## Update 17.10.2026 – Preise-Reiter nach Preisrefresh

prices_hub_screen_test.dart prüft, dass ein neuer Marktpreis nach einem
Widget-Update die alte Preisempfehlung ersetzt. Die Snapshot-Invalidierung
berücksichtigt außerdem die gespeicherten PriceObservations, damit die
Prospekt-Normalpreis-Ledgeranzeige nicht an einem alten Cache hängt.

## Update 17.10.2026 – Branch-scharfer Prospekt-Refresh

prospect_feed_service_test.dart prüft, dass ein erfolgreicher und ein
fehlgeschlagener Same-Name-Branch getrennte Refresh-Scopes erzeugen.
prospect_price_learning_test.dart und
prospect_regular_price_persistence_integration_test.dart prüfen, dass nur der
reguläre Preis der bestätigten Filiale gelernt und lokal gespeichert wird.

## Update 17.10.2026 – Aktivierte Routenmärkte bei Schreibvarianten

route_preferences_test.dart prüft, dass LIDL und ALDI SUED die konfigurierten
Lidl- und ALDI Süd-Filialen auswählen. Der Test vergleicht die exakten
Branch-IDs; die Normalisierung darf keine Filialen zusammenlegen.

## Update 17.10.2026 – Coverage bei Schreibvarianten

prospect_branch_coverage_test.dart prüft, dass ein LIDL-Datensatz zu einem
Lidl-Prospekt mit derselben Branch-ID und zum persistierten Branch-Zähler
zusammengeführt wird. Die Coverage bleibt eine Karte mit einer Filiale und
einem gespeicherten regulären Preis.
## Update 17.10.2026 – Covergruppierung bei Händler-Schreibvarianten

offers_screen_test.dart prüft, dass LIDL und Lidl mit gleicher Filialebene nur
eine Coverkarte erzeugen. Die Anzeige- und Filtergruppierung nutzt den
Präsentationsschlüssel; exakte Branch-Kontexte bleiben separat.
## Update 17.10.2026 – Angebotsquellenhinweis bei Schreibvarianten

offers_screen_test.dart prüft, dass ein regionaler KaufDA-Datensatz mit
LIDL als Angebotslabel und Lidl als Prospektlabel auch bei Quellstatus
ok den Regionalhinweis zeigt. Die Normalisierung betrifft nur die
Hinweiszählung; Branch- und Routenidentität bleiben unverändert.
## Update 17.10.2026 – KaufDA-Regionalgrenze

`prospect_feed_service_test.dart` prüft, dass eine KaufDA-Kennung aus den
Quellenmetadaten ohne eigene Angebots-Branch-ID nicht als exakte Filiale
übernommen wird. Die Zeile bleibt regional sichtbar, aber ohne Branch-ID und
damit außerhalb von Preisprojektion und Route.

## Update 17.10.2026 – Preislernen ohne Feedzeitpunkt

`prospect_price_learning_test.dart` und
`prospect_regular_price_persistence_test.dart` prüfen einen Datensatz mit
`capturedAt` ohne Feed-`generatedAt`. Der reguläre Preis wird gespeichert und
behält genau diesen Zeitpunkt; ein vollständig zeitloser Datensatz bleibt
ausgeschlossen.

## Update 17.10.2026 – Kategorie-Listen

`prospect_feed_service_test.dart` prüft einen mehrteiligen
Lebensmittel-Kategoriepfad und einen Tierbedarfsdatensatz. Der Lebensmittelpfad
bleibt sichtbar; der Non-Food-Eintrag wird bereits an der Feedgrenze verworfen.

## Update 17.10.2026 – Verschachtelte Gültigkeitszeiträume

`prospect_feed_service_test.dart` prüft einen gültigen verschachtelten
`validity`-Zeitraum für Angebot und Prospekt sowie einen malformed Startwert.
Nur der belegte Zeitraum wird übernommen; der malformed Datensatz bleibt
ausgeschlossen.

## Update 17.10.2026 – Verschachtelter Filialkontext

`prospect_feed_service_test.dart` prüft einen Feed mit zwei gleichnamigen
Lidl-Filialen und verschachtelten `branch`-Objekten. Quelle, Prospektseite und
Angebot müssen dieselbe Branch-ID sowie die jeweils belegten Orts- und
Adressfelder behalten.

## Update 17.10.2026 – Verschachtelte Bildaliasfelder

`prospect_feed_service_test.dart` prüft zusätzlich `images[].thumbnailUrl`.
Der Test stellt sicher, dass nur die validierte URL übernommen und weiterhin als
`ProspectImageKind.product` klassifiziert wird.

## Update 17.10.2026 – Listenförmige Prospekt-Artikelbilder

`prospect_feed_service_test.dart` prüft jetzt ein verschachteltes `images`-
Listenfeld mit `src`. Der Test erwartet die erste validierte HTTP(S)-URL und
`ProspectImageKind.product`; Preis- und Gültigkeitsfelder bleiben unverändert.

## Update 17.10.2026 – Prospekt-OCR mit OCR-getrennten Dezimalstellen

`prospect_page_ocr_test.dart` prüft zusätzlich `1, 99 €` und `2 . 49 €`.
Der Test bestätigt, dass der Parser den Betrag normalisiert, den regulären
Vorher-Preis getrennt behält und weiterhin einen expliziten Währungsmarker
verlangt.


## Prospekt-OCR-Währungsformat

`test/prospect_page_ocr_test.dart` prüft zusätzlich eine Zeile mit `€ 1,99`
und `€ 2,49`. Das Ergebnis enthält den Angebotsbetrag und den getrennten
Vorher-Preis; eine Live-Bildabfrage ist nicht beteiligt.

## Route-Suchgrenze

`test/route_preferences_test.dart` prüft, dass ein absichtlich überhöhter
`maxStores`-Wert auf `maximumSupportedRouteStores` begrenzt wird. Die
bestehenden Tests für ein bis sechs Märkte prüfen weiterhin die fachliche
Routenentscheidung.

## Prospektpreis-Reconcile

`test/prospect_regular_price_persistence_test.dart` prüft eine aktive
Preisänderung im selben Produkt-/Filial-Slot. Der alte reguläre Beleg bleibt
gespeichert, wird historisch markiert und der neue Beleg bleibt als einziger
aktueller Wert routefähig. Unveränderte Wiederholungen aktualisieren dagegen
weiterhin dieselbe Beobachtungs-ID.

## Identitätsbasierte Bonkandidaten

`test/product_match_candidates_test.dart` prüft synthetisch abgekürzte
Milchbezeichnungen gegen mehrere Fettstufen sowie die Trennung von frischen
Rispentomaten und Passata. Die Kandidaten tragen weiterhin eine Unsicherheits-
warnung; es gibt keine automatische Bestätigung und keine Live-Abfrage.

## Open-Prices-Sync-Optimierung

test/open_prices_sync_service_test.dart prüft die Deduplizierung gleicher
Produkt-IDs und den Abbruch während der EAN-Discovery. Die Tests verwenden
nur synthetische Produkte und Fetcher; es gibt keine Live-Abfrage.


## Katalogsuche

test/product_catalog_search_test.dart prüft die identitätsbasierte
Katalogauflösung mit synthetischen Produkten: generische frische Tomaten
finden getrennte Varianten, Passata bleibt außerhalb dieser Treffer,
konkrete Milchvarianten werden nicht vermischt und eine EAN bleibt als
unbekannter Text auffindbar. Es werden keine Live-Daten verwendet.



## Batch-Preisfluss

`test/shell_price_coordinator_test.dart` prüft den Mehrfachimport als einen koordinierten Schreibvorgang: alle Marktpreise und Beobachtungen bleiben erhalten, der Verlauf enthält nur reguläre Preisrollen und die Shell kann danach einen gemeinsamen Snapshot setzen. Es werden keine Live- oder privaten Belegdaten verwendet.

## Marktpreis-Evidenzrangfolge

`test/market_price_selection_test.dart` prüft die gemeinsame Auswahlregel: qualitätsbereinigter Betrag vor Aktualität, Aktualität vor Quellpriorität, stabile Reihenfolge bei gleichen Quellen, getrennte exakte Filialslots, Ausschluss unbestätigter oder unvollständiger Preisbelege sowie dieselbe Quellenwahl im `RoutePriceResolver`. Die Tests verwenden ausschließlich synthetische Preise und keine Live-Abfragen.
# Tests und Qualitätssicherung

## Aktueller CI-Vertrag

`.github/workflows/flutter_ci.yml` führt für Pushes und Pull Requests aus:

```sh
flutter pub get
flutter analyze
flutter test
flutter build web --release
```

Weitere Workflows aktualisieren Prospektdaten, erzeugen Release-Artefakte oder beobachten Releases. Sie sind getrennt vom Flutter-CI zu beurteilen: ein fehlgeschlagener Release-/Watcher-Lauf macht den Analyse-/Test-/Webbuild nicht automatisch rot, muss aber bei Release-Aufträgen untersucht werden. Der Release-Watcher muss `gh workflow run release.yml --ref main --repo "$REPOSITORY"` verwenden, weil der geplante Watcher keinen lokalen Checkout hat. Die Korrektur des bisher fehlenden `--repo`-Arguments wird mit diesem PR ausgeliefert; ein manueller Dispatch wird während der Prüfung vermieden, damit kein Release veröffentlicht wird.

## Bestehende Abdeckung und Regressionen

Die Testsuite enthält Domänen-, Store-, Service-, Widget- und Ablaufprüfungen. Relevante Anker:

- Angebote und Preise: `offer_filter_test.dart`, `offer_input_validation_test.dart`, `effective_price_test.dart`, `offer_store_safety_test.dart`, `offer_without_regular_price_test.dart`, `expired_offer_date_picker_test.dart`.
- Produktidentität/Normalisierung: `product_identity_test.dart`, `product_family_test.dart`, `product_hierarchy_test.dart`, `product_match_candidates_test.dart`, `product_data_cache_test.dart`, `product_package_validation_test.dart`, `quantity_normalizer_test.dart`, `unit_price_test.dart`, `market_price_comparability_test.dart`, `market_price_freshness_test.dart`, `barcode_product_resolver_test.dart`; `open_food_facts_product_source_test.dart` prüft zusätzlich UPC-A/GTIN-Normalisierung und strukturierte Einheiten wie `cl` vor Speicherung. `open_food_facts_product_discovery_test.dart` prüft die konservative Discovery über Name, exakte Packungsgröße und Mehrfachpackungs-Gesamtmenge einschließlich Ablehnung einer abweichenden Menge. `quantity_normalizer_test.dart` und `offer_import_test.dart` schützen außerdem den Vergleich von `cl` mit `ml`. Open-Food-Facts-, Open-Prices- und Produkteditor-Tests prüfen die EAN-Normalisierung vor Request, Antwortvergleich und Speicherung. Der Open-Prices-Parser erhält die normalisierte EAN explizit sowohl für Live- als auch Cache-Antworten. Die Preisvergleichsregressionen sichern außerdem, dass 500-g-/1-kg- oder mehrdeutige Varianten nicht als derselbe Routenpreis erscheinen und die Katalog-/Filialabdeckung eine falsche Packung nicht mitzählt.
- Angebotsvergleichbarkeit: `prospect_price_learning_test.dart`, `prospect_offer_products_test.dart` und `offer_import_test.dart` prüfen Multipack-Gesamtmengen, Stückpacks, KaufDA-Packungsmetadaten, regionale KaufDA-Sperren, abweichende Packungsgrößen und das bewusste Offenlassen von Variantenbereichen.
- Datenqualität/Quellen: `offer_import_test.dart`, `open_prices_service_test.dart`, `receipt_observation_store_test.dart`, `receipt_price_review_test.dart`, `prospect_feed_service_test.dart`, `prospect_feed_cache_test.dart`, `real_receipt_evidence_e2e_test.dart`; die Feed-Tests prüfen zusätzlich den öffentlichen Asset-Fallback, das Ausblenden abgelaufener Angebote, die Non-Food-Sperre, ungültige per-Record-Erfassungszeiten und tolerierte Metadatenformatwechsel bei strikt typisierten Preisen. `offer_import_test.dart` prüft außerdem, dass die konkrete Adapterherkunft (`sourceAdapter`, z. B. KaufDA) und der per-Quelle gelieferte Erfassungszeitpunkt im gespeicherten Offer-JSON erhalten bleiben. Die Python-Parserregressionen unter `tool/tests/` schützen den offiziellen Netto-Prospektadapter, Bring-Fallback und den deaktivierten KaufDA-Diagnoseadapter einschließlich Cache-Zeitpunkt. Aktivierte KaufDA-Tests stellen zusätzlich sicher, dass regionale Lebensmittel-Treffer sichtbar bleiben, aber ohne Branch-Assertion als `regionalOnly` nicht routefähig werden, Publisher-Metadaten getrennt bleiben und bei identischen Datensätzen der offizielle Händlernachweis primär bleibt.
- Die Projektionsregression in `price_observation_store_test.dart` prüft zusätzlich,
  dass ein `observedAt`-Zeitpunkt in der Zukunft gar nicht erst als
  `MarketPrice`-Kandidat gespeichert wird.
- `prospect_feed_service_test.dart` prüft zusätzlich, dass ein älteres Feedformat
  ohne `thumbnailUrl` sein erstes validiertes `pageSamples`-Bild als Cover
  übernimmt.
- Derselbe Feedtest prüft positive Seitennummern, stabile Reihenfolge und die
  Entfernung doppelter Seitennummern.
- `prospects_screen_test.dart` prüft die Auswahl des bildreichen aktuellen
  Zeitraums bei mehreren Prospektmetadaten desselben Händlers.
- `prospect_feed_status_test.dart` prüft, dass ein validiertes Cover-Fallback
  in der Datenabdeckung als Bildseite erscheint und ein ungültiger Link nicht.
- Der Prospekt-Refresh schließt automatisch erzeugte HTTP-Clients auch bei
  Fehlern über den `finally`-Pfad; injizierte Test-Clients behalten ihren
  bisherigen Besitzlebenszyklus.
- `test_refresh_prospects.py` prüft zusätzlich, dass Quellenkarten nach dem
  Non-Food-Filter die nutzbare Anzahl zeigen, den Rohwert separat bewahren und
  die verifizierten ALDI-, EDEKA-, Lidl-, Netto-, PENNY- und Kaufland-Cover mit
  Filiale, Zeitraum und Seite 1 behalten. Eine gemeinsame Asset-Regression
  stellt sicher, dass alle sechs konfigurierten Quellen einen aktuellen
  Zeitraum, eine HTTPS-Coverseite und vollständige Filialmetadaten liefern.
- `current_prospect_feed_matrix_test.dart` prüft dieselben Cover-, Zeitraum-
  und Filialinvarianten nach `parseProspectFeed` für alle sechs konfigurierten
  Märkte.
- Derselbe Python-Test prüft, dass ein größerer KaufDA-Trefferbestand aus einem
  abweichenden Zeitraum den offiziell belegten Händlerzeitraum nicht verdrängt.
- Der Prospekt-Refresh bewahrt bei vollständigem Quellfehler den bisherigen
  `generatedAt`-Zeitpunkt; ein erfolgreicher Quelllauf setzt ihn auf den echten
  Laufzeitpunkt. Beide Fälle sind in `test_refresh_prospects.py` abgedeckt.
- Workflow-Sicherheit: `.github/workflows/refresh_prospects.yml` wird beim
  `push`-Ereignis nur auf `main` ausgeführt; PR-Branches können dadurch keinen
  automatischen Feed-Commit direkt nach `main` schreiben.
- Route: `route_price_resolver_test.dart`, `route_price_quality_test.dart`, `route_road_distance_test.dart`, `route_recommendation_test.dart`, `route_multi_market_e2e_test.dart`, `list_to_route_flow_test.dart`, `route_to_purchase_flow_test.dart`, `branch_identity_test.dart`; zusätzlich schützen Filialtests branch-spezifische Marktpreise und Angebote vor Standortverwechslung.
- `planning_market_prices_test.dart` schützt zusätzlich die deterministische
  Quellen-/Nachweisreihenfolge bei exakt gleichem Qualitätswert und Zeitstempel
  in Planung und Routenauflösung.
- `receipt_family_market_prices_test.dart` schützt denselben Gleichstand schon
  beim Zusammenführen mehrerer Bonbeobachtungen in einen Familienpreis.
- `test_kaufda_prospects.py` prüft zusätzlich, dass ein fehlgeschlagener
  Cache-Ersatz den vorherigen Offline-Datensatz und keine temporäre Datei
  zurücklässt.
- `test_refresh_prospects.py` prüft, dass offizielle Prospektlabels ihre
  sichere Einzel-/Mehrfach-/Zählpackung und den daraus berechneten Grundpreis
  behalten. Variable Angaben mit Bindestrich oder Schrägstrich werden bewusst
  ohne Grundpreis übernommen.
- Derselbe Adapter speichert Liveantworten erst nach erfolgreichem Parsing und
  verwendet bei einer HTTP-200-Formatänderung den vorherigen gültigen Cache;
  eine Regression prüft außerdem, dass der alte Cache unverändert bleibt.
- Der gemeinsame Refresh-Helper prüft außerdem, dass ein HTTP-403 nicht mit
  einem anderen User-Agent wiederholt wird.
- Derselbe Adapter behandelt ein beschädigtes Cache-Root-Dokument als
  Cache-Miss, statt den optionalen Refresh mit einem Strukturfehler abzubrechen.
- Derselbe Adaptertest schützt außerdem die harte Nullgrenze der begrenzten
  Suchliste. Das gilt sowohl für eine direkte `KaufdaConfig` als auch für
  `SPARZAM_KAUFDA_MAX_QUERIES=0` aus der Umgebungs-Konfiguration.
- Ein weiterer KaufDA-Fixturetest prüft die kanonische Auflösung direkt
  übergebener Filialmappings einschließlich Netto-Alias.
- `route_multi_market_e2e_test.dart` schützt zusätzlich die stabile
  Artikelzuweisung bei identischem Preis und vertauschter Store-Reihenfolge.
- `route_price_resolver_test.dart` schützt gleich günstige aktive Angebote
  gegen eine reihenfolgeabhängige Quellenwahl.
- `prospect_app_shell_flow_test.dart` prüft zusätzlich, dass ein verzögerter
  alter Named-List-Read eine bereits eingegebene Position nicht überschreibt.
- `named_shopping_list_store_test.dart` prüft Read-after-write über parallele
  lokale Aufrufe und verwirft Mengen kleiner oder gleich null.
- `route_price_resolver_test.dart` prüft außerdem, dass externe Angebote
  ohne vertrauenswürdigen Nachweis trotz gültigem Zeitraum nicht routen;
  manuelle Angebote bleiben ohne externen Nachweis zulässig.
- `branch_identity_test.dart`, `shopping_candidate_service_test.dart` und
  `shopping_suggestions_test.dart` schützen zusätzlich die Filialgrenze in
  den Such- und Preisoberflächen; Händlername allein reicht bei bekannter
  anderer Filiale nicht mehr.
- `shopping_price_quotes_test.dart`, `shopping_candidate_service_test.dart`
  und `shopping_suggestions_test.dart` prüfen dieselbe Grenze für
  Preisfenster, Suchkandidaten und Produktempfehlungen, damit eine unbelegte
  externe Aktion nicht nur aus der Route, sondern aus allen aktuellen
  Preisentscheidungen herausbleibt.
- `price_observation_store_test.dart` schützt zusätzlich die gemeinsame,
  fallunabhängige Behandlung manueller Angebotsevidenz beim Übergang in die
  Beobachtungshistorie.
- `offer_import_test.dart` deckt dieselbe Fallunabhängigkeit bereits an der
  Importgrenze ab.
- `market_price_store_test.dart` prüft zusätzlich, dass zwei Filialen derselben
  Kette im lokalen Speicher getrennte Preis-Slots behalten.
- UI/Flows: `widget_test.dart`, `home_screen_test.dart`, `store_screen_test.dart`, `prospects_screen_test.dart`, `offers_screen_test.dart`, `shopping_price_badge_visuals_test.dart`, `scan_to_list_flow_test.dart`, `receipt_import_display_test.dart`, `offer_input_validation_test.dart`. `prospects_screen_test.dart` deckt dabei auch ein belegtes Cover ohne strukturierte Seiten und die manuelle Übernahme eines Seitenartikels ab; `offers_screen_test.dart` schützt den Regionalhinweis auch bei einem offiziellen Quellstatus `ok`; beim Bearbeiten eines importierten Angebots bleiben dessen Quellen- und Filialfelder erhalten, solange der Markt nicht gewechselt wird.
- `prospects_screen_test.dart` baut zusätzlich ein größeres Cover-Grid,
  prüft die lazy Sliver-Grenze und scrollt bis zu späteren Märkten. Der
  Browser-/Canvas-Renderer bleibt dadurch als echter Web-Performancecheck
  weiterhin offen.
- `safe_external_url_test.dart` prüft, dass auch bereits gespeicherte
  Angebots-, Katalog- und Preisfensterbildreferenzen vor `Image.network` auf
  absolute HTTP(S)-Ziele mit Host begrenzt werden; `javascript:`, `data:`,
  relative und unvollständige URLs bleiben ohne Netzwerkwidget.
- `offer_image_render_safety_test.dart` prüft zusätzlich den Angebotsnachweis
  als Widget: Eine unsichere gespeicherte Bildreferenz erzeugt weder ein
  `Image`-Widget noch den Bildnachweis-Semantikbereich.
- `price_observation_store_test.dart` prüft, dass ein vorhandener
  `sourceAdapter` beim JSON-Roundtrip, beim Adapter und in der
  `MarketPrice`-Projektion erhalten bleibt; der Preisverlauf zeigt KaufDA als
  konkrete Herkunft.
  KaufDA-/Prospekt-`capturedAt` beim Übergang in `PriceObservation` nicht durch
  den späteren Speichermoment ersetzt wird.
- `price_observation_merge_test.dart` prüft, dass parallele append-only Reads
  keine neue Beobachtung verlieren und bei gleicher ID der geladene Upsert
  gewinnt.
- `shopping_price_quotes_test.dart` prüft, dass unsichere Marktpreise nicht als
  exakte Listenquote erscheinen, während ein alter, sicherer Bonpreis nur als
  historische Orientierung sichtbar bleibt.
- `receipt_observation_store_test.dart` prüft, dass ein laufender Belegimport
  vor einer Backup-Ersetzung abgeschlossen wird und die Ersetzung anschließend
  den vollständigen Bestand bestimmt.
- Preis- und Bonbeleg-Stores prüfen zusätzlich, dass ein paralleler Read den
  abgeschlossenen Schreibstand erhält.
- `price_history_store_test.dart` und `market_price_store_test.dart` prüfen
  denselben Read-after-write-Vertrag für Verlauf und aktuelle Marktpreise über
  getrennte Storeinstanzen; Demo-Bereinigung und Branch-Slot-Regeln bleiben in
  denselben Suites abgedeckt.
- `purchase_history_edit_test.dart` und `recent_purchase_store_safety_test.dart`
  prüfen denselben Read-after-write-Vertrag für Kaufhistorie und Wiederkäufe
  über getrennte Storeinstanzen; ID-Zusammenführung, Chronologie und die
  30-Einträge-Begrenzung bleiben dabei erhalten.
- `offer_store_safety_test.dart` prüft denselben Read-after-write-Vertrag für
  Prospekt-/KaufDA-Angebote über getrennte Storeinstanzen und bewahrt dabei
  Quellen- und Nachweisfelder.
- `product_catalog_store_test.dart` prüft denselben Read-after-write-Vertrag
  für eigene Produktstammdaten über getrennte Storeinstanzen; EAN und übrige
  Produktmetadaten bleiben erhalten.
- `budget_store_safety_test.dart` prüft denselben Read-after-write-Vertrag für
  Monatsbudget, Lebensmittelbudget und Ausgaben gemeinsam; ungültige Werte
  werden weiterhin abgewiesen.
- `mobility_settings_store_test.dart` und `price_data_settings_store_test.dart`
  prüfen denselben Read-after-write-Vertrag für Routenpräferenzen und
  abschaltbare Preisquellen; Defaults und gespeicherte Grenzwerte bleiben
  erhalten.
- `diagnostic_log_service_test.dart` prüft, dass zwei parallele lokale
  Diagnoseeinträge gemeinsam erhalten bleiben und leere Meldungen weiterhin
  ignoriert werden.
- `prospect_favorites_store_test.dart` prüft den Read-after-write-Vertrag für
  Favoriten über getrennte Storeinstanzen sowie die bestehende Sortierung und
  Dublettenbereinigung.
- `open_prices_cache_test.dart`, `product_data_cache_test.dart` und
  `prospect_feed_cache_test.dart` prüfen den Read-after-write-Vertrag der
  lokalen Open-Prices-, Open-Food-Facts- und Prospektcache über getrennte
  Instanzen; Barcode-Normalisierung und datierter Fallback bleiben abgedeckt.
- `prospect_feed_cache_test.dart` prüft zusätzlich, dass parallele
  `ProspectFeedService.load()`-Aufrufe dieselbe laufende Anfrage teilen und
  ein fehlgeschlagener Lauf einen späteren Retry freigibt.
- Der gemeinsame Operation-Scheduler prüft zusätzlich einen typisierten Read
  hinter einem laufenden Write und setzt die Queue nach Fehlern fort; dieselbe
  Reihenfolge gilt jetzt auch für Alias-, Distanz- und Routenmatrixcaches.
- `route_preferences_test.dart` prüft, dass Kosten je zusätzlichem Markt den
  Planungswert und die Auswahl beeinflussen, ohne den Zahlbetrag zu verändern;
  `mobility_settings_store_test.dart`, `mobility_finite_validation_test.dart`
  und `route_alternative_card_test.dart` sichern Persistenz, Eingabegrenze und
  die getrennte Anzeige.
- Der AppShell-Backuppfad invalidiert verspätete Start- und Prospekt-Reads per
  Datenrevision; ein echter Flutter-Widgetlauf bleibt wegen des fehlenden
  lokalen SDKs für CI vorbehalten.
- Ein KaufDA-Angebot mit Branch-ID erhält dabei exakte Confidence; ein
  gespeichertes Altangebot ohne Branch-ID bleibt im Beobachtungsadapter bei
  Confidence 0.
- Der Import- und Lernpfad prüft zusätzlich ein KaufDA-Record ohne Branch-ID,
  selbst wenn `regionalOnly` fälschlich auf `false` steht.
- `prospect_feed_cache_test.dart` prüft beim Live-Fallback zusätzlich den
  identifizierenden User-Agent des öffentlichen Feed-Abrufs.
- Der Prospekt-Suchpfad verwendet eine lazy Sliver-Liste; ungültige externe
  Bildreferenzen werden am Feed-Eingang und vor dem Kartenbild abgefangen.
- Artikelbilder in den Prospektlisten verwenden im Web den Canvas-Renderer
  ohne Plattform-View; nur die kurze Favoritenleiste und der einzelne
  Seitenviewer behalten einen begrenzten HTML-Fallback für externe CDN-Bilder.
  Das scrollende Cover-Grid erzeugt dadurch keine Plattform-Views pro Karte.
  Die Kacheln isolieren ihre Repaints. Ein echter Browser-/iPhone-
  Performance-Lauf bleibt wegen der fehlenden lokalen Flutter-Toolchain ein
  CI-/Gerätecheck.
- Ein begrenzter Lauf im veröffentlichten Web-Build hat Coverseite, fünf
  Viewer-Seiten, weiteres Scrollen und die Übernahme eines Seitenartikels in
  die Einkaufsliste geprüft. Der Test belegt nur den Webpfad; native Kamera-,
  OCR- und Offline-Abnahme bleiben separat.
- Historische Preis-Hinweise: `receipt_family_price_hint_test.dart` prüft, dass
  Bon-Mediane in der Einkaufsliste als historische Beobachtung mit Stand
  erscheinen und nicht wie ein aktuelles Angebot wirken; `shopping_suggestions_test.dart`
  prüft dasselbe für Suchvorschläge und dass vergleichbare historische Werte
  innerhalb ihrer Evidenzklasse nach Preis sortiert werden. `shopping_candidate_service_test.dart`
  schützt zusätzlich die Medianbasis der Varianten-Auswahl und schließt nicht
  vergleichbare Packungspreise aus.
- `receipt_price_statistics_test.dart` prüft zusätzlich, dass historische
  Grundpreise aus g/kg sowie cl/l vor dem Median auf kg bzw. l vereinheitlicht
  werden und gemischte Dimensionen weiterhin auf Packungspreise zurückfallen.
  Zukünftige Bonbeobachtungen bleiben auch bei einem falschen Erfassungsdatum
  aus Median, letztem Preis und Beobachtungsanzahl ausgeschlossen.
- `prospect_price_statistics_test.dart` prüft zusätzlich, dass ein abgelaufener
  Prospekt mit zukünftigem Erfassungstag keinen historischen Preis-Median
  erzeugt.
- `open_food_facts_product_discovery_test.dart` schützt die EAN-Discovery vor
  reinen Teilstring-Treffern und bekannten Variantenkonflikten.
- `receipt_ledger_test.dart` schützt zusätzlich den Inhaltsfingerprint für
  Mengen-, Einheits- und Rabattmetadaten. Zahlungszeilen und physische
  OCR-/PDF-Zeilennummern bleiben ausgeschlossen, damit harmlose
  Layoutverschiebungen weiterhin als derselbe Bon erkannt werden.
- `offer_import_test.dart`, `prospect_offer_products_test.dart` und
  `price_observation_store_test.dart` prüfen, dass Angebots-Packungsbasis und
  Grundpreis beim Import, bei der JSON-Persistenz und in regulären wie
  rabattierten Preisbeobachtungen erhalten bleiben.
- `open_prices_source_test.dart` prüft zusätzlich, dass bekannte Katalog-
  Packungsdaten beim Open-Prices-Adapter bis zum normierten Grundpreis erhalten
  bleiben.
- `offer_card_test.dart` prüft, dass die gespeicherte Basis im Angebotsdetail
  als verständlicher Grundpreis sichtbar wird.
- `route_price_resolver_test.dart`, `shopping_price_quotes_test.dart`,
  `shopping_candidate_service_test.dart` und `shopping_suggestions_test.dart`
  schützen zusätzlich davor, dass ein Angebot mit explizit falscher Packung
  als aktueller Preis ausgewählt wird.
- `offer_import_test.dart` prüft zusätzlich, dass ein regionaler KaufDA-
  Datensatz auch bei direktem Aufruf der Importauflösung kein exaktes `Offer`
  erzeugt.
- `route_price_resolver_test.dart`, `shopping_price_quotes_test.dart`,
  `shopping_candidate_service_test.dart` und `shopping_suggestions_test.dart`
  prüfen zusätzlich die rückwirkende Sperre bereits gespeicherter KaufDA-
  Angebote ohne Branch-ID.
- Dashboarddaten/Teilrouten: `shell_dashboard_test.dart` prüft, dass
  unvollständige Preisabdeckung weder Sparpotenzial noch Budgetverbrauch
  vortäuscht und dass zukünftige oder abgelaufene Angebote nicht als aktuell
  gezählt werden.
- Kaufabschluss: `receipt_completion_feedback_test.dart` prüft, dass eine
  Teilroute nicht bestätigt werden kann und fehlende Artikel sichtbar bleiben.

Bei jedem behobenen Fehler kommt ein enger Test für Ursache und Gegenbeispiel hinzu. Datenqualitätskorrekturen dürfen nicht allein anhand des erwarteten UI-Texts getestet werden: prüfe den resultierenden Preis-/Identitäts-/Routenstatus.

## Visuelle Tests

Flutter `testWidgets` ermöglicht reproduzierbare Widget- und Interaktionsregressionen. `widget_test.dart` prüft zusätzlich einen 390×844-Viewport auf Flutter-Layoutfehler; das ist ein schmaler mobiler Widget-Smoke-Test, kein iPhone-Simulatornachweis. Der aktuelle CI-Workflow führt keinen Golden-Datei-Abgleich, Screenshot-Vergleich oder nativen iOS-Build aus. Für eine konkrete Layoutänderung:

1. Widget-/Flow-Test für Zustand und Interaktion ergänzen.
2. Auf den relevanten kleinen und großen Layoutbreiten rendern und Overflow/Bedienbarkeit prüfen.
3. Golden/Screenshot nur hinzufügen, wenn Theme, Fonts, Locale, Testdaten und Flutter-Version fixiert sind und die Baseline tatsächlich visuell geprüft wurde.
4. Für iPhone-spezifische Aussagen einen realen iOS-/Simulatorlauf ausweisen; ein Web-Build allein belegt das nicht.

Keine privaten Bons, Preislisten oder Kundendaten in Goldens, Snapshots oder CI-Artefakte aufnehmen.

Die KaufDA-Fixtures prüfen zusätzlich den feldgeprüften `__NEXT_DATA__`-
Fallback bei umbenannten Ergebniscontainern und verhindern, dass ein
regionaler Datensatz Filialdaten aus der Händler-Quellenkarte erbt; ein
Legacy-KaufDA-Datensatz ohne Regionalflag bleibt ebenfalls gesperrt. Der
Angebotsbildschirm blendet ungültige externe Link-Schemata aus und öffnet nur
HTTP(S)-Ziele mit Host.
`offer_input_validation_test.dart` prüft außerdem, dass ein Produktwechsel im
Editor KaufDA-Nachweis und Filialkontext nicht auf die neue Identität überträgt.
Ein fehlerhaftes `regionalOnly: false` ohne eigene Branch-ID bleibt ebenfalls
regional und wird nicht routefähig.

Die Shell-Änderung vom 13.10.2026 verwendet eine gemeinsame lokale
Schreibwarteschlange für Backup-, Preis-, Angebots-, Katalog-, Kauf-,
Einstellungs- und Listenmutationen. Die bestehende
`sequential_write_queue_test.dart` bleibt der Regressionstest für Reihenfolge
und Fehlerfortsetzung; ein echter Flutter-Widgetlauf bleibt auf diesem Host
wegen des fehlenden SDKs offen.

Die Prospekt-Refresh-Regression prüft zusätzlich Badesalz/Medizin, Tierfutter,
Haushaltsartikel und bepflanzte Gefäße gegen Lebensmittel mit ähnlichen
Wortbestandteilen. Der versionierte Feed wird nach jedem Filterlauf auf
Lebensmittelstatus, gültige Preise und gültige Zeiträume geprüft.

Die Routen- und Filialansichten verwerfen Antworten aus einem überholten
Entfernungsabruf und setzen den Ladezustand auch bei Routing-/Cachefehlern
zurück. Ein Flutter-Widgetlauf für diese Interaktionen bleibt auf diesem Host
wegen des fehlenden SDKs offen; die OSRM-/Cache-Fehlerpfade sind in den
Service-Regressionen weiterhin ohne Live-Netzwerk testbar.

Der Belegimport prüft nach dem asynchronen Speichern erneut `mounted`, bevor
der leere Ergebnis- oder Fehlerzustand den Dialog aktualisiert. Ein echter
Widget-Lifecycle-Lauf bleibt wegen des fehlenden Flutter-SDKs offen.

Auch die Datumsdialoge im Angebotseditor und im manuellen Prospektseiten-
Editor verwerfen Antworten nach einer Navigation. Die Prüfung ist durch den
gleichen ausstehenden Flutter-Widgetlauf begrenzt.

Der Bon-Produktcallback und das Laden der Mobilitätsstrecken behandeln eine
geschlossene Ansicht bzw. einen defekten lokalen Cache ebenfalls als
Lebenszyklus-/Fallbackfall. Der echte Flutter-Widgetlauf bleibt auf diesem
Host wegen des fehlenden SDKs offen.

Die KaufDA-Parserregression enthält zusätzlich eine `__NEXT_DATA__`-Fixture
ohne `type`-Attribut. Die Daten werden nur bei exakter Script-ID und gültigem
JSON akzeptiert.

Die Shell-Angebotsmutationen laufen wie Backup, Preis- und Katalogänderungen
über die Datenrevision. Ein verspäteter Callback kann den importierten
Angebotsbestand daher nicht mehr überschreiben; der Widget-Lifecycle-Test
bleibt wegen des fehlenden Flutter-SDKs offen.

Die Strecken-Store-Regressionen prüfen zusätzlich mehrere Startadressen und
das Lesen der alten Einzel-Cacheformate. Damit bleibt der Offline-Fallback
über einen Adresswechsel hinweg erhalten; der Flutter-Lauf ist auf diesem
Host weiterhin nicht ausführbar. Die Stores warten beim Lesen außerdem auf
laufende Schreibvorgänge, damit ein paralleler Refresh keinen älteren
Zwischenstand sichtbar macht. Groß-/Kleinschreibung und Leerraum der
Startadresse werden dabei sowohl am Cache-Schlüssel als auch im gespeicherten
Inhalt normalisiert.

Die Feed- und Produkt-Discovery-Regressionen prüfen, dass deaktivierte externe
Quellen keinen Request erzeugen und ausschließlich lokale Daten verwenden.

Der automatische Prospektpreis-Lernpfad wird mit einer anonymen Fixture geprüft: Eine Zeile mit originalPrice erzeugt genau eine reguläre Beobachtung, eine offer-only Zeile erzeugt keine automatische reguläre Beobachtung. Die bestehende prospectPriceObservations-Regression bleibt zusätzlich erhalten, damit Angebots- und Normalpreis als getrennte fachliche Evidenz modelliert bleiben.
Die Shell-Regression wechselt zwischen Prospekte und Liste und prüft, dass der Suchtext im gemounteten Prospektreiter erhalten bleibt.
## Abschlussgate

- `flutter analyze` grün.
- `flutter test` grün.
- `flutter build web --release` grün.
- GitHub Flutter CI grün.
- Der separate Release-Workflow muss den Android-Release-Build ebenfalls
  erfolgreich abschließen; native Geräteabnahme bleibt davon getrennt.
- Bei Daten-/Preis-/Routenänderungen die passenden Regressionen benennen; bei UI-Änderungen die geprüften Screens/Viewport dokumentieren.
- Release-Workflow separat bewerten, falls er durch den Auftrag berührt wird.

- `price_observation_store_test.dart` simuliert ein Browser-`QuotaExceededError`, prüft die Verdichtung automatischer Preisbeobachtungen und stellt sicher, dass Bonbelege erhalten bleiben.


Die Preislern-Regression prüft zusätzlich, dass abgelaufene und zukünftige
Prospektperioden beim automatischen regulären Preisimport ignoriert werden,
während die jeweils aktive Periode mit ihrer Gültigkeit erhalten bleibt.

Die Preisquellen-Regression prüft außerdem die Projektion einer aktuell gültigen
regulären Prospektbeobachtung als Prospektpreis und stellt sicher, dass eine
Prospekt-Angebotsbeobachtung nicht als regulärer MarketPrice erscheint.

Die Prospektparser-Regression prüft zusätzlich die gemeinsame Branch-Identität
über Quelle, Prospektseite und Angebot. Groß-/Kleinschreibung und umgebender
Leerraum werden beim Vergleich toleriert; Filialwert, Ort und Adresse bleiben
als Herkunftsdaten erhalten. Eine andere oder fehlende Branch-ID darf weiterhin
kein Seitenbild oder Quellenmetadatum übernehmen.


`tool/tests/test_kaufda_prospects.py` prüft zusätzlich gemischte
Lebensmittel-Taxonomien wie `Obst__Gemuese__Pflanzen`, singuläre
`categoryPath`-Felder sowie Produktbildlisten und Mengen-Aliase. Echte
Haushalts-/Pflanzenartikel bleiben ausgeschlossen; Bild- und Kategorieangaben
werden nur aus expliziten Quellfeldern übernommen.


Die KaufDA-Regression prüft zusätzlich den neuesten Gruppenzeitpunkt: Ein
älterer Cache-Treffer vor einer späteren Live-Antwort darf den gruppierten
`capturedAt`-Wert nicht verjüngen; `cacheUsed` bleibt wahr.

Die KaufDA-Regression prüft zusätzlich verschachtelte
`validityPeriod.startDate/endDate`-Felder und Mengenobjekte mit Betrag/Einheit.
Ein Datensatz mit nur einem verschachtelten Startdatum wird als ungültig
ausgeschlossen. Der Test verwendet ausschließlich die versionierte synthetische
Fixture.

Die KaufDA-Regression deckt zusätzlich Händlerobjekte, verschachtelte
Ergebnislisten und ein bekanntes Preisobjekt mit Betrag/Währung ab. Es werden
keine Live-Anfragen ausgeführt; die vorhandene HTML-Fixture wird nur im Test
umbenannt bzw. verschachtelt.

Die Store-Regression prüft, dass ein älterer aktueller regulärer
Prospektbeleg bei einer Grenze von drei Einträgen erhalten bleibt, auch wenn
drei neuere historische Zeilen vorhanden sind. Die globale automatische
Obergrenze bleibt unverändert.

Die versionierte Kaufland-Coverregression verwendet jetzt den im Asset
gespeicherten `generatedAt`-Tag als Referenztag und prüft Start/Ende,
Coverseite und Branch-ID. Ein später aktualisiertes, weiterhin gültiges
Prospektfenster erzeugt dadurch keinen falschen CI-Fehler.


- KaufDA-Feedparser: `prospect_feed_service_test.dart` prüft jetzt auch mehrere gleichnamige Filialen mit gemeinsamer Adapterkennung. Der branchlose Datensatz behält `sourceAdapter: kaufda`, bleibt `regionalOnly` und erhält weder Filiale noch Standort.


## Prospektsuche mit vielen Treffern
Die Widgetregression 'loads additional prospect search pages on demand' prüft,
dass ein großer aktueller Feed zunächst paginiert erscheint und nach der
Nutzeraktion vollständig weitergeladen werden kann.


## Prospekt-Coverraster mit vielen Märkten
Die Widgetregression 'scrolls a larger cover grid without eagerly building every card'
lädt die nächste Coverstufe explizit und prüft anschließend das letzte Cover.

## Prospektviewer mit vielen Seiten
Die Widgetregression 'builds long prospect page lists lazily' prüft, dass ein
langer Viewer zunächst weniger Seitenbilder materialisiert, den Button „Weitere
Seiten laden“ verwendet und danach die letzte Seite erreichen kann.

## Preise-Reiter: günstigste Hinweise
Die Widgetregression 'sortiert aktuelle Preis-Hinweise nach dem günstigsten Wert'
setzt die Einkaufsliste absichtlich in teurer Reihenfolge und prüft, dass die
kompakte Hinweisleiste den günstigeren aktuellen Preis zuerst zeigt.


## Routenpreis-Resolver: Händler-Schreibvarianten

Die Regressionen in `test/route_price_resolver_test.dart` prüfen getrennt, dass eine Angebotszeile mit `ALDI SUED` an `ALDI Süd` gefunden wird und ein Marktpreis mit `LIDL` an `Lidl` gefunden wird. Beide Tests führen weiterhin eine exakte Branch-ID-Prüfung aus.


## Preis-Matrix: Händler-Schreibvarianten

Die Regressionen in `test/store_identity_test.dart` und `test/shopping_price_quotes_test.dart` prüfen den gemeinsamen Schlüssel, die Filterung eines `LIDL`-Preises über den aktivierten Markt `Lidl` und die Matrixdarstellung von `ALDI SUED` unter `ALDI Süd`.


## Branchprüfung mit Händler-Schreibvarianten

`test/branch_identity_test.dart` prüft passende `LIDL`/`Lidl`- und `ALDI SUED`/`ALDI Süd`-Labels sowie den Ausschluss einer fremden Branch-ID.


## Prospektpreis bis zur Route

`test/product_resolution_route_e2e_test.dart` prüft den vollständigen lokalen Datenfluss eines datierten regulären Prospektpreises: Persistenz, Projektion, Planpreis und filialgenaue Routenempfehlung. Die Regression erwartet den gekreuzten Normalpreis und schließt den Angebotspreis aus. Eine zweite Prüfung weist einen Preis mit fremder Branch-ID zurück.