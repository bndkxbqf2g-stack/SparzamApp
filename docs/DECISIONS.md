## D191 – Händlervergleich im Preis-Refresh teilt die Prospekt-Semantik

Der automatische Lernpfad filtert Beobachtungen anhand der vom Feed als frisch gemeldeten Händler.
Dieser Vergleich verwendet denselben Präsentationsschlüssel wie Suche und Coverage: Leerraum,
Großschreibung und die üblichen deutschen `ae/oe/ue`-Transliterationen sind Darstellungsdetails.
Der Schlüssel wird nicht gespeichert und ersetzt weder den sichtbaren Namen noch die exakte Filial-ID.
So kann ein Refresh `ALDI SUED` zuverlässig auf Datensätze mit `ALDI Süd` anwenden, ohne
verschiedene Filialen, Produktvarianten oder Preisrollen zu verschmelzen.

## D189 – Persistenzstatus folgt der aktuellen Preisprojektion

Der lokale Prospektpreis-Ledger bleibt append-only: Ein erfolgreicher Feed-Refresh darf einen
abgelösten regulären Beleg als historische Zeile behalten und mit `isCurrent=false` markieren.
Die UI-Bestätigung der automatischen Speicherung darf deshalb nicht nur die Beobachtungs-ID
finden, sondern muss denselben aktuellen Status prüfen, den die MarketPrice-Projektion für
Routen verwendet. So wird ein historischer Normalpreis sichtbar gehalten, aber nicht erneut
als aktuelle Preisabdeckung gezählt.

## D190 – Händlerdarstellung wird nur für Metadatenvergleich normalisiert

Öffentliche Prospektquellen können denselben Händler in Großschreibung, mit
abweichendem Leerraum oder deutscher Schreibvariante melden. Such-, Coverage-
und Issue-Matching verwenden deshalb einen gemeinsamen normalisierten
Vergleichsschlüssel. Der sichtbare Händlername bleibt unverändert; die exakte
Branch-ID bleibt ein separater Schlüssel und wird nicht durch die
Händlernormalisierung ersetzt. So kann eine Darstellung variieren, ohne
Filialen oder Produktidentitäten zu verschmelzen.

## D188 – Produktauflösungscaches enthalten ihre Validierungsgrundlage

Ein UI-Cache für die Zuordnung eines Prospektartikels zu einem lokalen Produkt darf
nicht nur die technische Quell-ID verwenden. Die Auflösung prüft neben Händler und
exakter Filiale auch EAN, Packungsgröße, Preis, Gültigkeitszeitraum, Quelle,
Adapter, Nachweis und den Regionalstatus. Diese Felder werden deshalb gemeinsam
mit der branch-sicheren Record-Identität im Memo-Schlüssel geführt.

So kann ein geänderter oder korrigierter Feeddatensatz keinen früheren positiven
oder negativen Katalogtreffer übernehmen. Die Regel betrifft nur die lokale
Memoisierung; Datenmodell, Offer-/MarketPrice-Rollen und RouteOptimizer bleiben
unverändert.

## D187 – Prospektkarten verwenden eine filialgenaue Widget-Identität

Ein technischer Quellartikel darf nicht allein anhand seiner ID als Flutter-Widget-Identität
dienen, weil dieselbe ID auf Prospekt- oder Kampagnenebene in mehreren gleichnamigen
Filialen vorkommen kann. Der Schlüssel für Suchkarten, Artikelkarten und die lokale
Produktauflösung kombiniert deshalb Händler und Quell-ID mit vorhandener Branch-ID, Ort
und Adresse. Ohne Quell-ID bleibt der bestehende sichtbare Fallback erhalten und ergänzt
die vorhandene Filialherkunft.

So können virtuelle Listen Karten recyceln, ohne den Add-to-List-Zustand oder eine
aufgelöste Produktvariante zwischen exakten Märkten zu übertragen. Das ändert weder
Offer-/Preisrollen noch die Gültigkeits- und Filialregeln der Datenpipeline.

## D186 – Transiente Prospektangebote verwenden exakte Filialschlüssel

Ein Prospekt-Quellartikel darf nicht anhand seiner technischen Angebots-ID allein
dedupliziert werden. Anbieter-IDs können auf Prospekt- oder Kampagnenebene gelten
und in mehreren gleichnamigen Filialen wiederkehren. Der transiente Snapshot-Schlüssel
kombiniert deshalb ID, Händler sowie vorhandene Branch-ID, Ort und Adresse. So bleiben
gleichnamige Filialen getrennt; reguläre Preisbeobachtungen und deren Persistenzvertrag
bleiben unverändert.

## D185 – Der optionale KaufDA-Rohcache bleibt begrenzt

Der KaufDA-Adapter darf öffentliche Rohantworten lokal zwischenspeichern, aber nur mit
einer festen Grenze von 16 gültigen Einträgen und 8 MiB. Beschädigte oder übergroße
Einträge werden verworfen, die neuesten gültigen Werte werden bevorzugt. Die Begrenzung
schützt lokalen Speicher und ändert weder die Quelle noch die Angebots-/Normalpreis-
Trennung.

## D184 – Cache-Angebote sind vor dem Live-Refresh flüchtig nutzbar

Ein validierter Cache- oder Bundle-Feed darf aktuelle, filialbezogene Angebote sofort
in den In-Memory-Snapshot projizieren, damit Einkaufsliste und Routenhinweise offline
sichtbar bleiben. Diese Offer-Zeilen werden nicht als dauerhafte Preisbeobachtungen
gespeichert. Nur ausdrücklich belegte reguläre Prospektpreise laufen separat durch den
bestehenden PriceObservationStore; der Live-Feed kann den transienten Stand später
ersetzen.

## D183 – Manuelle Prospektübernahme bleibt ein bestätigter Listenpfad

Wenn eine aktuelle, filialbezogene und belegte Prospektzeile wegen mehrerer möglicher
Katalogvarianten nicht automatisch aufgelöst werden kann, darf die UI die exakte
Quellbezeichnung als eigenen Listeneintrag anbieten. Das benötigt eine ausdrückliche
Bestätigung und erzeugt keine automatisch zugeordnete Offer-, Preis- oder Routenidentität.
Regional-only-, unbewiesene, abgelaufene oder preislich ungültige Datensätze bleiben
vollständig gesperrt.

## D182 – Offizielle Prospektkategorien bleiben begrenzt und präsentationsbezogen

Die offiziellen Prospektadapter dürfen bekannte Kategorievarianten wie Unterkategorie,
Abteilung, Kategoriegruppe und einen begrenzten Kategoriepfad übernehmen. Verschachtelte
Objekte werden nur über benannte Präsentationsfelder bis zu einer festen Tiefe gelesen;
IDs, URLs, beliebige Arrays und Quellobjekte werden nicht als Kategorie verwendet. Die
Kategorie bleibt Herkunfts- und Anzeigeinformation und darf keine Produktidentität,
Preisbeobachtung, Gültigkeit oder Routenentscheidung ersetzen.

## D181 – kaufDA-Evidenzfelder bleiben explizit und regional

Der opt-in-kaufDA-Adapter darf bekannte öffentliche Feldvarianten für Bilder, Kategorien, Packungen, Grundpreise und ausdrücklich benannte Normalpreise tolerieren. Verschachtelte Werte werden nur über benannte Präsentationsfelder mit begrenzter Tiefe gelesen; Bildwerte müssen HTTP(S) sein. Eine solche Normalisierung ändert weder die Filialzuordnung noch die regionale-only-Grenze und erzeugt keine fehlenden Identitäts- oder Gültigkeitsnachweise.

## D180 – Prospekt-Evidenzfelder bleiben explizit und getrennt

Die Feedgrenze darf bekannte öffentliche Feldvarianten für Artikelbilder, Kategorien,
Packungsgrößen und Grundpreise tolerieren. Sie liest verschachtelte Werte nur aus
benannten Präsentationsfeldern und verwirft ungültige URLs oder nicht-textuelle
Identitätsannahmen. Fehlende Bilder, Kategorien, Filialdaten oder Gültigkeitsangaben
bleiben als Datenlücke sichtbar; kein Feld ersetzt einen anderen Nachweis.

## D179 – Prospektfeed beim App-Fortsetzen im Hintergrund aktualisieren

Ein validierter Prospektstand, der beim Fortsetzen der App älter als sechs Stunden ist,
löst einen begrenzten Hintergrund-Refresh aus. Der vorhandene lokale Stand bleibt
währenddessen sichtbar; die Aktualisierung verwendet weiterhin nur die konfigurierten
öffentlichen Quellen und den bestehenden Cache-/PriceObservation-Pfad. Fehlende oder
zukünftige Zeitstempel werden konservativ behandelt, und doppelte Lifecycle-Ereignisse
werden kurz gedrosselt; während die App aktiv ist, läuft höchstens ein sechsstündiger Timer. Beim Pausieren wird er beendet, damit weder blockierende noch unnötige Abrufe entstehen.

# SparzamApp – Architektur- und Produktentscheidungen

Diese Datei hält Entscheidungen fest, damit sie in neuen Chats oder Work-Läufen nicht erneut erraten werden.

## D176 – Generische Einkaufslisten zeigen aktuelle Prospektpreise als Variantenhinweis

Ein generischer Listeneintrag wie „Milch“ darf ein aktuelles, belegtes Prospektangebot
für eine bekannte passende Familienvariante in der Marktmatrix anzeigen, sofern
Marktfiliale, Angebotszeitraum, Nachweis und Packungsbasis gültig sind. Die Anzeige
kennzeichnet die konkrete Variante weiterhin über die Angebotsdetails. Konkrete
Varianten bleiben bei ihrer exakten Produkt-ID; die Routenberechnung übernimmt die
familienweite Anzeige nicht automatisch. So gehen aktuelle Prospektdaten nicht
verloren, ohne Produktvarianten still gleichzusetzen.

## D177 – Automatische Bonpreise sind sichtbare Hinweise, aber keine Routenfreigabe

Bonstatistiken für generische Wünsche umfassen auch automatische Zuordnungen und
zeigen deren Markt, Preis und Status als „Variante prüfen“. Bestätigte Preise
bleiben davon getrennt; nur die bestätigte Sicht darf in die routenfähige
Preisprojektion gelangen. Konkrete Varianten sehen ausschließlich ihre exakte
Belegzuordnung.

## D178 – Prospekt-Fallback wählt den neuesten validierten Stand

Wenn Netzwerk, Cache und gebündeltes App-Asset unterschiedliche Prospektstände
liefern, entscheidet `generatedAt` deterministisch. Ein älterer lokaler Cache
darf weder ein neueres gebündeltes Asset noch einen neueren validierten
Netzwerkstand verdecken. Automatisch importierte Angebote werden nicht dauerhaft
im Nutzer-OfferStore gespeichert; sie werden aus dem aktuellen Feed rekonstruiert,
während explizit gespeicherte Nutzerangebote erhalten bleiben.

## D001 – GitHub ist technische Wahrheit
Der gepushte Stand auf main ist der verlässliche Wiederaufsetzpunkt. Ein abgebrochener Chat oder Work-Lauf darf nicht dazu führen, dass nur lokal gedachte Änderungen als umgesetzt gelten.

## D002 – Standard-Start jedes neuen Arbeitslaufs
Vor Projektänderungen zuerst lesen:
1. docs/PROJECT_STATUS.md
2. docs/ARCHITECTURE.md
3. docs/ROADMAP.md
4. docs/DECISIONS.md
Danach aktuellen Branch/Commit und relevante Dateien prüfen.

## D003 – Schrittweise Entwicklung
Kleine, abgeschlossene Arbeitspakete statt großer Umbauten. Nach jedem Paket analysieren, testen, bauen, committen und pushen.

## D004 – Modularität
Dateien klein und Verantwortlichkeiten klar halten. Keine unnötigen Großdateien, keine doppelte Logik.

## D005 – Produktvarianten bleiben unterscheidbar
Relevante Varianten eines Produkts werden nicht nur wegen ähnlicher Bontexte zusammengelegt. Beispiel: Milch 1,5 % und 3,5 % sind unterschiedliche Produktvarianten.

## D006 – Unsicherheit sichtbar lassen
Unklare Bonpositionen werden nicht blind dauerhaft einem Produkt zugeordnet. Bei zu geringer Sicherheit Review/Nutzerentscheidung ermöglichen.

## D007 – Nutzerbestätigung ist Lernsignal
Explizite Korrekturen und Zuordnungen sollen künftiges Matching verbessern, aber korrigierbar und nachvollziehbar bleiben.

## D008 – Angebote sind Preise, keine neuen Produkte
Ein Wochenangebot erzeugt grundsätzlich keine neue Produktidentität. Angebot, Normalpreis, Zeitraum und Quelle gehören zur Preisbeobachtung.

## D009 – Preisquelle bleibt nachvollziehbar
Bonpreis, manuell bestätigter Preis, Open Prices, Angebot und Schätzung dürfen intern nicht ununterscheidbar werden.

## D010 – Regalvideos zunächst nur evaluieren
Die Aldi-Testvideos dienen aktuell ausschließlich der Prüfung, ob Regalvideos für Produkt-/Preiserfassung praktikabel sind. Aus der Videoanalyse werden ohne separate Entscheidung keine Code- oder Datenänderungen vorgenommen.

## D011 – UI-Zielrichtung
Modern, harmonisch, warmweiß/salbeigrün; getrennte Hauptbereiche. Die bereits freigegebene SparzamApp-Designrichtung bleibt Referenz.

## Pflege dieser Datei
Neue dauerhafte Entscheidungen als D012, D013 usw. ergänzen. Bestehende Entscheidungen nur ändern, wenn die Änderung bewusst beschlossen wurde; Änderung kurz dokumentieren.

## D018 – Angebote-Tab zeigt ausschließlich den aktuellen Prospekt
Die sichtbare Rubrik „Angebote“ ist eine aktuelle Prospektansicht. Sie zeigt
nur Prospektdatensätze, deren Gültigkeitszeitraum heute umfasst. Gespeicherte
oder historische Angebote bleiben intern für Preisbeobachtungen und die
Routenplanung erhalten, werden aber nicht mit der aktuellen Prospektansicht
vermischt.

## D019 – Netto Thüngersheim nutzt die Filial-Produktkacheln
Die Netto-Filialseite `4371` in Thüngersheim ist die Quelle für den aktuellen
Prospektfeed. Produktname, Angebotspreis, optionaler Referenzpreis,
Gültigkeitszeitraum und Bild werden aus den zugänglichen Produktkachel-
Attributen gelesen. Die frühere Anchor-Text-Regel bleibt nur als Fallback.

## D012 – Bonpositionen bleiben als Beobachtungen erhalten
Jede vollständig geprüfte Produktzeile eines Bons wird als historische Bonbeobachtung gespeichert, auch wenn noch keine sichere Katalogzuordnung möglich ist. Pfand, Leergut-Rückgaben und reine Rabattzeilen werden nicht als Produkte gespeichert. Unsichere Beobachtungen dürfen später gelernt/zugeordnet werden, ohne bereits als sicherer Katalogpreis zu gelten.

## D013 – Produktfamilie vor exakter Variante
Bonbeobachtungen können eine konservativ erkannte Produktfamilie (z. B. Hackfleisch) besitzen, während die konkrete Variante offen bleibt. So kann die spätere Einkaufslisten-Preislogik generische Begriffe nutzen, ohne Varianten wie gemischtes Hackfleisch/Rinderhack oder Milch 1,5 %/3,5 % fälschlich gleichzusetzen.

