## Update 14.10.2026 – Artikelbilder aus belegten Prospektseiten

- [x] Strukturierte Angebote können bei fehlendem Artikelbild das bereits validierte Bild derselben Prospektseite verwenden.
- [x] Store, Seitennummer und überschneidender Gültigkeitszeitraum sind Pflicht für den Fallback; alte oder uneindeutige Seiten bleiben ohne Bild.
- [x] Der Nachweis bleibt unverändert am Angebot, und eigene Quellbilder werden nie überschrieben.

## Update 14.10.2026 – Artikelübernahme bei uneindeutiger Identität

- [x] Eindeutig belegte Prospektartikel bleiben direkt hinzufügbar; uneindeutige, aber gültige Datensätze erhalten einen sichtbaren Bestätigungsdialog.
- [x] Der bestätigte Pfad übernimmt nur die exakte Quellbezeichnung als Listeneintrag und verändert keine Offer-/Routenpreisidentität.
- [x] Regional-only, fehlende Nachweise, abgelaufene und ungültige Angebote bleiben deaktiviert.

## Update 14.10.2026 – Offizielle Prospektkategorien erweitern

- [x] Unterkategorien, Abteilungen und begrenzte Kategoriepfade offizieller Quellen werden transparent übernommen.
- [x] Die Normalisierung bleibt auf benannte Präsentationsfelder beschränkt und erzeugt keine Produkt- oder Preisidentität.
- [x] Nicht-textuelle oder nur technische Kategoriewerte bleiben als sichtbare Datenlücke bestehen.

## Update 14.10.2026 – Prospekt-Evidenzfelder an der App-Grenze

- [x] Explizite Bild-, Kategorie-, Packungs- und Grundpreisvarianten werden an der Dart-Feedgrenze einheitlich und nachvollziehbar normalisiert.
- [x] Verschachtelte Quellobjekte werden nur über benannte Präsentationsfelder gelesen; fehlende Daten bleiben sichtbar und werden nicht geraten.
- [x] Der bestehende Filial-, Gültigkeits-, Nachweis- und Lebensmittel-Filter bleibt vor jeder Anzeige und Preisprojektion aktiv.

## Update 14.10.2026 – Prospektpreise beim App-Fortsetzen aktualisieren
- [x] Beim Fortsetzen der App wird ein validierter Prospektstand älter als sechs Stunden automatisch im Hintergrund aktualisiert.
- [x] Der aktuelle Einkauf, die Route und die Prospektansicht bleiben während des Abrufs bedienbar; der lokale Cache wird sofort weiterverwendet.
- [x] Die Prüfung ist timestamp-basiert, begrenzt doppelte Resume-Ereignisse und erzeugt keine zusätzliche dauerhafte Datenquelle.
- [x] Während die App aktiv bleibt, plant sie höchstens einen sechsstündigen Refresh; bei Pause wird der Timer beendet.

## Update 13.10.2026 – Coverraster progressiv laden
- [x] Große Prospekt-Coverlisten im Angebote-Reiter zunächst seitenweise rendern und weitere Karten ausdrücklich nachladen lassen.
- [x] Den bestehenden Detailviewer, die Quellenbelege und die aktuelle Gültigkeitsprüfung unverändert weiterverwenden.

## Update 13.10.2026 – Prospekt-Cover-Scroll stabilisieren
- [x] Coverkarten im Überblick auf Canvas-only umstellen, damit Flutter Web beim schnellen Scrollen keine Plattform-Views pro CDN-Bild anlegt.
- [x] Detailviewer-Fallback für einzelne Bilder und Test für die Renderer-Grenze beibehalten.

## Update 13.10.2026 – Shell-Routing-Snapshot
- [x] Dashboard, Kaufabschluss und Seitensammlung teilen je Build einen
  aktuellen und regulären RouteOptimizer für identische Eingaben.
- [x] Wiederholte Preis-/Alternativenaufbereitung wird damit aus demselben
  Build entfernt; ein neuer Datenstand erzeugt bewusst einen neuen Snapshot.

## Update 14.10.2026 – OSRM-Fahrzeitmatrix für Planung

- [x] OSRM-Tabellenantworten können neben Entfernungen auch explizite Fahrzeiten übernehmen.
- [x] Alte lokale Matrizen ohne Fahrzeiten bleiben lesbar und fallen deterministisch auf die konfigurierte Mobilitätsgeschwindigkeit zurück.
- [x] Zeitwert, TravelEstimate und Routenzusammenfassung verwenden die Fahrzeit nur bei vollständiger, gültiger Rundtour-Evidenz.

# SparzamApp – Roadmap

Diese Roadmap ist eine Prioritätenliste, kein starres Releaseversprechen.

## Phase A – Solide Datengrundlage
- Bon-Parsing stabilisieren.
- Stück-, Gewichts- und Grundpreise korrekt unterscheiden.
- Produktvarianten zuverlässig auseinanderhalten.
- Nutzerkorrekturen sicher speichern.
Status: weit fortgeschritten, weitere reale Bons dienen als Praxistest.

