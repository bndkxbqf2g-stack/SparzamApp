# SparzamApp – Projektstatus

> Diese Datei ist der Einstiegspunkt für jeden neuen Chat und jeden Work-Lauf.
> Vor Änderungen immer zuerst PROJECT_STATUS.md, ARCHITECTURE.md, ROADMAP.md und DECISIONS.md lesen und danach den aktuellen GitHub-Stand prüfen.

## Stand
- Repository: bndkxbqf2g-stack/SparzamApp
- Hauptbranch: main
- Letzter geprüfter Main-Stand: ccba4c38fb07a4af593da37884abead98b6a2bea
- Main-CI zu diesem Stand: 545 Tests, Analyse, Web-Build, Pages-Deployment und Android-APK erfolgreich.
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
- Der frühere UX-/Katalogbefund zu frischen Tomaten ist durch die getrennten
  Basiskatalogprodukte für Rispen-, Party- und Cherrytomaten (Commit 25bd1ba)
  behoben. Verarbeitete Tomatenprodukte bleiben separat.
- Architekturhinweis: `app_shell.dart` ist mit rund 1.050 Zeilen weiterhin deutlich größer als die in `ARCHITECTURE.md` angestrebten kleinen Verantwortungsbereiche.
- Die verpflichtenden Kamera-/Neustarttests auf einem echten Android- oder iOS-Gerät sind lokal nicht ausgeführt. Zwei in `REAL_RECEIPT_MATRIX.md` benannte Originalbons fehlen weiterhin als Quelldateien.

## Aktueller Schwerpunkt
Eine intelligente und alltagstaugliche Preisdatenbank aufbauen:
1. Wiederkehrende Einkäufe und bekannte Produktidentitäten lernen.

## Update 02.10.2026 – Ungültige Mehrfachkaufdaten abgesichert
- Mehrfachkaufregeln werden nur noch bei positiven Kauf-/Bezahlmengen mit
  echter Ersparnis angewendet. Importierte Altwerte wie „3 kaufen, 0 bezahlen“
  fallen auf den normalen Angebotspreis zurück und können keine kostenlose
  Route erzeugen.
- Eine Resolver-Regression prüft den Schutz; Produktidentität, Angebotsgültigkeit
  und die bestehende Angebotsquelle bleiben unverändert.

## Update 02.10.2026 – Cashback-Angebote führen im Variantenfenster
- Ein aktuelles Angebot verdrängt jetzt auch dann den historischen Bon-Median
  desselben Marktes, wenn der sichtbare Angebotsname wegen Cashback „Angebot,
  effektiv“ lautet.
- Die historische Beobachtung bleibt im Preisverlauf erhalten; die Auswahl
  zeigt je Markt keine doppelte, widersprüchliche Preiszeile mehr.
- Eine Regression prüft den Cashback-Fall mit effektivem Angebotspreis.
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

## Update 02.10.2026 – Persönlichen Zeitaufwand in die Routenwahl einbeziehen
- Die Mobilitätseinstellungen bieten jetzt einen optionalen persönlichen
  Zeitwert pro Stunde. Ein Wert von `0 €` lässt die bisherige monetäre Auswahl
  unverändert und zeigt die Wegezeit weiterhin an.
- Wenn ein Wert gesetzt ist, fließt der geschätzte Rundweg als separater
  Zeitwert in den Planungswert ein. Der Wert wird ausdrücklich nicht zu den
  tatsächlichen Warenkorb- oder Fahrtkosten addiert.
- Zusammenfassung und Vergleichskarten kennzeichnen Wegezeit, Zeitwert und
  Planungswert getrennt; Persistenz, Grenzwerte und die Entscheidung für einen
  näheren Einzelmarkt sind regressionsgetestet.

## Update 02.10.2026 – Wegezeit in Routenalternativen
- Die Vergleichskarten im Routenbildschirm zeigen jetzt neben Warenkorb,
  Fahrtkosten und Preisabdeckung auch die geschätzte Wegezeit der jeweiligen
  Ein- oder Mehrmarktroute.
- Die Berechnung verwendet dieselben gespeicherten Straßen-/Fallbackdistanzen
  und das gewählte Verkehrsmittel wie die empfohlene Route. Es entstehen keine
  neuen Preisannahmen; die Zeitinformation dient der transparenten Abwägung
  von Ersparnis, Fahrtkosten und Aufwand.
- Ein Widgettest prüft die sichtbare Zeitangabe zusammen mit Fahrtkosten und
  Preisabdeckung.

## Update 02.10.2026 – Verifizierte Web-Abnahme des aktuellen Stands
- Der gemergte Stand `52009fb` wurde nach dem Deployment im veröffentlichten
  Web-Build geprüft. Flutter CI (`36942607555`) und Release artifacts
  (`36942607423`) waren einschließlich Web-Build, Pages-Deployment und
  Android-APK erfolgreich.
- Der Angebotstab zeigte den datierten aktuellen Prospektstand mit allen sechs
  Filialen und 884 Angeboten: ALDI Süd 46, EDEKA 16, Kaufland 540, Lidl 22,
  PENNY 232 und Netto 28. Abgelaufene Datensätze wurden nicht angezeigt.
- Die Suche nach „Milch“ stellte aktuelle Angebote vor unbelegten Varianten
  dar, darunter PENNY Frische Vollmilch für 0,99 € und PENNY H-Milch für
  1,35 €. Varianten und Packungsangaben blieben getrennt.
- Ein Mehrmarkt-Test zeigte im Routenvergleich die Wegezeiten für die
  Alternativen. Der temporäre Testzustand wurde anschließend aus der
  Browserliste entfernt.
- Die native Geräteabnahme für Kamera, lokale OCR, Neustart und Offlinebetrieb
  bleibt eine separate offene Abnahme, die ein echtes Android- oder iOS-Gerät
  erfordert.

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

## Update 01.10.2026 – Sparroute direkt aus der Einkaufsliste
- Eine gefüllte Einkaufsliste bietet jetzt den sichtbaren Einstieg
  „Sparroute prüfen“.
- Der Callback öffnet die bestehende Routenberechnung mit derselben Liste und
  bewahrt dadurch die gemeinsame Bewertung von Angeboten, Marktpreisen,
  Datenlücken und Fahrtkosten.
- Bei leerer Liste oder fehlender Route-Funktion bleibt der Einstieg verborgen;
  ein Widgettest prüft den sichtbaren Klickpfad.

## Update 01.10.2026 – Prospektquellen zeigen den konkreten Markt
- Die sechs offiziellen Prospektquellen führen jetzt Filial-ID, Ort und
  Adresse aus der bestehenden Markt-Konfiguration mit.
- Prospektkarten und die Detailansicht zeigen den Ort neben dem Händlernamen;
  so bleibt die Entfernungssituation bei Angeboten nachvollziehbar.