## D014 – Historische Bonpreise nur vergleichbar ausweisen, wenn die Basis sicher ist
Preisstatistiken aus Bonbeobachtungen verwenden einen robusten Median und standardmäßig ein 90-Tage-Fenster. Rabattierte Positionen werden aus dem Normalpreis-Median ausgeschlossen. Sind für eine Produktfamilie keine durchgängig vergleichbaren Einzel-/Grundpreise vorhanden, wird der Wert ausdrücklich nur als historischer Packungspreis mit Prüfhinweis angezeigt; daraus wird kein „günstigster Markt“ abgeleitet.

## D015 – Händlerbezogene Bon-Aliase lernen erst nach Wiederholung
Explizite Nutzerzuordnungen werden als Händler+Bonbezeichnung→Produkt-Lernsignal gespeichert. Eine identische Zuordnung wird erst nach mindestens zwei Bestätigungen als gelernt vorgeschlagen. Eine widersprechende spätere Korrektur setzt die Bestätigung für die neue Zuordnung zurück, statt die alte Sicherheit stillschweigend zu übernehmen. Gelernte Treffer bleiben im Bonreview sichtbar und prüfbar.

## D016 – Jede unklare Produktzeile kann manuell zugeordnet werden
Die Review-Oberfläche bietet für jede nicht sicher erkannte Produktposition eine generische, durchsuchbare Katalogauswahl. Eine manuelle Zuordnung bestätigt zunächst die Produktidentität und wird als Alias-Lernsignal gespeichert. Sie erzeugt nur dann zusätzlich einen direkten Katalogpreis, wenn Menge/Packungsbasis bereits sicher genug für einen korrekten Preisvergleich ist.

## D017 – Neue Produkte dürfen kontrolliert aus Bonpositionen entstehen
Wenn für eine erkannte Bonposition noch kein passendes Katalogprodukt existiert, kann im Review direkt ein Produktkandidat angelegt werden. Name, Produktgruppe und Einheit bleiben vor dem Speichern editierbar. Das neue Produkt wird regulär im benutzerdefinierten Katalog gespeichert und die Bonzeile sofort damit verknüpft; die rohe Händlerbezeichnung wird als Alias mitgeführt.

## D018 – Zugeordnete Varianten bekommen getrennte Preisstatistiken
Sobald eine Bonbeobachtung eine konkrete Produkt-ID besitzt, wird ihre Preisstatistik nach dieser Produktidentität und nicht nur nach der groben Produktfamilie gruppiert. Damit dürfen z. B. Milch 1,5 % und 3,5 % trotz gemeinsamer Familie nicht in denselben Median fallen. Familienwerte dienen nur noch als Fallback für noch nicht konkret zugeordnete Beobachtungen.

## D019 – Erkannte Bonprodukte wachsen automatisch in den Katalog
Bei einem vollständig geprüften/ausgeglichenen Bon werden alle echten erkannten Produktpositionen automatisch in den Produktkatalog übernommen, sofern noch keine sichere oder exakt aliasgleiche Produktidentität existiert. Pfand und reine Rabattzeilen bleiben ausgeschlossen. Bei unklaren Varianten wird ausschließlich die tatsächlich gelesene Bonbezeichnung als vorläufige Produktidentität gespeichert; fehlende Details wie Fettstufe oder Packungsvariante werden nicht erfunden. Exakt normalisierte vorhandene Bon-Aliase/Namen werden wiederverwendet, um Dubletten zu vermeiden. Eine automatische Anlage zählt nicht als explizite Nutzerbestätigung für das Alias-Confidence-Lernen.


## D020 – Bonfamilien werden bei der Auswertung aus dem Rohtext neu abgeleitet
Für historische Preisstatistiken wird die Produktfamilie jeder Bonbeobachtung mit der jeweils aktuellen Familienerkennung erneut aus der originalen Bonbezeichnung abgeleitet. So profitieren auch bereits gespeicherte Bons von später verbesserten Alias-/Familienregeln, ohne dass Bons neu importiert oder gespeicherte Beobachtungen migriert werden müssen. Eine vorhandene konkrete productId bleibt davon unberührt und behält Vorrang für variantenspezifische Historien.


## D021 – Tatsächlich bezahlte rabattierte Bonpreise bleiben als Historie sichtbar
Eine echte gekaufte Bonposition wird nicht aus der Einkaufspreishistorie entfernt, nur weil direkt danach ein Artikelrabatt steht. Der auf der Produktzeile ausgewiesene Preis bleibt als belegte historische Preisbeobachtung verfügbar. Rabatt-/Angebotsstatus bleibt als Herkunftsmerkmal erhalten; daraus darf nicht stillschweigend ein dauerhafter Normalpreis abgeleitet werden.


## D022 – Einkaufsliste und Route verwenden dieselbe familienbewusste Preisbasis
Bekannte Bonpreise dürfen nicht nur als UI-Hinweis existieren. Sie werden in die gemeinsame Preisbasis für Einkaufsliste und Routenplanung überführt. Ein generischer Einkaufswunsch (z. B. „Schmand“) darf auf belastbare Beobachtungen derselben konservativen Produktfamilie zurückgreifen. Eine konkrete Variante darf einen Familienpreis dagegen nur übernehmen, wenn die Bonidentität exakt über Name/Alias passt; dadurch bleiben z. B. Milch 1,5 % und 3,5 % getrennt. Historische Bonpreise bleiben als solche gekennzeichnet und sollen in einer folgenden Ausbaustufe hinsichtlich Aktualität/Qualität gegenüber aktuellen Angeboten gewichtet werden.


## D023 – Ziel der Einkaufsoptimierung ist der wirtschaftlichste Gesamteinkauf
Die zentrale Optimierung bewertet nicht isoliert den billigsten Einzelartikel oder Markt. Für jeden geplanten Einkauf werden alle belastbaren Preise der Einkaufspositionen je Markt zusammengeführt und sinnvolle Markt-Kombinationen verglichen. Das Ergebnis soll die wirtschaftlichste Gesamtstrategie sein: ein einzelner Markt oder – nur wenn der Mehrwert den zusätzlichen Aufwand rechtfertigt – eine Kombination aus mehreren Märkten.

In die Bewertung gehören mindestens:
- Warenkorbkosten der jeweiligen Markt-/Routenkombination,
- tatsächlicher zusätzlicher Fahrweg und daraus abgeleitete Fahrtkosten,
- Aktualität, Herkunft und Sicherheit der verwendeten Preise,
- zeitlich gültige Angebote getrennt von historischen/normalen Preisen,
- Produkt- und Packungsvergleichbarkeit,
- fehlende Preise, die nicht stillschweigend als sicher bekannt behandelt werden.

Ein günstiger Einzelpreis allein darf keinen zusätzlichen Markt erzwingen. Beispiel: Schmand kann bei Kaufland 0,79 €, Edeka 0,89 € und Lidl 0,69 € kosten; erst der komplette Warenkorb entscheidet, ob Lidl, Kaufland oder z. B. Lidl + Aldi insgesamt wirtschaftlicher ist. Ein weiter entfernter Markt wie Kaufland kann trotzdem optimal sein, wenn die Gesamtersparnis des Warenkorbs den Mehrweg rechtfertigt.

Die Benutzeroberfläche muss dafür nicht jeden internen Rechenschritt in den Vordergrund stellen. Primäres Produktziel ist ein verständliches Endergebnis wie „am günstigsten: Lidl“ oder „am günstigsten: Lidl + Aldi“, ergänzt um erwartete Einkaufskosten, Fahrtaufwand/-kosten und sinnvolle Vergleichswerte.

## D024 – Mehrere Preise derselben Markt-Produkt-Kombination eindeutig auswählen
Die Routenplanung wählt bei konkurrierenden Beobachtungen einer exakten Produkt-ID pro Markt unabhängig von der Listenreihenfolge die Quelle nach dem Vorrang eigener Preis > Bonpreis > Open Prices. Innerhalb derselben Quelle gewinnt die jüngste Beobachtung. Herkunft und historischer Bonstatus werden im Einkaufsplan angezeigt. Angebotszuordnungen verlangen eine exakte Produkt-ID, damit Varianten nicht wegen ähnlicher Texte denselben Rabatt erhalten. Die weitergehende Gewichtung historischer Preisunsicherheit bleibt ein eigenes Arbeitspaket.

## D025 – Preisqualität verändert den Planungswert, nicht die Kassenprognose
Für die Wahl zwischen Märkten und Routen wird ein sichtbarer Unsicherheitsaufschlag auf den Preisanteil schwächerer Quellen gerechnet. Der erwartete Warenkorb und die Fahrtkosten bleiben unverändert ausgewiesen. Es gelten zunächst folgende heuristische Aufschläge: eigener Preis bis 30 Tage 0 %, danach 5 %; routenfähiger Bonpreis bis 30 Tage 5 %; historische Bonpreise bleiben für Hinweise/Statistiken erhalten, werden aber ab Tag 31 nicht mehr in die konkrete Routenprojektion übernommen; bei einem routenfähigen Bonpreis mit erkanntem Artikelrabatt kommen 10 Prozentpunkte hinzu; Open Prices bis 7 Tage 5 %, danach 10 %; hinterlegter Katalogpreis ohne aktuelle Beobachtung 15 %; zeitlich gültiges, exakt zugeordnetes Angebot 0 %. Die Regeln sind konservative Produktentscheidungen, keine gemessenen Prognosefehler, und sollen bei ausreichenden realen Daten kalibriert werden. Fehlende Schätzpreise qualifizieren weiterhin keine vollständig belegte Route.

## D026 – Beobachtungshistorie neben aktueller Preisprojektion
Neue manuelle und Open-Prices-Preise werden zusätzlich als unveränderliche, deduplizierte Beobachtungen gespeichert. Der aktuelle Marktpreis ist eine Projektion und darf historische Belege nicht löschen. Bonbeobachtungen und Angebotsspeicher bleiben erhalten; sie werden erst mit geprüfter Mengen-/Identitätslogik auf das gemeinsame Modell abgebildet. Jeder Beleg kann Produkt/Familie, Variante/EAN, Markt/Filiale/Region, Betrag/Einheit/Grundpreis, Rabatt-/Angebotszeitraum, Datum, Quelle, Confidence und Nachweisreferenz getrennt führen. Alte lokale Preisformate bleiben lesbar.

## D027 – Konkurrierende Marktpreise nach qualitätsbereinigtem Betrag
Ein fester Quellenvorrang darf einen deutlich veralteten eigenen Preis nicht automatisch über einen aktuellen belegten Preis stellen. Bei mehreren vergleichbaren Beobachtungen für dieselbe exakte Produkt-ID und denselben Markt wählt die Route den niedrigsten Betrag inklusive des nach D025 transparenten Unsicherheitsaufschlags; Quelle und Alter sind getrennte Faktoren. Bei Gleichstand gewinnt der jüngere Beleg. Die erwarteten Kassenkosten bleiben der ungewichtete Preis. Dies ersetzt den festen Vorrang aus D024 für die Routenwahl; die aktuelle Marktpreis-Projektion wird in einem folgenden Paket aus der vollständigen Historie neu abgeleitet.

## D028 – Externe Daten und Rückgabe nur über prüfbare Adapter
Open Prices ist bereits lesend angebunden. Weitere Datensätze/Händlerquellen benötigen eine austauschbare Zuordnung mit EAN, Packungsbasis, Filiale, Angebotsgültigkeit und Herkunft; öffentlich sichtbare Daten sind nicht automatisch zur Weiterverwendung geeignet. Es wird kein fragiles Händler-Scraping eingebaut. Ein späterer Upload eigener Belege/Preise zu Open Prices oder Community-Plattformen erfolgt nur nach ausdrücklicher Nutzerentscheidung, mit geeigneter Belegbereinigung und unter den jeweiligen API-/Lizenzbedingungen.


## D029 – Exakte Beobachtungshistorie ist Eingang der Routenprojektion
Die aktuelle `MarketPriceStore`-Projektion darf die für die Routenwahl sichtbare Historie nicht begrenzen. Gespeicherte `PriceObservation`-Einträge mit konkreter Produkt-ID und voller Identitäts-Confidence werden für unterstützte Quellen (manuell, Bon, Open Prices) zusätzlich in die bestehende Marktpreis-Planungsschnittstelle projiziert. Dadurch kann D027 tatsächlich zwischen mehreren historischen Beobachtungen derselben Produkt-/Markt-Kombination wählen. Familien-only-Beobachtungen oder unsichere Identitäten werden nicht als exakte Produktpreise hochgestuft. Diese Rückprojektion ist eine Übergangsschnittstelle, bis Route und UI das gemeinsame Beobachtungsmodell direkt konsumieren.


## D030 – Bon- und Angebotsdaten werden Evidenz, nicht Ersatz ihrer Fachmodelle
Bonzeilen und Angebote werden zusätzlich in die gemeinsame `PriceObservation`-Historie adaptiert, während ihre bestehenden Fachmodelle vorerst erhalten bleiben. Bonzeilen ohne exakte Produktzuordnung bleiben Familienbeobachtungen; nur eine konkrete bestätigte Produkt-ID erhält volle Identitäts-Confidence. Angebote tragen ihre zeitliche Gültigkeit in der Beobachtung, und abgelaufene Angebote dürfen nicht als aktueller exakter Routenpreis verwendet werden.

## D031 – Vergleichbarkeit kommt vor Preisranking
Vor D025/D027 muss feststehen, dass zwei Preisbeobachtungen fachlich vergleichbar sind. Unterschiedliche Packungsgrößen dürfen nicht anhand des absoluten Packungspreises gegeneinander gewinnen, wenn keine sichere gemeinsame Mengenbasis vorliegt. Einheit und Menge müssen normalisierbar sein; Varianten bleiben getrennt, wenn die Einkaufsliste oder Produktidentität sie unterscheidet. Ein Grundpreis kann den Vergleich unterstützen, ersetzt aber keine sichere Produkt-/Variantenidentität. Das nächste Arbeitspaket implementiert diese Regel zentral statt quellenbezogener Sonderfälle.


## D032 – Work ist eine gezielte Ausführungsebene, kein zweiter Entwicklungsstrom
Der laufende Projektchat bleibt für kleine, klar abgegrenzte Änderungen, Entscheidungen, Tests, Commits und CI-Kontrolle zuständig. Aufgaben mit deutlichem Vorteil durch längere autonome Repo-/Browser-/Datei-Arbeit werden in der `WORK QUEUE` der Roadmap gesammelt. Work bearbeitet nur freigegebene Queue-Einträge und soll bereits abgeschlossene Pakete nicht erneut untersuchen, sofern kein konkreter Fehler dies verlangt. Ein Eintrag wird erst freigegeben, wenn seine dokumentierte Startvoraussetzung erfüllt ist.

## D033 – Generische Familien dürfen Geschwisterevidenz nutzen, konkrete Varianten nicht
Ein generischer Familienwunsch wie „Käse“ oder „Wurst“ darf passende Beobachtungen konkreter Familienmitglieder als Familien-/Historienevidenz verwenden. Ein konkreter Variantenwunsch wie „Bergkäse“ darf dagegen nicht den Preis eines Geschwisterprodukts wie Gouda als exakten eigenen Preis übernehmen. Exakte Produkt-/Aliasidentität bleibt dafür erforderlich. Familienbelege bleiben als solche unterscheidbar und werden nicht stillschweigend zur Variantenidentität hochgestuft.

## D034 – Familienpreis beeinflusst die Route nur mit sicherer Mengenbasis
Familienbeobachtungen dürfen erst dann als Planungs-/Routenpreis verwendet werden, wenn beobachtete Menge/Einheit und gewünschte Packungsbasis sicher normalisierbar und fachlich vergleichbar sind. Fehlt diese Basis, darf die Beobachtung weiterhin als historischer Hinweis oder Datenbeleg sichtbar sein, aber nicht den Routen-Score verändern. Diese Regel gilt vor Unsicherheitsgewichtung und Preisranking.