## Phase B – Lernende Preisdatenbank
- Gemeinsame append-only Preisbeobachtungen für bestehende Quellen speichern; aktuelle Marktpreise als Projektion ableiten, ohne Historie zu verlieren.
- Provider/Adapter schrittweise anschließen: Bon, manuell, Open Prices, Angebote, später geprüfte Händlerdaten und Regalbilder; keine produktbezogene Sonderlogik.
- Confidence aus Herkunft und Alter getrennt modellieren und fehlende Preise als Unsicherheitsbereich behandeln; knappe Routenentscheidungen kennzeichnen.
- [x] Datenlücken-Relevanz aus fehlender Marktdeckung, Menge, bestätigter Kaufhäufigkeit und belastbarer Historie für häufige, teure und entscheidungsrelevante Einkaufspositionen priorisieren; die Beleganforderung bleibt UI-gesteuert.
- Produktidentität von Preisbeobachtungen trennen.
- Frische Tomatenvarianten im Basiskatalog getrennt von verarbeiteten
  Tomatenprodukten anbieten.
- Händler-/Bon-Aliase lernen.
- Confidence für automatische Zuordnungen.
- Wiederkehrende Käufe bevorzugt erkennen.
- Korrekturen des Nutzers als Lernsignal verwenden.
- Preisverlauf pro Produkt/Markt.

## Update 09.10.2026 – Datenlücken-Relevanz abgeschlossen
- Der deterministische Datenlücken-Score ist implementiert und wird vor den
  einzelnen Tie-Breakern angewendet. Dadurch kann eine Position mit größerer
  bekannter Auswirkung eine nur häufige, aber kleinere Lücke überholen.
- Der Score bleibt ein Priorisierungsindex. Er erzeugt keinen Preis, verlängert
  keine Angebotsgültigkeit und wird nicht als direkte Routenbasis verwendet.
- PR #163 und der nachgelagerte Main-/Release-Check sind in
  `docs/PROJECT_STATUS.md` dokumentiert.

## Phase C – Angebote intelligent einbeziehen
- Angebote zeitlich begrenzen.
- Normalpreis und Angebotspreis getrennt halten.
- Effektivpreise korrekt vergleichen.
- Einkaufsliste gegen aktuelle Angebote prüfen.
- Keine künstlichen Produktduplikate durch Angebote erzeugen.
- [x] Sichtbare Rubrik „Angebote“ zunächst ausschließlich auf den aktuellen
  Prospektfeed und gültige Prospektzeiträume begrenzen.
- [x] Den zuletzt validierten öffentlichen Prospektfeed bei vorübergehendem
  Offline-Abruf als datierten Fallback nutzen, ohne abgelaufene Angebote zu
  reaktivieren.
- [x] Einen validierten lokalen Cache-/Bundle-Stand beim Shell-Kaltstart vor dem Netzwerkabruf anzeigen und anschließend im Hintergrund aktualisieren.
- [x] Den versionierten öffentlichen Feed auch beim Kaltstart ohne Netzwerk und
  ohne lokalen Cache als App-Asset laden; der Stand bleibt als nicht-live
  gekennzeichnet und wird weiterhin auf Angebotsgültigkeit geprüft.
- [x] Bei einem vollständigen Refresh-Ausfall den ursprünglichen
  `generatedAt`-Zeitpunkt erhalten, damit Fallback-Daten nicht künstlich frisch
  erscheinen.
- [x] Artikelbilder in großen Prospektlisten im Web strikt im Canvas rendern;
  die wenigen Cover- und Viewerbilder dürfen bei einem Bild-/CORS-Problem auf
  HTML-Plattform-Views zurückfallen. Dadurch bleibt der große Scrollpfad ohne
  unnötige Plattform-Views.
- [x] Non-Food-Kampagnenartikel an Refresh- und App-Grenze aus dem aktuellen
  Angebotsbestand ausschließen, ohne Lebensmittelbegriffe mit ähnlichen
  Wortteilen zu verlieren.
- [x] Die sichtbare Quellenabdeckung nach dem Filter zählen und abweichende
  Provider-Rohmengen separat als `rawRecordCount` erhalten.
- [x] Eine verifizierte Coverseite des Netto-Filialprospekts im Offline-Stand
  mit Zeitraum, Seite und exakter Filiale anzeigen.
- [ ] Prospektfeed weiter auf vollständige Artikelbilder, Kategorien,
  Filialbezug und belastbare Gültigkeit ausbauen.
- [x] Konkrete Produktzuordnung in Such-, Seiten- und erweiterten
  Händler-/Kategoriegruppen je sichtbarem Angebotsdatensatz memoisiert, damit
  große Prospekte und der Angebote-Reiter keine wiederholte
  Identitätsauflösung ausführen.
- [x] Feednormalisierung, Kategorien und sichtbare Filialkarten zwischen
  Suche-/Favoriten-Rebuilds wiederverwenden, solange der Eingabesnapshot gleich
  bleibt.
- [x] Bildseiten ermöglichen eine geprüfte manuelle Artikelübernahme mit
  Seitenlink, Preis, Gültigkeitsende und bestehender Filialprovenienz.

## Phase D – Alltagstaugliche Datenerfassung
- Kassenbons möglichst automatisch.
- [x] JPG/PNG- und Kamera-Bons auf Android/iOS lokal per OCR lesen und in den bestehenden Bonreview führen.
- [x] Bildbasierte PDFs ohne Textebene auf Android/iOS lokal rendern und über den geprüften OCR-/Review-Pfad verarbeiten.
- Barcode als sichere Produktidentität nutzen.
- Open Prices/Open Food Facts sinnvoll ergänzen.
- Regalvideo-Erfassung evaluieren: Lesbarkeit von Preisschildern, Produktbezug, Dubletten, Aufwand und Datenschutz.
- Erst nach erfolgreicher Evaluation Video-Pipeline implementieren.