- Die bestehende Preisidentität bleibt an den kanonischen Händlernamen gebunden;
  die Filialdaten ergänzen nur die Herkunftsanzeige und erzeugen keine neuen
  Preise.
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

## Update 01.10.2026 – Marktanzahl aus der Händlerkonfiguration
- Die Profilanzeige leitet die aktive Marktanzahl jetzt aus derselben
  konfigurierten Händlerliste wie der Routenoptimierer ab. Eine leere Auswahl
  zeigt dadurch korrekt sechs statt sieben Märkte.
- Doppelte oder unbekannte Namen aus alten lokalen Einstellungen werden nicht
  als aktive Märkte gezählt. Zwei Regressionen decken beide Fälle ab.
- `flutter analyze` ist ohne Befund, alle 449 Flutter-Tests sind grün und
  `flutter build web --release` war erfolgreich.

## Update 01.10.2026 – Teilwarenkörbe in der Markt-Detailansicht
- `StoreShoppingSummary` führt nicht bepreiste oder nur geschätzte Positionen
  als `unpricedItems` und stellt `pricedItemCount`, `totalItemCount` sowie
  `hasDataGaps` bereit.
- `StoreValue` unterdrückt bei unvollständiger Abdeckung die vollständigen
  `isWorthIt`-/Neutral-Aussagen. Die Detailansicht nennt die betroffenen Artikel
  und bezeichnet Kosten und Ersparnis ausdrücklich als Teilwarenkorb.
- Die UI-Regression prüft die sichtbare Warnung „Preisabdeckung unvollständig“
  und verhindert eine irreführende Markt-Empfehlung.
- `flutter analyze` ist ohne Befund, alle 451 Flutter-Tests sind grün und der
  Web-Build wird im Abschlussgate erneut geprüft.

## Update 01.10.2026 – Dashboard kennzeichnet Teilrouten
- `buildShellDashboard` unterdrückt Sparpotenzial und geplanten Budgetverbrauch,
  wenn die empfohlene Route oder ihre Einzelmarkt-Baseline unvollständig ist.
- Die Startseite zeigt dann „—“, „Teilroute prüfen“ und einen direkten Hinweis
  auf die fehlende Preisabdeckung. Eine vollständige Route bleibt unverändert.
- Die Daten- und Widgetregressionen stehen in `shell_dashboard_test.dart` und
  `home_screen_test.dart`.
- `flutter analyze` ist ohne Befund, alle 453 Flutter-Tests sind grün und
  `flutter build web --release` war erfolgreich.

## Update 01.10.2026 – Kaufabschluss sperrt Teilrouten
- `ReceiptScreen` deaktiviert „Einkauf bestätigen“, sobald die Route noch
  unzugeordnete Positionen enthält, und listet diese Artikel mit der fehlenden
  Preisabdeckung auf. Ein unvollständiger Baseline-Vergleich macht nur die
  Ersparnis vorläufig, nicht den Abschluss einer vollständigen Route.
- `AppShell.completePurchase` prüft die Abdeckung zusätzlich im Handler, bevor
  Budget und Kaufhistorie verändert werden.
- `receipt_completion_feedback_test.dart` deckt die blockierte Teilroute ab.
- `flutter analyze` ist ohne Befund, alle 454 Flutter-Tests sind grün und
  `flutter build web --release` war erfolgreich.

## Update 01.10.2026 – Historische Bonmediane sichtbar datiert
- Die Einkaufsliste kennzeichnet vergleichbare Bonfamilienwerte jetzt als
  „Bon-Median (historisch)“ und zeigt bei einem einzelnen Markt den Stand der
  letzten Beobachtung.
- Mehrere historische Marktmediane tragen ebenfalls einen gemeinsamen
  Historie-Hinweis; aktuelle Angebote und route-taugliche Belege bleiben im
  Preisfenster separat gekennzeichnet.
- `receipt_family_price_hint_test.dart` schützt die sichtbare Einzel- und
  Mehrmarktkennzeichnung.
- `flutter analyze` ist ohne Befund, alle 456 Flutter-Tests sind grün und
  `flutter build web --release` war erfolgreich.

## Update 01.10.2026 – Android-Release mit ML-Kit-OCR stabilisiert
- Der Release-Workflow scheiterte in R8, weil `google_mlkit_text_recognition`
  seine vier nicht-lateinischen Recognizer nur als `compileOnly` deklariert,
  der Plugin-Code sie aber referenziert.
- Das Android-App-Modul bündelt die ML-Kit-Abhängigkeiten für Chinesisch,
  Devanagari, Japanisch und Koreanisch explizit. Damit bleibt die lokale
  lateinische Bon-OCR unverändert und der Release-Build kann alle vom Plugin
  referenzierten Klassen auflösen.
- Der anschließende Release-Workflow `36795819509` ist vollständig grün:
  Android-APK inklusive Artifact-Upload, Web-Build, Pages-Deployment und die
  Flutter-CI liefen erfolgreich.

## Update 01.10.2026 – Bon-Mediane in Suchvorschlägen datiert
- Vergleichbare Bon-Mediane aus der historischen Statistik werden in den
  Suchvorschlägen jetzt ebenfalls als historische Werte mit Beobachtungsstand
  angezeigt. Dadurch ist die Herkunft auch bei einer direkten Eingabe wie
  „Milch“ sichtbar.
- Aktive Angebote und aktuelle Preisbelege behalten Vorrang. Sind mehrere
  Suchtreffer in derselben Evidenzklasse, wird der günstigere vergleichbare
  Wert zuerst angezeigt.
- `shopping_suggestions_test.dart` schützt Kennzeichnung und Rangfolge;
  `flutter analyze` ist ohne Befund, alle 456 Flutter-Tests sind grün und
  `flutter build web --release` war erfolgreich.

## Update 01.10.2026 – Varianten-Auswahl nutzt robuste Bonstatistik
- Die Auswahl konkreter Produkte aus einem Oberbegriff verwendet jetzt den
  gespeicherten Median vergleichbarer Bonpreise statt eines einzelnen letzten
  Bons. Dadurch entscheidet ein Ausreißer nicht allein über die Empfehlung.
- Bonwerte ohne sichere gemeinsame Packungs-/Einheitsbasis bleiben in dieser
  Auswahl sichtbar, aber nicht als Preisranking wirksam.
- `shopping_candidate_service_test.dart` schützt Medianbasis und Ausschluss;
  `flutter analyze` ist ohne Befund, alle 457 Flutter-Tests sind grün und
  `flutter build web --release` war erfolgreich.

## Update 01.10.2026 – Dashboard zählt nur aktuell gültige Angebote
- Die Highlight-Anzahl im Dashboard verwendet jetzt das vollständige
  Angebotsfenster aus `validFrom` und `validUntil`. Künftige Angebote werden
  nicht vorzeitig als heutige Angebote angezeigt.
