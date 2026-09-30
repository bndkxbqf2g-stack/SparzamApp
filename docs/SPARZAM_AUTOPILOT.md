# SparzamApp – Autopilot-Protokoll

Stand: 2026-09-25

## Ziel
SparzamApp wird schrittweise bis zu einem belastbaren Einkaufsoptimierer ausgebaut. Die App soll aus eigenen Kassenbons, bestätigten/manuellen Preisen, zulässigen Open-Prices-Daten, Entfernungen und Fahrtkosten eine wirtschaftlich sinnvolle Einkaufsroute ableiten. Das Ergebnis soll nicht nur Einzelpreise zeigen, sondern entscheiden, ob sich ein Einkauf in einem, zwei oder mehreren Märkten tatsächlich lohnt.

## Entwicklungsprinzip
- Erst bestehenden Code, Datenfluss und Tests prüfen, dann ändern.
- Ursachen statt sichtbarer Symptome beheben.
- Kleine, nachvollziehbare Commits; belegte Fehler erhalten Regressionstests.
- Keine hartcodierten Produkt-Alias-Sammlungen als Hauptlösung, wenn eine generalisierbare Normalisierung möglich ist.
- Keine erfundenen Preise.
- Preisquellen, Alter, Paketvergleichbarkeit und Unsicherheit bleiben nachvollziehbar.
- Historische Preisstatistik und route-taugliche Preise bleiben getrennt.
- Rote CI blockiert neue Feature-Arbeit.
- Architekturänderungen in kleineren Blöcken, UI-/Testverbesserungen dürfen größer gebündelt werden.

## Definition „fertig“
SparzamApp gilt erst als produktreif, wenn die Kernpipeline Bon/OCR → Produktidentität → Preisbeobachtung → Marktpreis → Planung → Route vollständig getestet ist, reale Bons robust verarbeitet werden, Mehrmarktentscheidungen wirtschaftlich korrekt sind und keine bekannten kritischen Preis-/Routenfehler offen sind.

## Roadmap

### Phase 1 – Produktidentität und Bonauflösung
- [x] zentrale Produktfamilien-/Identitätslogik
- [x] Schutz gegen falsche Substring-Zuordnung
- [x] generische Familienpreise über mehrere Märkte
- [x] Variantenlogik für Milch, Joghurt, Hackfleisch, Paprika u. a.
- [x] Frisch-/Konserven-Tomaten in der Route trennen
- [ ] reale sieben Bons als strukturierte Produkt×Markt-Testmatrix absichern
- [ ] weitere häufige Händlerkürzel generalisiert abdecken
- [x] Identitäts-Konfidenz und Ablehnungsgrund sichtbar/testbar machen
- [x] Store-Namen zwischen Bon, Open Prices und Marktmodell kanonisieren
- [ ] fehlende/mehrdeutige Produktidentitäten sauber als unsicher behandeln

### Phase 2 – Preisquellen und Vergleichbarkeit
- [x] manuelle/Receipt/Open-Prices-Quellen getrennt
- [x] Open Prices bei deaktivierter Quelle auch historisch ausschließen
- [x] 30-Tage-Fenster für route-taugliche Receipt-Preise
- [x] ältere Receipt-Daten für Historie behalten
- [x] Paketgrößen normalisieren
- [x] Vergleichbarkeit für Stück/Gewicht/Volumen systematisch härten
- [ ] Marktpreis-Konfidenz und Preisbasis vereinheitlichen
- [ ] Quellpriorität vollständig mit Tests absichern
- [ ] Angebotspreise vs. Normalpreise konsistent behandeln
- [ ] Angebotsquellen automatisiert importieren: Händler, Bild, Gültigkeit, Produktidentität
- [ ] Angebote per + direkt in die Einkaufsliste übernehmen
- [x] ausgewiesenen Normalpreis eines Angebots nur als bestätigte Preisbasis speichern
- [ ] UI klar zwischen historischem Hinweis und route-tauglichem Planungspreis unterscheiden

### Phase 3 – Einkaufslisten- und Preis-Matrix
- [ ] hierarchischen Produktkatalog aus Oberbegriff → Produktfamilie → Variante aufbauen
- [ ] Suchbegriff zeigt alle passenden Interpretationen (z. B. Tomate → frisch/Rispe/Party, getrennt von Tomatenmark/-sauce)
- [ ] für jede Position alle belastbaren Marktpreise aufbauen
- [ ] fehlende Preise explizit markieren
- [ ] Produkt×Markt-Matrix als interne Diagnose-/Teststruktur
- [ ] neuester/Median/Quelle/Alter/Vergleichbarkeit je Preis
- [ ] Einkaufsliste automatisch mit bekannten Daten aktualisieren
- [ ] Preisänderungen atomar in Planung übernehmen