## Phase E – Intelligente Einkaufsplanung
- Persönliche Wiederkaufrhythmen.
- Preisniveau und typische Preise lernen.
- [x] Sparpotenzial je Einkauf aus aktuell belegten Angeboten und dem vollständigen Routenvergleich.
- Für jede Einkaufsposition belastbare Preise je Markt zusammenführen und hinsichtlich Aktualität/Herkunft/Confidence bewerten.
- Ein-Markt-Strategien und sinnvolle Kombinationen aus mehreren Märkten für den gesamten Warenkorb vergleichen.
- Markt-/Routenoptimierung unter Berücksichtigung des tatsächlichen Mehrwegs und der daraus entstehenden Fahrtkosten.
- Persönlichen Zeitwert optional monetarisieren, ohne ihn mit tatsächlichen
  Kassen- oder Fahrtkosten zu vermischen.
- Fehlende Preisbelege direkt aus der Routen-Datenlücke zur bestehenden
  Marktpreis-Eingabe führen, ohne historische Werte zu bestätigen.
- Routenempfehlung erklärt vollständige Preisabdeckung gegenüber einer unvollständigen Einzelmarkt-Teilroute.
- Einen zusätzlichen Markt nur wählen, wenn die Ersparnis des gesamten Teilwarenkorbs den zusätzlichen Aufwand wirtschaftlich rechtfertigt.
- Primäres Ergebnis: konkrete Empfehlung der wirtschaftlichsten Einkaufsstrategie (z. B. nur Lidl, Lidl + Aldi oder nur Kaufland), nicht bloß eine Liste billiger Einzelpreise.
- Vorschläge nur dann, wenn sie praktisch relevant sind.

## Phase F – Synchronisierung / Mehrbenutzer
- Freiwillige Übermittlung geeigneter eigener Beobachtungen an Open Prices und später Community-Daten nur mit expliziter Freigabe und bereinigten Belegen.
- Backend/Account-Konzept.
- Cloud-Backup.
- Geräteübergreifende Synchronisierung.
- Optional gemeinsames Einkaufen/Listenfreigabe.

## Dauerhafte Qualitätsziele
- Kleine Module.
- Nachvollziehbare Datenherkunft.
- Keine automatischen Zuordnungen bei zu geringer Sicherheit.
- Reale Nutzbarkeit wichtiger als theoretisch maximale Automatisierung.
- Jede Phase in kleinen, testbaren GitHub-Commits umsetzen.

- [x] Gespeicherte exakte Preisbeobachtungshistorie als Eingang der bestehenden Marktpreis-/Routenprojektion verwenden, statt nur den zuletzt projizierten Marktpreis zu sehen.

- [x] Bonbeobachtungen in die gemeinsame Preisbeobachtungshistorie adaptieren, ohne Familienmatches als exakte Produktidentität auszugeben.
- [x] Angebote mit Gültigkeit in die gemeinsame Preisbeobachtungshistorie adaptieren und abgelaufene Angebote aus der exakten Routenprojektion ausschließen.
- [x] Packungs-/Mengengleichheit und Variantenvergleichbarkeit werden zentral vor dem Preisranking geprüft.


## WORK QUEUE

Work wird nur für Aufgaben eingesetzt, bei denen eine längere, selbstständige Arbeitskette einen klaren Vorteil gegenüber kleinen Änderungen im Projektchat hat. Bereits erledigte Pakete werden nicht erneut bearbeitet, außer ein konkreter Fehler erfordert es.

| Status | Aufgabe | Warum Work | Startvoraussetzung |
| --- | --- | --- | --- |
| DONE | End-to-End-Audit der Preis- und Routenlogik | Identitäts-Bypässe, Projektion und Preis-/Routenfluss repo-weit geprüft; belegte Fehler mit Regressionen geschlossen | abgeschlossen 25.09.2026 |
| WAITING | Reale Preisdatenquellen und Provider-Adapter | Recherche, Quellenprüfung, Mapping, Implementierung und Validierung als zusammenhängender Arbeitslauf | Beobachtungs-/Confidence-Schnittstellen stabil |
| WAITING | Migration auf PriceObservation als direkte Planungsbasis | Größeres Refactoring über Stores, Route und UI mit Rückbau von Übergangsschnittstellen | PriceObservation deckt Bon, Angebot, fehlende Preise und Vergleichbarkeit ab |
| WAITING | Meilenstein-Qualitätssicherung | App-/Repo-weite Tests, CI, Datenflussprüfung, Fehlerbehebung und Dokumentationsabgleich | vor dem nächsten größeren Produktmeilenstein |

### Work-Regel
- Projektchat: kleine klar abgegrenzte Pakete, Architekturentscheidungen, gezielte Implementierung, Tests, Commits und CI-Kontrolle.
- Work: nur freigegebene Einträge dieser Queue; keine eigenständige Wiederholung bereits abgeschlossener Pakete.
- Ein Queue-Eintrag wechselt erst auf READY, wenn seine Startvoraussetzung erfüllt ist.
- Nach Work-Abschluss: Status/Dokumentation aktualisieren, CI grün herstellen und nächsten Queue-Status eindeutig festhalten.

