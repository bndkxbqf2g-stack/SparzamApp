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
- REWE wurde als Händlerintegration entfernt. Die Händlerauswahl umfasst damit
  wieder die sechs für dieses Projekt vorgesehenen Märkte; Netto Thüngersheim
  bleibt als Filiale `4371` enthalten.
- Die Netto-Filialseite für Thüngersheim wird jetzt über ihre tatsächlichen
  Produktkacheln ausgelesen: 28 aktuelle Angebote mit Preis, Gültigkeit,
  Nachweis und Bild-URL wurden erfolgreich erkannt.
- Die Rubrik „Angebote“ zeigt ausschließlich aktuell gültige, aus dem
  aktuellen Prospektfeed ausgelesene Angebote. Gespeicherte/manuelle Angebote
  bleiben für Preis- und Routenlogik erhalten, werden dort aber nicht mit der
  Prospektansicht vermischt.
- Gewichtsartikel und kg-Mengen im Bon-Parser sauberer getrennt.
- Gedruckte Kilopreise werden sicher gelesen und im Review gekennzeichnet.
- Exaktes Matching für gewichtete Bananen ergänzt.
- Kaufland-Milch 1,5 % und 3,5 % als getrennte Produkte behandelt.
- Explizite Zuordnung unklar abgekürzter Kaufland-Milchzeilen ermöglicht.
- Milch-Auswahl nur für sicher zuordenbare, ausgeglichene und nicht rabattierte Bonzeilen.

## Update 30.09.2026 – Keine synthetischen Produktionspreise
- Die sechs Produktionsmärkte enthalten keine fest eingebauten Beispielpreise
  mehr. `Store.prices` wird nur durch belegte Beobachtungen, aktuelle Angebote
  oder ausdrücklich gepflegte Nutzerpreise befüllt.
- Eine frische Installation legt keine Demoangebote und keine synthetische
  Preishistorie mehr an. Bekannte Altbestände werden einmalig anhand ihrer
  reservierten Demo-IDs bzw. exakten Beobachtungsschlüssel bereinigt; eigene
  Einträge bleiben erhalten.
- Die Einkaufslisten-Preisauflösung berücksichtigt `validFrom` und
  `validUntil`, sodass ein zukünftiges Angebot vor seinem Startdatum weder als
  Treffer noch als Routenpreis erscheint.
- Die Route-Regressionstests liefern ihre Marktpreise jetzt explizit als
  versionierte Fixture. Dadurch testen sie Preislogik, ohne Produktionsdaten
  als echte Marktbeobachtung auszugeben.
- Für diesen Block: Flutter-Analyse ohne Befund, 423 Tests bestanden und
  `flutter build web --release` erfolgreich.

## Update 30.09.2026 – Angebotsvorrang bei konkreten Varianten
- Das Auswahlfenster für allgemeine Wünsche wie „Käse“ oder „Milch“ priorisiert
  aktive Angebote jetzt vor Bon- und normalen Marktpreisen, auch wenn ein
  historischer Einzelpreis nominal niedriger ist.
- Coupon-/Cashback-Effekte werden im Auswahlpreis berücksichtigt. Gültigkeit,
  Händler und Nachweis bleiben getrennt; abgelaufene Angebote gelangen nicht in
  die Auswahl.
- Eine Regression deckt den Vorrang und den effektiven Couponpreis ab.
- Für diesen Block: Flutter-Analyse ohne Befund, 424 Tests bestanden und
  `flutter build web --release` erfolgreich.

## Update 30.09.2026 – Routenempfehlung bei unvollständiger Preisabdeckung
- Wenn der beste Einzelmarkt nicht alle Listenartikel bepreisen kann, erklärt
  die Empfehlung einen vollständigen Mehrmarktplan als Preisabdeckungs-
  entscheidung. Sie berechnet daraus keine scheinbare Ersparnis gegenüber dem
  unvollständigen Einzelmarkt.
- Eine Regression prüft den Fall mit 50 % Einzelmarkt-Abdeckung und 100 %
  Mehrmarkt-Abdeckung. Die bestehende Warnung für tatsächlich unvollständige
  empfohlene Routen bleibt unverändert.
