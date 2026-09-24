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