## Update 24.09.2026 – Vergleichbarkeitspaket abgeschlossen
- [x] Mengen-/Einheitennormalisierung für g/kg, ml/l und Stück.
- [x] Exakte Packungsabweichungen vor der Routenprojektion blockieren.
- [x] Familienpreise nur mit sicherer Mengenbasis normalisieren.
- [x] Generische Familienwünsche von konkreten Geschwistervarianten trennen.
- [x] Open-Prices-Sync auf aktuelle Einkaufsnachfrage begrenzen.
- [x] Fehlende EAN konservativ über Open Food Facts entdecken, ohne Discovery als bestätigte Identität auszugeben.
- [x] Automatische Bon-Vorschläge nicht als bestätigte exakte Produktidentität speichern.

### WORK QUEUE Statusänderung
Die Startvoraussetzung „Mengen-/Packungs-/Variantenvergleich abgeschlossen“ ist erfüllt. Der Eintrag **End-to-End-Audit der Preis- und Routenlogik** ist damit **READY**. Beim nächsten Work-Lauf soll dieser Audit als erstes freigegebenes Paket bearbeitet werden. Die übrigen Einträge bleiben WAITING, bis ihre jeweiligen Voraussetzungen erfüllt sind.


## Update 25.09.2026 – End-to-End-Audit abgeschlossen
- Der Audit des Datenflusses `ReceiptObservation → PriceObservation → MarketPrice → planningMarketPrices → RoutePriceResolver → RouteOptimizer` ist für die aktuell vorhandenen, belegten Daten abgeschlossen.
- Identitäts-Bypässe aus automatischen Bonzuordnungen wurden geschlossen; unbestätigte automatische Identitäten dürfen nicht als exakte Routenpreise auftreten.
- Ein im Audit verbliebener Projektionsfehler wurde behoben: mehrere exakte Beobachtungen derselben Produkt×Markt-Kombination werden vor der Route nicht mehr blind auf den neuesten Zeitstempel reduziert. Die Auswahl verwendet jetzt zentral denselben qualitätsbereinigten Preiswert wie der Route-Resolver.
- Die vollständige Sieben-Bon-Matrix bleibt separat offen, weil zwei im UI sichtbare Originalbelege weiterhin nicht als Quelldatei vorliegen. Dieser Datenblocker wird nicht durch erfundene Parserannahmen umgangen.
- Nächster Featureblock nach nachweislich grüner CI: hierarchische Produkt-/Suchauflösung sowie weitere Absicherung von Quellpriorität und Angebot/Normalpreis.


## Update 25.09.2026 – Suchhierarchie und Angebotsnachweis
- [x] Familie/Variante in der Einkaufssuche sichtbar machen.
- [x] Verwandte Interpretationen getrennt von identitätskompatiblen Treffern anzeigen; Referenzfall „Tomate“.
- [x] Häufige Grundbedarfs- und Grundvorratsfamilien mit getrennten Varianten in den Basiskatalog aufnehmen.
- [x] Häufige Bonabkürzungen und Händlerpräfixe über die zentrale Identität auffindbar machen; unklare Codes bleiben im Review.
- [x] Externe Angebotsimporte ohne belastbaren Nachweis von exakter Preisprojektion ausschließen.
- [x] Ausgewiesenen Normalpreis eines belegten Angebots als getrennte reguläre Preisbeobachtung erhalten.
- [ ] Hierarchie über weitere Produktfamilien systematisch ausbauen; die vollständige Katalogmigration bleibt offen.
- [x] Scanner- und manuelle EAN-Eingaben werden ohne Identitätsraten
  normalisiert; UPC-A und getrennte Eingabeformatierung bleiben exakt
  vergleichbar.
- [ ] Angebotsquellen automatisiert aus realen Prospekten/Bildern einspeisen und Gültigkeit/Filialbezug prüfen.


## Update 29.09.2026 – Bring-Hotspotadapter
- [x] Share-Link-Struktur für die sechs Zielhändler analysiert; feste Prospekt-BRN von dauerhaftem „aktuell“-Abruf getrennt.
- [x] Optionalen standortbezogenen Bring-Adapter für aktuelle Prospektseiten, strukturierte Produkt-Hotspots, Bilder, Angebots- und Normalpreise implementiert.
- [x] Bring-Angebote laufen mit Gültigkeit und Nachweis durch den bestehenden Angebots-/PriceObservation-Vertrag.
- [ ] Live-Abruf in GitHub aktivieren, sobald die drei Bring-Zugangsdaten als Repository-Secrets hinterlegt sind; bis dahin bleiben die offiziellen Händleradapter führend.
- [x] Bild-only-Prospektseiten können lokale OCR-Vorschläge mit Confidence anzeigen; bei mehreren Treffern wählt der Nutzer eine Zeile, bevor sie ausschließlich über das bestehende Nutzer-Review in ein manuelles Angebot überführt wird.