- `shell_dashboard_test.dart` deckt aktuelle, künftige und abgelaufene Angebote
  ab; die übrige Angebots- und Routenlogik bleibt unverändert.
- `flutter analyze` ist ohne Befund, alle 458 Flutter-Tests sind grün und
  `flutter build web --release` war erfolgreich.

## Update 01.10.2026 – Aktueller Prospektfeed wieder mit Netto-Nachweisen
- Der versionierte öffentliche Feed wurde mit dem offiziellen Netto-Filialabruf
  aktualisiert. Netto liefert wieder 28 aktuelle, nachweisbare Angebote mit
  `proofRef` und – soweit vorhanden – Produktbild; zusammen mit ALDI Süd,
  EDEKA, Kaufland, Lidl und PENNY sind damit alle sechs Projektmärkte im
  aktuellen Feed vertreten.
- Der Feed enthält 838 Angebote, die zum Erfassungsstand 01.10.2026 innerhalb
  ihres `validFrom`-/`validUntil`-Fensters liegen. Die App filtert beim Anzeigen
  und Planen zusätzlich immer gegen den aktuellen Tag.
- Die bestehenden Python-Parserregressionen und die JSON-/Diff-Prüfung bleiben
  ohne Befund; es wurden keine Preise oder Produktidentitäten ergänzt, die
  nicht aus der öffentlichen Händlerquelle stammen.

## Update 01.10.2026 – Prospekt-Refresh vor Branch-Schreibzugriff geschützt
- Der Refresh-Workflow reagiert auf `push` jetzt ausschließlich auf `main`.
  Zeitplan und manueller Start bleiben erhalten.
- Damit kann ein PR-Branch den öffentlichen Feed prüfen, aber nicht mehr über
  `git push HEAD:main` ungeprüfte oder konkurrierende Daten in `main` schreiben.

## Update 01.10.2026 – Historische Prospektpreise marktübergreifend sichtbar
- Die historische Prospektstatistik bewahrt jetzt alle belastbaren
  Produkt×Markt-Mediane statt nur eines einzelnen Markt-Hinweises.
- Die Produktsuche wählt daraus den günstigsten zulässigen historischen
  Angebotsmedian und berücksichtigt den Marktfilter. Der Wert bleibt mit
  Markt- und Beobachtungsstand gekennzeichnet und wird nicht als aktueller
  Routenpreis verwendet.
- Die neuen Markt- und Filterregressionen sind in
  `prospect_price_statistics_test.dart` und `shopping_suggestions_test.dart`
  verankert; der vollständige Analyse-, Test- und Web-Build-Gate folgt für den
  Änderungsstand.

## Update 01.10.2026 – Bonparser erkennt typografische Mengentrenner
- Mehrfachmengen aus PDF-/OCR-Text werden jetzt mit `x`, `X` und `×` erkannt.
  Das gilt für vorgelagerte Mengenzeilen sowie kompakte Produktzeilen mit
  Menge vor oder nach dem Einzelpreis.
- Die Preis- und Summenprüfung bleibt unverändert streng: Bei einer
  Abweichung wird die Zeile nicht korrigiert, sondern als ungeklärt markiert.
- Regressionen in `receipt_ledger_test.dart` decken die neuen Darstellungen ab;
  der vollständige Analyse-, Test- und Web-Build-Gate folgt für den
  Änderungsstand.

## Update 01.10.2026 – Kaufland-Bon erneut gegen die Produktsuche geprüft
- Der freigegebene PDF-Bon `20260923_100506.pdf` wurde lokal erneut ausgelesen:
  102 Buchungszeilen, 78 echte Produktzeilen und eine ausgeglichene Summe von
  184,08 €. Die Originaldatei bleibt außerhalb des Repositories.
- Von 72 unterschiedlichen Produktlabels erhalten 70 eine passende
  preisfreie Katalogauswahl. `KLCToilettenpapier` wird jetzt trotz fehlendem
  Trennzeichen als Toilettenpapier erkannt; `Kartoffeln 2,5Kg` schlägt nicht
  mehr fälschlich Kartoffel-Wedges vor.
- Die zwei nicht belastbar interpretierbaren Händlercodes
  `bev.sen.SoSp 50` und `bev.KidsRoll50` bleiben bewusst zur manuellen Prüfung
  offen. Es werden daraus weder Identität noch Preis abgeleitet.
- Regressionen in `receipt_label_resolution_test.dart`,
  `receipt_search_products_test.dart` und `shopping_suggestions_test.dart`
  sichern Präfixnormalisierung, Dublettenvermeidung und die generische
  Variantenrangfolge ab; Analyse, Gesamttests und Web-Build folgen für den
  Änderungsstand.

## Update 01.10.2026 – Varianten-Dialog nutzt gelernte Prospektmediane
- Der Auswahl-Dialog für generische Einkaufswünsche wie „Käse“ oder „Milch“
  erhält jetzt dieselben marktbezogenen historischen Prospektmediane wie die
  direkte Produktsuche.
- Aktive Angebote sowie aktuelle, belegte Markt-/Bonpreise bleiben vorrangig.
  Ein historischer Prospektwert ergänzt nur einen Markt ohne aktuelle Evidenz
  und wird als „Früheres Angebot (Median)“ bzw. „Prospekt-Normalpreis
  (historisch)“ mit Beobachtungsstand angezeigt.
- Historische Prospektwerte werden weder zu aktuellen Angeboten noch zu
  bestätigten Routenpreisen hochgestuft. Pro Markt bleibt im Dialog höchstens
  ein konservativer historischer Hinweis sichtbar.
- `shopping_candidate_service_test.dart` und
  `shopping_candidate_selector_test.dart` sichern Ranking, Marktfilter,
  Evidenztrennung und die sichtbare Datierung ab.
- `flutter analyze` ist ohne Befund, alle 467 Flutter-Tests sind grün und
  `flutter build web --release` war erfolgreich.
## Update 01.10.2026 – Effektiver Angebotspreis im Preisfenster
- Das Preisfenster der Einkaufsliste zeigt Coupon- und Cashback-Angebote jetzt
  mit dem berechneten effektiven Preis und kennzeichnet sie sichtbar als
  „Angebot, effektiv“.
- Suche, Liste und Route verwenden damit dieselbe Berechnung; Mehrfachkauf
  bleibt korrekt mengenabhängig in der Routenplanung.
- Regressionen prüfen Coupon, Cashback und die tatsächlich sichtbare
  Preiszeile. `flutter analyze` ist ohne Befund, alle 469 Flutter-Tests und
  `flutter build web --release` sind erfolgreich.