- Für diesen Block: Flutter-Analyse ohne Befund, 425 Tests bestanden und
  `flutter build web --release` erfolgreich.

## Audit 30.09.2026
- Die App startet jetzt in der Einkaufsliste; ein Widget-Test prüft den sichtbaren Einstieg bei 390 × 844 px.
- Ein doppelter Import in `app_shell.dart` wurde entfernt.
- `flutter analyze`: keine Befunde. `flutter test`: 377 Tests bestanden. `flutter build web --release`: erfolgreich.
- Offener UX-/Katalogbefund: Der Basiskatalog enthält keine frischen Tomatenvarianten. Auf einer frischen Installation wird „Tomate“ deshalb als freies Produkt angeboten, obwohl die Roadmap dieses Beispiel als hierarchische Produktsuche vorsieht. Die vorhandenen Tomatentests verwenden eigens angelegte Testprodukte.
- Architekturhinweis: `app_shell.dart` ist mit rund 1.050 Zeilen weiterhin deutlich größer als die in `ARCHITECTURE.md` angestrebten kleinen Verantwortungsbereiche.
- Die verpflichtenden Kamera-/Neustarttests auf einem echten Android- oder iOS-Gerät sind lokal nicht ausgeführt. Zwei in `REAL_RECEIPT_MATRIX.md` benannte Originalbons fehlen weiterhin als Quelldateien.

## Aktueller Schwerpunkt
Eine intelligente und alltagstaugliche Preisdatenbank aufbauen:
1. Wiederkehrende Einkäufe und bekannte Produktidentitäten lernen.
2. Unklare Bonpositionen nicht dauerhaft starr behandeln.
3. Varianten (z. B. Fettstufe, Packungsgröße, Marke) getrennt halten.
4. Bestätigte Nutzerzuordnungen als Lernsignal verwenden.
5. Angebote als zeitabhängige Preise behandeln, nicht als neue Produkte.
6. Preisqualität/Herkunft/Aktualität nachvollziehbar halten.

## Update 30.09.2026 – Frische Tomaten im Basiskatalog
- Auf einer frischen Installation bietet die Produktsuche jetzt
  Rispentomaten, Partytomaten und Cherrytomaten als getrennte Varianten an.
- Die Identitätshierarchie hält diese Varianten von Tomatenmark, Passata und
  Tomatensauce getrennt; gemeinsame Begriffe erzeugen keinen gemeinsamen
  Preis- oder Routenbeleg.
- Eine Regression prüft die Suche gegen den echten Basiskatalog und verhindert,
  dass die dokumentierte Tomatenfunktion nur in Testkatalogen existiert.
- Für diesen Block: Flutter-Analyse ohne Befund, 425 Tests bestanden und
  `flutter build web --release` erfolgreich.

## Update 30.09.2026 – Angebote und Preise direkt in der Einkaufssuche
- Prospektkarten, Seiten und Zähler verwenden nur aktuell gültige Datensätze. Abgelaufene Seiten werden durch den offiziellen Händlerlink ersetzt.
- Jeder nachgewiesene strukturierte Prospektpreis wird mit Angebotspreis, gegebenenfalls ausgewiesenem Normalpreis, Packung, Händler, Nachweis und Gültigkeit in der lokalen Preisbeobachtungshistorie gelernt. Vergangene, packungsvergleichbare Preise erscheinen in der Einkaufssuche als datierter 90-Tage-Median.
- Historische Prospektpreise werden weder als aktuelle Angebote noch als bestätigte Marktpreise für die Route projiziert. Eine Katalog-ID wird nur bei exakt gleichem Label und nachweislich gleicher Packung wiederverwendet; ähnliche Marken bleiben getrennt.
- Aktuell gültige, belegte Prospektangebote können als eigene exakte
  Suchprodukte erscheinen, auch wenn ein Artikel noch nicht im kleinen
  Basiskatalog steht. Unbekannte Labels werden nicht per Ähnlichkeit mit
  bestehenden Produkten zusammengeführt.
- Exakt übereinstimmende normalisierte Prospektlabels teilen eine ID über
  Märkte hinweg. Erst beim Hinzufügen wird das Produkt in die Einkaufsliste
  übernommen.