## D035 – Automatische Identitätserkennung ist Retrieval-Evidenz, keine Bestätigung
Automatische Bon-Vorschläge und über Open Food Facts entdeckte EAN-Kandidaten dürfen Recherche, Matching und weitere Datenabfragen unterstützen, gelten aber nicht allein als bestätigte exakte Produktidentität. Ein daraus abgerufener Preis darf erst nach ausreichend bestätigter Identität in den exakten Routenpreisstrom gelangen. Damit bleibt die Identitäts-Confidence von Quellenqualität und Preisaktualität getrennt.

- Tomato receipt evidence may share the broad historical family, but route planning keeps fresh tomatoes separate from preserved tomato products such as passata or chopped tomatoes.


## D036 – Bring-Share-Links sind Prospektausgaben, keine dauerhaften Aktualitätslinks
Ein geteilter Bring!-Link enthält eine konkrete `offersbrochure`-BRN und darf deshalb nur als Nachweis genau dieser Prospektausgabe behandelt werden. Neue Wochen werden standortbezogen neu entdeckt; alte BRNs werden nicht als „aktuelles Prospekt“ weiterverwendet. Der Bring-Adapter läuft ausschließlich im serverseitigen Refresh mit Secrets. Nur strukturierte Hotspots mit belegter Gültigkeit und Preis werden als `leaflet`-Angebot in die Preisbeobachtung übernommen. Prospektbilder ohne solchen Datensatz bleiben visuelle Evidenz und erzeugen keinen erfundenen Preis.


## D037 – Unbekannte Prospektlabels werden nur als exakte Suchprodukte angeboten
Ein aktueller Prospektartikel ohne sichere Katalogidentität darf als separates, angebotsgebundenes Produkt in der Einkaufssuche erscheinen, wenn Preis, Gültigkeit und externer Nachweis vorhanden sind. Seine ID wird nur aus dem normalisierten Originallabel gebildet; ähnliche oder familienfremde Namen werden nicht automatisch verschmolzen. Beim Hinzufügen wird dieses exakte Label als Produkt gewählt. Ein fehlender regulärer Preis bleibt fehlend. Suchvorschläge priorisieren gültige Angebote; bekannte Packungsgrößen werden vor dem Preisvergleich auf einen gemeinsamen Grundpreis normiert. Ohne Angebot können aktuelle Marktpreise bzw. hinreichend frische, vergleichbare Bonmediane als Rangierhilfe dienen. Diese Suchrangfolge ändert weder die Bestätigung eines Marktpreises noch die Identitäts-Confidence der Route.

## D038 – Aktuelle Prospekte, dauerhafte Preisbelege
Prospektkarten und Bildseiten werden nur für eine belegte, heute gültige Ausgabe angezeigt. Strukturierte Angebotsdatensätze werden bei jedem Abruf als deduplizierte, datierte Preisbeobachtungen gespeichert: Angebotspreis und ein tatsächlich ausgewiesener Normalpreis bleiben getrennt, mit Quelle, Nachweis, Markt, Packung und Gültigkeit. Abgelaufene Beobachtungen mit normalisierbarer Packungsbasis dürfen in der Einkaufssuche als ausdrücklich historischer 90-Tage-Median erscheinen, aber niemals als aktuelles Angebot oder bestätigter Routen-Marktpreis. Eine Katalogprodukt-ID darf ein Prospektpreis nur bei exakt übereinstimmendem Namen und explizit gleicher Packung übernehmen; Familienähnlichkeit allein reicht nicht. Alte importierte Angebote werden beim Laden verworfen und aus dem erfolgreichen aktuellen Feed neu gebildet.

## D039 – Unbestätigte Bonlabels sind Suchgedächtnis, keine Preisidentität
Eine unbestätigte Produktzeile aus einem ausgeglichenen Bon darf zeitlich begrenzt als wiederauffindbarer Einkaufsvorschlag erscheinen. Das Originallabel bleibt als Alias erhalten; nur ein klar abgegrenzter Händlerpräfix darf für die Anzeige entfernt werden. Der Vorschlag wird als früher gekauft und prüfbedürftig gekennzeichnet. Er übernimmt weder einen Familienmedian noch einen exakten Markt- oder Routenpreis. Bei mehrdeutigen Varianten wie `K.H-Milch` werden getrennte vorhandene Varianten zur Auswahl angeboten, ohne die unbekannte Fettstufe automatisch festzulegen. Zusammengesetzte Lebensmittel werden vor Zutatenbegriffen klassifiziert, damit etwa Eier-Spätzle nicht als Eier und ein Käse-Croissant nicht als Käsepreisidentität gelten.

## D040 – Bestätigte Bons erweitern die Wiederkauflogik ohne Identitäts- oder Mengenschätzung
Die Nachkaufprognose darf neben abgeschlossenen In-App-Einkäufen ausdrücklich bestätigte `ReceiptObservation`-Zeilen derselben konkreten Produkt-ID verwenden. Unbestätigte Produktlabels bleiben davon ausgeschlossen. Bonzeilen mit Gewicht oder Volumen zählen erst nach geklärter Packungssemantik als Wiederkaufmenge; sie bleiben bis dahin gültige Preis-/Historienevidenz. Mehrere Quellen am selben Kalendertag werden zu einem Kauftag zusammengeführt, damit ein importierter Bon denselben abgeschlossenen Einkauf nicht doppelt in den Rhythmus einfließen lässt. Die UI zeigt die verwendete Evidenzquelle sichtbar an.

## D041 – Starter-Grundbedarf ist Auswahlhilfe, keine Preisbehauptung
Der Basiskatalog darf häufige Grundbedarfsartikel als `isStaple` markieren, damit sie auf einer leeren Einkaufsliste direkt auswählbar sind. Diese Markierung ist weder eine bevorzugte Marke noch ein Marktpreis und erzeugt keine Preisbeobachtung. Ein Starterartikel wird erst durch einen gültigen aktuellen Angebotspreis oder eine vergleichbare belegte Markt-/Bonbeobachtung routenfähig; fehlt diese Evidenz, bleibt die Datenlücke sichtbar.

## D042 – Produktionsstart ohne synthetische Preisbehauptungen
Produktionsmärkte, Angebotsbestand und Preishistorie dürfen beim ersten Start
keine festen Beispielwerte als reale Beobachtungen ausgeben. Ein leerer
Preisbestand bleibt eine sichtbare Datenlücke, bis aktuelle Prospekte,
Bonimporte, eigene Preise oder andere belegte Quellen ihn füllen. Ältere
Versionen dürfen ihre bekannten Demo-IDs bzw. exakten Demo-Beobachtungen bei
der ersten Migration entfernen, müssen aber alle übrigen Nutzerwerte erhalten.
Angebote sind erst innerhalb ihres vollständigen Gültigkeitszeitraums aktiv;
historische Preisbelege bleiben von aktuellen Routenpreisen getrennt.

## D043 – Aktive Angebote führen die konkrete Variantenwahl an
Wenn ein generischer Einkaufswunsch mehrere konkrete Katalogvarianten zulässt,
werden Varianten mit einem heute gültigen Angebot vor Varianten mit nur
historischen Bon- oder normalen Marktpreisen angezeigt. Innerhalb des
Angebotsvorrangs zählt der effektive Preis einschließlich sicher berechenbarer
Coupon-/Cashback-Effekte. Historische Preise bleiben als Evidenz sichtbar und
werden nicht gelöscht oder zur aktuellen Angebotsbehauptung umetikettiert.

## D044 – Der Grundvorrat erweitert Suche, nicht Preiswissen
Der Basiskatalog darf häufige Varianten und Grundvorratsfamilien enthalten,
damit Wünsche wie „Reis“, „Öl“, „Mehl“ oder „Joghurt“ auf einer leeren Liste
direkt auflösbar sind. Die zentrale Identitätslogik trennt konkrete Varianten
wie Basmati/Parboiled, Raps-/Olivenöl und Bio-/Freilandeier; Aliase dienen nur
der Suche und erzeugen keine Preisbeobachtung. Neue Starterprodukte bleiben
preisfrei, bis ein aktuelles Angebot oder eine nachvollziehbare Markt-/Bonquelle
vorliegt. Verarbeitete Tomaten bleiben als Konservenfamilie von frischen
Tomaten getrennt.

## D045 – Bonabkürzungen verbessern die Suche ohne Identitäts-Bypass
Händlerpräfixe und belegte Abkürzungsmuster dürfen über die zentrale
Produktidentität zu einer preisfreien Katalogauswahl führen. Ein zusätzlicher
Texttreffer wird nur für die Rangfolge genutzt, wenn mehrere kompatible
Familienvarianten übrig bleiben; er erweitert weder die Kompatibilität noch
überträgt er Preise. Ein nicht belastbar interpretierbarer Code bleibt als
prüfbedürftige Bonzeile sichtbar und wird nicht stillschweigend einer
Produktfamilie oder Route zugeordnet.

## D046 – Offline-Prospektcache bleibt öffentlich, datiert und route-sicher
Der letzte erfolgreich validierte öffentliche Prospektfeed darf lokal auf dem
Gerät zwischengespeichert und bei einem vorübergehenden Abruffehler angezeigt
werden. Der Cache enthält keine privaten Belege oder Nutzerpreise. Auch aus dem
Cache werden Angebotsdatensätze vor der Anzeige und Routenplanung mit ihrer
Gültigkeit gefiltert; abgelaufene oder unvollständige Datensätze bleiben
Historie bzw. Nachweis und werden nicht als aktuelle Preise ausgegeben. Der
Feed wird sichtbar als Cache-Ergebnis unterscheidbar gehalten.

## D047 – Bildbon-OCR bleibt lokal und durchläuft denselben Review
JPG-/PNG-Bons und Kameraaufnahmen werden auf Android/iOS lokal mit ML Kit
ausgelesen. Der erkannte Text wird ausschließlich als `ReceiptDraft` in den
bestehenden Bonreview gegeben; ohne ausgeglichenen Bon und explizite
Preisbestätigung entsteht weder eine Preisbeobachtung noch ein Routenpreis.
Web, macOS und Linux verwenden einen sichtbaren manuellen Fallback, weil der
mobile OCR-Adapter dort nicht verfügbar ist. Bildbasierte PDFs ohne
Textebene werden auf mobilen Geräten ebenfalls gerendert und lokal gelesen;
OCR- oder Renderfehler bleiben als unlesbare Referenz im Review.

## D048 – Routenempfehlungen trennen Preisabdeckung und Ersparnis
Wenn der beste Einzelmarkt nicht alle Einkaufspositionen mit belastbaren
Preisen abdeckt, darf ein vollständiger Mehrmarktplan nicht als reine
Ersparnis gegenüber diesem Teilwarenkorb erklärt werden. Die UI benennt in
diesem Fall die vollständige Preisabdeckung als Grund für die Mehrmarkt-
Empfehlung. Eine unvollständige empfohlene Route bleibt weiterhin ausdrücklich
vorläufig und zeigt ihre Datenlücke.

## D049 – Frische Tomatenvarianten bleiben im Basiskatalog getrennt
Der Basiskatalog führt häufige frische Tomatenvarianten mit eigener Produkt-ID,
Packungsbasis und Suchidentität. Ein generischer Suchbegriff wie „Tomate“ darf
Rispentomaten, Partytomaten und Cherrytomaten gemeinsam anbieten; verarbeitete
Produkte wie Tomatenmark, Passata und Tomatensauce bleiben über die bestehende
Hierarchie verwandte, aber separate Identitäten. Eine gemeinsame Familie ist
kein gemeinsamer exakter Preis- oder Routenbeleg.

## D050 – Die Einkaufsliste zeigt Preisabdeckung je aktiviertem Markt
Das Preisfenster eines exakten Listenprodukts führt jeden aktivierten Markt
separat auf. Wenn keine Marktauswahl hinterlegt ist, werden die sechs
Projektmärkte verwendet. Aktive Angebote werden vor sonstigen Beobachtungen
angezeigt; der beste nicht rabattierte Beleg wird nach seiner Aktualität
ausgewählt. Ein fehlender Beleg bleibt als Datenlücke sichtbar und erzeugt
keinen Schätz- oder Routenpreis. Die Matrix ist eine Orientierung für die
Einkaufsliste; die verbindliche Marktzuordnung bleibt der Route vorbehalten.

## D051 – Routen-Gleichstände werden deterministisch aufgelöst
Bei gleicher Preisabdeckung und gleichem qualitätsbereinigtem Planungswert
entscheidet zuerst die Route mit weniger Märkten. Bleibt auch die Marktanzahl
gleich, werden die kanonischen Marktnamen lexikografisch verglichen. Dadurch
ist die Empfehlung unabhängig von der Reihenfolge eingehender Preisquellen
reproduzierbar; ein Gleichstand wird nicht als zusätzliche Ersparnis behauptet.

## D052 – Marktanzahlen kommen aus der konfigurierten Händlerliste
Die Anzeige „Märkte für Empfehlungen aktiv“ wird nicht separat hartcodiert.
Eine leere Auswahl bedeutet genau alle aktuell konfigurierten Händler; doppelte
oder unbekannte Namen aus alten lokalen Einstellungen werden nicht gezählt.
Damit bleiben Profil, Marktfilter und Routenoptimierer auf derselben
Händlerquelle und zeigen im aktuellen Projekt sechs Märkte.

## D053 – Teilwarenkörbe bleiben in der Marktansicht ausdrücklich vorläufig
Die Detailansicht eines einzelnen Marktes führt nicht bepreiste oder nur
geschätzte Listenpositionen separat als Datenlücke. Gesamtpreis, Ersparnis und
Fahrtkosten dürfen für den belegten Teil weiterhin angezeigt werden, müssen aber
als Teilwarenkorb gekennzeichnet sein. Eine vollständige Aussage, dass sich der
Markt lohnt oder dass die Fahrtkosten den Warenkorb übersteigen, wird bei
fehlender Preisabdeckung nicht ausgegeben. Dadurch bleiben fehlende Daten vor
der Einkaufsentscheidung sichtbar und werden nicht als Nullpreis interpretiert.

## D054 – Das Dashboard plant unvollständige Routen nicht als Sparbetrag
Das Dashboard darf eine vorläufige Teilroute informativ anzeigen, darf deren
bekannte Teilkosten aber weder als vollständiges Sparpotenzial noch als geplanten
Budgetverbrauch ausgeben. Bei fehlender Abdeckung zeigt es deshalb einen
Hinweis zur Preisabdeckung, unterdrückt den Sparbetrag und setzt den geplanten
Budgetanteil auf null, bis eine vollständige belastbare Route vorliegt. Ein
Vergleich zwischen einer vollständigen Route und einer unvollständigen
Einzelmarkt-Baseline bleibt ebenfalls als nicht belastbar markiert.

## D055 – Einkauf bestätigen nur mit vollständiger Preisabdeckung
Der Kaufabschluss übernimmt nur eine Route ohne unzugeordnete Positionen in
Budget und Kaufhistorie. Bei einer Teilroute bleibt die Schaltfläche zum
Bestätigen deaktiviert und nennt die fehlenden Artikel; auch der
Abschluss-Handler verweigert eine direkte oder veraltete Teilroutenübergabe.
Ist nur die Einzelmarkt-Baseline unvollständig, darf eine vollständige Route
bestätigt werden, aber ihr Ersparnisvergleich wird als vorläufig gekennzeichnet.

