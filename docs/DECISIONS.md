# SparzamApp – Architektur- und Produktentscheidungen

Diese Datei hält Entscheidungen fest, damit sie in neuen Chats oder Work-Läufen nicht erneut erraten werden.

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
