# SparzamApp – Projektstatus

> Diese Datei ist der Einstiegspunkt für jeden neuen Chat und jeden Work-Lauf.
> Vor Änderungen immer zuerst PROJECT_STATUS.md, ARCHITECTURE.md, ROADMAP.md und DECISIONS.md lesen und danach den aktuellen GitHub-Stand prüfen.

## Stand
- Repository: bndkxbqf2g-stack/SparzamApp
- Hauptbranch: main
- Letzter bei Einrichtung geprüfter Commit: 8ada2e33112cc86894dda2a92a7b37a5f1f0eb34
- App: Flutter-Prototyp für intelligent geplante Lebensmitteleinkäufe.
- Arbeitsweise: kleine, nachvollziehbare Schritte; modular; nach jedem abgeschlossenen Paket testen, committen, pushen und diese Datei aktualisieren.

## Aktuell funktionsfähig
- Einkaufsliste mit mehreren Listen, Mengen, Notizen, Kategorien und lokalem Zustand.
- Produktkatalog inkl. Barcode/Open Food Facts.
- Preisvergleich und Routenlogik.
- Bon-Import für textbasierte PDF/TXT/CSV und lokale Kaufhistorie.
- Bestätigte Bonpreise haben Vorrang vor externen/geschätzten Preisen.
- Open Prices als optionale Preisquelle.
- Angebote/Prospekte als eigener Bereich.
- Budget- und Diagnosefunktionen.

## Zuletzt umgesetzt
- Gewichtsartikel und kg-Mengen im Bon-Parser sauberer getrennt.
- Gedruckte Kilopreise werden sicher gelesen und im Review gekennzeichnet.
- Exaktes Matching für gewichtete Bananen ergänzt.
- Kaufland-Milch 1,5 % und 3,5 % als getrennte Produkte behandelt.
- Explizite Zuordnung unklar abgekürzter Kaufland-Milchzeilen ermöglicht.
- Milch-Auswahl nur für sicher zuordenbare, ausgeglichene und nicht rabattierte Bonzeilen.

## Aktueller Schwerpunkt
Eine intelligente und alltagstaugliche Preisdatenbank aufbauen:
1. Wiederkehrende Einkäufe und bekannte Produktidentitäten lernen.
2. Unklare Bonpositionen nicht dauerhaft starr behandeln.
3. Varianten (z. B. Fettstufe, Packungsgröße, Marke) getrennt halten.
4. Bestätigte Nutzerzuordnungen als Lernsignal verwenden.
5. Angebote als zeitabhängige Preise behandeln, nicht als neue Produkte.
6. Preisqualität/Herkunft/Aktualität nachvollziehbar halten.

## Noch offen / nächste sinnvolle Arbeitspakete
- Lernendes Produktmatching und Alias-/Zuordnungswissen entwerfen und modular implementieren.
- Preisbeobachtungen stärker von Produktstammdaten trennen.
- Confidence-/Review-Logik für unsichere Zuordnungen ausbauen.
- Wiederkehrende Käufe für schnellere, zuverlässigere Zuordnung nutzen.
- Regalvideo-Erfassung separat evaluieren. Aktuell daraus noch KEINE Code- oder Datenänderungen ableiten.

## Übergaberegel
Jeder Work-Lauf beendet ein möglichst kleines Arbeitspaket vollständig. Vor Ende:
1. flutter analyze
2. flutter test
3. flutter build web --release
4. Änderungen committen und pushen
5. PROJECT_STATUS.md aktualisieren
6. Falls eine Architekturentscheidung gefallen ist: DECISIONS.md aktualisieren

Falls ein Lauf vorzeitig endet, muss der nächste Lauf GitHub als technische Wahrheit verwenden und vom letzten gepushten Commit fortsetzen.

## Update 24.09.2026 – Bonbeobachtungen
- Vollständig geprüfte Bonpositionen werden nun zusätzlich als deduplizierte historische Produktbeobachtungen gespeichert, auch ohne sichere Katalogzuordnung.
- Beobachtungen behalten Rohbezeichnung, Markt, Datum, Gesamtpreis, Menge/Einheit, ggf. Einzel-/Grundpreis, Rabattstatus und optionale Produktzuordnung.
- Pfand und reine Rabattzeilen werden nicht zu Produktbeobachtungen.
- Eine konservative Produktfamilie wird vorbereitet (u. a. Hackfleisch, Milch, Trauben, Bananen, Kartoffeln), damit generische Einkaufslistenbegriffe später auf historische Marktpreise zugreifen können.
- Nächster Schritt: Preisstatistik (Median/Aktualität/Beobachtungszahl) aus diesen Beobachtungen und Anbindung an die Einkaufsliste.