## Update 01.10.2026 – Milchsuche trennt Zutaten von Standardmilch
- Die veröffentlichte Einkaufsliste zeigte bei der Eingabe „Milch“ zunächst
  Kondensmilch, Milchriegel, Milchschokolade und Käse aus dem aktuellen
  Prospektfeed. Ursache war eine zu frühe Familienzuordnung des Wortteils
  „Milch“.
- Zusammengesetzte Bezeichnungen werden jetzt vor der Milchfamilie aufgelöst;
  die Produktsuche filtert denselben Identitätsfehler auch bei gelernten
  Einkäufen. Dadurch bleiben normale Voll-/H-Milch und ihre Varianten nach
  Angebots- und Preisbeleg-Rangfolge sichtbar.
- Regressionen in `product_identity_test.dart` und
  `shopping_suggestions_test.dart` decken Prospekt- und Lernfälle ab. Die
  vollständigen Flutter-/Web-Gates laufen für diesen Änderungsstand in CI.

## Update 01.10.2026 – Prospekt-Sternchen bleiben bei der Milchsuche sichtbar
- Penny kennzeichnete „Frische Vollmilch*“ mit einem Sternchen direkt am
  Produktwort. Die Identitätsnormalisierung behandelt dieses redaktionelle
  Zeichen jetzt als Trenner, sodass das aktuelle Milchangebot auch in der
  Einkaufssuche gefunden und preislich gerankt wird.
- Eine Regression deckt die echte Prospektbezeichnung mit Sternchen ab; die
  Originalbezeichnung und ihr Nachweis bleiben unverändert.

## Update 01.10.2026 – Zusammengesetzte Produktlabels sauber trennen
- [x] Die zentrale Identität erkennt Kaffee-Kapseln und -Pads, ohne
  Kaffeemaschinen, Kaffeegetränke oder Kaffeegebäck als Kaffeepackung zu
  behandeln.
- [x] Käse-Wiener und Leberkäse bleiben Wurstidentitäten; Hart-, Schnitt-,
  Weich-, Schaf- und Ziegenkäse werden als Käsevarianten gefunden.
- [x] Die Hollandaise-Abkürzung `Holl.` wird nicht mehr mit „Holl. Hartkäse“
  verwechselt.
- [x] Regressionen sichern sowohl die Identität als auch die sichtbare
  Suchauswahl für Kaffee und Käse.

## Update 01.10.2026 – Backwaren, Saucen und Snacks nicht als Grundartikel führen
- [x] Donut-/Franzbrötchen-Bezeichnungen bleiben außerhalb der generischen
  Brötchenfamilie.
- [x] Pasta- und Nudelsaucen werden nicht mehr als Nudeln vorgeschlagen.
- [x] Käse- oder Salz-Stängli bleiben Snackartikel und werden nicht als
  Speisesalz gerankt.
- [x] Die Identitäts- und Suchregressionen prüfen die drei Negativzuordnungen
  mit den aktuellen Prospektlabels. Originalbezeichnung, Quelle und Preis
  bleiben unverändert; nur die Familienzuordnung wird korrigiert.

## Update 01.10.2026 – Grundbegriffe gegen Händlerzusammensetzungen abgesichert
- [x] Brot, Wasser, Saft, Tee und Fleisch sind jetzt eigene bekannte
  Suchfamilien. Toast bleibt als gespeicherte Alt-Familie abrufbar und wird
  bei einer generischen Brotsuche hierarchisch berücksichtigt.
- [x] Brotaufstriche, Wassergeräte/-filter, Saft-Bockwurst, Teewurst,
  Fleischsalat, Tiernahrung, Proteinprodukte, Kosmetik und Nuss-Nougat-Creme
  werden vor der jeweiligen Grundfamilie erkannt.
- [x] Choco-Crossies-/Choclait-Chips bleiben Schokoladen-Snacks und werden bei
  der Kartoffelchips-Suche nicht mehr als Preisidentität geführt. Ein
  generischer Fleischwunsch kann weiterhin Hackfleisch einschließen; die
  gespeicherte Hackfleisch-Unterfamilie bleibt dabei erhalten.
- [x] Die aktuelle Prüfung über 876 Angebote aus sechs Märkten zeigt für die
  betroffenen Suchbegriffe keine Geräte-, Tierfutter-, Aufstrich-, Wurst- oder
  Kosmetiktreffer mehr. Händlerlabels, Quellen und Preise wurden nicht
  verändert.

## Update 01.10.2026 – Fränkische Klöße im Bon-Suchlauf korrekt identifiziert
- Die Bonzeile `K.Klo Frän.Art750g` wird als Kartoffelklöße erkannt. Das
  Händlerkürzel `Klo` darf nicht wegen der bestehenden Toilettenpapier-Abkürzung
  als Haushaltsartikel erscheinen.
- Kartoffelklöße sind als preisfreies Katalogprodukt mit 750-g-Einheit
  auswählbar; es werden keine Preise oder Angebote aus der Bonzeile erfunden.
- Eine Regression prüft die Zuordnung und stellt gleichzeitig sicher, dass
  `KLCToilettenpapier` weiterhin Toilettenpapier bleibt.

## Update 01.10.2026 – Wiederkehrende Einkäufe zeigen aktuelle Preis-Hinweise
- Der Bereich „Bald wieder nötig“ verwendet jetzt dieselbe Preisauflösung wie
  die Einkaufssuche. Aktive Angebote werden dadurch bereits vor dem Hinzufügen
  mit Markt, Preis und Gültigkeit sichtbar.
- Fehlt belastbare Evidenz, bleibt der Hinweis leer; es wird kein Preis
  geschätzt und kein historischer Wert als aktuelles Angebot ausgegeben.
- Ein Widget-Test sichert die sichtbare Angebotszeile und den bestehenden
  Hinzufügen-Flow ab.

## Update 01.10.2026 – Joghurt mit der Ecke bleibt eine eigene Variante
- Die belegte Abkürzung `Mü.Jogh.m.d.Ecke` wird jetzt als „Joghurt mit der
  Ecke“ vorgeschlagen und nicht mehr als beliebiger Fruchtjoghurt vorgezogen.
- Die neue Katalogvariante verwendet bewusst `Packung` als Einheit, solange
  der Beleg keine belastbare Grammangabe enthält; ein Preis wird nicht
  erfunden.
- Eine Regression prüft die Variante und hält Fruchtjoghurt getrennt.

## Update 01.10.2026 – Fehlende Marktpreise werden priorisiert
- Route und Marktansicht nennen fehlende Preisbelege jetzt in einer stabilen
  Reihenfolge statt nur als ungeordnete Sammelmeldung.
- Die Reihenfolge nutzt ausschließlich die Zahl fehlender aktivierter Märkte,
  die Grundbedarfsmarkierung und die Listenmenge. Schätzpreise, historische
  Werte oder fremde Varianten werden nicht als Prioritätssignal verwendet.