## D056 – Historische Bonmediane bleiben in Einkaufsliste und Suche klar datiert
Bonmediane aus der historischen Preisstatistik dürfen als Orientierung an einem
Listenartikel oder einem Suchvorschlag erscheinen, sind aber keine Zusage für
den heutigen Regalpreis. Einkaufsliste und Produktsuche kennzeichnen sie deshalb
ausdrücklich als historischen Bon-Median und zeigen den Zeitpunkt der letzten
Beobachtung. Aktuelle Angebots- und route-taugliche Preisbelege bleiben davon
getrennt und behalten ihre eigene Quellenkennzeichnung. Aktive Angebote
behalten Vorrang; innerhalb derselben Evidenzklasse darf der günstigere
vergleichbare historische Wert zuerst erscheinen. Die Varianten-Auswahl nutzt
dafür den gespeicherten Median vergleichbarer Bonbeobachtungen; unklare
Packungspreise bleiben aus dem Preisranking heraus.

## D057 – ML-Kit-Spracherweiterungen werden im Android-Release gebündelt
Der Flutter-Plugin-Code für die lokale Bon-OCR referenziert neben Latein auch
optionale ML-Kit-Recognizer. Diese Bibliotheken sind im Plugin nur
`compileOnly`; ein Android-Release mit R8 darf deshalb nicht auf eine lokale
Debug-Konfiguration vertrauen. Die vier optionalen Recognizer werden als
explizite App-Abhängigkeiten gebündelt, damit der Release-Build reproduzierbar
auflösbar bleibt und die OCR-Script-Auswahl keinen fehlenden Klassenfehler
erzeugt.

## D058 – Dashboard zählt Angebote nach vollständigem Gültigkeitsfenster
Die Anzahl der aktuellen Angebote im Dashboard verwendet dieselbe
`validFrom`-/`validUntil`-Prüfung wie Angebotsansicht, Suche und Route. Ein
zukünftiges oder abgelaufenes Angebot darf nicht als heutiges Highlight
erscheinen.

## D059 – Der versionierte Prospektfeed enthält nur nachweisbare aktuelle Angebote
Der versionierte Feed wird nach jedem Abruf auf die dominante aktuell gültige
Prospektperiode je Händler reduziert. Jeder übernommene Datensatz braucht eine
öffentliche `proofRef`, einen positiven Angebotspreis und ein gültiges
Zeitfenster. Wenn ein Händler seine Seite gegen einfache Abrufe schützt, darf
der Adapter einen normalen Browser-User-Agent verwenden; Preise werden dabei
nicht aus Vermutungen oder privaten Daten ergänzt. Der aktuelle Netto-Adapter
liefert dadurch wieder belegte Artikel mit Bild- und Nachweis-URL für die
sechs konfigurierten Märkte.

## D060 – Der Prospekt-Refresh schreibt nur aus main nach main
Der automatische Prospekt-Refresh darf den versionierten Feed nur aus einem
Lauf auf `main`, aus dem Zeitplan oder aus einem manuellen Lauf aktualisieren.
Der `push`-Trigger ist deshalb auf `main` begrenzt. Ein Push auf einen
Arbeits- oder PR-Branch darf niemals per `git push HEAD:main` fremde Änderungen
in den Hauptbranch schreiben und dadurch einen Pull Request überholen.

## D061 – Historische Prospektmediane bleiben je Markt erhalten
Ein Produkt kann in abgelaufenen Prospekten bei mehreren Märkten beobachtet
worden sein. Die Einkaufssuche darf diese Marktinformationen nicht auf den
zuletzt verarbeiteten Markt reduzieren. Der primäre historische Hinweis wird
deshalb deterministisch aus der günstigsten belastbaren Angebotsstatistik
gewählt und trägt die übrigen Marktmediane als Alternativen mit. Diese Werte
bleiben ausdrücklich historisch; sie werden weder als aktuelles Angebot noch
als bestätigter Routenpreis verwendet. Ein aktivierter Marktfilter beschränkt
auch diesen Hinweis auf die ausgewählten Märkte.

## D062 – Mengentrenner im Bonparser bleiben semantisch gleich
Bon- und OCR-Exporte verwenden für Mehrfachmengen sowohl `x`/`X` als auch das
typografische Multiplikationszeichen `×`. Diese Schreibweisen werden in den
drei bereits unterstützten Layouts (Menge vor Preis, Menge in der Produktzeile
und Einzelpreis vor Menge) gleich behandelt. Die Parseränderung verändert
weder das gelesene Label noch die Preisbelege; eine abweichende Gesamtsumme
bleibt weiterhin als ungeklärte Bonzeile sichtbar.

## D063 – Händlerpräfixe dürfen die Produktidentität nicht verdecken
Kaufland-Bons können das bekannte Hausmarkenpräfix `KLC` oder `KBio` ohne
Trennzeichen vor dem Produktnamen drucken. Die Identitätsnormalisierung fügt
für diese bekannten Präfixe nur eine interne Wortgrenze ein; sie erzeugt weder
ein Alias noch eine neue Preisidentität. Im unbestätigten Bon-Suchvorschlag
wird das Präfix zusätzlich aus der Anzeige entfernt, wobei die rohe
Bezeichnung als Alias erhalten bleibt. Undurchsichtige Händlercodes ohne
erkennbares Produkt bleiben weiterhin ungeklärt.

## D064 – Varianten-Dialoge dürfen historische Prospektpreise nur als Kontext nutzen
Der Dialog zur Konkretisierung eines generischen Einkaufswunsches verwendet
dieselbe marktbezogene Prospekthistorie wie die direkte Produktsuche. Aktive
Angebote und aktuelle belegte Markt-/Bonpreise behalten ihre Vorrangklassen.
Ein historischer Prospektmedian ergänzt nur einen Markt ohne aktuelle Evidenz,
bleibt als historische Quelle mit Beobachtungsstand gekennzeichnet und wird
nicht als aktuelles Angebot oder bestätigter Routenpreis weitergereicht. Pro
Markt wird höchstens ein solcher Hinweis angezeigt, damit mehrere historische
Prospektzeilen nicht wie mehrere aktuelle Preisbelege wirken.

## D065 – Einkaufsliste zeigt denselben effektiven Angebotspreis wie Suche und Route
Das Preisfenster eines Listenartikels verwendet für aktive Angebote dieselbe
`effectivePrice`-Berechnung wie die Produktsuche und die Routenauflösung.
Prozent-/Euro-Coupons und Cashback werden deshalb als effektiver Preis angezeigt
und im Quellhinweis ausdrücklich markiert. Mehrfachkauf bleibt mengenabhängig und
wird weiterhin erst in der Routenberechnung auf die konkrete Listenmenge
angewandt. So zeigt die Liste keine scheinbare Ersparnis, die von Suche oder
Route abweicht.

## D066 – Zutatenbegriffe dürfen keine fremde Produktsuche öffnen
Ein allgemeiner Einkaufswunsch wie „Milch“ darf nicht über einen bloßen
Teilstring auf Kondensmilch, Milchriegel, Milchschokolade oder Käse mit
„Milch“ im Markennamen springen. Die Identitätsauflösung prüft solche
zusammengesetzten Bezeichnungen vor der Milchfamilie; der verbleibende
Textfallback ist bei bereits bekannter Identität auf eine vollständige
Bezeichnung begrenzt. Das gilt gleichermaßen für Prospektprodukte und gelernte
Einkäufe. Konkrete Suchanfragen bleiben über ihre eigene Bezeichnung auffindbar,
ohne fremde Preisidentitäten zu übernehmen.

## D067 – Prospekt-Sonderzeichen sind keine Produktbestandteile
Händlerfeeds markieren Angebote teilweise mit einem Sternchen direkt am
Produktwort, etwa `Vollmilch*`. Solche redaktionellen Zeichen werden bei der
internen Identitätsnormalisierung als Worttrenner behandelt. Die unveränderte
Originalbezeichnung bleibt weiterhin die sichtbare Quelle; nur die Zuordnung
zur Produktfamilie wird dadurch robust genug für Angebots- und Preisranking.

## D068 – Zutaten und Gerätekontexte bleiben von Grundprodukten getrennt
Die zentrale Produktidentität behandelt zusammengesetzte Händlerlabels vor der
Familienzuordnung. Kaffeegebäck und Kaffeegetränke dürfen eine Suche nach
Kaffee nicht als Kaffeepackung ausgeben; Kaffeemaschinen und ähnliche Geräte
bleiben ebenfalls außerhalb der Lebensmittelidentität. Kaffeekapseln und
-pads sind dagegen konkrete Kaffeevarianten. Entsprechend bleiben Käse-Wiener
und Leberkäse Wurstidentitäten, während Hart-, Schnitt-, Weich-, Schaf- und
Ziegenkäse als Käsevarianten auffindbar sind. Abkürzungen wie `Holl.` werden
nur im nachgewiesenen Hollandaise-Kontext als Sauce gelesen, damit „Holl.
Hartkäse“ nicht aus der Käsesuche fällt. Diese Regeln verhindern falsche
Preis- und Routenzuordnungen; die sichtbare Originalbezeichnung bleibt
unverändert.

## D069 – Zusammengesetzte Back-, Saucen- und Snacklabels behalten ihre Familie
Die Produktidentität löst Donut-/Franzbrötchen-Bezeichnungen vor der generischen
Brötchenfamilie auf. Pasta- und Nudelsaucen bleiben ebenso außerhalb der
Nudelfamilie wie Käse- oder Salz-Stängli außerhalb der Speisesalzfamilie.
Damit erzeugt eine generische Einkaufssuche keine fremden Preisidentitäten oder
Routenpositionen. Die Händlerbezeichnung, Quelle und der Preis werden nicht
verändert; die Regel wirkt ausschließlich auf die hierarchische
Identitätszuordnung und ist durch negative Suchregressionen abgesichert.

## D070 – Grundfamilien werden vor semantisch fremden Zusammensetzungen erkannt
Die generischen Suchfamilien Brot, Wasser, Saft, Tee und Fleisch dürfen nicht
durch einen enthaltenen Wortteil auf Aufstriche, Geräte, Wurst, Tiernahrung oder
andere Nicht-Grundartikel springen. Solche Bezeichnungen erhalten zuerst eine
eigene hierarchische Identität; Toast und Hackfleisch bleiben als bestehende
Unterfamilien kompatibel, wenn die Anfrage ausdrücklich generisch ist.
Schokoladen-Snacks mit „Chips“ werden ebenfalls vor der Kartoffelchipsfamilie
aufgelöst. Die Regeln ändern weder Händlerlabels noch Preise oder Quellen und
werden mit aktuellen Feed-Labels sowie synthetischen Negativ- und Positivfällen
geprüft.

## D071 – Abgekürzte Klöße werden vor Haushaltskürzeln erkannt
Kaufland kann Kartoffelklöße als `K.Klo Frän.Art750g` drucken. Die zentrale
Identität löst dieses belegte Kürzel vor der allgemeinen `Klo`-Zuordnung für
Toilettenpapier auf und führt es in eine eigene Klöße-Familie. Die Regel bleibt
auf den erkennbaren Kloß-Kontext begrenzt; ein unklarer Händlercode erhält keine
erfundene Produktidentität und keine Preisübernahme.

## D072 – „Joghurt mit der Ecke“ bleibt eine konkrete Joghurtvariante
Die Bonabkürzung `Mü.Jogh.m.d.Ecke` enthält eine belastbare Produktart, aber
keine sichere Packungsgröße. Sie wird deshalb als eigene Joghurtvariante
`ecke` geführt und mit der neutralen Einheit `Packung` angeboten. Die Variante
teilt weder Identität noch Preisbasis mit Natur- oder Fruchtjoghurt, bis eine
konkrete Packung bestätigt ist.

## D073 – Preis-Datenlücken werden ohne Preisannahmen priorisiert
Route und Marktansicht sortieren ungeklärte Listenpositionen zuerst nach der
Anzahl aktivierter Märkte ohne belastbaren Preis. Bei gleicher Abdeckung folgen
Grundbedarfsmarkierung und gewünschte Listenmenge; Produktname und ID bilden
den stabilen Tiebreaker. Diese Reihenfolge dient nur der Arbeitsplanung für
fehlende Daten. Sie darf weder geschätzte Preise erzeugen noch historische
Familienwerte, fremde Varianten oder unbestätigte Belege als Marktpreis
hochwerten.

## D074 – Routenpreise zeigen ihre Evidenz direkt an
Jede zugewiesene Routenposition zeigt die verwendete Evidenzklasse: aktives
Angebot mit Quelle und Gültigkeit, beobachteter Preis mit Quelle und
Beobachtungsstand oder ein hinterlegter Preis ohne dokumentierten Quellenstand.
Die Anzeige ist rein erklärend und ändert weder die Routenfähigkeit noch die
Qualitäts- und Fahrtkostenberechnung. Eine Zusammenfassung der Route zählt nur
belegte Positionen; fehlende Positionen bleiben in der separaten Datenlückenliste
und werden nicht als Schätzpreise ausgegeben.

## D075 – Wiederkäufe schärfen die Datenlücken-Priorität
Die Route darf die bekannte Kaufhäufigkeit einer exakt identischen
Produkt-ID als zusätzliches, preisfreies Relevanzsignal verwenden. Sie folgt
weiterhin zuerst der fehlenden Marktdeckung und der Grundbedarfsmarkierung;
erst danach entscheidet die gespeicherte Kaufhäufigkeit vor der gewünschten
Listenmenge. Die Historie liefert dabei weder einen Preis noch eine Variante:
IDs werden nicht über Aliasnamen oder Produktfamilien zusammengeführt. Fehlt
die Kaufhistorie, bleibt die bisherige deterministische Reihenfolge bestehen.

## D076 – Historisches Preisniveau bleibt ein reines Datenlücken-Signal
Für eine offene Listenposition darf ein Median aus exakt zugeordneten,
regulären historischen Preisbeobachtungen die Reihenfolge der Datenlücken
schärfen. Rabattierte/Angebotsbeobachtungen, Schätzquellen, unsichere
Identitäten und nicht vergleichbare Packungen werden ausgeschlossen. Das
Preisniveau wird ausdrücklich als Historie angezeigt und weder als aktueller
Marktpreis gespeichert noch durch `RoutePriceResolver` für eine Route
verwendet. Fehlende Historie lässt die Position in der bisherigen
deterministischen Reihenfolge weiterlaufen.

## D077 – Prospekt-Historie ergänzt fehlende Listenpreise nur sichtbar
Die Einkaufsliste darf einen historischen Prospekt-Median je Markt als
Orientierung zeigen, wenn für die exakte Produktidentität kein aktueller
Preisbeleg vorhanden ist. Ein aktuelles Angebot oder ein aktueller
Marktpreis verdrängt diesen Hinweis für denselben Markt. Der historische Wert
trägt seinen Preisstand und die Kennzeichnung „historisch“, zählt nicht zur
aktuellen Preisabdeckung und wird weder als Angebot noch als `MarketPrice` für
die Routenplanung verwendet.

## D078 – Produktempfehlungen werden nur aus aktueller Evidenz vorausgewählt
Bei einer generischen Einkaufsanfrage darf die Variantenwahl die erste
kompatible Produktvariante mit aktuellem Angebot, Marktpreis oder routenfähigem
Bonpreis vorauswählen. Historische Prospekt-Mediane bleiben sichtbare
Orientierung und lösen keine automatische Produktauswahl aus. Die Vorauswahl
ist eine reversible UI-Empfehlung; erst die ausdrückliche Übernahme ändert die
Einkaufsliste.

