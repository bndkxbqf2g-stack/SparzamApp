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

## Update 24.09.2026 – Automatische Übernahme aller erkannten Bonprodukte
- Alle echten Produktpositionen eines vollständig geprüften Bons werden beim Speichern automatisch dem Produktkatalog zugeführt.
- Bereits sicher erkannte oder exakt aliasgleiche Produkte werden wiederverwendet; dadurch entstehen bei wiederholten Bons keine unnötigen Dubletten.
- Unklare Varianten werden konservativ unter der tatsächlich gelesenen Bonbezeichnung angelegt. Nicht belegte Details (z. B. 1,5 %/3,5 % bei unspezifischer H-Milch) werden nicht ergänzt.
- Pfand und reine Rabattzeilen bleiben ausgeschlossen.
- Automatisch erzeugte Zuordnungen gelten nicht als explizite Nutzerbestätigung für das Alias-Lernen.

## Update 24.09.2026 – Bonpreise in der Einkaufsliste
- Historische Bonpreise werden in der Einkaufsliste jetzt auch dann als konservativer Familienhinweis gefunden, wenn eine ältere Beobachtung bereits einer anderen konkreten/provisorischen Produkt-ID zugeordnet wurde.
- Exakte Produkt-ID-Historie hat weiterhin Vorrang; Familienwerte sind nur Fallback und werden nicht als exakte Variantenidentität ausgegeben.
- Nicht vergleichbare Packungspreise werden nicht nach dem niedrigsten Betrag als vermeintlich günstigster Markt sortiert, sondern als historischer Hinweis nach Aktualität behandelt.
- Produktfamilie und konkrete Produkt-ID bleiben in neuen Bonbeobachtungen getrennte Dimensionen.


## Update 24.09.2026 – Selbstheilende Produktfamilien aus Bonhistorie
- Preisstatistiken leiten die Produktfamilie für jede Bonbeobachtung erneut aus der originalen Bonbezeichnung ab, statt einem möglicherweise veralteten gespeicherten familyKey blind zu vertrauen.
- Dadurch werden auch bereits gespeicherte Bons automatisch mit der aktuellen Erkennungslogik ausgewertet; ein erneuter Bonimport ist nicht erforderlich.
- Die Reparatur gilt generisch für alle Produkte. Konkrete productId-Zuordnungen bleiben dabei erhalten und Variantenstatistiken weiterhin getrennt.


## Update 24.09.2026 – Rabattierte Bonprodukte bleiben als Preisbeleg sichtbar
- Echte gekaufte Produktzeilen werden für historische Einkaufspreise nicht mehr vollständig ausgefiltert, wenn ihnen ein Artikelrabatt zugeordnet ist.
- Dadurch bleibt z. B. „K.Frischer Schmand 0,79 €“ vom Kaufland-Bon als historische Preisbeobachtung für Schmand nutzbar, obwohl anschließend ein K-Card-Rabatt steht.
- Die Regel gilt generisch für alle Produkte; Rabattstatus bleibt an der Beobachtung erhalten und darf später separat als Angebots-/Rabattinformation ausgewertet werden.


## Update 24.09.2026 – Gemeinsame Preisbasis für Liste und Routenplanung
- Bonhistorie wird jetzt in die gemeinsame Marktpreis-Pipeline der Einkaufsliste und Routenplanung überführt.
- Generische Einkaufsbegriffe wie „Schmand“ dürfen einen bekannten Preis derselben konservativen Produktfamilie nutzen; konkrete Varianten erhalten keinen breiten Familienpreis, wenn die Bonidentität nicht exakt passt.
- Exakte, aus einem Bon gewachsene Produktidentitäten erzeugen bei sicherer Preisbasis einen direkten Bon-Marktpreis. Ein nachfolgender Artikelrabatt verändert den auf der Produktzeile ausgewiesenen Preis nicht.
- Bonbeobachtungen werden nach Import sofort im Shell-/Routenkontext neu geladen.
- Korrigierte bereits vorhandene Bonbeobachtungen werden nun auch dann persistiert, wenn ihre ID bereits existiert.
- Schmand ist der End-to-End-Referenzfall: „Schmand“ → Familie → Kaufland-Bonpreis 0,79 € → Einkaufsliste → Planungs-/Routenpreis.
- Nächster Ausbau: Preisqualität/Aktualität explizit in der Routenbewertung gewichten, damit historischer Bonpreis, aktuelles Angebot und aktuelle Marktbeobachtung nicht gleich stark behandelt werden.