## Update 24.09.2026 – Preisintelligenz aus Bonhistorie
- Bonbeobachtungen werden je Produktfamilie und Markt zu einer 90-Tage-Statistik verdichtet.
- Angezeigt werden Median, Beobachtungszahl und Vergleichbarkeit; rabattierte Zeilen fließen nicht in den Normalpreis-Median ein.
- Nur bei sicher einheitlicher Preisbasis wird der Wert als vergleichbar behandelt. Unklare Packungsgrößen erscheinen als „historisch, Packung prüfen“ und werden nicht als sicherer Preisvergleich ausgegeben.
- Die Einkaufsliste lädt diese Statistiken und zeigt passende historische Marktpreishinweise direkt am Artikel; nach Bonimport werden sie sofort neu geladen.
- Nächster Schritt: Zuordnungslernen (wiederkehrende Bonbezeichnungen → Produkt/Variante) und anschließend Nutzung sicherer Familienpreise in der Routen-/Sparpotenziallogik.

## Update 24.09.2026 – Lernende Bon-Aliase
- Explizite Produktzuordnungen können jetzt händlerbezogen aus der normalisierten Bonbezeichnung gelernt werden.
- Erst zwei gleiche Bestätigungen machen eine Zuordnung zu einem gelernten Vorschlag; widersprechende Korrekturen setzen die Confidence zurück.
- Bei späteren Bons wird ein sicher gelernter Alias vorbefüllt und im Review als gelernte, weiterhin prüfbare Zuordnung kenntlich gemacht.
- Das Lernen ist bewusst konservativ und ersetzt keine sichere Produktidentität durch bloße Textähnlichkeit.
- Nächster Schritt: die Alias-Zuordnung von der bisherigen Milch-Sonderbehandlung auf eine generische Review-Auswahl für alle unklaren Bonpositionen erweitern.

## Update 24.09.2026 – Generische Produktzuordnung im Bonreview
- Jede nicht sicher erkannte Produktposition kann jetzt über eine durchsuchbare Produktauswahl einem vorhandenen Katalogprodukt zugeordnet werden.
- Die Auswahl wird in der Bonbeobachtung gespeichert und als händlerbezogenes Alias-Lernsignal verwendet.
- Bereits sicher gelernte Aliase werden beim nächsten Import vorbefüllt, bleiben aber sichtbar änderbar oder entfernbar.
- Eine manuelle Identitätszuordnung erzeugt bewusst nicht automatisch einen direkten Vergleichspreis, solange Packungs-/Mengensemantik unsicher ist. Die bestehende sichere Milchlogik darf weiterhin einen direkten Preis erzeugen.
- Nächster Schritt: sinnvolle Behandlung von Bonpositionen, für die noch gar kein Katalogprodukt existiert (Produktkandidat anlegen/prüfen), damit die Datenbank aus neuen Produkten wachsen kann.

## Update 24.09.2026 – Katalog wächst aus realen Bons
- Unbekannte Bonpositionen können im Review jetzt direkt als neues Katalogprodukt angelegt und derselben Bonzeile zugeordnet werden.
- Vor dem Anlegen sind Produktname, Produktgruppe und Einheit editierbar; die Bonbezeichnung wird als Alias am neuen Produkt gespeichert.
- Das neue Produkt läuft über den bestehenden Katalog-Speicher und steht danach auch der Produktauswahl zur Verfügung.
- Die Zuordnung fließt anschließend wie andere Nutzerbestätigungen in Bonbeobachtung und Alias-Lernen ein.
- Preisstatistiken wurden zusätzlich variantensicher gemacht: konkrete Produkt-IDs werden getrennt aggregiert; Familienwerte sind nur Fallback für unzugeordnete Beobachtungen.
- Damit ist die Kernkette Bon → Beobachtung → Zuordnung/Lernen → Katalogwachstum → historische Preisstatistik geschlossen.
- Nächste Ausbaustufe: sichere, ausreichend belastbare Produktpreise in Routen-/Sparpotenziallogik einspeisen; Angebote weiterhin separat behandeln.

## Verbindliche Abschlussregel für Arbeitspakete
- Ein Entwicklungs-Arbeitspaket gilt erst als abgeschlossen, wenn die GitHub **Flutter CI vollständig grün** ist.
- Nach jedem Codepaket wird der zugehörige CI-Lauf geprüft: `flutter analyze`, `flutter test` und `flutter build web --release` müssen erfolgreich sein.
- Bei einem CI-Fehler werden Logs ausgewertet, der Fehler behoben, gepusht und der neue CI-Lauf erneut geprüft. Diese Schleife wird innerhalb derselben Bearbeitung fortgesetzt, bis die CI grün ist oder ein externer/blockierender Grund eine automatische Fortsetzung unmöglich macht.
- Ein laufender oder noch nicht gestarteter CI-Lauf darf nicht als erfolgreicher Abschluss gemeldet werden.