- Bei einer vollständigen Preislosigkeit zeigt die Route dieselbe priorisierte
  Datenlückenliste und erklärt, welche belegte Quelle für die Berechnung noch
  benötigt wird.
- Eine reine Fachlogik-Regression prüft die Reihenfolge und den stabilen
  Namens-Tiebreaker. Flutter-CI bestätigt Analyse, 485 Tests und Web-Build;
  der Release-Lauf bestätigt Web, Android und Pages-Deployment.
- Der veröffentlichte Route-Screen zeigt die priorisierte Karte bei einer
  unbelegten Testposition; deren Marktdeckung bleibt mit `0/6` sichtbar.

## Update 01.10.2026 – Evidenz der Routenpreise sichtbar
- Zugewiesene Routenpositionen zeigen jetzt unmittelbar Quelle, Preisstand und
  Qualitätsstufe eines beobachteten Preises beziehungsweise Quelle und
  Gültigkeitsfenster eines aktiven Angebots.
- Die Route fasst zusätzlich zusammen, wie viele Positionen aus Angeboten,
  Bons, eigenen Preisen, Open Prices oder einem hinterlegten Preis ohne
  Quellenstand stammen. Unbepreiste Positionen bleiben ausschließlich in der
  Datenlückenanzeige und werden nicht als Schätzbeleg gezählt.
- Die neue Fachlogik ist in `route_price_evidence_test.dart` gegen Angebots-,
  Bon-, Open-Prices-, eigene und undokumentierte Preisquellen abgesichert.

## Update 01.10.2026 – Wiederkäufe priorisieren offene Preisbelege
- Die Route übernimmt jetzt die lokal gespeicherte Kaufhäufigkeit aus den
  exakten Produkt-IDs der letzten Einkäufe in ihre Datenlückenkarte.
- Bei gleicher Marktdeckung und gleicher Grundbedarfsmarkierung stehen häufig
  gekaufte Positionen vor selten gekauften; die Liste zeigt die bekannte
  Kaufzahl direkt an.
- Die Kaufhistorie erzeugt weder Preise noch Varianten. Ohne passenden
  historischen Produktdatensatz bleibt die bisherige preisfreie Reihenfolge
  erhalten. Eine Fachlogik-Regression schützt Sortierung und Anzeige.

## Update 01.10.2026 – Teure offene Positionen zuerst belegbar machen
- Die Route erhält exakt zugeordneten historischen Preisverlauf zusätzlich
  als Datenlücken-Signal und priorisiert bei gleicher Kaufhäufigkeit das
  höhere bekannte Preisniveau.
- Rabattierte/aktive Angebotswerte, Schätzungen, unsichere Identitäten und
  nicht vergleichbare Packungsgrößen werden aus diesem Signal ausgeschlossen.
- Die Karte nennt den historischen Median ausdrücklich als Historie. Er wird
  nicht in den aktuellen Marktpreis übernommen und nicht für die Route
  verwendet; die Fachlogik-Regression schützt Reihenfolge und Anzeige.

## Update 01.10.2026 – Gelernte Prospektpreise in der Einkaufsliste
- Die Preiszeile eines Listenartikels übernimmt jetzt historische Prospekt-
  Mediane je Markt, wenn für diesen Markt kein aktueller Preisbeleg vorhanden
  ist.
- Historische Werte werden mit Preisstand und dem Hinweis „Prospekt-Median
  (historisch)“ dargestellt. Sie erhöhen nicht die aktuelle Preisabdeckung,
  werden nicht als Angebot ausgegeben und gelangen nicht in die Route.
- Ein aktueller Marktpreis oder ein gültiges Angebot hat je Markt Vorrang vor
  dem historischen Prospektwert. Die sechs Projektmärkte bleiben auch bei
  ausschließlich historischen Daten als fehlende bzw. historische Zeilen
  unterscheidbar.
- Fach- und Widgetregressionen prüfen die historische Fallback-Zeile, den
  Vorrang eines aktuellen Preises und die sichtbare Kennzeichnung im
  Preisfenster.

## Update 01.10.2026 – Spar-Empfehlung bei generischen Produktwünschen
- Die Variantenwahl für Oberbegriffe wie „Milch“ oder „Käse“ wählt jetzt die
  erste Variante mit einem aktuellen Angebot, Markt- oder Bonpreis vor.
- Die Empfehlung bleibt reversibel: alle kompatiblen Varianten bleiben sichtbar,
  die Vorauswahl kann geändert oder erweitert werden, bevor sie in die Liste
  übernommen wird.
- Historische Prospekt-Mediane liefern weiterhin Orientierung, lösen aber keine
  automatische Produktwahl aus. So wird ein alter Angebotswert nicht als
  aktueller Kaufwunsch ausgegeben.
- Eine Widget-Regression prüft Vorauswahl, sichtbare Empfehlung und den
  Übernahme-Flow.

## Update 01.10.2026 – Prospekt-Historie als optionale Detailansicht
- Das Preisfenster eines Listenartikels bietet jetzt eine eigene Detailansicht
  für gelernte Prospektwerte je Markt.
- Die Ansicht zeigt Medianpreis, Beobachtungsanzahl, Angebots- oder
  Normalpreishistorie und das letzte Gültigkeitsende der abgeschlossenen
  Prospekte.
- Die Erklärung macht sichtbar, dass diese Werte nur Orientierung aus der
  Historie sind. Sie erhöhen weder die aktuelle Preisabdeckung noch die
  Routenfähigkeit und werden nicht als aktuelle Angebote ausgegeben.
- Eine Widget-Regression prüft das Öffnen der Detailansicht und ihre
  Markt-/Quell-/Datumskennzeichnung.

## Update 01.10.2026 – Neue Prospektartikel aus dem Angebotstab nutzbar
- Ein aktuell gültiger, nachweisbarer Prospektartikel ohne vorhandenen
  Katalogeintrag kann jetzt auch im Tab „Angebote“ zur Einkaufsliste
  hinzugefügt werden.
- Dafür bleibt die exakte Händlerbezeichnung als separates Prospektprodukt
  erhalten. Es werden keine Aliase, Varianten oder Preise auf andere Produkte
  übertragen; der explizite Klick des Nutzers speichert den Artikel später als
  lokalen Katalogkandidaten.
- Eine Widget-Regression prüft den Add-to-List-Flow für ein unbekanntes,
  aber nachgewiesenes aktuelles Prospektlabel.

## Update 01.10.2026 – Prospekt-Fallback bleibt nachweisgebunden
- Der neue Fallback im Angebotstab wird nur für ein unbekanntes Label mit
  belastbarem `proofRef` aktiviert.