## Update 01.10.2026 – Preisabdeckung direkt in der Einkaufsliste
- [x] Das Preisfenster zeigt für jeden aktivierten Markt eine eigene Zeile.
- [x] Aktive Angebote werden je Markt vor Bon- und eigenen Preisbelegen gewählt;
  Märkte ohne exakte Evidenz bleiben als fehlend sichtbar.
- [x] Bei leerer Marktauswahl werden die sechs konfigurierten Projektmärkte
  dargestellt. Die Anzeige erzeugt keinen geschätzten Preis und verändert nicht
  die verbindliche Routenzuordnung.

## Update 01.10.2026 – Historische Prospektorientierung je Markt
- [x] Gelernte Prospekt-Mediane werden in der Einkaufsliste je Markt als
  historische Orientierung gezeigt, wenn ein aktueller Preisbeleg fehlt.
- [x] Aktuelle Angebote und aktuelle Marktpreise haben Vorrang; historische
  Prospektwerte bleiben aus aktueller Preisabdeckung und Routenplanung heraus.
- [x] Preisstand und historische Kennzeichnung sind im Preisfenster sichtbar
  und durch Fach-/Widgettests abgesichert.

## Update 01.10.2026 – Prospekt-Historie als Detailansicht
- [x] Die Einkaufsliste bietet pro Produkt eine optionale Detailansicht der
  abgeschlossenen Prospektbeobachtungen je Markt.
- [x] Median, Beobachtungsanzahl, Quellart und letztes Gültigkeitsende bleiben
  in der Historie nachvollziehbar.
- [x] Die Detailansicht ist erklärend; historische Werte werden nicht in die
  aktuelle Preisabdeckung oder Routenplanung übernommen.

## Update 01.10.2026 – Neue Prospektartikel aus dem Angebotstab
- [x] Aktuelle, nachgewiesene Prospektlabels ohne Katalogidentität können aus
  dem Angebotstab zur Einkaufsliste übernommen werden.
- [x] Der Fallback bleibt an das exakte Händlerlabel gebunden und erfindet
  weder Variante noch Alias; Preis- und Quellenbeleg bleiben am Prospektfluss.
- [x] Der sichtbare Add-to-List-Flow ist als Widget-Regression abgesichert.
- [x] Der Fallback bleibt bei fehlendem Nachweis oder mehrdeutiger Identität
  gesperrt.

## Update 01.10.2026 – Vorauswahl der belegten Spar-Variante
- [x] Generische Wünsche wählen im Variantenfenster die erste aktuell belegte
  Spar-Variante vor.
- [x] Historische Prospektwerte bleiben Hinweise und lösen keine stille
  Produktwahl aus.
- [x] Die Empfehlung bleibt manuell änderbar und ist im Übernahme-Flow
  getestet.

## Update 01.10.2026 – Deterministische Routen-Gleichstände
- [x] Gleiche Preisabdeckung und gleiche Planungswerte werden über weniger
  Märkte und danach kanonische Marktnamen stabil aufgelöst.
- [x] Eine Regression prüft den Gleichstand zwischen EDEKA und Lidl und schützt
  die Auswahl vor einer zufälligen Quellreihenfolge.

## Update 01.10.2026 – Mehrmarkt-End-to-End-Fixture
- [x] Ein versionierter Warenkorb wird gegen vollständige 1-, 2- und
  3-Markt-Kombinationen verglichen.
- [x] Die Fixture prüft die gemeinsame Warenkorbepreisung, Rundfahrtkosten und
  den Wechsel zurück zum Einzelmarkt bei hohen Fahrtkosten.

## Update 01.10.2026 – Händleranzahl konsistent halten
- [x] Profil, Marktfilter und Route verwenden dieselbe konfigurierte
  Händlerliste; die leere Auswahl zählt die sechs Projektmärkte.

## Update 01.10.2026 – Teilwarenkörbe in der Marktansicht kennzeichnen
- [x] Unbepreiste oder nur geschätzte Listenpositionen werden in der
  Markt-Detailansicht als Datenlücke aufgelistet.
- [x] Warenkorb-, Ersparnis- und Fahrtkostenwerte werden bei Lücken als
  Teilwarenkorb bezeichnet; eine vollständige Markt-Empfehlung bleibt aus.
- [x] Regressionen decken Datenmodell, Empfehlungsstatus und sichtbare UI-Warnung
  ab.

## Update 01.10.2026 – Dashboard vor Teilrouten schützen
- [x] Das Dashboard zeigt eine unvollständige Route ausdrücklich als vorläufige
  Teilroute und verlinkt zur Preisabdeckung.
- [x] Teilkosten werden nicht als Sparpotenzial behauptet und nicht in die
  Budgetplanung übernommen.
- [x] Daten- und Widgettests decken die Teilroute ab.

## Update 01.10.2026 – Kaufabschluss gegen Teilrouten absichern
- [x] Eine Teilroute kann nicht als vollständiger Einkauf bestätigt werden.
- [x] Fehlende Artikel und die vorläufige Ersparnis werden im Abschluss sichtbar
  genannt.
- [x] Der App-Handler blockiert Teilrouten auch außerhalb der UI.

## Update 01.10.2026 – Sparroute direkt aus der Einkaufsliste
- [x] Eine gefüllte Einkaufsliste zeigt jetzt direkt die Aktion „Sparroute
  prüfen“.