## D079 – Prospekt-Historie bleibt eine erklärende Detailansicht
Die Einkaufsliste darf gelernte Prospekt-Mediane je Markt in einer optionalen
Detailansicht zusammenfassen. Diese Ansicht zeigt Medianpreis,
Beobachtungsanzahl, Angebots- oder Normalpreishistorie und das letzte
Gültigkeitsende, damit die Herkunft der Orientierung nachvollziehbar bleibt.
Historische Beobachtungen zählen weiterhin nicht zur aktuellen Preisabdeckung,
werden nicht als aktuelles Angebot ausgegeben und dürfen nicht als Preisquelle
für `RoutePriceResolver` oder eine Routenempfehlung dienen.

## D080 – Unbekannte Prospektartikel bleiben exakt und explizit auswählbar
Ein aktuell gültiger Prospektdatensatz mit belastbarem Nachweis darf aus dem
Angebotstab zur Einkaufsliste übernommen werden, auch wenn die lokale
Produktidentität noch keinen Katalogtreffer besitzt. Dafür wird ausschließlich
das unveränderte Händlerlabel als separates Prospektprodukt verwendet. Es
werden keine Aliase, Familienvarianten oder fremden Preisidentitäten ergänzt;
die Übernahme durch den Nutzer ist die ausdrückliche Bestätigung dieses
Kandidaten. Erst danach kann die bestehende Katalog- und Preislernlogik daran
weiterarbeiten.

## D081 – Prospekt-Fallbacks benötigen weiterhin belastbare Evidenz
Der Prospekt-Fallback im Angebotstab greift ausschließlich bei einem
unbekannten Produktlabel mit nicht leerem `proofRef`. Ungültige Preis- oder
Gültigkeitsdaten, fehlende Nachweise und mehrdeutige Identitäten bleiben
gesperrt. So erweitert der Fallback die Produktabdeckung, ohne die
Nachweisgrenze der Angebots- und Routenpipeline zu umgehen.

## D082 – Prospektpreise behalten den konkreten Filialbezug
Die sechs offiziellen Prospektquellen schreiben ihre konfigurierte Filial-ID,
ihren Ort und ihre Adresse in den Feed-Metadatenblock. Die App zeigt diese
Angaben in der Prospektkarte und im Detail, damit ein Angebot vor der
Routenentscheidung als Zellingen, Thüngersheim oder Würzburg erkennbar bleibt.
Die Angaben stammen ausschließlich aus der bestehenden Markt-Konfiguration;
sie ändern weder den kanonischen Händlernamen noch Preisidentität oder
Routenpreis. Fehlende Artikelbilder, Kategorien und bild-only OCR bleiben
separate Datenqualitäts- und Review-Aufgaben.

## D083 – OCR-Korrekturen bleiben auf Geldtokens begrenzt
Wenn ein OCR-Lauf eine gedruckte Null in einem Geldbetrag als `@` liefert,
darf der Bon-Parser dieses Zeichen ausschließlich innerhalb des erkannten
Geldtokens als Null lesen. Produktlabels und Identitätsbestandteile werden
nicht verändert. Mengen-, Preis- und Bilanzabweichungen bleiben sichtbar und
blockieren die automatische Bestätigung; eine OCR-Korrektur darf keine
fehlende Zeile oder einen abweichenden Gesamtbetrag erfinden.

## D084 – Feed-Frische und Cache-Provenienz bleiben sichtbar
Die Ansichten „Angebote“ und „Prospekte“ zeigen den Zeitstempel des
Prospektfeeds und kennzeichnen einen Offline-Fallback als letzten geprüften
Stand. Diese Anzeige beschreibt nur die Datenherkunft. Die Gültigkeit bleibt
pro Angebotsdatensatz das maßgebliche Gate; `generatedAt` verlängert kein
Angebot, erhöht keine Preisabdeckung und macht keinen abgelaufenen Preis für
die Routenplanung verwendbar.

## D085 – Händlerkategorien bleiben Quellenmetadaten
Wenn ein strukturierter Händleradapter eine Kategorie liefert, wird sie am
`OfferImportRecord` erhalten und darf die Gruppierung und Suche in den
Prospektansichten steuern. Fehlt sie, verwendet die UI ihren bestehenden
konservativen Label-Fallback. Eine Kategorie darf weder eine Produktidentität
bestätigen noch Preise, Vergleichbarkeit, Angebotsgültigkeit oder
Routenfähigkeit verändern; nicht gelieferte Kategorien werden nicht erfunden.

## D086 – Kategorieanzeige normalisiert nur die Präsentation
Technische Händlerwerte dürfen für die Anzeige in gemeinsame, lesbare Gruppen
übersetzt werden, damit Nummernpräfixe, Unterstriche, Transliterationen und
bekannte Slugvarianten nicht als uneinheitliche Bedienoberfläche erscheinen.
Die Rohkategorie bleibt unverändert am Importdatensatz erhalten. Die
Normalisierung ist weder eine neue Identitätslogik noch eine Preis- oder
Gültigkeitsannahme; unbekannte Werte werden lediglich sprachlich formatiert,
und fehlende Quellkategorien bleiben fehlend.

## D087 – Unvollständige Netto-Labels werden nicht zu Produktidentitäten
Wenn eine geschützte Netto-Quelle nur einen Rabatt, eine Sorten-/Kühlungs-
beschreibung oder eine reine Herkunftszeile liefert, wird dieser Datensatz
vor der Feed-Erzeugung verworfen. Ein solcher Text darf weder als unbekannter
Prospektartikel noch als Preisbeobachtung in die Einkaufsliste gelangen.
Die Prüfung ist bewusst auf bekannte, eindeutig unvollständige Muster
begrenzt, damit echte Produktlabels unverändert bleiben. Fehlende Namen,
Bilder und Preise werden nicht aus Kontext ergänzt; nur ein später belastbarer
Quellbeleg darf diese Datenlücke schließen.

## D088 – Bestands-Fallbacks dürfen verworfene Netto-Labels nicht reaktivieren
Wenn der offizielle Netto-Abruf fehlschlägt, darf der letzte gültige Feed als
vorsichtiger Fallback dienen. Dabei wird dieselbe konservative
Produktlabel-Prüfung erneut auf die Bestandsdaten angewendet. So werden alte
Rabatt-, Sorten-, Kühlungs- oder Herkunftsplatzhalter nicht erneut als
aktuelle Einkaufsoptionen angeboten, während belastbare Produktlabels und
ihre ursprünglichen Nachweise erhalten bleiben.

## D089 – Fehlende Angebotsquellen bleiben im Angebotsvergleich sichtbar
Ein Händler ohne aktuell belastbare Angebotsdaten wird im Tab „Angebote“ als
Quellenstatus angezeigt, sofern der Prospektfeed ihn kennt. Die Statuskarte
nennt Händler und Filiale sowie die konkrete Ursache (kein aktueller Zeitraum,
fehlende strukturierte Daten oder Abruffehler), liefert aber keinen Preis und
keine erfundene Produktidentität. So bleibt der Angebotsvergleich vollständig
und die Nutzerin kann eine Datenlücke von „kein Angebot gefunden“ unterscheiden.

## D090 – Statuskarten verlinken nur auf die offizielle Händlerquelle
Wenn ein Angebotsfeed fehlt, darf die Statuskarte die konfigurierte offizielle
Prospekt-URL öffnen. Der Link dient ausschließlich der manuellen Prüfung der
Quelle; er erzeugt keinen Preis, keine Produktidentität und keine automatische
Routenbeobachtung. So bleibt die Nutzerin handlungsfähig, ohne die
Nachweisgrenze der App zu umgehen.

## D091 – Netto-Readerdaten bleiben offizielle Prospektevidenz
Wenn die öffentliche Netto-Filialseite für den automatischen Abruf geschützt
ist, darf der bereits vorgesehene öffentliche Reader-Fallback dessen
Markdown-Kacheln auswerten. Ein Datensatz wird nur aus einem offiziellen
`ViewMMPWishlist-AddStoreArticle`-Link mit Produktname, Preis und
Gültigkeitsende übernommen; der Link bleibt der Nachweis und die Bild- bzw.
Packungsangabe wird nur übernommen, wenn sie im selben Reader-Block steht.
Die Gültigkeit des einzelnen Links bleibt maßgeblich. Reine Rabatt-, Sorten-
oder Herkunftszeilen erzeugen weiterhin keine Produkte. So werden belastbare
Netto-Angebote wieder sichtbar, ohne einen Preis aus einer Schätzung oder
einem fremden Feed zu erzeugen.

## D092 – Aktive Fallbackangebote bleiben als Fallback sichtbar
Wenn ein Händlerabruf fehlschlägt, aber bereits gespeicherte Angebotsdatensätze
mit gültigem Zeitfenster verbleiben, zeigt die Angebotsansicht einen preisfreien
Hinweis auf den letzten geprüften Prospektstand. Die Datensätze bleiben durch
ihre eigene Gültigkeit anzeigbar und routenfähig; der Hinweis erzeugt keinen
Preis und verlängert kein Angebotsfenster. So bleiben Datenherkunft und
Aktualisierungsstatus für die Nutzerin unterscheidbar.

## D093 – Fallback-Provenienz gilt in Angebote und Prospekte
Ein gültiger Bestands-Fallback wird in den beiden Prospekt-Einstiegspunkten
gleich bezeichnet. Der Angebotstab zeigt den Hinweis direkt bei den
Marktangeboten; der Prospekte-Tab nennt zusätzlich die Anzahl der gültigen
Datensätze. Beide Ansichten verwenden weiterhin ausschließlich die eigene
Gültigkeit und den Originalnachweis eines Datensatzes. Die gemeinsame
Kennzeichnung ist ein Herkunftshinweis und erzeugt weder Preis noch Identität.

## D094 – Verwandte Interpretationen werden nach aktueller Evidenz sortiert
Wenn eine unklare Anfrage mehrere ausdrücklich als verwandte Interpretation
angezeigte Produktvarianten zulässt, stehen aktuelle Angebote und danach
aktuelle belegte Preise vor historischen Hinweisen und unbelegten Varianten.
Innerhalb derselben Evidenzstufe wird der günstigste belastbare Preis zuerst
gezeigt. Die Sortierung ändert weder die Produktidentität noch überträgt sie
den Preis einer verwandten Variante auf die ursprünglich angefragte Identität.

## D095 – Unklare H-Milch-Kürzel öffnen die normale Milchauswahl
Ein Bonkürzel wie `K.H-Milch` enthält keine belastbare Fettstufe und darf im
Einkaufsfluss deshalb neben 1,5-%- und 3,5-%-H-Milch auch eindeutig als normale
Milch erkannte Produkte zur Auswahl stellen. Jede Produktidentität bleibt
getrennt; ein Angebot für Frischmilch bestätigt weder die Bonzeile noch eine
andere Milchvariante. Die aktuelle Angebots- und Preisrangfolge entscheidet,
welche Auswahl zuerst angezeigt wird, ohne einen Preis zu übertragen.

## D096 – Persönlicher Zeitwert bleibt vom Kassenbetrag getrennt
Die Routenplanung darf neben Warenkorb, Fahrtkosten und der bestehenden
Preisunsicherheitsreserve einen optionalen persönlichen Zeitwert berücksichtigen.
Er wird aus der geschätzten Wegezeit und einem in den Mobilitätseinstellungen
gespeicherten Euro-Wert pro Stunde berechnet und fließt ausschließlich in den
`planningScore` ein. `RoutePlan.total`, Budget, Kaufabschluss und gespeicherte
Kaufkosten bleiben unverändert. Der Standardwert ist `0 €`, damit bestehende
Nutzerdaten nicht stillschweigend mit einer fremden Zeitbewertung belastet
werden; Wegezeit bleibt auch dann sichtbar.

## D097 – Preis-Datenlücken führen direkt zur bestehenden Bestätigung
Eine offene Preis-Datenlücke darf aus der Routenansicht direkt die bestehende
Marktpreis-Ansicht öffnen. Die Nutzerin bestätigt dort weiterhin jeden
Marktpreis einzeln als manuellen Preis mit Erfassungsdatum; historische
Mediane, Angebote und Schätzwerte werden nicht automatisch übernommen. Nach
der Rückkehr wird die Route mit den gespeicherten Preisen neu berechnet, damit
die Datenlücke sichtbar und ohne Medienbruch schließbar bleibt.

## D098 – Marktübergreifende Mediane bleiben Hinweise
Der Routenresolver darf für ein Produkt×Markt-Paar nur einen belegten
Marktpreis, ein gültiges Angebot oder einen ausdrücklich gepflegten
Preisbeleg verwenden. Fehlt dieser Beleg, liefert der Resolver keine
Kategorie-Schätzung und überträgt auch keinen Median eines anderen Marktes auf
den unbekannten Markt. Historische bzw. marktübergreifende Mediane bleiben in
der Einkaufssuche und Preis-Datenansicht als gekennzeichnete Orientierung
erhalten; die Route zeigt die Position als Datenlücke.

## D099 – Ungültige Mehrfachkaufregeln werden nie zu Gratispreisen
Ein Mehrfachkauf-Angebot ist nur dann routenwirksam, wenn Kauf- und
Bezahlmenge positiv sind und die Bezahlmenge darunter liegt. Ungültige oder
alte importierte Werte bleiben als normales Angebot lesbar; sie dürfen weder
als Mehrfachkauf angezeigt noch die erwarteten Kassenkosten auf null senken.

## D100 – Aktive Angebote verdrängen historische Marktzeilen derselben Auswahl
Wenn ein aktuelles Angebot für eine konkrete Produkt-/Markt-Kombination
vorliegt, wird der historische Bon-Median dieses Marktes im Variantenfenster
nicht zusätzlich als zweite gleichrangige Zeile angezeigt. Das Angebot bleibt
mit seinem effektiven Coupon-/Cashbackpreis sichtbar; historische Belege
bleiben in der getrennten Historie erhalten und werden nicht gelöscht.

## D101 – Historische Bonpreise brauchen eine gemeinsame Mengeneinheit
Eine Bonpreisstatistik gilt nur dann als grundpreisbasiert vergleichbar, wenn
alle Beobachtungen einen gültigen positiven Einzelpreis besitzen und ihre
Mengenmetadaten dieselbe Einheitendimension (Masse, Volumen oder Stück)
belegen. Unterschiedliche Packungsmengen innerhalb derselben Dimension dürfen
weiter über den Grundpreis zusammengefasst werden; bekannte g/kg- und
ml/cl/l-Einheiten werden dafür zuerst auf kg bzw. l normiert. Gemischte
Dimensionen, ungültige Mengen oder nur teilweise vorhandene Mengenmetadaten
fallen auf den historischen Packungspreis zurück. Alte Beobachtungen ohne
Mengenmetadaten bleiben aus Kompatibilitätsgründen lesbar und vergleichbar,
sofern ihre Einzelpreise gültig sind.

## D102 – Die iOS-Kamerafreigabe erklärt beide lokalen Kamerawege
Die iOS-Kamera-Berechtigungsbeschreibung nennt sowohl das Scannen von
Produktbarcodes als auch das lokale Auslesen von Kassenbonfotos. Beide Wege
verwenden dieselbe Kamera-Freigabe; die Bonbilder werden für die OCR lokal
verarbeitet und nicht durch die Berechtigungsbeschreibung als Uploadquelle
ausgegeben.

## D103 – Altersgrenzen werden taggenau über alle Preisprojektionen angewendet
Die Frischegrenze einer Preisbeobachtung wird anhand des lokalen
Kalendertages von Erfassung und Prüfzeitpunkt berechnet. Die gemeinsame
`PriceObservation`-Projektion und das daraus entstehende `MarketPrice`
verwenden dadurch am Grenztag dieselbe Entscheidung; Uhrzeiten innerhalb
eines Tages machen einen Beleg weder früher noch später routenfähig.