- Fehlende Nachweise, ungültige Preise/Gültigkeitsfenster und mehrdeutige
  Identitäten bleiben nicht auswählbar und werden nicht als Katalogkandidat
  gespeichert.
- Ein Positiv- und ein Negativ-Widgettest sichern beide Bedienpfade.

## Update 01.10.2026 – OCR-Nullzeichen im Bon-Parser begrenzt normalisieren
- Die Simulation des bereitgestellten Kaufland-Bons hat eine typische OCR-
  Verwechslung erkannt: gedruckte Nullen wurden in Geldbeträgen als `@`
  gelesen.
- Der Parser normalisiert `@` ausschließlich innerhalb erkannter Geldtokens;
  Produktbezeichnungen bleiben unverändert. Dadurch werden gültige Zeilen
  wie `@,39` oder `-@,20` nicht mehr still übersprungen.
- Mengen-/Preisabweichungen und die Bilanzprüfung bleiben sichtbar und werden
  nicht automatisch korrigiert. Der Originalbeleg und sein OCR-Rohtext bleiben
  außerhalb des Repositories; der generische Fall ist als Regressionstest
  versioniert.

## Update 01.10.2026 – Prospektstand in den aktuellen Ansichten verifizieren
- Die Ansichten „Angebote“ und „Prospekte“ zeigen jetzt den Zeitstempel des
  geladenen Prospektfeeds und unterscheiden einen Live-Feed vom geprüften
  Offline-Cache.
- Der Hinweis bleibt informativ: Pro Angebot wird weiterhin das eigene
  Gültigkeitsfenster geprüft; ein Feed-Zeitstempel verlängert kein Angebot und
  macht abgelaufene Daten nicht routenfähig.
- Die Widgetregression prüft Zeitformat, Live-/Cache-Provenienz und die
  unveränderte Aussage, dass nur aktuell gültige Angebote angezeigt werden.

## Update 01.10.2026 – Händlerkategorien aus dem Prospektfeed erhalten
- Strukturierte Händleradapter übernehmen jetzt eine ausdrücklich gelieferte
  Kategorie in das Prospektangebot. Die Kategorie bleibt Quellenmetadatum und
  wird nicht in Produktidentität, Preisvergleich oder Routenfähigkeit
  umgedeutet.
- Angebote und Prospekte gruppieren und durchsuchen nach dieser Kategorie,
  wenn sie vorhanden ist. Für Quellen ohne Kategorie bleibt die bisherige
  konservative Label-Klassifikation als sichtbarer Fallback bestehen.
- Parser- und Widgetregressionen prüfen Kategorieerhalt für strukturierte
  ALDI-, EDEKA-, Lidl-, Kaufland- und PENNY-Daten sowie den UI-Fallback.

## Update 01.10.2026 – Händlerkategorien einheitlich darstellen
- Technische Quellwerte wie `02_Obst__Gemuese__Pflanzen`, `getraenke1` oder
  `kuehlregal` werden in Angebote und Prospekte als lesbare, gemeinsame
  Anzeigegruppen dargestellt.
- Die Normalisierung ist ausschließlich Präsentation: Der unveränderte
  Quellwert bleibt am Importdatensatz erhalten und verändert keine
  Produktidentität, Preisbeobachtung, Gültigkeit oder Routenentscheidung.
- Suche und Gruppierung berücksichtigen jetzt sowohl den Quellwert als auch
  die lesbare Darstellung. Unbekannte Quellenkategorien werden nur sprachlich
  formatiert, nicht inhaltlich erfunden.
- Fach- und Widgetregressionen decken Kaufland-Nummernkategorien,
  Händler-Slugs, unbekannte Werte und die bestehende Fallback-Klassifikation
  ab.

## Update 01.10.2026 – Unvollständige Netto-Labels nicht als Produkte führen
- Der Netto-Adapter verwirft jetzt nachweislich unvollständige Platzhalter wie
  reine Rabattwerte (`-21%`), `versch. Sorten`, `gekühlt` und reine
  Herkunftszeilen. Solche Texte sind keine belastbare Produktidentität und
  dürfen deshalb weder als Einkaufslistenvorschlag noch als Preisvergleich
  erscheinen.
- Echte Netto-Produktlabels bleiben unverändert; die Filterung greift nur in
  den drei bestehenden Parserpfaden (Kacheln, Links und Text-Fallback).
- Es werden keine Produktnamen, Bilder oder Preise aus den fehlenden
  Quellinformationen ergänzt. Der offizielle Quellnachweis und die sichtbare
  Datenlücke bleiben erhalten.
- Auch beim geschützten Quellenabruf werden solche Labels nicht aus dem
  vorherigen Feed weitergereicht. Der Bestands-Fallback behält nur weiterhin
  belastbare Netto-Produktlabels.

## Update 01.10.2026 – Fehlende Angebotsquellen im Angebotstab sichtbar halten
- Der Tab „Angebote“ zeigt jetzt auch Märkte ohne aktuelle Datensätze als
  transparente Statuskarte. Ein nicht erreichbarer Händlerfeed verschwindet
  dadurch nicht still aus dem Angebotsvergleich.
- Die Anzeige unterscheidet fehlende aktuelle Angebote, fehlende strukturierte
  Produktdaten und einen fehlgeschlagenen automatischen Abruf. Händlername und
  Filialort bleiben sichtbar; die eigentlichen Angebote werden nicht durch
  Schätzungen ersetzt.
- Eine Widgetregression prüft den Netto-Fall „Automatischer Abruf aktuell
  nicht verfügbar“ direkt im Angebotstab.
- Die Statuskarte bietet zusätzlich den direkten Button „Offiziellen Prospekt
  öffnen“, damit die fehlende Automatikquelle ohne Umweg beim Händler geprüft
  werden kann.

## Update 01.10.2026 – Netto-Reader-Fallback wieder mit aktuellen Angeboten
- Die geschützte Netto-Filialseite wird bei Bedarf über den bereits
  vorgesehenen öffentlichen Reader-Fallback als Markdown gelesen.
- Offizielle Produktlinks liefern wieder belastbare Netto-Angebote mit
  Produktname, ausgewiesenem Angebots-/Normalpreis, Packungsangabe, Bild,
  Gültigkeitsende und Originalnachweis. Der Feed enthält damit wieder Daten
  für alle sechs konfigurierten Märkte; zuletzt wurden 28 Netto-Angebote
  übernommen.
- Der Parser bleibt konservativ: Ohne offiziellen Produktlink und ein
  gekoppeltes Preis-/Gültigkeitsfeld wird kein Angebot erzeugt. Die bestehende
  Filterung unvollständiger Labels bleibt aktiv.
- Eine versionierte Reader-Regression prüft regulären Angebotspreis, Aktion,
  Packungsgröße, Bild, Nachweis und Gültigkeitsende.