- Vorschläge priorisieren gültige Angebote; innerhalb vergleichbarer
  Packungsgrößen entscheidet der normierte Preis. Ohne passendes Angebot
  können aktuelle Marktpreise und vergleichbare Bonpreis-Mediane der letzten
  60 Tage die Reihenfolge bestimmen. Preisquelle und Markt erscheinen direkt
  in den Suchergebnissen.
- Allgemeine Vorratswünsche wie Eier, Brötchen/Aufbackbrötchen, Marmelade,
  Nudeln und Kaffee erhalten generische Produktfamilien; konkrete Varianten
  bleiben getrennt und auswählbar.
- Regressionstests decken Angebotsuche, Preisrangfolge, sichere
  Produktidentität und den Abzug von Fahrtkosten beim Angebotsvergleich ab.
- Der letzte lokale Prospekt-Refresh erhielt für Netto Thüngersheim HTTP 403.
  Ohne verlässliche Angebotsdaten darf die App dort keine aktuellen Preise
  anzeigen; ein belastbarer offizieller Feed bleibt offen.

## Update 30.09.2026 – Wiederholung des Kaufland-Einkaufs vom 26.05.2026
- Der Originalbeleg `20260923_100506.pdf` wurde lokal vollständig simuliert:
  78 Produktzeilen und 102 Buchungszeilen einschließlich Rabatten und Pfand
  balancieren zur gedruckten Summe von 184,08 €. Alle 78 Produktzeilen sind
  nach Bonimport über ihr belegtes Label wieder auffindbar; wiederholte Zeilen
  ergeben 72 unterschiedliche Einkaufslistenprodukte und 132 Einheiten.
- Unbestätigte Bonlabels bekannter Familien werden bis zu zwölf Monate als
  Suchvorschläge erinnert und sichtbar mit „Früher gekauft · Sorte und Packung
  prüfen“ markiert. Sie werden erst durch Antippen zur Einkaufsliste übernommen.
- Solche Suchvorschläge erhalten keinen historischen Familienmedian und keinen
  Routenpreis. Bei `K.H-Milch` erscheinen zusätzlich 1,5-%- und 3,5-%-Milch als
  getrennte Auswahl; die unbekannte Fettstufe wird nicht erfunden.
- Fehlzuordnungen aus dem Beleg wurden generisch korrigiert: Eier-Spätzle zählt
  zu Nudeln, Käse-Croissant zu Backwaren und `R.-Hackfleisch` zu Rind statt zu
  gemischtem Hack. Linguine, Kritharaki und zusammengesetzte
  Weizenbrötchen-Bezeichnungen werden erkannt.

### Angebotsansicht
- Die sichtbare Rubrik „Angebote“ ist bewusst auf den aktuellen Prospekt
  beschränkt.
- Abgelaufene Prospektdatensätze und gespeicherte Einzelangebote werden nicht
  angezeigt.
- Die Daten bleiben intern erhalten, damit die getrennte Preis-/Routenpipeline
  weiterhin historische Nachweise und bestätigte Angebote verwenden kann.

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
- Familienbeobachtungen aus Bons werden bis 90 Tage für historische Hinweise/Statistiken berücksichtigt. Für die konkrete Routenplanung sind Bonpreise wegen der zentralen Frischegrenze nur bis 30 Tage routenfähig; ältere Belege bleiben sichtbar, verändern aber den Routen-Score nicht.
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

## Update 24.09.2026 – Vergleichbarkeit, Familien und externe Identität
- Mengen werden zentral auf kg/l/Stück normalisiert; deklarierte abweichende Packungsgrößen dürfen nicht als exakter Preis derselben Produktpackung in die Route gelangen.
- Bon-Familienpreise werden nur bei sicherer Mengenbasis auf die gewünschte Packung normiert. Ohne sichere Basis bleiben sie Hinweis statt Routenpreis.
- Käse/Wurst besitzen eine breite Familienebene: generische Wünsche dürfen passende Geschwisterbelege nutzen, konkrete Varianten wie Bergkäse jedoch nicht den Preis von Gouda erben.
- Historische Open-Prices-Beobachtungen respektieren Aktivierung und Alterslimit auch bei der Rückprojektion.
- Open Prices wird bedarfsorientiert nur für Produkte der aktuellen Einkaufsliste abgefragt.
- Für Produkte ohne EAN kann Open Food Facts konservativ zur EAN-Suche genutzt werden. Automatisch entdeckte EANs sind zunächst nur Retrieval-Evidenz und erzeugen keinen exakten Routenpreis ohne bestätigte Identität.
- Auch automatische Bon-Vorschläge gelten nicht mehr als bestätigte exakte Produktidentität; nur explizite Zuordnungen dürfen diese Sicherheit herstellen.
- Aktueller nächster großer Prüfschritt: End-to-End-Audit der Preis- und Routenlogik aus der WORK QUEUE.