### Phase 4 – Routenoptimierung
- [x] ein bis drei Märkte
- [x] Fahrtkosten berücksichtigen
- [x] Preisabdeckung vor Teilkosten bevorzugen
- [x] unsichere/geschätzte Preise nicht als belastbar behandeln
- [x] Mindestvorteil für zusätzlichen Markt
- [ ] realistische Mehrmarkt-End-to-End-Tests
- [ ] gleiche Produktliste gegen 1/2/3 Markt-Kombinationen vergleichen
- [ ] Entfernung, Fahrtkosten und Preisersparnis transparent aufschlüsseln
- [ ] unvollständige Preisabdeckung sauber in Empfehlung einbeziehen
- [ ] robuste Tie-Breaker und Grenzfälle
- [ ] Routenempfehlung mit klarer Begründung ausgeben

### Phase 5 – Automatische Datenerfassung
- [ ] Bon-OCR robuster gegen Händlerlayouts machen
- [ ] Produktzeilen automatisch erkennen/zuordnen
- [ ] erkannte Produkte automatisch als Beobachtungen aufnehmen
- [ ] Dubletten-/Receipt-Fingerprint-Härtung
- [ ] Open Prices als optionale Ergänzung optimieren
- [ ] manuelle Preisbestätigung vereinfachen
- [ ] spätere Video-/Regalerfassung nur nach stabiler Foto/OCR-Basis prüfen

### Phase 6 – UX / Dashboard
- [ ] heutiges Sparpotenzial
- [ ] empfohlene Route prominent
- [ ] Gesamtpreis + Fahrtkosten + Ersparnis
- [ ] Preisabdeckung und Unsicherheit verständlich
- [ ] schneller Einkaufsliste→Route-Flow
- [ ] klare Hinweise, wenn Daten für Empfehlung fehlen
- [ ] kompakte iPhone-Darstellung
- [ ] Detailansicht pro Produkt/Markt
- [ ] historische Preisentwicklung als optionale Detailansicht

### Phase 7 – Produktreife
- [ ] vollständiger Repo-/Architektur-Audit
- [ ] End-to-End Pipeline-Test mit realen Bons
- [ ] Performance bei größerer Historie
- [ ] Offline-/Fehlerverhalten
- [ ] Datenexport/-import
- [ ] PWA/Release-Härtung
- [ ] Dokumentation
- [ ] finaler CI-/UX-/Datenqualitäts-Audit

## Arbeitsmodi A/N/Q/U

Die Kürzel gelten für das vom Nutzer genannte Repository. Sind mehrere Repositories ausdrücklich genannt, bearbeite sie jeweils getrennt.

### `A` — Autopilot
Erledige den vereinbarten Umfang in diesem Repository maximal selbstständig: aktuellen Branch und CI prüfen, Ursachen klären, Implementierung und Regressionstests ergänzen, relevante CI ausführen und klare Folgefehler beheben. Arbeite bis die Checks grün sind oder eine echte externe Grenze erreicht ist. Keine unbeauftragte Scope-Erweiterung; keine riskante Datenänderung, kein Merge und kein Release allein aufgrund des Kürzels.

### `N` — Normaler Entwicklungsblock
Arbeite einen begrenzten Block von typischerweise bis zu fünf logisch zusammenhängenden Schritten ab. Führe danach die passenden Tests und CI aus und berichte den nächsten sinnvollen Schritt.

### `Q` — Qualitätssicherung
Prüfe den benannten Bereich oder vorhandenen Diff, führe passende Tests aus und behebe nur klar reproduzierbare Fehler mit Regressionstest. Keine neuen Features.

### `U` — Update
Prüfe nur Repository-, Branch-, Test- und CI-Status und berichte ihn kompakt mit Ampel. Keine Änderungen und keine eigenständige Fehlerbehebung.

## Bestehende Kurzbefehle
- `A`: maximal selbstständige Umsetzung und Problembehebung im jeweils genannten Repository
- `N`: begrenzter Entwicklungsblock im jeweils genannten Repository
- `Q`: fokussierte Qualitätssicherung ohne neue Features
- `U`: Statusbericht ohne Änderungen

## Wiedereinstieg nach dem aktuellen Entwicklungsblock
Der End-to-End-Audit hat drei konkrete Identitäts-Bypässe geschlossen: Eine bloße `productId` auf einer Bonbeobachtung gilt nicht mehr automatisch als bestätigte Identität; automatisch angelegte Bonprodukte dürfen keinen direkten `MarketPrice` erzeugen; automatische Preisvorschläge starten unselektiert und werden erst nach expliziter Nutzerbestätigung als exakter Marktpreis übernommen. Alte `receipt_auto_*`-Beobachtungen werden konservativ als unbestätigt gelesen.