## Update 24.09.2026 – Eindeutige Marktpreisauswahl für die Route
- Treffen mehrere Beobachtungen für dieselbe Produkt-ID und denselben Markt aufeinander, wählt die Route unabhängig von der Eingabereihenfolge zuerst einen eigenen bestätigten Preis, dann Bonpreis, dann Open Prices; innerhalb derselben Quelle zählt die neueste Beobachtung.
- Im Einkaufsplan wird die gewählte Preisquelle angezeigt; Bonpreise älter als 30 Tage werden dort als historisch bezeichnet.
- Angebote greifen nur für die genaue Produkt-ID. Ähnliche Produkt-IDs oder gemeinsame Wörter verbinden keine unterschiedlichen Varianten.
- Nächster Schritt: historische/rabattierte Bonpreise und aktuelle Preise mit einer ausdrücklich definierten Unsicherheitsregel im Vergleich bewerten; heute sind historische Bonpreise weiterhin nominale Preise mit Herkunftshinweis.

## Update 24.09.2026 – Preisunsicherheit im Warenkorbvergleich
- Die Routenplanung addiert einen separat ausgewiesenen heuristischen Unsicherheitsaufschlag zum Planungswert, nicht zum erwarteten Kassenbetrag oder den Fahrtkosten. Artikelzuordnung, Einmarktvergleich, Kombinationen und Mindestvorteil verwenden denselben Planungswert.
- Eigene Marktpreise: 0 % bis 30 Tage, danach 5 %. Bonpreise: 5 % bis 30 Tage, 15 % bis 60 Tage, danach 25 %; erkannter Artikelrabatt +10 Prozentpunkte. Open Prices: 5 % bis 7 Tage, danach 10 %. Hinterlegte Katalogbeispiele ohne Beleg: 15 %. Aktuelle passende Angebote: 0 %. Prozentwerte sind Vorsichtsregeln, keine behauptete Preisschwankungsstatistik.
- Ein alter rabattierter Einzelpreis allein kann so keine zusätzliche Marktfahrt auslösen, wenn sein nomineller Vorteil die Unsicherheit und die tatsächlichen Fahrtkosten nicht deckt. Ein größerer Vorteil im gesamten Warenkorb kann ihn weiterhin überwiegen.
- Neu importierte rabattierte Bonbeobachtungen behalten das Rabattmerkmal auch in der Marktpreispipeline. Alte gespeicherte direkte Marktpreise ohne Rabattmerkmal bleiben als solche unbekannt; die Bonhistorie trägt das Merkmal weiterhin.
- Familienbeobachtungen aus Bons bleiben bis 90 Tage für die Planung verfügbar. Ältere Belege wie der Schmand-Bon erhalten den höheren Unsicherheitsaufschlag und gelten nicht als sicher aktueller Regalpreis.
- Nächster Schritt: Packungs-/Mengengleichheit und echte Verfügbarkeit je Markt weiter absichern, dann Unsicherheitsregeln anhand realer Preisverläufe kalibrieren.