## Update 25.09.2026 – Bonimport-Review und gewichtete Originalpreise
- Im Bonimport werden vollständig geprüfte Bons vor gesperrten Bons angezeigt; gesperrte Bons starten eingeklappt. Eine Zusammenfassung zeigt, wie viele ausgewählte Bons tatsächlich übernehmbar sind.
- Unzugeordnete Artikelpreise stehen lesbar direkt unter dem Artikelnamen statt gequetscht am rechten Rand. Bei Gewichtsartikeln ohne gedruckten Grundpreis wird nur Masse plus Gesamtpreis gezeigt; ein nicht belegter Einzel-/Kilopreis wird nicht vorgetäuscht.
- Kaufland-Zeilen wie `Bananen kg 0,498 kg 0,64 B` behalten jetzt die gekaufte Masse als `0,498 kg`. Die Familienpreislogik kann daraus bei eindeutig gewünschter Kilobasis den vergleichbaren Preis mathematisch normieren.
- Der letzte Quellen-Upload wurde gegen den Parser auditiert: die drei enthaltenen Kaufland-Bons und zwei Netto-Bons ergeben jeweils exakt ihre gedruckte Bonsumme. Die reale Bon-Matrix dokumentiert diese Originalquellen nun ausdrücklich.
- Die im UI sichtbaren Dateien `Kassenbon_2026-07-24_19.19.pdf` und `Kassenbon_2026-01-16_11.53.pdf` fehlen weiterhin als Originaldateien; deren konkrete Summenabweichung wird deshalb nicht durch Annahmen überbrückt.


## Update 25.09.2026 – Qualitätsranking bleibt durch die Planungsprojektion erhalten
- Die append-only Beobachtungshistorie wird nicht mehr vorzeitig nach dem Prinzip „neuester exakter Preis gewinnt“ reduziert.
- `planningMarketPrices` und `RoutePriceResolver` verwenden dieselbe zentrale Auswahl je Produkt×Markt: Preis plus D025-Unsicherheitsaufschlag, bei Gleichstand der jüngere Beleg.
- Exakte Produktidentität behält weiterhin Vorrang vor Familien-Fallback.
- Ein Regressionstest sichert ab, dass ein älterer, qualitätsbereinigt günstigerer exakter Preis nicht von einem neueren, schlechter bewerteten Preis verdrängt wird.
- Der End-to-End-Audit der aktuellen Preis-/Routenpipeline ist damit bis zu den dokumentierten Originaldaten-Grenzen abgeschlossen. Die vollständige Sieben-Bon-Matrix bleibt wegen fehlender Originalbelege separat offen.


## Update 25.09.2026 – Hierarchische Suchinterpretationen
- Die Einkaufssuche zeigt die bestehende Produktidentität jetzt als Familie → Variante, z. B. `Tomaten › Rispe` oder `Milch › H-Milch · 3,5 %`.
- Primäre Treffer bleiben weiterhin identitätskompatibel. Bei „Tomate“ bleiben frische Tomatenvarianten echte Treffer.
- Verwandte, aber fachlich andere Produkte wie Tomatenmark und Passata werden separat unter „Weitere Interpretationen“ angeboten und nicht in dieselbe Preisidentität hochgestuft.
- Die Darstellung baut auf der zentralen Produktidentitätslogik auf und führt keine neue Alias-Sonderliste als Matching-Grundlage ein.