Die reale Bon-Matrix ist in `docs/REAL_RECEIPT_MATRIX.md` begonnen. Der im Repository eindeutig belegte Kaufland-Schmand-Fall vom 23.07.2026 wird jetzt über `ReceiptObservation → PriceObservation → MarketPrice → planningMarketPrices → RoutePriceResolver → RouteOptimizer` getestet. Für sechs weitere Originalbons fehlen im Repository weiterhin eindeutig rekonstruierbare Original-Fixtures; deshalb bleibt der Roadmap-Punkt „sieben reale Bons“ offen und es wurden keine fehlenden Preise ergänzt.

Die Einkaufsliste muss als primäre Preisoberfläche dieselben route-tauglichen `planningMarketPrices` anzeigen wie der Optimierer. Familienpreise aus Bons dürfen deshalb nicht nur intern in der Route existieren. Die Tomatenidentität trennt frische Tomatenvarianten von Tomatenmark, Tomatensauce und Konserven; generische frische Tomaten dürfen passende frische Varianten bündeln.

Zielbild für die nächsten Blöcke: hierarchischer, erweiterbarer Produktkatalog statt einer endlosen flachen Aliasliste; Suche liefert mögliche Interpretationen; bekannte Bon-/Preis-/Angebotsdaten werden darunter eingeordnet. Danach Angebotsimport mit Bild und Gültigkeit sowie +‑Übernahme in die Einkaufsliste und expliziter Normalpreisbestätigung. Die Route bewertet den gesamten Warenkorb gegen 1/2/3 Märkte inklusive Fahrtkosten und Angebotsvorteil.

Nächster sicherer Schritt nach grüner CI: den Such-/Katalogpfad auf diese hierarchische Produktauflösung umstellen und Quellpriorität sowie Angebot/Normalpreis absichern. Die sechs fehlenden Originalbelege bleiben ein Datenblocker nur für die vollständige reale Produkt×Markt-Matrix und daraus abgeleitete reale 1/2/3-Markt-Tests.


## Update 25.09.2026 – Such- und Angebotsblock
Die Einkaufssuche nutzt jetzt die vorhandene Identitätslogik auch als sichtbare Hierarchie. Identitätskompatible Produkte bleiben die primären Treffer; verwandte, aber andere Familien werden separat als Interpretationen angeboten. Im Referenzfall „Tomate“ werden damit frische Varianten nicht mit Tomatenmark/Passata als Preisidentität vermischt.

Externe Angebote benötigen für eine belastbare Preisbeobachtung einen `proofRef`. Ohne Nachweis bleibt ihre Identitäts-Confidence 0; manuell eingegebene Angebote gelten weiterhin als explizite Nutzerbestätigung.

Nächster sicherer Schwerpunkt: reale Angebots-/Prospektdaten in den bereits abgesicherten Importvertrag einspeisen und danach die Produkt×Markt-Abdeckung bzw. `dataGap`-Priorisierung ausbauen. Die zwei weiterhin fehlenden Originalbons bleiben ein separater Datenblocker und werden nicht erraten.

Der öffentliche Prospektfeed wird nach erfolgreicher Validierung lokal zwischengespeichert. Bei einem vorübergehenden Netzwerkfehler darf dieser Feed als Cache-Fallback weiterlaufen; die aktuelle Gültigkeitsprüfung bleibt unverändert und private Belegdaten werden nicht mitgespeichert.

## Update 30.09.2026 – Grundvorrat und Variantenwahl
Der Basiskatalog enthält jetzt weitere preisfreie Varianten für den täglichen
Einkauf. Die zentrale Identität löst zusätzlich Reis, Mehl, Öl, Zucker, Salz,
Ketchup und haltbare Tomatenprodukte auf. Ein Oberbegriff findet kompatible
Varianten, während konkrete Produktarten getrennte Preisidentitäten behalten.
Damit ist der hierarchische Katalogpfad für die häufigsten Grundbedarfswünsche
erweitert; die vollständige Katalogmigration und echte Preisabdeckung bleiben
separate Arbeitspakete.

## Update 30.09.2026 – Belegabkürzungen im Einkaufslistenlauf
Ein bereitgestellter Kaufland-Beleg wurde lokal gegen die Produktsuche
simuliert. 70 von 72 Produktzeilen erhalten eine passende preisfreie Auswahl;
zwei undurchsichtige Händlercodes bleiben zur Review offen. Die Suchrangfolge nutzt
erkennbare Labelbestandteile nur als Hinweis und macht daraus weder eine
bestätigte Produktidentität noch einen Preis.
