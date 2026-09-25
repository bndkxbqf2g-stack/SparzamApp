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
- [ ] Identitäts-Konfidenz und Ablehnungsgrund sichtbar/testbar machen
- [ ] Store-Namen zwischen Bon, Open Prices und Marktmodell kanonisieren
- [ ] fehlende/mehrdeutige Produktidentitäten sauber als unsicher behandeln

### Phase 2 – Preisquellen und Vergleichbarkeit
- [x] manuelle/Receipt/Open-Prices-Quellen getrennt
- [x] Open Prices bei deaktivierter Quelle auch historisch ausschließen
- [x] 30-Tage-Fenster für route-taugliche Receipt-Preise
- [x] ältere Receipt-Daten für Historie behalten
- [x] Paketgrößen normalisieren
- [ ] Vergleichbarkeit für Stück/Gewicht/Volumen systematisch härten
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

## Maximal-Befehl

### `A Sparzam`
Wenn der Nutzer nur `A Sparzam` sendet, arbeitet ChatGPT ausschließlich an SparzamApp und führt innerhalb des aktuellen Chat-Turns so viel sichere Arbeit wie möglich aus.

Ablauf:
1. Aktuellen `main`-Stand und neueste Flutter-CI/Release/Pages prüfen.
2. Bei roter CI ausschließlich Ursache beheben, Regressionstest ergänzen und neue CI starten.
3. Bei grüner CI den obersten noch offenen Roadmap-Punkt mit dem größten Nutzen für die Kernpipeline wählen.
4. Vor jeder Änderung den betroffenen Datenfluss vollständig prüfen.
5. Mehrere kleine, getrennte Commits selbstständig umsetzen.
6. Nach kohärenten Teilblöcken relevante Tests/CI starten.
7. Solange CI grün ist und Tool-/Turn-Laufzeit sinnvoll reicht, mit dem nächsten Teilblock fortfahren.
8. Roadmap-Checkboxen nur nach belegter Umsetzung aktualisieren.
9. Bei Architektur-/Datenmodelländerungen kleinere sichere Blöcke bevorzugen.
10. Abschlussmeldung nur mit Ampelstatus, erledigtem Bereich und nächstem Roadmap-Punkt.

Typischer Umfang pro `A Sparzam`-Turn: deutlich größer als `N`; mehrere Entwicklungsblöcke und häufig etwa 10–25 kleine Änderungen/Commits, soweit CI, Tool-Laufzeit und Sicherheitsgrenzen dies erlauben. Die tatsächliche Zahl ist nicht garantiert.

Stop-Bedingungen:
- rote CI, die erst weiter analysiert werden muss
- riskante oder schwer rückrollbare Datenmigration
- fehlende externe Credentials/API-Konfiguration
- kostenpflichtiger externer Dienst ohne Freigabe
- unklare Produkt-/Preisannahme, die reale Daten erfordert
- Tool-/Turn-Grenze

## Bestehende Kurzbefehle
- `N`: normaler nächster 5-Schritte-Block in den aktiven Projekten nach bisheriger Regel
- `N Sparzam`: normaler 5-Schritte-Block nur SparzamApp
- `U`: CI/aktuellen Block prüfen oder Fehler weiter beheben
- `A`: maximaler FamSchicht-Autopilot
- `A Sparzam`: maximaler SparzamApp-Autopilot

## Aktueller nächster Schwerpunkt
Nach grüner CI: Produkt-/Markt-Evidenzmatrix auf Basis der realen Bons weiter absichern, Store-Namen kanonisieren und anschließend realistische Mehrmarkt-End-to-End-Routentests ergänzen.