## Update 25.09.2026 – Externe Angebote benötigen Preisnachweis
- Manuell eingegebene Angebote bleiben als explizite Nutzerbestätigung nutzbar.
- Externe Händler-/Prospektimporte werden nur noch als aufgelöste Angebote akzeptiert, wenn ein echter `proofRef` vorhanden ist.
- Externe Angebots- und Normalpreisbeobachtungen ohne Nachweis erhalten zusätzlich Identitäts-Confidence 0 und können dadurch nicht als exakter Routenpreis projiziert werden.
- Angebotspreis und ausgewiesener Normalpreis bleiben getrennte Beobachtungen; Gültigkeit und Herkunft bleiben erhalten.


## Update 25.09.2026 – Reale Lidl-Plus-Digitalbons
- Zwei hochgeladene Lidl-Plus-Digitalbons aus Zellingen sind als vollständige reale Parser-Regressionen erfasst: 07.05.2026 mit 34,23 € und 18.07.2026 mit 44,84 €.
- Der Bonparser erkennt jetzt Lidl als Händler, `zu zahlen` als Bonsumme und Lidl-Datumszeilen ohne vorangestelltes `Datum`.
- Die Regressionen decken gewichtete Ware mit gedrucktem €/kg-Preis, Mehrfachmengen, mehrere aufeinanderfolgende Lidl-Plus-Rabatte, Preisvorteile und Pfand ab.
- Beide Original-PDFs sind bildbasiert und enthalten keine extrahierbare Textebene. Parserunterstützung und OCR sind deshalb bewusst getrennt: Das Lidl-Layout ist jetzt abgesichert, automatische OCR für Bild-PDFs bleibt ein eigenes offenes Paket.


## Update 29.09.2026 – Bring-Prospektadapter
- Die vom Nutzer geteilten Bring!-Links wurden strukturell ausgewertet. Sie enthalten eine feste Prospekt-BRN (z. B. `brn:bring-de:offersbrochure:218970`) und ein Coverbild und sind damit Referenzen auf genau diese Prospektausgabe, nicht auf automatisch nachfolgende Wochen.
- Ein optionaler `tool/bring_prospects.py`-Adapter entdeckt deshalb aktuelle Prospekte standortbezogen neu, statt alte Share-Links dauerhaft zu verwenden.
- Strukturierte Prospekt-Hotspots werden mit Produktbezeichnung, Angebotspreis, optionalem Normalpreis, Produktbild, Gültigkeit und Prospektnachweis als `leaflet`-Evidenz in den bestehenden Angebots-/PriceObservation-Fluss übernommen.
- Vollständige Prospektseiten werden als Bildseiten an den Bereich „Prospekte“ geliefert. Inhalte ohne strukturierten Preis-Hotspot bleiben Bild-/Prospektevidenz und werden nicht per unsicherem OCR als Preis erfunden.
- Der Adapter ist nur aktiv, wenn `BRING_AUTH_TOKEN`, `BRING_API_KEY` und `BRING_USER_UUID` als GitHub-Secrets vorhanden sind. Ohne diese Zugangsdaten laufen die bestehenden offiziellen Händleradapter unverändert weiter.
- Bei identischem Händler, Produkt, Zeitraum und Angebotspreis behält der Feed den strukturierten Händlerdatensatz als führenden Beleg; Bring ergänzt die Prospektseiten und nur fehlende Angebotsdatensätze.


## Update 30.09.2026 – Bestätigte Bons speisen die Wiederkauflogik
- `buildReplenishmentSuggestions` verarbeitet jetzt neben abgeschlossenen Routen-
  Einkäufen auch bestätigte `ReceiptObservation`-Zeilen.
- Unbestätigte Bonlabels sowie gewichtete/volumetrische Zeilen erzeugen weiterhin
  keinen konkreten Nachkaufvorschlag. Dadurch wird weder eine Produktvariante noch
  eine Stückmenge erfunden.
- Bon und In-App-Kauf am selben Kalendertag werden dedupliziert; die belegte
  Herkunft bleibt an der Vorschlagskarte als `Kaufhistorie`, `bestätigte Bons`
  oder Kombination sichtbar.
- Regressionen decken bestätigte Bonkäufe, Identitäts-/Mengenausschluss und die
  Tagesdeduplizierung ab. Der Vorschlag bleibt aus, wenn das Produkt bereits auf
  der aktuellen Liste steht.