## Update 24.09.2026 – Einstieg in die hybride Preisbasis
- Bestandsaufnahme: Bonbeobachtungen und Alias-Lernen, manuelle/Open-Prices-Marktpreise, Angebote und einfacher Preisverlauf sind vorhanden. Marktpreise überschreiben derzeit den aktuellen Wert pro Produkt/Markt; der einfache Verlauf verliert Filial-, Rabatt- und Nachweisinformationen. Die Route schließt unbekannte Preise derzeit aus und verwendet noch Beispielpreise für einige Katalogprodukte.
- Neues gemeinsames `PriceObservation`-Modell mit Produkt/Familie/Variante/EAN, Markt/Filiale/Region, Menge/Einheit/Grundpreis, Normal-/Angebotsstatus, Zeitraum, Quelle, Zeitpunkt, separater Identitäts-Confidence und Nachweisreferenz. Neue manuelle/Open-Prices-Marktpreise werden beim Speichern zusätzlich idempotent als einzelne historische Beobachtungen gesichert, auch wenn die aktuelle Projektion sie nicht auswählt.
- Die Routenauflösung wählt konkurrierende vorhandene Marktpreise anhand Preis plus D025-Unsicherheitsaufschlag statt starrem Quellenvorrang; Quelle und Alter werden dazu getrennt berechnet. Die aktuelle Marktpreis-Projektion begrenzt weiterhin, welche historischen Alternativen die Route überhaupt sieht. Das ist das nächste Integrationspaket.
- Externe Prüfung: [Open Prices API und Datenmodell](https://openfoodfacts.github.io/open-prices/topics/core/) bieten Preise, Nachweise, Orte und Produkt/EAN bzw. Kategorie; [Datenzugang und ODbL](https://openfoodfacts.github.io/open-prices/guides/data/) sowie [Preis-Upload mit proof_id](https://openfoodfacts.github.io/documentation/docs/Open-prices/prices/prices_create/) erlauben perspektivisch kontrollierte Rückgabe. Aktuelle lesende EAN-Abfrage existiert schon in `OpenPricesService`.
- [german-supermarket-prices](https://github.com/loukesio/german-supermarket-prices) enthält einen regionalen Snapshot für mehrere Ketten, allerdings lückenhafte Abdeckung und Angebote; [rewe-price-data](https://github.com/L480/rewe-price-data) bietet tägliche REWE-CSVs für zwei Regionen. Beide sind Drittquellen, keine offizielle bundesweite Filial-API. Keine davon wird jetzt automatisch importiert; Nutzung/Weitergabe und Filialbezug sind vor einem Adapter zu prüfen.
- Nächste Pakete: Historie als Eingang der Projektion/Route lesen; Bon/Angebote mit geprüfter Packungssemantik adaptieren; unbekannte Preise als Bereiche mit Confidence statt stillen Nullwerten behandeln; dataGap nach Entscheidungsrelevanz priorisieren. Upload eigener Belege bleibt opt-in und getrennt von Preisabrufen.


## Update 24.09.2026 – Beobachtungshistorie erreicht die Routenplanung
- Die append-only `PriceObservation`-Historie wird beim Start geladen und nach manuellen Preisänderungen bzw. Open-Prices-Syncs sofort neu eingelesen.
- Exakte, vollständig sichere Beobachtungen aus manuell, Bon und Open Prices werden zurück in die bestehende `MarketPrice`-Planungsschnittstelle projiziert. Dadurch sieht der Route-Resolver nicht mehr nur den zuletzt in `MarketPriceStore` verbliebenen Wert, sondern alle gespeicherten konkurrierenden Beobachtungen.
- Die Auswahl bleibt D025/D027-konform: nomineller Preis plus Unsicherheit aus Quelle/Alter/Rabatt; der erwartete Kassenbetrag bleibt ungewichtet.
- Familien-only-Beobachtungen und unsichere Produktidentitäten werden bewusst nicht als exakte Produktpreise projiziert. Bon-Familienfallback bleibt separat und konservativ.
- Nächster Schritt: Bon- und Angebotsquellen kontrolliert auf das gemeinsame `PriceObservation`-Modell adaptieren, insbesondere Packungs-/Mengengleichheit und Gültigkeit. Danach unbekannte Preise als Bereiche/Confidence und `dataGap` angehen.


## Update 24.09.2026 – Bon- und Angebotsadapter abgeschlossen
- Flutter CI des vorherigen Historienpakets und des Adapterpakets ist grün.
- Gespeicherte Bonzeilen werden zusätzlich idempotent als `PriceObservation` abgelegt. Menge, Einheit, Grundpreis, Produktfamilie, Rabattstatus, Bon-Fingerprint und Beobachtungsdatum bleiben erhalten.
- Eine Bonzeile ohne exakte Produktzuordnung bleibt Familienbeobachtung mit niedriger Identitäts-Confidence und wird nicht als exakter Produktpreis in die Route hochgestuft.
- Gespeicherte Angebote werden zusätzlich als `PriceObservationKind.offer` mit Produkt, Markt, Angebotspreis, Gültigkeitsende und Nachweisreferenz abgelegt.
- Abgelaufene Angebotsbeobachtungen werden aus der exakten Routenprojektion ausgeschlossen.
- **Work-Handoff nach Limit:** Nicht erneut Historie/Bon-/Angebotsadapter bauen. Nächstes Arbeitspaket ist Packungs-, Mengen- und Variantenvergleichbarkeit. Danach: fehlende Preise als Bereiche/Confidence, anschließend `dataGap`.


## Arbeitsmodus Projektchat / Work
- Kleine, klar begrenzte Entwicklungspakete werden im Projektchat umgesetzt und jeweils über GitHub CI abgeschlossen.
- Größere repo-weite Prüfungen, mehrstufige Migrationen und Recherche+Implementierung werden für Work in der `WORK QUEUE` der Roadmap gesammelt.
- Work soll ausschließlich freigegebene Queue-Aufgaben bearbeiten und abgeschlossene Pakete nicht unnötig erneut analysieren.
- Der Projektchat entscheidet bei neuen Aufgaben selbstständig, ob direkte Umsetzung oder Work-Queue wirtschaftlicher ist.