## D104 – Bon-Suchhinweise verwenden eine inklusive Kalendertagsgrenze
Bon-Mediane und unbestätigte Bonzeilen dürfen am konfigurierten Altersgrenzentag
noch als Such- bzw. Auswahlhinweis erscheinen. Erst Beobachtungen vor diesem
Tag werden ausgeschlossen; zukünftige Beobachtungen bleiben ausgeschlossen.
Damit verwendet die Suche dieselbe lokale, inklusive Frischegrenze wie die
Bonstatistik und die Preisprojektion, ohne historische Hinweise zu aktuellen
Routenpreisen hochzustufen.

## D105 – Preis-Datenlücken führen bei bekannten Familien zur Produktauswahl
Wenn eine Listenposition keine belastbare Marktpreisabdeckung besitzt und ihre
Bezeichnung einer bekannten Produktfamilie entspricht, öffnet „Produkt oder
Preis ergänzen“ zuerst die konkrete Kandidatenauswahl. Aktuelle Angebote stehen
dort vor aktuellen Markt-/Bonpreisen; historische Prospekt- und Bonwerte bleiben
als Hinweis gekennzeichnet. Erst die explizite Nutzerwahl ersetzt die
unbestimmte Listenposition durch konkrete Produktidentitäten. Unbekannter
Freitext bleibt im manuellen Preiseditor, weil eine automatische Erweiterung
dort eine unbelegte Produktidentität erzeugen würde.

## D106 – Bekannte Suchfamilien wählen nicht über den freien Fallback
Wenn die Einkaufssuche eine bekannte Produktfamilie erkennt, führt auch die
zusätzliche Fallback-Kachel in die konkrete Kandidatenauswahl. Aktuelle
Angebote und belegte Preise bleiben dadurch vor der Listenübernahme sichtbar;
eine Familienanfrage wird nicht stillschweigend als unbepreister Eigenartikel
gespeichert. Nur unbekannter Freitext darf direkt als eigener Artikel angelegt
werden.

## D107 – Bon-Aliase werden auf konfigurierte Marktidentitäten normalisiert
Bon-OCR darf einen Markt mit abweichender Schreibweise oder Ortszusatz
liefern. Beim Lernen und Nachschlagen wird deshalb zuerst die konfigurierte
Marktidentität verwendet, sofern sie eindeutig erkannt wird; bestehende
unbekannte Händlerlabels bleiben unverändert. So verbindet die Lernhistorie
„ALDI SUED“ mit „ALDI Süd“ und „Lidl · Zellingen“ mit „Lidl“, ohne Preise
einem beliebigen Händler per Teilstring zuzuordnen.

## D108 – Preisabdeckung zählt nur vergleichbare Produktpackungen
Katalog- und Filialabdeckung verwenden dieselbe zentrale Mengen-/Einheitsprüfung
wie Einkaufspreisfenster, Beobachtungsprojektion und Routenauflösung. Ein
bekannter Preis mit abweichender Packungsgröße erhöht keine Abdeckung und wird
als eigene Datenlücke sichtbar gemacht. Aufrufe ohne Produktkatalog dürfen für
Diagnosezwecke weiterhin die vorhandene quellenbasierte Zählung verwenden.

## D109 – Produktquellen normalisieren Einheiten an der Grenze
Open-Food-Facts-Mengen werden vor dem Speichern in die unterstützten internen
Einheiten überführt. Eine strukturierte Angabe wie `20 cl` wird zu `200 ml`;
unbekannte Einheiten bleiben ohne Packungsbasis. Dadurch teilen Adapter,
Preisvergleich und Routenauflösung dieselbe vergleichbare Mengensemantik.

## D110 – Zentiliter sind eine unterstützte Volumen-Schreibweise
Die gemeinsame Mengen-Normalisierung behandelt `cl`/`centiliter` als
Volumenangabe und vergleicht sie mit Millilitern und Litern. Produkt-,
Prospekt- und Preisparser dürfen deshalb `20 cl` als 200 ml vergleichbar
machen; eine unbekannte oder mehrdeutige Schreibweise bleibt weiterhin offen.
## D111 – Externe Angebote benötigen einen Nachweis für die direkte Route

`Offer`-Einträge aus Händler-, Prospekt- oder anderen externen Quellen dürfen
den `RoutePriceResolver` nur mit einer vertrauenswürdigen `proofRef` erreichen.
Manuelle Nutzerangebote bleiben ohne externe Referenz zulässig. Damit sind
gespeicherte, unvollständige oder nachträglich veränderte Importdatensätze
keine stillschweigenden Preisbelege. Die Prüfung nutzt dieselbe
`hasTrustedOfferProofReference`-Regel wie der Import- und Beobachtungspfad.

## D112 – Konkrete Adapterherkunft bleibt neben der Quellenklasse erhalten

`PriceObservation` und die daraus projizierte `MarketPrice` speichern
`sourceAdapter` optional zusätzlich zur stabilen Quellenklasse. Damit bleibt
eine Herkunft wie KaufDA in Historie und Preisfenster nachvollziehbar, ohne
alte JSON-Formate oder die fachliche Quellenbewertung umzudeuten.

## D113 – Externe Angebotsnachweise gelten für jede aktuelle Preiswahl

Die für `RoutePriceResolver` eingeführte Nachweisgrenze wird auch in
Preisfenster, Suchvorschlägen und Kandidatenkarten verwendet. Ein externes
Angebot ohne vertrauenswürdige `proofRef` darf dort nicht als aktueller Preis
gerankt werden. Manuelle Nutzereingaben bleiben ohne externe Referenz zulässig;
die Angebotsübersicht kann unvollständige Datensätze weiterhin als Prüfhinweis
anzeigen.

## D114 – Bekannte Filialen werden vor jeder lokalen Preiswahl abgeglichen

Preisfenster, Suchkandidaten und Vorschläge verwenden neben der Route dieselbe
kanonische Filialprüfung. Ein `sourceLocationId` oder `Offer.locationId`, das
nachweislich zu einer anderen konfigurierten Filiale derselben Kette gehört,
bleibt aus der lokalen Preiswahl heraus. Fehlende Quellfilialen bleiben als
Legacy-Fallback sichtbar, weil daraus keine eindeutige Gegenentscheidung folgt.

## D115 – Evidenzprüfung bleibt im Beobachtungsadapter identisch

Die Vertrauensentscheidung wird im Offer-zu-`PriceObservation`-Adapter
wiederverwendet. Dadurch bleibt manuelle Eingabe auch bei einer abweichenden
Groß-/Kleinschreibung als bestätigte Nutzerquelle erhalten.

Die Importgrenze verwendet dieselbe Fallnormalisierung für `manual`; dadurch
entsteht zwischen manuell erfassten Importen und gespeicherten Angeboten keine
abweichende Nachweispflicht.

## D116 – Bon-Dubletten vergleichen Inhaltsmetadaten ohne alte IDs zu ändern

Die Importprüfung verwendet zusätzlich zum historischen, layoutstabilen
Bon-Fingerprint einen Inhaltsfingerprint. Mengen, Einheit, Einzelpreis,
Rabattverknüpfung und der berechnete Betrag werden berücksichtigt; Zahlungszeilen
und physische OCR-/PDF-Zeilennummern bleiben ausgeschlossen. Der bestehende
Fingerprint bleibt unverändert, damit gespeicherte Beobachtungs- und Preis-IDs
bei einer erneuten App-Version stabil bleiben.

## D117 – Angebots-Packungsbasis bleibt bis zur Preisbeobachtung erhalten

Wenn ein Prospektdatensatz eine eindeutig parsebare Packungsmenge liefert,
speichert das daraus erzeugte `Offer` Menge, Einheit und normalisierten
Grundpreis. Der Rabatt- und der ausgewiesene Normalpreis übernehmen diese
Basis getrennt in `PriceObservation`. Legacy-Angebote ohne Mengenangabe bleiben
lesbar, werden aber nicht durch eine angenommene Packungsgröße vergleichbar.

## D118 – Explizit falsche Angebots-Packungen bleiben außerhalb der Preiswahl

Angebote mit gespeicherter Packungsmenge werden vor Route, Preisfenster,
Suchkandidaten und Vorschlägen gegen die angefragte Produktpackung geprüft.
Eine bekannte Abweichung wird wie eine Datenlücke behandelt; ältere Angebote
ohne Mengenmetadaten bleiben als rückwärtskompatible Legacy-Evidenz zulässig.

## D119 – Regionale KaufDA-Treffer bleiben auch an der Importgrenze unroutebar

Ein `OfferImportRecord` mit `regionalOnly` darf unabhängig vom aufrufenden UI-
Pfad kein gespeichertes `Offer` erzeugen. Der regionale Treffer bleibt im
Prospektfeed als Recherche- und Nachweistext sichtbar; für Filialpreis,
Preisbeobachtung und Route ist eine eigene Branch-Assertion erforderlich.

## D120 – Alte regionale KaufDA-Angebote werden nachträglich abgewiesen

Bereits gespeicherte `Offer`-Einträge können aus einer Version stammen, die
`regionalOnly` noch nicht bis zur Importgrenze geführt hat. Für
`sourceAdapter == kaufda` gilt deshalb zusätzlich eine vorhandene
`locationId` als notwendige Branch-Assertion. Ohne diese ID bleibt der
Datensatz lesbar, wird aber aus Route, Preisfenster, Kandidaten und
Vorschlägen ausgeschlossen; seine Beobachtungs-Confidence bleibt `0`.
Dasselbe Branch-Erfordernis gilt am `OfferImportRecord`- und Lernpfad, auch
wenn ein eingehendes Regionalflag manipuliert oder weggelassen wurde.

## D121 – Append-only Preisbeobachtungen werden bei parallelen Reads vereinigt

Bon-, Prospekt- und allgemeine Beobachtungs-Ladevorgänge dürfen beim
App-Start parallel laufen. Jeder Shell-State-Update vereinigt deshalb den
geladenen Stand nach stabiler Beobachtungs-ID mit dem bereits im Speicher
vorhandenen Stand. Ein später beendeter, älterer Read kann dadurch keine
zwischenzeitlich gelernte Beobachtung aus der sichtbaren Preisbasis entfernen.

## D122 – Backup-Importe invalidieren verspätete Start-Reads

Ein lokales Backup schreibt mehrere voneinander unabhängige Speicherbereiche.
Vor dem ersten asynchronen Write erhöht die Shell deshalb eine interne
Datenrevision. Start-, Prospekt- und Bon-Ladevorgänge prüfen diese Revision vor
jeder sichtbaren Projektion und werden bei einem inzwischen begonnenen Import
verworfen. Angebots- und Listen-Backups laufen zusätzlich hinter den jeweiligen
Schreibwarteschlangen; Beleg-Import und vollständige Beleg-Ersetzung teilen
eine Queue. So kann ein älterer Callback ein erfolgreich importiertes Backup
nicht wieder mit alten Daten überdecken.

## D123 – Preisoberflächen verwenden dieselbe Verwendbarkeitsgrenze

Die Einkaufsliste darf einen `MarketPrice` nicht als exakte Quote anzeigen,
wenn seine zentrale `identityConfidence` unter `1` liegt oder eine explizit
gespeicherte Mengenbasis ungültig ist. Für manuelle und Open-Prices-Preise gilt
außerdem dieselbe Aktualitätsprüfung wie in der Route. Alte, aber sicher
identifizierte Bonpreise bleiben ausschließlich als historische Hinweise
sichtbar. Damit kann die Listenmatrix keine Preisqualität behaupten, die der
Routenresolver bereits ablehnt.

## D124 – Prospekt-Übernahmen prüfen den Widget-Lebenszyklus

Ein Prospektkarten-Callback darf nach einer synchronen Elternänderung kein
bereits entferntes Karten-Widget mehr aktualisieren. Ebenso darf die manuelle
Seitenübernahme nach dem asynchronen Speichern keinen Callback in einen
unmounted Screen ausführen. Beide Stellen prüfen deshalb `mounted` direkt vor
dem lokalen State-Update beziehungsweise vor dem Listen-Callback.

## D125 – Persistente Preis- und Backup-Mutationen laufen geordnet

Backup, manuelle Marktpreise, Open Prices, Angebots-Historie, Katalog-, Kauf-
und Einstellungsänderungen sowie die betroffenen Listen-/Prospektpfade
verwenden in der Shell dieselbe lokale Schreibwarteschlange. Ein bereits
überholter Vorgang prüft seine Datenrevision vor dem Start und verwirft sein
Ergebnis vor dem sichtbaren State-Update. Der Backup-Write selbst wird als
zusammenhängender Vorgang in dieser Queue ausgeführt, damit ein verspäteter
lokaler Callback keine importierten Daten nachträglich überschreibt.

## D126 – Prospektbestände bleiben an Refresh- und App-Grenze lebensmittelrein

Die sichtbare Angebots- und Preisroute verarbeitet ausschließlich aktuelle
Lebensmittelangebote. Der Refresh-Filter verwirft klar erkennbare Haushalts-,
Kosmetik-, Medizin-, Tierfutter- und saisonale Non-Food-Artikel; die Flutter-
Feedgrenze wiederholt dieselbe Prüfung für ältere oder manuell bereitgestellte
Feedstände. Händlerkategorien werden nur als zusätzliche starke Evidenz für
Tierbedarf verwendet, damit Lebensmittel wie Proteinriegel oder Shakes aus
fehlerhaft gruppierten Händlerkategorien nicht verloren gehen. Ein vorhandener
Nachweis, Preis oder ein Bild hebt die Non-Food-Sperre nicht auf.

## D127 – Straßenstreckenabrufe dürfen keinen veralteten UI-Zustand projizieren

Routen- und Filialansichten versehen Laden und Aktualisieren der
Entfernungsmatrix mit einer Anfrage-Revision. Ein Abruf, der nach einem
Adresswechsel, einer neuen Aktualisierung oder dem Entfernen des Widgets
zurückkehrt, wird verworfen. Fehler beim Routing oder lokalen Cache beenden den
Ladezustand und zeigen einen verständlichen Hinweis; vorhandene manuelle bzw.
gecachte Entfernungen bleiben dabei erhalten.

## D128 – Belegimporte aktualisieren keinen entfernten Dialog

Nach asynchronem OCR-, Alias- oder Preisspeichern prüft der Belegdialog seinen
Widget-Lebenszyklus, bevor ein Fehlerzustand gesetzt oder das Ergebnis
angezeigt wird. Ein bereits geschlossener Dialog verwirft den verspäteten
Rückweg; die persistierten Beobachtungen bleiben davon unberührt.

## D129 – Datumsdialoge prüfen den Widget-Lebenszyklus

Angebots- und manuelle Prospektseiten übernehmen ein gewähltes Datum erst,
wenn der aufrufende Editor noch montiert ist. Wird der Editor während des
DatePickers geschlossen, wird die Antwort ohne State-Update verworfen.

## D130 – KaufDA-Next-Daten bleiben bei optionalem Script-Typ stabil

Der optionale KaufDA-Adapter akzeptiert `__NEXT_DATA__` weiterhin nur anhand
der exakten Script-ID und gültigem JSON. Das optionale HTML-Attribut `type` darf
fehlen oder `application/json` lauten; andere Script-IDs und nicht parsebares
JSON bleiben Fehler. Damit übersteht der Diagnosepfad eine harmlose
Markupänderung, ohne fremde Seiteninhalte einzulesen.

## D131 – Manuelle Angebotsmutationen respektieren die Datenrevision