## Update 30.09.2026 – Grundbedarf auf leerer Liste
- Der Basiskatalog markiert häufige Starterartikel (`Milch`, `Eier`, `Joghurt`,
  `Wurstaufschnitt`, `Gouda`, `Aufbackbrötchen`, `Marmelade`, `Spaghetti` und
  `Filterkaffee`) als `isStaple`.
- Diese Produkte erscheinen im Schnellzugriff und bleiben über die hierarchische
  Identitätslogik suchbar. Marken, Fettstufen und andere Varianten werden dabei
  nicht automatisch gleichgesetzt.
- Für die neuen Starterartikel wurden keine Preise oder Angebote erfunden. Ohne
  belegte aktuelle Evidenz markiert die Routenplanung sie weiterhin als
  unvollständige Preisabdeckung.
- Regressionen prüfen Schnellzugriff und Suchbarkeit für die Grundbedarfsbegriffe
  sowie das Speichern des neuen Katalogmerkmals.

## Update 30.09.2026 – Grundvorrat mit hierarchischer Variantenwahl
- Der Basiskatalog enthält jetzt zusätzliche, preisfreie Varianten für Milch,
  Eier, Joghurt, Wurst, Käse, Nudeln und Kaffee sowie Kartoffeln, Äpfel und
  Paprika.
- Reis, Mehl, Öl, Zucker, Salz, Ketchup und haltbare Tomatenprodukte besitzen
  eigene Produktfamilien. Oberbegriffe finden kompatible Varianten; konkrete
  Varianten bleiben für Preis- und Bonzuordnung getrennt.
- „Passierte Tomaten“, „Gehackte Tomaten“, Tomatenmark und Tomatensauce werden
  nicht als frische Tomaten angeboten. Das verhindert, dass eine Konserve in
  der Einkaufsliste oder Route eine Frischware-Preisidentität übernimmt.
- Gruppenbezeichnungen führen die neuen Grundvorratsgruppen einheitlich unter
  „Vorrat“ bzw. „Milch & Käse“; die Preisabdeckung bleibt bewusst leer, bis
  aktuelle Prospekte oder belegte Beobachtungen vorliegen.
- Regressionen decken Identität, Hierarchie, Suchvorschläge und sichtbare
  Warengruppen ab.

## Update 30.09.2026 – Belegsimulation mit Händlerkürzeln
- Der bereitgestellte Kaufland-Beleg wurde lokal als erneuter Einkaufslistenlauf
  simuliert; der Originalbeleg bleibt außerhalb des Repositories.
- 70 von 72 geprüften Produktzeilen führen jetzt zu einer passenden
  preisfreien Katalogauswahl. Abgedeckt sind unter anderem Milch-, Käse-,
  Joghurt-, Tiefkühl-, Wurst-, Nudel-, Gemüse- und Konservenkürzel.
- Zwei nicht belastbar interpretierbare Codes (`bev.sen.SoSp 50` und
  `bev.KidsRoll50`) bleiben bewusst zur manuellen Prüfung offen. Es werden
  weder Produktidentität noch Preis aus dem Kürzel geraten.
- Die Suchrangfolge bevorzugt bei mehreren kompatiblen Varianten die noch im
  Bonlabel erkennbare Bezeichnung, ohne Preis- oder Identitätsvertrauen zu
  erhöhen.

## Update 30.09.2026 – Einheitliche H-Milch-Auswahl
- Die separate Auswahlansicht für generische Einkaufspositionen übernimmt jetzt
  dieselbe offene H-Milch-Interpretation wie die direkte Produktsuche. Ein
  Händlerlabel ohne Fettstufe zeigt beide belegbaren Milchvarianten zur Auswahl;
  keine Variante erbt dabei den Preis der anderen.
- Ein Regressionstest deckt diesen Auswahlpfad ab.

## Update 30.09.2026 – Öffentlicher Prospektcache für Offline-Fallback
- Der zuletzt erfolgreich validierte Feed wird lokal als öffentlicher Cache
  gespeichert. Fällt der Netzwerkabruf aus, kann die App den Feed weiter
  verarbeiten und kennzeichnet das Ergebnis als Cache.