## Update 01.10.2026 – Gültige Händler-Fallbacks transparent kennzeichnen
- Wenn ein Händlerabruf zeitweise fehlschlägt, bleiben bereits vorhandene
  Angebote nur mit ihrem eigenen gültigen Zeitraum verwendbar.
- Der Angebotstab zeigt für solche Datensätze jetzt ausdrücklich den letzten
  geprüften Prospektstand und die aktuell fehlende automatische Aktualisierung.
- Die Anzeige ist preisfrei und wird durch eine Widgetregression abgesichert;
  sie reaktiviert keine abgelaufenen Angebote und erzeugt keine neue Quelle.

## Update 02.10.2026 – Fallback-Provenienz in beiden Prospektansichten
- Der Angebotstab und der Prospekte-Tab kennzeichnen gültige Datensätze aus
  einem vorübergehend fehlgeschlagenen Händlerabruf jetzt einheitlich als
  letzten geprüften Prospektstand.
- Die Prospektkarte nennt zusätzlich die Anzahl der gültigen Fallbackangebote;
  die Detailansicht wiederholt den preisfreien Aktualisierungshinweis.
- Eine Widgetregression deckt Karten- und Detailansicht ab. Angebotsgültigkeit,
  Nachweis und Preisfluss bleiben unverändert.

## Update 02.10.2026 – Verwandte Suchvarianten sparenorientiert ordnen
- Bei offenen Bonkürzeln wie `K.H-Milch` werden verwandte, klar getrennte
  Varianten jetzt nach aktueller Evidenz und Angebotspreis sortiert.
- Ein günstiges gültiges Angebot kann dadurch vor unbelegten Varianten stehen;
  die Oberfläche kennzeichnet den Bereich weiterhin als „Weitere
  Interpretationen“.
- Die Sortierung überträgt keine Produktidentität und keinen Preis in die
  Routenplanung. Eine Regression prüft den PENNY-/Kaufland-Milchfall.

## Update 02.10.2026 – Normale Milch bei unklarer H-Milch-Abkürzung einbeziehen
- `K.H-Milch` öffnet im Einkaufsfluss jetzt zusätzlich eindeutig normale
  Milchprodukte neben den getrennten H-Milch- und Fettstufenvarianten.
- Ein aktuelles Angebot für normale Milch kann dadurch an erster Stelle stehen;
  die Produktauswahl bleibt trotzdem getrennt und überträgt keinen Preis auf
  die unbekannte Bonzeile.
- Suchauswahl und Kandidatenfenster haben dieselbe Regel; Regressionen prüfen
  den günstigen normalen Milchpreis in beiden Pfaden.

## Update 02.10.2026 – Preis-Datenlücken direkt bearbeiten
- Routen- und Datenlückenkarten bieten pro offener Listenposition jetzt die
  Aktion „Preis ergänzen“.
- Die Aktion öffnet die bestehende Marktpreis-Ansicht mit allen sechs Märkten;
  manuelle Preise werden weiterhin pro Markt, Quelle und Erfassungsdatum
  gespeichert und nach der Rückkehr sofort in die Route übernommen.
- Eine Widgetregression prüft den Klickpfad. Historische Hinweise bleiben von
  der Bestätigung getrennt und werden nicht automatisch zu Routenpreisen.

## Update 02.10.2026 – Unbelegte Routenpreise bleiben Datenlücken
- Der Routenresolver erzeugt für fehlende Produkt×Markt-Belege keine festen
  Kategoriepreise und überträgt auch keinen Median eines anderen Marktes auf
  den unbekannten Markt.
- Aktive, nachgewiesene Angebote und explizit gespeicherte Markt-/Bonpreise
  bleiben routenfähig; fehlende Positionen erscheinen stattdessen in der
  bestehenden Preis-Datenlücke.
- Resolver-Regressionen sichern ab, dass unbekannte und veraltete Preisstände
  nicht als scheinbare Marktpreise in Route oder Marktansicht gelangen.

## Update 02.10.2026 – Bestätigte Bonvorschläge lernen Produktidentität
- Ein gesetztes Häkchen bei einem eindeutigen Bonpreisvorschlag ordnet die
  konkrete Bonzeile jetzt auch als bestätigte Produktidentität zu. Dadurch
  bleibt die Zuordnung in der `ReceiptObservation` erhalten und kann in das
  marktbezogene Alias-Lernen einfließen.
- Die Auswahl bleibt auf denselben Beleg-Fingerprint begrenzt; unbestätigte
  Vorschläge werden weiterhin nur als Preis- und Beobachtungshinweis geführt.
- Eine Regression prüft die Zuordnung sowohl für die bestätigte als auch für
  die nicht ausgewählte Vorschlagszeile.

## Update 02.10.2026 – Bon-Zuordnung explizit zurücknehmen
- Das Abwählen eines Bonpreisvorschlags entfernt jetzt auch eine zuvor an
  derselben Bonzeile gelernte Zuordnung. Dadurch kann eine Nutzerkorrektur
  einen automatischen Lernvorschlag ohne versteckte Restzuordnung verwerfen.
- Eine vorhandene abweichende manuelle Zuordnung wird dabei nicht überschrieben
  oder gelöscht.
- Die Regression prüft die reversible Auswahl inklusive Beleg-Fingerprint.

## Update 02.10.2026 – Wiederkaufsartikel vor dem Einfügen mit Angeboten prüfen
- Wiederkaufsvorschläge zeigen neben dem schnellen Hinzufügen jetzt die Aktion
  „Angebote und Varianten prüfen“.
- Diese öffnet die bestehende belegbasierte Kandidatenauswahl mit aktuellen
  Angeboten, bestätigten Markt-/Bonpreisen und getrennt sichtbaren historischen
  Prospektwerten. Die Auswahl kann dadurch eine günstigere, kompatible Variante
  vorschlagen, bevor sie in die Einkaufsliste übernommen wird.
- Die aus der Kaufhistorie gelernte Menge wird auf die explizit ausgewählten
  Produkte angewendet. Abbrechen verändert die Liste nicht; der schnelle
  Direktpfad bleibt als bewusste Alternative verfügbar.
- Widgetregressionen prüfen die neue Aktion und den vollständigen Flow inklusive
  Mengenübernahme.

## Update 02.10.2026 – Bonstatistik schützt Einheitenvergleich
- Historische Bonmediane verwenden Grundpreise nur noch bei einer durchgängig
  belegten und einheitlichen Mengendimension. Gemischte Masse-/Volumenbelege,
  ungültige Mengen und teilweise fehlende Mengenmetadaten werden als
  Packungspreise gekennzeichnet und nicht als günstiger Grundpreis gerankt.