Auch das Speichern und Löschen eines manuell geprüften Angebots erfasst die
aktuelle Shell-Datenrevision. Beginnt vorher ein Backup-Import, wird der alte
Callback innerhalb der gemeinsamen Schreibwarteschlange verworfen und nicht
nachträglich in den importierten Angebotsbestand geschrieben.

## D132 – Offline-Strecken werden je Startadresse versioniert gespeichert

Entfernungen und Straßenmatrizen werden in lokalen Mehrfach-Cache-Einträgen
pro normalisierter Startadresse gespeichert. Der bisherige Einzelwert bleibt
über einen Legacy-Fallback lesbar. Read-Modify-Write-Vorgänge laufen
serialisiert, damit ein Wechsel zwischen Thüngersheim, Zellingen und Würzburg
keine bereits ermittelte Offline-Strecke verliert.

## D133 – Externe Prospekt- und Produkt-Discovery ist abschaltbar

`ProspectFeedService` und `ProspectImportModule` können Netzwerkzugriffe per
Feature-Flag deaktivieren und verwenden dann ausschließlich lokalen Cache oder
das gebündelte Asset. Die optionale Open-Food-Facts-Discovery besitzt dieselbe
Grenze. Ein deaktivierter Dienst erzeugt keinen Request und liefert keine
erfundene Identität oder Preisbasis.

## D134 – EAN-Discovery braucht Token- und Variantenverträglichkeit

Fehlt ein EAN, akzeptiert die Open-Food-Facts-Discovery nur Treffer mit
vollständigen Namens-Tokens und kompatibler Produktidentität. Reine
Teilstrings sowie abweichende Varianten wie Milch mit 1,5 % und 3,5 % Fett
werden nicht als dieselbe konkrete Produktvariante vorgeschlagen.

## D135 – Externe EAN-Preise tragen die bekannte Packungsbasis

Liefert Open Prices eine bekannte Produkt-Packungsgröße, übernimmt der Adapter
Menge, Einheit und den daraus normalisierten Grundpreis in `MarketPrice`.
Damit bleiben zentrale Packungs- und Einheitenprüfungen aktiv; fehlende oder
nicht vergleichbare Daten bleiben unbekannt.

## D136 – Evidenzspeicher liefern den abgeschlossenen Schreibstand

Lesen aus dem Preis- oder Bon-Evidenzspeicher wartet auf die gemeinsame lokale
Schreibwarteschlange. Queue-interne Operationen lesen weiterhin direkt, damit
kein Deadlock entsteht. Ein paralleles Lesen kann dadurch keinen veralteten
Stand vor einer abgeschlossenen Append-Operation zurückgeben.

## D137 – Kontrollierte KaufDA-Branchdaten bleiben vollständig

Wenn eine separat verifizierte KaufDA-Branch-Assertion neben der ID auch Ort
und Adresse enthält, übernimmt der Parser alle gelieferten Filialfelder in den
Angebotsnachweis. Ohne diese Assertion bleibt derselbe Treffer regional-only;
der Parser leitet keine Filiale aus dem Händlernamen ab.

## D138 – Unabhängige Start-Reads laufen parallel

Die lokalen Initialdaten werden vor `runApp` gemeinsam gestartet und danach
alle abgewartet. So bleibt der erste `SparzamApp`-Snapshot vollständig und
konsistent, ohne unabhängige Speicherzugriffe künstlich zu serialisieren.

## D139 – Cache-Schlüssel und Inhaltsprüfung normalisieren Startadressen gleich

Distanz- und Straßenmatrixspeicher vergleichen gespeicherte und angefragte
Startadressen über dieselbe trim-/casefold-/whitespace-normalisierte Form wie
ihre Cache-Schlüssel. So bleiben Schreib- und Lesevorgänge bei harmlosen
Eingabeformatänderungen verbunden, während unterschiedliche Orte getrennt
bleiben.

## D140 – Zukünftige Bonbeobachtungen beeinflussen keine Preisstatistik

`buildReceiptPriceStats` verwirft Beobachtungen nach dem Prüfzeitpunkt vor der
Gruppierung. Dadurch bleiben Median, letzter Preis und Beobachtungsanzahl auf
bereits eingetretene Belege beschränkt; die Bon-Routenprojektion verwendet
dieselbe Zeitgrenze bereits. Historische Belege innerhalb des konfigurierten
Fensters bleiben unverändert verfügbar.

## D141 – Prospekthistorie prüft den Erfassungstag

Historische Prospekt-Mediane akzeptieren nur Beobachtungen bis zum aktuellen
Kalendertag. Ein zukünftiger `observedAt`-Wert bleibt auch dann ausgeschlossen,
wenn das Prospekt selbst bereits abgelaufen ist; so kann eine fehlerhafte oder
manipulierte Zeitangabe keine Preisorientierung vorwegnehmen.

## D142 – Optionale KaufDA-Daten verdrängen keine offiziellen Zeiträume

Der gemeinsame Prospekt-Refresh wählt je Händler den aktuell gültigen Zeitraum
mit mindestens einem offiziellen Quellenrecord vor einem ausschließlich aus
KaufDA stammenden Zeitraum. Die Anzahl der KaufDA-Treffer darf diese Priorität
nicht überstimmen. KaufDA bleibt als optionale Ergänzung im ausgewählten
Zeitraum nutzbar und kann bei fehlender offizieller Periode weiterhin alleinige
regionale Treffer liefern.

Damit bleiben bestehende autoritative Händlerquellen führend, während der
inoffizielle Adapter die Angebotsabdeckung verbessert, ohne einen anderen
Gültigkeitszeitraum einzuschleusen.

## D143 – Zukunftsbelege werden vor der Marktpreisprojektion ausgeschlossen

`marketPricesFromObservations` akzeptiert eine Preisbeobachtung nur bis zum
Prüfdatum. Ein zukünftiger `observedAt`-Zeitpunkt bleibt damit bereits aus dem
gespeicherten `MarketPrice`-Bestand heraus; die spätere Routenprüfung muss ihn
nicht erst nachträglich aussondern. Gültigkeitszeitraum und Quellen-Altersfenster
bleiben zusätzliche, unabhängige Grenzen.

## D144 – Validierte Prospectseiten dürfen als Cover zurückfallen

Wenn ein älteres Feedformat kein eigenes `thumbnailUrl` liefert, darf der
Parser das erste bereits HTTP-validierte `pageSamples`-Bild als Cover
verwenden. Der Fallback nutzt nur vorhandene Quelldaten; ungültige URLs und
fehlende Seiten bleiben ohne Bild und werden nicht durch Produktbilder ersetzt.

## D145 – Prospektseiten werden nach Seitennummer dedupliziert

Der Feedparser akzeptiert nur positive Seitennummern, behält bei Duplikaten den
ersten validierten Quelldatensatz und sortiert die Seiten numerisch. So bleibt
der Viewer bei wechselnden oder wiederholten öffentlichen `pageSamples`
deterministisch, ohne Bilder aus fremden Seiten zu kombinieren.

## D146 – Aktive Prospektansichten wählen die stärkste verfügbare Evidenz

Wenn ein Händler mehrere aktuell gültige Prospektmetadaten liefert, wird nicht
die Feed-Reihenfolge als fachliche Auswahl verwendet. Status, Seitennachweis,
Cover, Angebotsanzahl, Gültigkeitsende und stabile Quellenfelder bilden einen
deterministischen Tie-Breaker. Ein abgelaufener Datensatz kann die aktuelle
Ansicht nicht verdrängen.

## D147 – Abdeckung und Viewer teilen die Cover-Fallback-Regel

Ein einzelnes validiertes HTTP(S)-`thumbnailUrl` zählt als eine Bildseite, wenn
keine detaillierten `pageSamples` vorhanden sind. Damit beschreibt die
Datenabdeckung denselben sichtbaren Nachweis wie der Viewer; ungültige Links
bleiben ohne Bildsignal.

## D148 – Exakte Marktpreisgleichstände bleiben reproduzierbar

Wenn zwei nutzbare `MarketPrice`-Belege denselben qualitätsbereinigten Preis
und denselben Beobachtungszeitpunkt haben, entscheidet eine gemeinsame stabile
Tie-Break-Regel in Planung und `RoutePriceResolver`. Quellenart, Adapter,
Filialkennung, externe ID, Nachweis und Packungsmetadaten werden nur für diesen
Gleichstand verglichen. So kann die Reihenfolge eines append-only Imports keine
abweichende Routenquote erzeugen; Gültigkeits- und Altersprüfungen bleiben
vorgelagert.

Die Bon-Familienprojektion verwendet denselben Comparator bereits beim
Zusammenführen ihrer Kandidaten; dadurch wird die Regel nicht erst nach einer
potenziell reihenfolgeabhängigen Vorselektion wirksam.

## D149 – KaufDA-Cache wird atomar ersetzt

Der optionale KaufDA-JSON-Cache wird in derselben Verzeichnisstruktur zunächst
vollständig in eine temporäre Datei geschrieben und danach per atomarem Replace
übernommen. Schlägt der Ersatz fehl, bleibt der vorherige Cache für den
Offline-Fallback erhalten; temporäre Reste werden entfernt. Der Adapter bleibt
read-only gegenüber KaufDA und ändert weder Datenmodell noch Abrufhäufigkeit.

Ein beschädigtes Cache-Root-Dokument oder ein nicht objektförmiger Eintrag
wird als Cache-Miss behandelt. Der optionale Refresh darf dadurch weder einen
ungefangenen Parserfehler erzeugen noch unprüfbare Daten als Offlinebeleg
verwenden.

## D150 – Gleiche Artikelpreise verwenden einen stabilen Filialschlüssel

Bei der Artikelzuweisung in `RouteOptimizer.buildPlan` entscheidet bei exakt
gleichem qualitätsbereinigtem Preis ein normalisierter Schlüssel aus Händler,
Filial-ID, Ort und Adresse. Damit bleiben Warenkorbzuweisung und daraus
abgeleitete Teilrouten unabhängig von der Reihenfolge, in der Stores an den
Optimizer übergeben werden.

Bei aktiven Angeboten mit identischem effektivem Gesamtpreis wird zusätzlich
der belegte Normalpreisstatus und danach die konkrete Quellen-/Nachweiskennung
verglichen. So bleibt die gewählte Angebotsquelle unabhängig von der
Reihenfolge eines Feed-Imports reproduzierbar.

## D151 – Startup-Listenstände werden gegen Nutzermutationen geschützt

Der asynchrone Ladevorgang benannter Einkaufslisten merkt sich eine eigene
Mutationsrevision. Nach einer sichtbaren Listenänderung verwirft er einen
verzögert eintreffenden älteren Snapshot, statt die aktuelle Eingabe zu
überschreiben. Backup-Revisionen bleiben davon getrennt und invalidieren den
gesamten Shell-Stand weiterhin über `_dataRevision`.

## D152 – ShoppingListStore serialisiert lokale Zugriffe

Der lokale Listenstore führt einen gemeinsamen, fehlerisolierten Scheduler für
Reads und Writes über alle Instanzen. Reads werden selbst in diese Reihenfolge
eingereiht und sehen dadurch genau den abgeschlossenen Stand vor ihnen;
Read-Modify-Write-Aktionen wie bekannte Produkte und bevorzugte Varianten
laufen ebenfalls innerhalb derselben Queue. Dadurch können UI, Backup und
Startup keine veralteten Listenwerte gegeneinander schreiben.

## D153 – Lokale Evidenz- und Streckenstores verwenden denselben Operation-Scheduler

Preisbeobachtungen, Bonbeobachtungen, gelernte Bon-Aliase,
Straßenentfernungen und Routenmatrizen reihen Reads und Writes jetzt über einen gemeinsamen
fehlerisolierten Operationstyp ein. Ein öffentlicher Read wird dadurch selbst
Teil der Reihenfolge und kann nicht zwischen zwei Read-Modify-Write-Schritten
einen älteren Zwischenstand liefern. Der bestehende fachliche Fallback und die
Legacy-Cacheformate bleiben unverändert.

## D154 – Marktstopp-Aufwand bleibt ein reiner Planungswert

Nutzer können optional einen persönlichen Kostenwert für jeden Markt nach dem
ersten hinterlegen. Der Optimierer berechnet daraus
`(Anzahl Märkte - 1) * Kosten je zusätzlichem Markt` und addiert ihn nur zum
`RoutePlan.planningScore`. `RoutePlan.total` bleibt der erwartete Betrag aus
Warenkorb und Fahrt; dadurch wird der persönliche Aufwand weder als Preisquelle
noch als Kassenbetrag ausgegeben.

Der Wert ist begrenzt, lokal serialisiert und standardmäßig null. Die Auswahl
berücksichtigt ihn gemeinsam mit Preisunsicherheit, Zeitwert, Fahrtkosten,
Preisabdeckung, Mindestvorteil und der maximalen Marktanzahl. Die UI zeigt den
Aufwand getrennt an, damit die Empfehlung nachvollziehbar bleibt.

## D155 – Preisverlauf und aktuelle Marktpreise teilen ihre lokale Reihenfolge

`PriceHistoryStore` und `MarketPriceStore` verwenden für Reads, vollständige
Ersetzungen und Upserts jeweils einen statischen, fehlerisolierten
`SequentialOperationQueue`. Queue-interne Speicherzugriffe bleiben privat, um
Deadlocks beim Initialisieren oder Bereinigen alter Einträge zu vermeiden.

Die fachlichen Regeln ändern sich dadurch nicht: Demo-Historie wird weiterhin
nur beim Laden entfernt, Branch-spezifische Marktpreise bleiben getrennte Slots,
und manuelle Preise behalten ihre bestehende Priorität gegenüber externen
Quellen. Die Queue schützt ausschließlich die lokale zeitliche Reihenfolge.

## D156 – Kaufhistorie und Wiederkäufe teilen ihre lokale Reihenfolge

`PurchaseStore` und `RecentPurchaseStore` verwenden für Reads, vollständige
Ersetzungen und Read-Modify-Write-Aktionen jeweils einen statischen,
fehlerisolierten `SequentialOperationQueue`. Die Operation liest den
gespeicherten Stand innerhalb derselben Queue und legt erst danach den
zusammengeführten Snapshot ab. So kann ein paralleler UI-Read keinen älteren
Kaufstand zwischen einer laufenden Änderung und deren Persistierung liefern.

Die fachlichen Regeln bleiben unverändert: Kaufhistorien werden weiterhin per
ID ersetzt und chronologisch sortiert, Wiederkäufe behalten ihre bisherigen
Zähler und die lokale Begrenzung auf 30 Einträge. Die Queue ändert nur die
zeitliche Reihenfolge lokaler Speicherzugriffe.

## D157 – Angebotsimports teilen ihre lokale Reihenfolge

`OfferStore` verwendet für Reads, vollständige Ersetzungen und Upserts einen
statischen, fehlerisolierten `SequentialOperationQueue`. Read-Modify-Write-
Aktionen führen die Zusammenführung mit dem gespeicherten Stand innerhalb
derselben Queue aus. Ein paralleler Prospekt- oder KaufDA-Import kann dadurch
keinen älteren Snapshot zwischen Persistierung und UI-Projektion ablegen.

Die fachlichen Regeln bleiben unverändert: bekannte Demoangebote werden beim
Laden entfernt, IDs ersetzen bestehende Angebote und Quellen-, Nachweis- sowie
Gültigkeitsfelder werden vollständig aus dem importierten `Offer` bewahrt.

## D158 – Eigene Produktkataloge teilen ihre lokale Reihenfolge

