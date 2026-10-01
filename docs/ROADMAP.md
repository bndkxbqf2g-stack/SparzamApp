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
- dataGap-Score für häufige, teure und entscheidungsrelevante Einkaufspositionen; nur gezielt neue Preisbelege anfordern.
- Produktidentität von Preisbeobachtungen trennen.
- Frische Tomatenvarianten im Basiskatalog getrennt von verarbeiteten
  Tomatenprodukten anbieten.
- Händler-/Bon-Aliase lernen.
- Confidence für automatische Zuordnungen.
- Wiederkehrende Käufe bevorzugt erkennen.
- Korrekturen des Nutzers als Lernsignal verwenden.
- Preisverlauf pro Produkt/Markt.

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
- [ ] Prospektfeed weiter auf vollständige Artikelbilder, Kategorien,
  Filialbezug und belastbare Gültigkeit ausbauen.

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
- Sparpotenzial je Einkauf.
- Für jede Einkaufsposition belastbare Preise je Markt zusammenführen und hinsichtlich Aktualität/Herkunft/Confidence bewerten.
- Ein-Markt-Strategien und sinnvolle Kombinationen aus mehreren Märkten für den gesamten Warenkorb vergleichen.
- Markt-/Routenoptimierung unter Berücksichtigung des tatsächlichen Mehrwegs und der daraus entstehenden Fahrtkosten.
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
- [ ] Angebotsquellen automatisiert aus realen Prospekten/Bildern einspeisen und Gültigkeit/Filialbezug prüfen.


## Update 29.09.2026 – Bring-Hotspotadapter
- [x] Share-Link-Struktur für die sechs Zielhändler analysiert; feste Prospekt-BRN von dauerhaftem „aktuell“-Abruf getrennt.
- [x] Optionalen standortbezogenen Bring-Adapter für aktuelle Prospektseiten, strukturierte Produkt-Hotspots, Bilder, Angebots- und Normalpreise implementiert.
- [x] Bring-Angebote laufen mit Gültigkeit und Nachweis durch den bestehenden Angebots-/PriceObservation-Vertrag.
- [ ] Live-Abruf in GitHub aktivieren, sobald die drei Bring-Zugangsdaten als Repository-Secrets hinterlegt sind; bis dahin bleiben die offiziellen Händleradapter führend.
- [ ] Bild-only-Prospektinhalte nur dann zusätzlich per OCR auswerten, wenn ein eigener Confidence-/Review-Pfad verhindert, dass erkannte Texte oder Preise ungeprüft routenfähig werden.

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