- Die bestehende Gültigkeitsprüfung bleibt vor Anzeige und Routenprojektion
  aktiv. Ein abgelaufenes Cache-Angebot wird deshalb nicht zu einem aktuellen
  Angebot.
- Private Bons, Nutzerpreise und andere lokale Kontodaten gelangen nicht in den
  Cache. Vier Regressionen decken Live-Speicherung, Offline-Fallback,
  abgelaufene Cache-Angebote und beschädigte Cache-Daten ab.

## Update 01.10.2026 – Mobile Bildbon-OCR mit Review-Gate
- JPG-/PNG-Dateien und Kameraaufnahmen werden auf Android/iOS lokal über den
  ML-Kit-Text-Recognizer gelesen. Der erkannte Text läuft danach durch denselben
  `ReceiptDraft`-/Bonreview-Pfad wie durchsuchbare PDFs; Aliaslernen,
  Ausgleichsprüfung und explizite Preisbestätigung bleiben dadurch unverändert.
- Bilddateien werden als strukturierte Bons behandelt und bei gleichem
  Fingerprint wie andere Bons dedupliziert. Ein unlesbares Bild bleibt als
  importierte Referenz sichtbar und erhält eine verständliche Handlungsanweisung.
- Bildbasierte PDF-Seiten ohne Textebene werden auf mobilen Geräten gerendert
  und an denselben OCR-Adapter übergeben. Web, macOS und Linux melden den
  fehlenden mobilen OCR-Support und bieten weiterhin den manuellen bzw.
  durchsuchbaren-PDF-Fallback.
- Die plattformneutrale Regression prüft Bildweiterleitung, Pfadübergabe und
  dass der erkannte Text in denselben Bonreview geparst wird. Eine native
  Geräteabnahme steht noch aus.

## Update 01.10.2026 – Produkt×Markt-Preisabdeckung in der Einkaufsliste
- Das Preisfenster eines Listenartikels löst jetzt die aktivierten Märkte einzeln
  auf. Bei leerer Marktauswahl werden alle sechs konfigurierten Projektmärkte
  gezeigt.
- Je Markt bleibt die Quelle getrennt: ein gültiges Angebot steht vor einem
  Bon- oder eigenen Preis; ohne exakten Preisbeleg erscheint ausdrücklich
  „fehlt“. Es wird kein Kategoriepreis in die Matrix eingesetzt.
- Die Detailansicht zeigt zusätzlich die Belegabdeckung und listet auch Märkte
  ohne Preis. Damit ist vor der Routenansicht erkennbar, ob ein günstiger
  Einzelpreis nur für einen Teil des Warenkorbs bekannt ist.
- Regressionen decken Angebotsvorrang, Bonpreis, fehlende Märkte und die sechs
  Standardmärkte ab. `flutter analyze` ist ohne Befund, alle 444 Flutter-Tests
  sind grün und `flutter build web --release` war erfolgreich.

## Update 01.10.2026 – Deterministische Routen-Gleichstände
- `RouteOptimizer` löst gleiche Preisabdeckung und gleiche qualitätsbereinigte
  Planungswerte jetzt zuerst über weniger Märkte und danach über kanonische
  Marktnamen auf.
- Eine Regression mit gleich teuren EDEKA-/Lidl-Preisen verhindert, dass die
  Empfehlung von der Reihenfolge der Preisquelle abhängt.
- `flutter analyze` ist ohne Befund, alle 445 Flutter-Tests sind grün und
  `flutter build web --release` war erfolgreich.

## Update 01.10.2026 – Mehrmarkt-End-to-End-Fixture
- `test/route_multi_market_e2e_test.dart` vergleicht denselben Warenkorb mit
  vollständiger Preisabdeckung gegen 1, 2 und 3 Märkte.
- Die Regression prüft, dass die günstigste 3-Markt-Aufteilung inklusive
  Rundfahrtkosten empfohlen wird und bei hohen Fahrtkosten wieder der beste
  Einzelmarkt gewinnt.
- Die neue Fixture besteht zusammen mit `flutter analyze`; alle 447 Flutter-
  Tests sind grün und `flutter build web --release` war erfolgreich.