- [x] Der Einstieg führt dieselbe aktuelle Liste in die vorhandene
  Routenberechnung, damit Angebote, Marktpreise, Datenlücken und Fahrtkosten
  ohne Umweg gemeinsam bewertet werden.
- [x] Der sichtbare Klickpfad ist als Widgetregression abgesichert; bei einer
  leeren Liste oder ohne Route-Callback erscheint die Aktion nicht.

## Update 01.10.2026 – Prospektquellen zeigen den konkreten Markt
- [x] Alle sechs offiziellen Prospektquellen tragen jetzt die konfigurierte
  Filial-ID, den Ort und die Adresse im Feed-Metadatenblock.
- [x] Die Prospektkarten und die Prospektdetailansicht zeigen den Ort, damit
  ein Angebot eindeutig als Zellingen, Thüngersheim oder Würzburg erkennbar
  bleibt.
- [x] Parser- und Widgetregressionen sichern die vollständige Zuordnung der
  sechs Quellen; Artikelbilder, Kategorien und OCR für bild-only Seiten bleiben
  weiterhin getrennte offene Ausbaustufen.

## Update 01.10.2026 – OCR-Geldtokens robust gegen Nullverwechslung
- [x] Der Bon-Parser erkennt die häufige OCR-Verwechslung `@` für `0` in
  Geldbeträgen und normalisiert sie nur innerhalb des Geldtokens.
- [x] Negative Rabatte, Stückpreise und Zeilenbeträge bleiben dabei derselben
  Quellen- und Mengenprüfung unterworfen.
- [ ] Vollständige Bild-OCR, Produktidentität und Geräteakzeptanz bleiben
  separate offene Ausbaustufen; ungeklärte Mengen- oder Bilanzabweichungen
  werden weiterhin zur Nutzerprüfung vorgelegt.

## Update 01.10.2026 – Prospektfeed-Frische sichtbar
- [x] Angebote und Prospekte zeigen den Zeitstempel des geladenen Feeds.
- [x] Offline-Fallback wird als letzter geprüfter Stand gekennzeichnet, ohne
  abgelaufene Angebote wieder gültig zu machen.
- [ ] Artikelbilder, Kategorien, bild-only OCR und Geräteakzeptanz bleiben
  separate Ausbaustufen für die vollständige Prospektabdeckung.

## Update 01.10.2026 – Händlerkategorien als Quellenmetadatum
- [x] Explizite Kategorien strukturierter Händlerantworten werden im Feed
  erhalten und in Angebote/Prospekte für Gruppierung und Suche verwendet.
- [x] Fehlt eine Kategorie, bleibt die bestehende sichtbare Fallback-Kategorie
  aktiv; Identität und Preise werden dadurch nicht verändert.
- [ ] Vollständige Artikelbilder, Kategorieabdeckung in jedem Live-Feed,
  bild-only OCR und Geräteakzeptanz bleiben offene Datenqualitätsstufen.

## Update 01.10.2026 – Händlerkategorien lesbar gruppieren
- [x] Technische Nummern- und Slugwerte der Händlerquellen werden in eine
  einheitliche UI-Darstellung normalisiert.
- [x] Die Rohkategorie bleibt als Quellenmetadatum erhalten; die Darstellung
  greift nicht in Identität, Preis, Gültigkeit oder Route ein.
- [ ] Fehlende Kategorien in ALDI-, EDEKA- und Netto-Live-Antworten werden erst
  ergänzt, wenn die Händlerquelle sie belastbar liefert; UI-Klassifikation
  ersetzt keine Quellenangabe.

## Update 01.10.2026 – Netto-Labels auf verwertbare Produkte begrenzen
- [x] Offensichtliche Netto-Platzhalter und reine Rabatt-/Herkunftszeilen
  werden vor der Feed-Erzeugung verworfen.
- [x] Gültige Produktlabels bleiben in Kachel-, Link- und Text-Fallbacks
  erhalten; ein Regressionstest deckt die Abgrenzung ab.
- [ ] Die Netto-Quelle muss weiterhin belastbare Produktdaten und Bilder
  liefern, bevor die fehlenden aktuellen Angebote wieder ergänzt werden
  können. Der Adapter erfindet diese Daten nicht.
- [x] Der Bestands-Fallback entfernt dieselben unvollständigen Labels, wenn
  die offizielle Netto-Seite vorübergehend nicht auslesbar ist.

## Update 01.10.2026 – Angebotsquellen transparent ausweisen
- [x] Märkte ohne aktuelle Angebotsdatensätze bleiben im Tab „Angebote“ mit
  Händler- und Filialstatus sichtbar.
- [x] Abruffehler, fehlende strukturierte Produktdaten und ein leerer aktueller
  Angebotszeitraum werden getrennt benannt; kein Status erzeugt einen Preis.
- [ ] Belastbare Netto-Produktdaten und Bilder bleiben eine Quellaufgabe und
  werden erst bei nachweisbarer Händlerantwort wieder als Angebote angezeigt.
- [x] Der Status führt direkt zum offiziellen Händlerprospekt, ohne die
  fehlende Quelle durch einen Preis zu ersetzen.

## Update 01.10.2026 – Netto-Reader-Fallback
- [x] Der offizielle öffentliche Reader-Fallback liest Netto-Markdown-Kacheln
  mit Produktlink, Preis, Packung, Bild und Gültigkeitsende.