- Unterschiedliche Packungsmengen derselben Dimension (z. B. 500 g und 1 kg)
  bleiben über den normalisierten Grundpreis vergleichbar. Legacy-Belege ohne
  Mengenmetadaten bleiben lesbar, solange ihre Einzelpreise gültig sind.
- Die Regression deckt sichere Gewichtsvergleiche, gemischte Dimensionen und
  teilweise fehlende Mengenmetadaten ab.

## Update 02.10.2026 – iOS-Kamerafreigabe erklärt Bon-OCR
- Die native iOS-Kamerabeschreibung nennt jetzt sowohl Barcode-Scans als auch
  das lokale Auslesen von Kassenbonfotos. Damit entspricht der Systemhinweis
  den beiden tatsächlich angebotenen Kamerawegen.
- Die Verarbeitung bleibt im bestehenden lokalen OCR-/Review-Pfad; es werden
  keine Belegbilder in das Repository übernommen.

## Update 02.10.2026 – Preisprojektion nutzt taggenaue Altersgrenzen
- Die gemeinsame Projektion von `PriceObservation` zu `MarketPrice` verwendet
  jetzt dieselbe lokale Kalendertagsgrenze wie die direkte Preisprüfung.
- Ein Beleg am 30-Tage-Grenztag bleibt in Liste und Route konsistent nutzbar;
  ein Beleg am Vortag bleibt ausgeschlossen. Uhrzeitunterschiede erzeugen
  keine widersprüchliche Preisabdeckung mehr.
- Eine Regression deckt den Grenztag und den unmittelbar vorherigen Tag ab.

## Update 02.10.2026 – Bon-Suchfenster schließt den Grenztag ein
- Bon-Mediane und unbestätigte Bonzeilen bleiben in der Produktsuche und im
  Variantenfenster bis einschließlich des konfigurierten Altersgrenzentags
  verfügbar. Der unmittelbar vorherige Tag bleibt ausgeschlossen.
- Zukünftige Beobachtungen werden in diesen Suchpfaden nicht als Preis- oder
  Identitätshinweis verwendet. Damit folgen Suche, Kandidatenranking und
  gemeinsame Preisprojektion derselben kalendertaggenauen Frischegrenze.
- Regressionen prüfen den eingeschlossenen Grenztag und den ausgeschlossenen
  Vortag für beide Sucharten.

## Update 02.10.2026 – Main-Stand nach Status-Synchronisierung
- Der Status wurde nach dem Merge von PR #116 auf `eeee59350c2d8212bc135c307dc2254000d919a0` synchronisiert.
- Der nachgelagerte Main-CI-Lauf `36965653783` und der Release-Lauf `36965653777` sind erfolgreich; der veröffentlichte Webstand und das Android-Artefakt entsprechen damit wieder dem dokumentierten Main-Stand.

## Update 02.10.2026 – Sample-Angebote aus Variantenwahl ausgeschlossen
- Der Varianten-/Wiederkaufspfad filtert reservierte Demoangebote jetzt ebenso wie die direkte Einkaufssuche.
- Die Regression erhöht den geprüften Main-Stand auf 539 Tests; Main-CI `36967553100` und Release `36967553168` sind erfolgreich.

## Update 02.10.2026 – Verifizierte Angebotserparnis in der Einkaufsliste
- Aktive Angebote zeigen in der Einkaufsliste neben dem effektiven Preis jetzt
  die konkrete Ersparnis gegenüber dem verifizierten Normalpreis.
- Coupon- und Cashback-Effekte sind in diesem Betrag enthalten. Ein nicht
  verifizierter oder nicht belegter Normalpreis erzeugt weiterhin keine
  Ersparnisanzeige.
- PR #120 (`8858e871`) ergänzt Fach- und Widgetregressionen; Main-CI
  `36969611852` und Release `36969611952` sind erfolgreich. Der Live-Smoke-Test
  zeigt für das aktuelle Kaufland-Müllermilch-Angebot `0,69 € · Ersparnis
  0,80 €`.

## Update 02.10.2026 – Teststand nach dem Angebotserparnis-Fix
- Der gemergte Main-Stand `42bef668` enthält jetzt 540 bestandene Tests.
- Main-CI `36970553111` und Release `36970552957` sind erfolgreich; Analyse,
  Web-Build, Pages-Deployment und Android-APK bleiben grün.

## Update 02.10.2026 – Preisquelle und Nachweis im Preisfenster
- Die Detailansicht eines Angebots zeigt jetzt Herkunft (z. B. Prospekt oder
  Händler-Website) und ausdrücklich, ob ein `proofRef` vorhanden ist.
- Fehlt der Nachweis, bleibt das sichtbar; dadurch wird ein manueller Preis
  nicht stillschweigend wie ein bestätigter Händlerbeleg dargestellt.
- PR #123 (`c88ab75`) ergänzt Fach- und Widgetregressionen. Die PR-CI bestand
  mit 542 Tests, Analyse und Web-Build; Main-CI `36972753662` und Release
  `36972753666` sind nach dem Merge erfolgreich, einschließlich Analyse,
  Web-Build, Pages-Deployment und Android-APK.

## Update 02.10.2026 – Angebotserparnis im Variantenfenster
- Das Variantenfenster für Wiederkaufs- und Grundbedarfsartikel zeigt bei
  aktiven Angeboten jetzt Quelle, Nachweisstatus und die verifizierte Ersparnis.
- Coupon- und Cashback-Effekte fließen in die sichtbare Ersparnis ein. Ein
  nicht verifizierter Normalpreis bleibt ohne Ersparnisbehauptung.
- Die Produktidentität und die Angebotsrangfolge bleiben unverändert; die
  Detailansicht macht dieselbe Evidenz jetzt bereits vor der Übernahme sichtbar.
- PR #125 (`70bef3f`) ergänzt Fach- und Widgetregressionen. Die PR-CI bestand
  mit 544 Tests, Analyse und Web-Build; Main-CI `36975457591` und Release
  `36975457595` sind erfolgreich, einschließlich Pages-Deployment und
  Android-APK.

## Update 02.10.2026 – Nachweisstatus in der Routen-Evidenz
- Routenpositionen zeigen bei aktiven Angeboten jetzt Quelle und ausdrücklich,
  ob ein `proofRef` vorhanden ist.
- Händler-Website-Quellen mit und ohne Unterstrich werden einheitlich
  dargestellt.
- Preisberechnung, Gültigkeit und Routenauswahl bleiben unverändert; die
  Änderung verbessert die Nachvollziehbarkeit der verwendeten Evidenz.
- PR #127 (`b10bdf6`) ergänzt Fachregressionen. Die PR-CI bestand mit 545
  Tests, Analyse und Web-Build; Main-CI `36977247429` und Release
  `36977247450` sind nach dem Merge erfolgreich, einschließlich
  Pages-Deployment und Android-APK.
