# SparzamApp – Roadmap

Diese Roadmap ist eine Prioritätenliste, kein starres Releaseversprechen.

## Phase A – Solide Datengrundlage
- Bon-Parsing stabilisieren.
- Stück-, Gewichts- und Grundpreise korrekt unterscheiden.
- Produktvarianten zuverlässig auseinanderhalten.
- Nutzerkorrekturen sicher speichern.
Status: weit fortgeschritten, weitere reale Bons dienen als Praxistest.

## Phase B – Lernende Preisdatenbank
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