- [x] Die sechs konfigurierten Märkte liefern wieder einen sichtbaren
  Quellenstatus; Netto-Angebote werden nur mit ihrem offiziellen Nachweis und
  eigenem Gültigkeitsfenster übernommen.
- [x] Parserregressionen sichern den Fallback gegen reine Rabatt-/Sorten- und
  Herkunftsplatzhalter ab.

## Update 01.10.2026 – Aktive Fallbackangebote kenntlich machen
- [x] Gültige Bestandsangebote eines vorübergehend nicht erreichbaren
  Händlerfeeds bleiben sichtbar, solange ihr eigenes Angebotsfenster gilt.
- [x] Der Angebotstab kennzeichnet diesen Stand als letzten geprüften
  Prospekt und zeigt die fehlende automatische Aktualisierung ohne Preis- oder
  Identitätserfindung.
- [ ] Die Händlerquelle muss weiterhin regelmäßig erfolgreich aktualisieren,
  damit der Hinweis wieder in einen frischen Live-Status übergeht.

## Update 02.10.2026 – Fallback-Provenienz in Angebote und Prospekte
- [x] Beide Prospektansichten kennzeichnen gültige Bestandsangebote eines
  fehlgeschlagenen Händlerabrufs als letzten geprüften Prospektstand.
- [x] Die Prospektkarte zeigt dabei die Anzahl der gültigen Datensätze; die
  Detailansicht bleibt preisfrei und verweist auf die fehlende Aktualisierung.
- [x] Karten- und Detailpfad sind als Widgetregression abgesichert.

## Update 02.10.2026 – Sparorientierte Reihenfolge verwandter Varianten
- [x] Verwandte Interpretationen werden nach aktueller Angebots-/Preisevidenz
  und danach nach dem belastbaren Preis sortiert.
- [x] Unbelegte Varianten bleiben sichtbar und als Interpretation getrennt;
  die Sortierung erweitert keine Preisidentität.
- [x] Der offene `K.H-Milch`-Fall ist mit einer Preisrangfolge-Regression
  abgesichert.

## Update 02.10.2026 – Normale Milch aus unklaren Bonkürzeln auswählbar
- [x] `K.H-Milch` öffnet neben getrennten H-Milch-Fettstufen auch eindeutig
  normale Milchprodukte für den Preisvergleich.
- [x] Aktuelle Angebote für normale Milch werden im Such- und Kandidatenpfad
  zuerst berücksichtigt, ohne Produktidentitäten oder Preise zu verschmelzen.
- [x] Regressionen sichern beide Auswahlpfade und den bestehenden Schutz vor
  unbestätigten Varianten ab.

## Update 11.10.2026 – Prospektkategorien direkt durchsuchbar
- [x] Aktuelle Prospektartikel können zusätzlich zur Volltextsuche über ihre
  vorhandene Händler- oder Darstellungskategorie gefiltert werden.
- [x] Der Kategorienfilter bleibt reine Navigation: Herkunft, Gültigkeit,
  Produktidentität und sichere Add-to-List-Auflösung werden nicht verändert.
- [x] Widgetregression prüft die Auswahl einer Kategorie über mehrere Märkte.

## Update 11.10.2026 – Originalnachweis an jeder belegten Artikelkarte
- [x] Belegte kompakte und große Prospektkarten öffnen ihren vorhandenen
  HTTP(S)-Originalnachweis direkt aus der Artikelansicht.
- [x] Fehlende oder ungültige Nachweise erzeugen keinen Link und bleiben nach
  den bestehenden Identitätsregeln nicht auswählbar.
- [x] Widgetregression prüft die sichtbare Nachweisaktion und den Review-Fall.

## Update 11.10.2026 – Filialort in Suchtreffern
- [x] Marktübergreifende Prospektartikel zeigen den vorhandenen Filialort direkt
  unter dem Händlernamen.
- [x] Fehlende Filialdaten bleiben leer; es werden keine Standorte aus Labels
  oder Händlerähnlichkeiten erfunden.
- [x] Widgetregression deckt den sichtbaren Ort im Trefferpfad ab.

## Update 11.10.2026 – Prospektartikel nach Händler auswählen
- [x] Die Prospektansicht bietet Händlerchips für die direkte Marktfilterung.
- [x] Die Filterung nutzt nur aktuell gültige Datensätze und den bestehenden
  Nachweis-/Identitätsvertrag; sie erzeugt keinen Preis oder Marktbezug.
- [x] Widgetregression prüft die Auswahl eines Händlers gegenüber einem zweiten
  Markt.

## Update 11.10.2026 – Offizielle Prospektlinks validieren
- [x] Der offizielle Händlerlink im Prospektreader wird vor dem Öffnen auf ein
  gültiges HTTP(S)-Ziel mit Host geprüft.
- [x] Ungültige URI-Schemes bleiben ohne externe Aktion; Prospektdaten und
  Angebotsidentität werden dadurch nicht verändert.

## Update 11.10.2026 – Angebotsnachweise in der Abdeckung ausweisen
- [x] Die Abdeckungskarte zählt pro Markt die strukturierten Angebotsdatensätze
  mit vorhandenem Originalnachweis.
