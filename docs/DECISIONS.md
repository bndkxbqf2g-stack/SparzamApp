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
