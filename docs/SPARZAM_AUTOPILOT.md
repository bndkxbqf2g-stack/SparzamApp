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
- [ ] UI klar zwischen historischem Hinweis und route-tauglichem Planungspreis unterscheiden

### Phase 3 – Einkaufslisten- und Preis-Matrix
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

## Gemeinsame Chat-Befehle

### `A`
Wenn der Nutzer nur `A` sendet, arbeitet ChatGPT im aktuellen Chat-Turn maximal selbstständig an **beiden aktiven Projekten**: SparzamApp und FamSchicht.

Das gilt ausdrücklich auch für Problembehebung:
1. CI und aktuellen Stand beider Projekte prüfen.
2. Fehler nicht nur melden, sondern selbstständig analysieren.
3. Eindeutig belegte Ursachen direkt korrigieren.
4. Regressionstests ergänzen oder anpassen.
5. Änderungen committen und pushen.
6. CI erneut prüfen.
7. Solange sichere weitere Korrekturen oder Roadmap-Schritte möglich sind, im selben Turn weiterarbeiten.
8. Erst bei grüner CI oder einer echten externen Grenze stoppen.

### `N`
Normaler Entwicklungsblock für **beide aktiven Projekte**: typischerweise bis zu 5 logisch zusammengehörige Schritte pro Projekt, danach relevante CI.

### `U`
Nur **Status prüfen**. Keine neue Feature-Entwicklung und keine eigenständige Problembehebung starten.

## Bestehende Kurzbefehle
- `A`: maximal selbstständige Umsetzung **und Problembehebung** in SparzamApp + FamSchicht
- `N`: normaler Entwicklungsblock für beide aktiven Projekte
- `U`: nur Status beider aktiven Projekte prüfen

## Wiedereinstieg nach dem aktuellen Entwicklungsblock
Der End-to-End-Audit hat drei konkrete Identitäts-Bypässe geschlossen: Eine bloße `productId` auf einer Bonbeobachtung gilt nicht mehr automatisch als bestätigte Identität; automatisch angelegte Bonprodukte dürfen keinen direkten `MarketPrice` erzeugen; automatische Preisvorschläge starten unselektiert und werden erst nach expliziter Nutzerbestätigung als exakter Marktpreis übernommen. Alte `receipt_auto_*`-Beobachtungen werden konservativ als unbestätigt gelesen.

Die reale Bon-Matrix ist in `docs/REAL_RECEIPT_MATRIX.md` begonnen. Der im Repository eindeutig belegte Kaufland-Schmand-Fall vom 23.07.2026 wird jetzt über `ReceiptObservation → PriceObservation → MarketPrice → planningMarketPrices → RoutePriceResolver → RouteOptimizer` getestet. Für sechs weitere Originalbons fehlen im Repository weiterhin eindeutig rekonstruierbare Original-Fixtures; deshalb bleibt der Roadmap-Punkt „sieben reale Bons“ offen und es wurden keine fehlenden Preise ergänzt.

Nächster sicherer Schritt nach grüner CI: fehlende/mehrdeutige Produktidentitäten weiter auditieren und Quellpriorität sowie Angebot/Normalpreis absichern. Die sechs fehlenden Originalbelege bleiben ein Datenblocker nur für die vollständige reale Produkt×Markt-Matrix und daraus abgeleitete reale 1/2/3-Markt-Tests.