`ProductCatalogStore` verwendet für Reads, vollständige Ersetzungen und
Read-Modify-Write-Aktionen einen statischen, fehlerisolierten
`SequentialOperationQueue`. Der gespeicherte Stand wird innerhalb derselben
Queue mit einem laufenden Scanner- oder Stammdatenimport zusammengeführt.
Dadurch kann ein paralleler Read keinen älteren Produktkatalog zwischen
Persistierung und UI-Projektion sichtbar machen.

Die fachlichen Daten bleiben unverändert: EAN, Varianten, Aliase, Favoriten,
Stammdateneigenschaften und die alphabetische Sortierung werden weiter aus dem
jeweiligen `Product` übernommen.

## D159 – Budgetfelder teilen ihre lokale Reihenfolge

`BudgetStore` verwendet für Reads und vollständige Writes einen statischen,
fehlerisolierten `SequentialOperationQueue`. Monatsbudget,
Lebensmittelbudget und Ausgaben werden innerhalb eines abgeschlossenen
Storesnapshots gelesen oder geschrieben; ein Einkaufsabschluss kann dadurch
keinen gemischten Zwischenstand aus den drei Schlüsseln liefern.

Die bestehende Validierung endlicher, nichtnegativer Beträge und der Null-
Fallback bei fehlenden Werten bleiben unverändert. Die Queue ändert nur die
zeitliche Reihenfolge lokaler Budgetzugriffe.

## D160 – Routen- und Preisquelleneinstellungen teilen ihre lokale Reihenfolge

`MobilitySettingsStore` und `PriceDataSettingsStore` verwenden für Reads und
Writes jeweils einen statischen, fehlerisolierten `SequentialOperationQueue`.
So sehen Startup, Backup und UI nach einem abgeschlossenen Einstellungswechsel
denselben vollständigen JSON-Snapshot.

Die fachlichen Defaults, Mobilitätsvalidierung und der abschaltbare
Preisquellen-Schalter bleiben unverändert. Die Queue schützt nur die lokale
zeitliche Reihenfolge und aktiviert keine externe Datenquelle.

## D161 – Diagnoseeinträge teilen ihre lokale Reihenfolge

`DiagnosticLogService` verwendet für Reads, Einträge und Löschen einen
statischen, fehlerisolierten `SequentialOperationQueue`. Ein Diagnoseeintrag
liest und schreibt den lokalen Bestand innerhalb derselben Queue; parallele
Feed-, OCR- oder Persistenzfehler können dadurch keinen anderen Eintrag
überschreiben.

Das Protokoll bleibt lokal, auf 100 Einträge begrenzt und behandelt eigene
Speicherfehler weiterhin still, damit die Fehlerdiagnose den ursprünglichen
App-Fehler nicht verschärft.

## D162 – Prospektfavoriten teilen ihre lokale Reihenfolge

`ProspectFavoritesStore` verwendet für Reads und Writes einen statischen,
fehlerisolierten `SequentialOperationQueue`. Die normalisierte, sortierte
Favoritenmenge wird vor dem Einreihen als Snapshot erstellt; dadurch kann ein
schnelles Herz-Umschalten keinen älteren Stand nachträglich schreiben.

Die bestehende `null`-Semantik bei nicht verfügbarer Plattformpersistenz und
die Fehlerisolation des Prospektfeeds bleiben unverändert.

## D163 – Externe Fallback-Caches teilen ihre lokale Reihenfolge

Die lokalen Shared-Preferences-Adapter für Open Prices, Open Food Facts und
den öffentlichen Prospektfeed verwenden je Cachetyp einen statischen,
fehlerisolierten `SequentialOperationQueue`. Normalisierte Cache-Schlüssel und
vollständige Rohantworten werden innerhalb dieser Reihenfolge gelesen und
geschrieben; ein paralleler Refresh kann dadurch keinen älteren Stand nach
einem frischeren Wert persistieren.

Die Adapter bleiben best effort. Cachefehler blockieren weder Liveantworten
noch den Offline-Fallback, und der Cache erzeugt weiterhin keine Preis- oder
Identitätsbestätigung.

## D164 – Gleichzeitige Prospekt-Loads teilen eine laufende Future

`ProspectFeedService` hält während eines laufenden `load()`-Vorgangs dessen
Future. Weitere Aufrufer erhalten dieselbe Future, statt parallel dieselbe
öffentliche Feedquelle abzufragen. Nach Erfolg oder Fehler wird der Zustand
freigegeben, sodass ein späterer manueller Refresh wieder starten kann.

Die Feed-Reihenfolge bleibt unverändert: aktuelle Antwort, lokaler Cache und
versioniertes Asset werden weiterhin im bestehenden Fallbackpfad geprüft.

## D165 – Versionierte Prospekt-Assets müssen Cover und Filiale belegen

Der versionierte Prospektfeed darf für jede konfigurierte Quelle nur dann als
auslieferbarer Fallback gelten, wenn mindestens ein aktuell gültiger Zeitraum,
eine konkrete Filial-ID mit Ort und Adresse sowie eine HTTPS-Coverseite für
Seite 1 vorhanden sind. Die Regression verwendet den im Asset gespeicherten
Referenztag aus `generatedAt` und führt keine Live-Abfrage aus.

Damit bleibt ein fehlendes Cover, eine verlorene Filialzuordnung oder ein alter
Prospekt in der Datenbasis sichtbar, ohne historische Preisbeobachtungen oder
die optionale Live-Quelle zu verändern.

## D166 – Cover-Invarianten werden auch nach dem App-Parsing geprüft

Die Asset-Regression wird durch eine Flutter-Matrix ergänzt, die den tatsächlich
geparsten `ProspectIssue` prüft. Für jeden konfigurierten Markt müssen am im
Asset gespeicherten Referenztag Zeitraum, Filial-ID, Ort, Adresse und eine
HTTPS-Coverseite als Seite 1 erhalten bleiben.

So schützt die Prüfung sowohl die versionierte JSON-Datei als auch die
Übersetzung in das UI-Modell; Live-Quellen und historische Preisbeobachtungen
werden dadurch nicht aktiviert oder verändert.

## D167 – Große Prospektlisten bleiben lazy und ohne unnötige Keep-Alives

Cover-, Such-, Seiten- und Artikel-Sliver verwenden weiterhin Builder und
Repaint-Grenzen, deaktivieren aber automatische Keep-Alive-Wrapper für entfernte
Karten. Dadurch kann Flutter bei großen Händlerbeständen Renderobjekte früher
freigeben, ohne Daten, Reihenfolge oder Nutzeraktionen zu verändern.

## D168 – KaufDA-Cache wird erst nach erfolgreichem Parsing ersetzt

Der optionale KaufDA-Adapter schreibt einen Liveantwort-Body erst nach
erfolgreichem `__NEXT_DATA__`-Parsing in den lokalen Cache. Bei einer
Formatänderung trotz HTTP 200 wird der noch gültige vorherige Body erneut
geparst und mit seinem ursprünglichen `capturedAt` verwendet.

So bleibt eine Parserstörung sichtbar, ohne den letzten verwertbaren Nachweis
zu löschen oder künstlich zu verjüngen.

## D169 – HTTP-403 beendet den öffentlichen Quellenversuch

Der gemeinsame Refresh-Helper behandelt HTTP 403 als Zugriffsentscheidung der
Quelle und versucht keinen zweiten Abruf mit verändertem User-Agent. Cache,
versionierter Asset-Fallback und die isolierte Fehlerdiagnose bleiben die
einzigen Folgeschritte.

## D170 – Der offizielle Refresh aktiviert KaufDA nie implizit

Der GitHub-Workflow setzt `SPARZAM_KAUFDA_ENABLED` ausdrücklich auf `0`.
Eine produktive Aktivierung muss deshalb als bewusste Workflow-Änderung nach
der rechtlichen Prüfung erfolgen; der normale offizielle Refresh bleibt bei
den autoritativen Händlerquellen.

## D171 – KaufDA-Query-Limit Null bleibt eine harte Abschaltung

`SPARZAM_KAUFDA_MAX_QUERIES=0` wird im Umgebungsadapter als gültige
Nullgrenze gelesen. Der Wert führt zusammen mit der bestehenden begrenzten
Query-Auflösung zu keinem Abruf und wird nicht still auf den Defaultwert
angehoben. Negative oder syntaktisch ungültige Werte bleiben beim sicheren
Default.

## D172 – Automatische Preisbeobachtungen bleiben browser-speicherfähig

Prospekt-, Händler-, Open-Prices- und Schätzbeobachtungen werden lokal nicht
unbegrenzt als JSON-Liste fortgeschrieben. Die Persistenz behält pro exakter
Produkt-/Markt-/Quell-/Variantenbasis die neuesten drei automatischen
Beobachtungen und insgesamt höchstens 2.000 automatische Einträge. Bei einem
Browser-Quota-Fehler wird ein kleinerer Retry mit den neuesten automatischen
Belegen ausgeführt.

Bon-, manuelle, Bild- und sonstige nutzernahe Preisbelege bleiben geschützt.
Ein Speicherfehler darf weder den validierten Live-Prospektfeed noch dessen
Cache-/Asset-Fallback als Händlerfehler erscheinen lassen.
## D173 – Besuchte Hauptreiter bleiben montiert

`AppShell` verwaltet die sechs Hauptreiter in einem `IndexedStack`. Beim ersten
Start wird nur der aktive Einkaufslisten-Reiter aufgebaut; weitere Reiter werden
erst beim ersten Öffnen aktiviert. Danach bleiben ihre Stateful-Controller und
Scrollpositionen beim Navigieren erhalten.

Das verhindert, dass der Prospekt- oder Preisreiter beim Wechsel in die Liste
und zurück seine Suche, seinen Scrollstand oder laufende Offline-/Routing-Caches
verliert. Die fachlichen Daten, Reiterreihenfolge und Persistenz bleiben
unverändert.



## D174 – Automatische Prospektpreisbeobachtungen beschränken sich auf aktuelle Zeiträume

Der Feed darf historische und kommende Prospektperioden für Diagnose und
Nachvollziehbarkeit enthalten. Beim automatischen Speichern in
PriceObservationStore werden jedoch nur Datensätze berücksichtigt, deren
validFrom/validUntil am Aktualisierungstag aktiv sind. Dadurch kann ein
alter oder zukünftiger Normalpreis nicht als aktueller Datenbankpreis in
Planung und Preisoberfläche erscheinen. Der reguläre, belegte Preis bleibt
vom zeitlich befristeten Angebotspreis getrennt; Herkunft, Filiale,
Packungsgröße, Nachweis und Erfassungszeit werden unverändert übernommen.

## D175 – Reguläre Prospektpreise sind eine eigene route-taugliche Quelle

Ein aktuell gültiger, belegter Normalpreis aus einem Prospekt wird nach der
zentralen Beobachtungsprüfung als MarketPriceSource.prospect projiziert. Der
zeitlich befristete Angebotspreis bleibt im OfferStore und wird nicht nochmals
als regulärer Marktpreis projiziert. Dadurch bleiben Normalpreis, Angebot,
Quelle, Filiale, Packungsgröße, Nachweis und Gültigkeit getrennt sichtbar,
während Preise-Reiter und Route denselben aktuellen Normalpreis verwenden.
Die Quelle erhält eigene Frische-/Qualitäts- und Anzeigeetiketten; sie wird
nicht als eigener Preis oder Open Prices ausgegeben.

## D176 – Prospektseiten werden nur aus belegten Publisher-Katalogen ergänzt

Für Issue #409 werden vollständige Seitenlisten aus offiziellen
Händler-/Publisher-Readern bevorzugt: EDEKA `catalog.xml`, ALDI und Netto
Publitas mit `cacheToken` sowie Kaufland/Lidl Leaflets-v4. Ein parallel
veröffentlichtes Kaufland-`-OD`-Drogerieblatt darf den Lebensmittelprospekt
nicht verdrängen. Lidl-Kopien werden nach Händlerkampagne und Zeitraum
dedupliziert.

Jede Seite muss eine positive, begrenzte Nummer und eine gültige HTTP(S)-
Bildquelle besitzen. `pageCount`, `loadedPageCount`, fehlende Seitennummern,
Seitenstatus und Seitenquelle werden getrennt gespeichert. Kann die Quelle nur
das Cover oder keine belastbare Gesamtzahl liefern, bleibt dieser Zustand
sichtbar; fehlende Seiten, Artikel und Preise werden nicht erfunden. Bildseiten
ohne strukturierte Artikelzeile sind zunächst nur OCR-/Review-Evidenz.

Die normalisierten Artikel- und Preisfelder bleiben im bestehenden
`OfferImportRecord`-/`PriceObservation`-Datenfluss. `originalPrice` ist nur ein
ausdrücklich belegter Normal-/Streichpreis, `offerPrice` bleibt das zeitlich
befristete Angebot. Die neue Seitenmetadaten-Projektion darf weder eine
zweite Preisdatenbank noch eine implizite Produktidentität erzeugen.

Der lokale Prospektcache besitzt weiterhin genau einen austauschbaren Eintrag
und lehnt Werte über 4 MiB ab. Ein unabhängiger Händler-Endpunktfehler darf
noch gültige, mit ihrem ursprünglichen `capturedAt` gespeicherte
Vorbeobachtungen nicht leeren; ein späterer erfolgreicher Refresh ersetzt sie
idempotent.

## D177 – Bonpreisauflösung nutzt gespeicherte Identität ohne Varianten-Bypass

Die Übernahme von `ReceiptObservation` in die bestehende Familien-/Marktpreis-
projektion prüft zuerst eine ausdrücklich bestätigte `productId`. Sie darf ein
abweichendes oder unleserliches Rohlabel überbrücken, aber die vorhandene
Packungs- und Mengengrundlage bleibt zwingend. Ohne bestätigte konkrete
Produkt-ID darf ein gespeicherter `familyKey` nur dann einspringen, wenn der
Rohtext selbst keine belastbare Identität liefert.

Ein erkanntes, spezifischeres Rohlabel gewinnt gegen veraltete
Familienmetadaten. So kann ein OCR-fehlerhafter Schmand-Label familienbezogen
weitergenutzt werden, während `Tomatenmark` nie über ein altes `tomaten`-
Familienfeld zu frischen Tomaten wird. Die resultierende Evidenz bleibt eine
`MarketPriceSource.receipt` und läuft unverändert durch `planningMarketPrices`,
`RoutePriceResolver` und `RouteOptimizer`; unbestätigte Bon-Produkt-IDs werden
nicht zu exakten Routenpreisen.

## D176 – Legacy-Rabattbelege bleiben aus der automatischen Preisbasis

Automatische Prospektbelege tragen in aktuellen Formaten `kind=offer`. Ältere
lokale JSON-Zeilen können dieses Feld jedoch verloren haben und stattdessen nur
`discounted=true` enthalten. Bei IDs aus dem automatischen Prospekt-Namensraum
(`prospect|...` oder `offer|import|...`) gilt dieses Rabattmerkmal deshalb
als ausreichender Bereinigungsnachweis. Reguläre Zeilen mit demselben Namensraum
und `discounted=false` bleiben erhalten; nutzerbestätigte Belege außerhalb
dieser IDs werden nicht angetastet.

## D177 – Cache-Preisstatus vor Projektion auf ausstehend setzen

Ein lokal sichtbarer Cache-Feed darf nicht mit dem bestätigten Zähler eines
vorherigen Feedstands angezeigt werden, während seine regulären Preise erneut
in `PriceObservationStore` geschrieben werden. Der Shell-Status wechselt daher
vor dem queued write auf `pending` und setzt den Zähler zurück. Erst der
erfolgreiche Abschluss bestätigt die aktuelle Anzahl; ein Fehler bleibt
`failed` und löst keinen Fingerprint-Abschluss aus.