- [x] Fehlende Nachweise bleiben als sichtbare Datenlücke bestehen und werden
  weder durch einen Händlerlink noch durch eine Preis- oder Identitätsannahme
  ersetzt.
- [x] Ungültige URI-Schemes oder URLs ohne Host werden nicht als belastbarer
  Originalnachweis gezählt.


## Update 13.10.2026 – Preisvergleich für lange Listen
- [x] Preisvergleichskarten im Preise-Reiter werden in kleinen Seiten aufgebaut, damit lange Einkaufslisten nicht beim ersten Öffnen alle Detailkarten rendern.
- [x] Die bestehende Preisabdeckung bleibt vollständig; nur die sichtbare Vergleichsliste wird schrittweise erweitert.
- [x] Der Nachladepfad ist widgetgetestet und ändert keine Preis-, Angebots- oder Routenlogik.


## Update 13.10.2026 – Fehlende Preisbelege schneller erfassen
- [x] Der Preise-Reiter führt fehlende Marktpreise je Listenposition direkt in die bestehende Datenlückenauflösung.
- [x] Produkt-/Preiswahl, Quellenprüfung und Speicherung bleiben im vorhandenen `openPriceGapEditor`-Pfad gebündelt.
- [x] Die neue Aktion erzeugt keine Ersatzpreise und ändert keine Routenentscheidung ohne bestätigte Evidenz.


## Update 13.10.2026 – Route-Rebuilds beschleunigen
- [x] Der Route-Reiter cached den Optimierungs-Snapshot über stabile Eingabereferenzen und invalidiert bei Daten- oder Tageswechsel.
- [x] Preisabdeckung, Mindestvorteil, Fahrtkosten und Marktanzahl werden weiterhin ausschließlich vom bestehenden `RouteOptimizer` berechnet.
- [x] Der Performance-Block ändert keine Preisquelle und führt keine zusätzlichen Netzwerkanfragen ein.


## Update 14.10.2026 – Lange Einkaufslisten beschleunigen
- [x] Warengruppen werden im Einkaufsliste-Reiter seitenweise aufgebaut; zusätzliche Gruppen bleiben über „Weitere Warengruppen laden“ erreichbar.
- [x] Der bestehende Preis-, Angebots- und Kaufaktionsfluss wird unverändert an jede Gruppe weitergegeben.
- [x] Die neue Begrenzung ist lokal und reversibel und erzeugt keine zusätzlichen Datenabrufe.


## Update 14.10.2026 – Bestätigte Normalpreisspeicherung in den Prospektansichten
- [x] Der Angebotstab verwendet für den Hinweis „als Preisbasis gespeichert“ ausschließlich die vom lokalen Preisbeobachtungslauf bestätigte Anzahl.
- [x] Ein fehlgeschlagener oder noch nicht abgeschlossener Speichervorgang erzeugt keinen falschen Bestätigungsstatus, obwohl der Feed einen ausdrücklich ausgewiesenen Normalpreis enthält.
- [x] Die Standalone-Ansicht behält ihren konservativen Feed-Fallback, wenn kein Shell-Persistenzwert übergeben wird.


## Update 14.10.2026 – Reguläre Preisbasis je Händler nachvollziehbar
- [x] Der Prospektfeed führt die Anzahl ausdrücklich ausgewiesener Normalpreise je Händler bis in die Abdeckungskarte.
- [x] Die Anzeige trennt feed-seitig lernbare Normalpreise von den tatsächlich in `PriceObservationStore` gespeicherten Beobachtungen.
- [x] Bei einem fehlgeschlagenen Persistenzlauf bleibt der Speicherstatus unbekannt beziehungsweise null; ein Angebotspreis wird niemals als regulärer Preis gezählt.

## Update 14.10.2026 – Erfolgreiche Preisprüfung zeigt auch Nullspeicherung
- [x] Ein erfolgreicher Persistenzlauf wird je Händler mit `0 gespeichert` ausgewiesen, wenn der aktuelle Feed keinen belegten regulären Preis enthält.
- [x] `null` bleibt dem nicht übergebenen oder fehlgeschlagenen Speicherstatus vorbehalten; der UI-Fallback erfindet keine Bestätigung.
- [x] Die Statusprojektion wird mit einer Regression für leere Händlerkarten abgesichert.

## Update 14.10.2026 – Regulärer Prospektpreis im Preisvergleich sichtbar
- [x] Preisbeobachtungen behalten die Evidenzart `regular` bis in die Preisansicht.
- [x] Ausdrücklich ausgewiesene Normalpreise werden als `Prospektpreis · Normalpreis` gekennzeichnet und bleiben vom aktiven Angebot getrennt.
- [x] Widget- und Fachtests sichern die Kennzeichnung, ohne Legacy-Preise oder die Routenbewertung zu verändern.


## Update 14.10.2026 – Quellen- und Refresh-Provenienz geschützt
- [x] Ein Feed-Refresh ordnet Händlernamen nur nach Groß-/Kleinschreibung und Rand-Whitespace zu; unterschiedliche Märkte bleiben getrennt.
- [x] Die lokale Kompaktierung hält automatische Beobachtungen je Adapter getrennt, damit KaufDA- und Händlerdaten ihre Herkunft behalten.
- [x] Regressionen sichern den Refresh-Filter und die Quota-Buckets ohne zusätzliche Netzwerkanfragen.
