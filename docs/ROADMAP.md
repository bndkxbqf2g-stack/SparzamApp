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

## Phase D – Alltagstaugliche Datenerfassung
- Kassenbons möglichst automatisch.
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
- [ ] **Nächstes Work-Paket:** Packungs-/Mengengleichheit und Variantenvergleichbarkeit zentral prüfen, bevor Beobachtungen gegeneinander gerankt werden.


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
