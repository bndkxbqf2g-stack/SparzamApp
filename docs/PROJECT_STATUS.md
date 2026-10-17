## Update 17.10.2026 – Legacy-Prospektangebote vor der Projektion trennen

- Der Beobachtungsadapter verwirft direkte Prospekt-Angebotszeilen jetzt bereits bei `discounted=true`, auch wenn alte Daten kein `kind=offer` speichern.
- Solche Zeilen bleiben als Evidenz im Beobachtungsspeicher, gelangen aber nicht in die reguläre `MarketPrice`-Projektion.
- Eine Adapterregression schützt die Abwärtskompatibilität ohne neue Quelle oder Datenmodellmigration.

## Update 17.10.2026 – Preisabdeckung trennt Prospekt-Aktionspreise

- Direkte Prospekt-Aktionspreise werden in Katalog- und Marktdeckung nicht mehr als vergleichbare aktuelle Preise gezählt.
- Händler bleiben bei explizit angeforderten `storeNames` sichtbar, erhalten aber bei reiner Angebots-Evidenz null aktuelle Produkte.
- Eine Regression schützt die Trennung zwischen Angebotsbeleg und routenfähiger Preisabdeckung.

## Update 17.10.2026 – Legacy-Prospekt-Aktionspreise bleiben aus dem Preisverlauf

- `ShellPriceCoordinator` schreibt direkte Prospekt-Aktionspreise nicht mehr in den regulären `PriceHistoryStore`.
- Die Evidenz wird weiterhin als Beobachtung und Marktpreis-Datensatz erhalten; nur der Normalpreis-Verlauf bleibt frei von Aktionsbeträgen.
- Eine Coordinator-Regression schützt diese Persistenzgrenze.

## Update 17.10.2026 – Aktive Preisoberflächen trennen Angebotsbelege

- Die gemeinsame `usableMarketPrices`-Sicht verwirft direkte Legacy-Prospekt-Aktionspreise, bevor aktive Preisoberflächen und der Preisverlauf sie erhalten.
- `PriceDataQuality` führt Angebotsbelege weiterhin separat als Evidenz (auch bei Legacy-Zeilen mit `discounted=true` ohne `kind=offer`); sie erhöhen weder den aktuellen/routenfähigen Zähler noch die Marktdeckung. Reguläre Prospektpreise bleiben unverändert nutzbar.
- Eine Regression schützt die Trennung zwischen aktueller Preisbasis und sichtbarer Angebots-Evidenz.

## Update 17.10.2026 – Suchvorschläge verwenden keine direkten Prospekt-Aktionspreise

- Der Suchvorschlags-Preispfad verwirft direkte Legacy-Prospekt-Aktionspreise jetzt vor der sichtbaren Preisermittlung.
- Reguläre Prospektpreise bleiben als aktuelle Hinweise verfügbar; Angebotspreise stammen weiterhin aus dem getrennten Offer-Modell.
- Die Regression prüft, dass ein billiger Legacy-Aktionspreis keinen regulären Prospektpreis in Suchvorschlägen überdeckt.

## Update 17.10.2026 – Einkaufskandidaten verwerfen direkte Prospekt-Aktionspreise

- Direkte Legacy-Prospekt-Aktionspreise werden jetzt auch aus der Marktpreis-Schleife der Einkaufskandidaten entfernt.
- Aktuelle reguläre Prospektpreise bleiben als Preisbeleg sichtbar; aktive Angebote werden weiterhin ausschließlich über das Offer-Modell bewertet.
- Eine Regression schützt diese Trennung, damit Vorschläge, Preis-Matrix und Route dieselbe Preisbasis verwenden.

## Update 17.10.2026 – Direkte Prospekt-Aktionspreise bleiben nicht routbar

- [x] `MarketPrice` kennzeichnet Prospekt-Aktionspreise über Kind und Discount-Metadaten eindeutig.
- [x] Planungs-, Routen- und Preis-Matrix-Auswahl verwerfen diese Legacy-/Direktdatensätze zentral; `isUsable` bleibt für aktuelle Evidenz- und Qualitätsstatistiken unverändert.
- [x] Regressionen prüfen Projektion, `planningMarketPrices` und sichtbare Einkaufspreise; gültige reguläre Streichpreise bleiben unverändert nutzbar.
## Update 17.10.2026 – Preisquellenrangfolge in Suche und Kandidaten vereinheitlicht

- Marktpreise tragen in Suchvorschlägen und im Variantenfenster jetzt denselben
  qualitätsbereinigten Vergleichswert wie die Routenprojektion.
- Bei gleicher Qualität und gleichem Betrag gilt überall die dokumentierte
  Reihenfolge eigener Preis → Bonpreis → Prospekt → Open Prices; der angezeigte
  Kassenbetrag bleibt unverändert.
- Die neue Regression prüft Kandidaten- und Suchranking mit gleich teuren
  Belegen. Angebote behalten ihre eigene aktuelle Evidenz und werden nicht in
  reguläre Normalpreise umgedeutet.

## Update 16.10.2026 – Coverkarten füllen feste Zellen

- Favoritenrail und Coverraster füllen ihre festen Kartenhöhen jetzt vollständig; die weiße Metadatenfläche endet nicht mehr vor der Zellkante.
- Coverbild, Gültigkeit, Quellen-/Seitenstatus und Favoriten-/Öffnen-Aktionen bleiben unverändert.
- Ein Widgettest schützt die Höhe der Favoriten- und Rasterkarten.

## Update 16.10.2026 – Prospekte-Tab hält kürzere Bildreserve

- Der äußere Prospekte-Scroll wärmt nur noch 180 statt 360 Pixel Vorlauf vor.
- Dadurch bleibt die nächste Coverzeile schnell sichtbar, während beim schnellen Scroll weniger dekodierte Bilder außerhalb des Viewports gehalten werden.
- Die lazy Cover-, Seiten- und Add-to-List-Pfade bleiben unverändert.

## Update 16.10.2026 – Offers-Scroll hält kürzere Bildreserve

- Der übergeordnete Angebote-Scroll wärmt nur noch 180 statt 360 Pixel Vorlauf vor.
- Dadurch startet die nächste Coverzeile weiterhin früh genug, während beim schnellen Scroll weniger dekodierte Bilder außerhalb des sichtbaren Bereichs gehalten werden.
- Die verschachtelten Coverlisten bleiben bei Cache-Vorlauf 0; Angebots-, Gültigkeits- und Add-to-List-Regeln ändern sich nicht.

## Update 16.10.2026 – Cover-Scroll hält Offscreen-Karten nicht fest

- Die horizontale Favoritenleiste und das Coverraster deaktivieren automatische Keep-Alives und eigene Vorhaltebereiche; der übergeordnete Scrollpfad kontrolliert die sichtbare Reserve.
- Dadurch werden beim schnellen Prospekt-Scroll weniger Coverkarten und externe Bilder gleichzeitig im Widget-/Decode-Pfad gehalten.
- Das Coverraster bleibt seitenweise nachladbar; Quellen-, Gültigkeits- und Add-to-List-Regeln ändern sich nicht.

## Update 16.10.2026 – Prospektparser bleibt bei malformed Collections nutzbar

- Der Feedparser ignoriert falsch typisierte `sources`, `prospects`, `pageSamples` und `offers`-Felder, statt den gesamten aktuellen Snapshot zu verwerfen.
- Valide Einträge aus demselben Feed werden weiterhin eingelesen; unbekannte Collection-Strukturen bleiben ohne erfundene Angebote leer.
- Eine Parserregression deckt verschachtelte und oberste Fehlformate ohne Netzwerkzugriff ab.

## Update 16.10.2026 – Routen-Refresh bleibt bei Cachefehlern aktuell

- Ein frischer OSRM-/Straßenmatrix-Abruf wird jetzt auch dann in der Ansicht verwendet, wenn das lokale Schreiben der Matrix oder der Distanzkarte fehlschlägt.
- Die beiden Cachepfade werden unabhängig voneinander versucht; ein Speicherfehler verwirft keine gültige Live-Antwort und erzeugt keinen falschen Abruffehler.
- Eine Regression prüft beide Fehlergrenzen mit anonymisierten Routendaten.

## Update 16.10.2026 – Adapterherkunft im erzeugten Prospektfeed

- Aktuell geladene offizielle Angebotszeilen tragen jetzt die konkrete Adapterstrecke in sourceAdapter; der verwendete Modus (structured_api, Website-Fallback oder Netto-Adapter) bleibt damit bis zur Preisbeobachtung nachvollziehbar.
- Provider-eigene Kennungen wie KaufDA oder Bring werden nicht überschrieben.
- Eine Fixture-Regression prüft, dass offizielle Feedzeilen nicht ohne Adapterherkunft in den Import gelangen; Preise, Produktidentität, Gültigkeit und Filialregeln bleiben unverändert.

## Update 15.10.2026 – Coverkarten zeigen exakte Filialherkunft

Wenn der Prospektfeed eine Filial-ID liefert, wird sie gemeinsam mit der
Quellenkennung auf der Coverkarte angezeigt. Händlername und Ort bleiben davon
getrennt; gleichnamige Märkte bleiben durch den bestehenden vollständigen
Filialschlüssel eindeutig. Fehlende Filial-IDs werden nicht ergänzt.

## Update 15.10.2026 – Coverkarten zeigen Quellen- und Seitenstatus

Die Coveransicht zeigt jetzt die technische Herkunft des Prospektfeeds, wenn der
Adapter sie liefert, sowie die belegte Seitenabdeckung. Bekannte Gesamtseiten,
geladene Bildvorschauen und gemeldete fehlende Seiten werden getrennt angezeigt;
unbekannte Angaben bleiben ausgeblendet. Die Anzeige nutzt ausschließlich
vorhandene Feed-Metadaten und verändert weder die Prospektfilterung noch die
automatische Speicherung regulärer Normalpreise.

## Update 15.10.2026 – Zukünftige individuelle Prospekt-Erfassungen bleiben ungespeichert

Die automatische Speicherung regulärer Prospektpreise prüft neben Laufzeit,
Nachweis und Filialbezug nun auch den individuellen `capturedAt`-Zeitpunkt.
Liegt dieser Zeitpunkt in der Zukunft, bleibt der Beleg aus der lokalen
Preisgrundlage; ein gültiger Feed mit anderen Datensätzen wird dadurch nicht
verworfen. Eine Fachregression schützt diesen Provenienzfilter.

## Update 15.10.2026 – Gespeicherte Normalpreisbelege im Preise-Reiter

Der Preise-Reiter zeigt neben dem Speicherstatus nun die aktuell gültigen,
automatisch gespeicherten regulären Prospektbelege mit Produkt, exakter Filiale,
Gültigkeitszeitraum, Adapterherkunft und Nachweis. Angebotsbelege und abgelaufene
Beobachtungen werden aus diesem Ledger ausgeschlossen; die Anzeige bleibt eine
Nachvollziehbarkeitsschicht und ändert keine Routenentscheidung.

## Update 15.10.2026 – Preise-Reiter zeigt automatische Normalpreisspeicherung

Der Preise-Reiter zeigt jetzt zusätzlich zum aktuellen Belegbestand den Status
des automatischen Prospekt-Preislernens: Feed-Zeitpunkt, Cache-Herkunft,
bestätigte Speicherung und die Abdeckung je Markt/Filiale. Die Anzeige zählt
ausschließlich ausdrücklich ausgewiesene reguläre Normalpreise; Aktionspreise
bleiben getrennt. Die Darstellung ändert weder die bestehende
PriceObservation-/MarketPrice-Projektion noch die Routenentscheidung.

## Update 15.10.2026 – KaufDA-UVP bleibt aus der Preisbasis

- Der optionale KaufDA-Adapter erkennt neben dem Boolean-Feld auch explizite UVP-/Herstellerpreis-Kennzeichnungen.
- Solche Vergleichswerte bleiben aus `originalPrice` und damit aus der automatischen regulären Preisbeobachtung ausgeschlossen.
- Ein tatsächlich ausgewiesener, höherer Normalpreis bleibt weiterhin speicherbar; die neue Regression schützt beide Fälle.

## Update 15.10.2026 – Prospekt-Herkunft bleibt beim Öffnen erhalten

- `sourceAdapter` wird aus dem Feed-Metadatenknoten auch am `ProspectIssue` geführt und beim sichtbaren Issue-Rebuild erhalten.
- Manuelle Seiten-/OCR-Übernahmen können dadurch die technische Herkunft, etwa `kaufda`, bis zum gespeicherten Offer behalten.
- Der Adapter bleibt Provenienz; Filial-, Identitäts-, Gültigkeits- und Preisregeln ändern sich nicht.
- Parser-, Fingerprint- und Widgetregressionen decken die Grenze ab.

## Update 15.10.2026 – Geprüfte Prospektseiten behalten den Erfassungszeitpunkt

- Manuell bestätigte Angebote aus einer Prospektseite oder einem lokalen OCR-Vorschlag speichern jetzt den Zeitpunkt der Prüfung als `capturedAt`.
- Beim Weiterreichen in den persistenten Offer-Datensatz bleiben Erfassungszeitpunkt und optionale Adapterherkunft erhalten.
- Angebotsgültigkeit, Normal-/Angebotspreis-Trennung und Identitätsprüfung bleiben unverändert.
- Eine Widgetregression schützt den Provenienzbeleg.

## Update 15.10.2026 – Manueller Prospekt-Refresh repariert lokale Preisspeicherung

- Der manuelle Aktualisieren-Button darf einen unveränderten, validierten Feed erneut durch den regulären Preis-Persistenzpfad führen.
- Automatische und zeitgesteuerte Refreshes bleiben über den Feed-Fingerprint dedupliziert.
- So können reguläre, durchgestrichene Prospektpreise nach einem temporären Speicherfehler erneut lokal bestätigt werden, ohne Angebotspreise umzudeuten.
- Eine Fingerprint-Regression prüft den erzwungenen Reparaturlauf.

## Update 15.10.2026 – Prospekt-Adapterherkunft bis zur Preisbeobachtung

- Der Quellenknoten `mode` bzw. eine explizite Adapterkennung wird bei fehlender Zeilenkennung kontrolliert auf das Prospektangebot vererbt.
- Eine vorhandene Zeilenkennung wie `kaufda` hat Vorrang; Markt, Branch-ID, Gültigkeit, Preis und Nachweis bleiben unverändert.
- Dadurch bleibt die konkrete technische Herkunft auch in regulären `PriceObservation`-Belegen nachvollziehbar.
- Parser- und Persistenzregressionen prüfen Vererbung und explizite Überschreibung.

## Update 15.10.2026 – Formatierten Händlerquellen ohne doppelte Karten

- Quellen und konfigurierte Händlerkarten vergleichen Händlernamen jetzt mit derselben begrenzten Normalisierung aus Leerzeichen und Groß-/Kleinschreibung.
- Eine Quelle wie `LIDL` erzeugt dadurch keine zusätzliche `Lidl`-Platzhalterkarte; Filial- und Branch-Schlüssel bleiben davon unberührt.
- Die Parser-Regression prüft die eindeutige Anzeige und den weiterhin konservativen Mehrfilialfall.

## Update 15.10.2026 – Prospektquellen tolerieren Händlername-Formatierung

- Die Zuordnung von Angebotszeilen zu Quellenmetadaten normalisiert ausschließlich Groß-/Kleinschreibung und umgebende Leerzeichen des Händlernamens.
- Filial-ID, Ort und Adresse bleiben aus der exakten Quellenmetadaten erhalten; mehrere gleichnamige Filialen ohne Zeilen-Filial-ID bleiben weiterhin unbekannt.
- Regressionen prüfen den eindeutigen formatierten Treffer und den mehrdeutigen Mehrfilialfall.

## Update 15.10.2026 – Cache-Prospektpreise filialgenau ausweisen

- Der Offline-/Cache-Pfad verwendet jetzt dieselbe Persistenz-Auswertung wie der Live-Refresh.
- Nur aktuell gelernte und tatsächlich gespeicherte reguläre Beobachtungen zählen als bestätigt; ein fehlender regulärer Cache-Preis wird als bestätigte Null statt als alter Stand angezeigt.
- Filialschlüssel bleiben auch im Cache getrennt, sodass gleichnamige Märkte nicht zusammengezählt werden.
- Eine Regression schützt getrennte Filialen, storeweite Legacy-Einträge und nicht gespeicherte Beobachtungen.

## Update 15.10.2026 – Prospektabdeckung exakt je Filiale

- Prospektabdeckung gruppiert Angebote, Seiten und Herkunft jetzt über die bestehende Store-plus-Branch-Identität; gleichnamige Filialen werden getrennt angezeigt.
- Filial-ID, Ort und Adresse bleiben im Coverage-Modell sichtbar. Der alte Store-Platzhalter wird ausgeblendet, sobald exakte Filialdaten vorhanden sind.
- Persistierte reguläre Preise verwenden denselben Filialschlüssel. Store-only Altstände bleiben nur bei höchstens einer erkannten Filiale verwendbar; bei mehreren Filialen bleibt die Zuordnung unbekannt.
- Regressionstests decken getrennte gleichnamige Filialen, Legacy-Zähler und den einzelnen Filial-Fallback ab.

## Update 15.10.2026 – Cover-Fallbacks beim Scrollen begrenzt

- Nach einem Canvas-/CDN-Fehler dürfen höchstens vier Cover gleichzeitig einen teuren HTML-Plattformfallback reservieren.
- Recycelte Karten geben ihren Slot beim Unmount oder URL-Wechsel frei; weitere Fehler zeigen einen sicheren Platzhalter und erzeugen keine zusätzliche Browseransicht.
- Eine Unit-Regression schützt das Budget und die Wiederverwendung freier Slots. Der explizite Prospekt- und Großansicht-Link bleibt unverändert.

## Update 15.10.2026 – Seitenviewer begrenzt Plattform-Fallbacks

Der lange Prospektseitenviewer begrenzt automatische HTML-Plattform-Fallbacks jetzt auf die ersten zwei Seiten. Weitere Seiten bleiben im Canvas-Pfad und zeigen bei einem CDN/CORS-Fehler einen sicheren Platzhalter; der vorhandene Großansicht-Link bleibt als expliziter Ausweichpfad erhalten. Damit bleibt der Scrollpfad bei großen Prospekten begrenzt.

## Update 15.10.2026 – Aktuellste reguläre Prospektquelle pro Filiale

Die aktuelle Preisprojektion behandelt überlappende, neu eingelesene Prospektzeiträume derselben Produkt-/Filialkombination jetzt deterministisch: Der neueste belegte reguläre Anspruch ersetzt nur die ältere aktuelle Projektion. Append-only Preisbeobachtungen und ihre Nachweise bleiben erhalten; unterschiedliche Branch-IDs werden getrennt projiziert.

## Update 15.10.2026 – Preisregel im Prospekt-Reiter sichtbar

Die Prospektstatuskarte erklärt jetzt direkt die getrennte Preisrolle: Ein belegter, durchgestrichener Normalpreis kann als lokale Preisbasis gespeichert werden; der aktuelle Aktionspreis bleibt an den gültigen Prospektzeitraum gebunden und wird nicht als Normalpreis gespeichert. Die bestehende Speicherung und Routenlogik bleiben unverändert.

## Update 15.10.2026 – Preise-Reiter zeigt Herkunft und Route-Fähigkeit

Der Preise-Reiter zeigt jetzt neben dem Listenvergleich eine lokale Qualitätsübersicht der gespeicherten Marktpreisbelege. Nur `MarketPrice.isUsable` zählt als aktuell und routenfähig; veraltete, zukünftige, unvollständige oder unsichere Belege bleiben als Datenlücke sichtbar. Prospekt-Normalpreise werden getrennt von Prospekt-Angebotsnachweisen gezählt. Die Übersicht zeigt zusätzlich die aktuelle Abdeckung je Markt, ohne Preisauflösung oder Optimierer zu verändern.

## Update 15.10.2026 – Formatierte Normalpreise werden aus Prospekten gespeichert

Der Prospektparser akzeptiert reguläre Händlerpreise jetzt als Zahl oder als strikt formatierten deutschen Anzeigewert wie `7,99 €`. Freie Beschreibungen werden verworfen. Der Aktionspreis bleibt ausschließlich Angebotsdaten; nur der ausdrücklich höhere Normalpreis wird automatisch als `PriceObservationKind.regular` lokal gespeichert und weiterprojiziert. Ein End-to-End-Test prüft die Kette vom Feed bis zum lokalen Preisbeobachtungsspeicher.

## Update 15.10.2026 – Recycelte Prospektbilder behalten keinen alten Fallback

Beim schnellen Prospekt-Scroll werden verzögerte HTML-Fallbacks jetzt gegen die URL des aktuell montierten Bildes geprüft. Ein Fehler eines bereits recycelten Covers oder einer Seite kann dadurch keinen teuren Browserpfad für den nächsten Eintrag aktivieren. Eine Regression schützt die Zuordnung zwischen fehlgeschlagener und aktueller Bild-URL.

## Update 15.10.2026 – Filialgenaue Prospektkarten beim Lazy-Scroll

Die Prospektkarten verwenden für Cover, Öffnen und Favoriten jetzt denselben vollständigen Filialschlüssel wie die äußere Karte. Beim virtuellen Scrollen bleiben gleichnamige Filialen dadurch getrennt; Bild- und Aktionszustände können nicht zwischen zwei Märkten wiederverwendet werden. Eine Widgetregression prüft zwei Lidl-Filialen mit eigener Branch-ID.

## Update 15.10.2026 – Filialgenauer Distanz-Cache und Routenanzeige

Die einzelne Marktansicht speichert Straßenentfernungen jetzt über denselben stabilen Filialschlüssel wie die Routenberechnung. Ein alter Cache-Eintrag nur mit Händlername wird für eine identifizierte Filiale nicht mehr als scheinbar exakte Entfernung wiederverwendet. Routenalternativen zeigen zusätzlich den Ort; dadurch bleiben gleichnamige Filialen im Vergleich erkennbar. Tests schützen getrennte Fallback-Distanzen und die sichtbare Filialbezeichnung.

## Update 15.10.2026 – Routenalternativen bleiben filialgenau

- Die Alternativenliste unterschlägt gleichnamige Filialen nicht mehr: Branch-ID, Ort und Adresse fließen in den Routenschlüssel ein.
- RouteScreen und RouteOptimizer verwenden jetzt denselben Identitätsvertrag; Reihenfolge und sichtbare Alternativen bleiben deterministisch.
- Eine anonymisierte Regression trennt zwei Lidl-Filialen mit gleichem Händlernamen und unterschiedlichen Standorten.

## Update 15.10.2026 – Einkaufs-Preis-Matrix zeigt exakte Filiale

- Preiszitate verlieren die Quellfiliale nicht mehr zwischen Filterung, Matrix und UI: Branch-ID und lesbare Standortdaten bleiben erhalten.
- Einkaufslisten-Badge, Preis-Matrix und Detailansicht kennzeichnen jetzt die tatsächlich ausgewählte Filiale; ohne Quelle wird keine Filiale erfunden.
- Unit-Regressionen prüfen Marktpreis-, Angebots- und deterministische Gleichstandsfälle.

## Update 15.10.2026 – Reguläre Prospektpreise vor Cache-Rennen schützen

- Ein langsamer Cache-Lauf wird nach einem erfolgreichen Live-Feed verworfen; zusätzlich schützt der lokale Beobachtungsspeicher frischere automatische Evidenz vor verspäteten älteren Writes.
- Legacy-Angebotsbeobachtungen aus dem automatischen Prospektpfad werden auch ohne Feed-Zeitstempel entfernt. Sie gelangen weiterhin nicht in die Marktpreisprojektion.
- Store- und Persistenzregressionen decken den Cache-/Live-Fall sowie den timestamplosen Bereinigungspfad ab.

## Update 15.10.2026 – Prospektartikel bleiben filialgenau

- Aktuelle Prospektartikel werden nach Händler und vorhandener Branch-ID getrennt gruppiert; gleichnamige Filialen vermischen keine Artikel mehr.
- Händlername und Standort bleiben in der Anzeige lesbar; interne Schlüssel, Kategorien und Quellenhinweise bleiben exakt filialbezogen.
- Eine Widgetregression schützt getrennte Lidl-Gruppen für Zellingen und Würzburg.

## Update 15.10.2026 – Prospekt-Cover bleiben filialgenau

- Coverkarten und Artikelgruppen verwenden jetzt Händlername plus vorhandene Branch-ID als stabilen Schlüssel; gleichnamige Lidl-/Netto-Filialen bleiben getrennt.
- Nicht filialgebundene Altbelege zählen weiterhin als unscoped Evidenz für eine Branch-Karte, während Belege anderer expliziter Filialen nicht zugemischt werden.
- Eine Widgetregression schützt zwei anonymisierte Filialen derselben Kette in Favoritenleiste und Raster.

## Update 15.10.2026 – Prospekt-Cover beim Scrollen stabilisieren

- Coverbilder erhalten innerhalb des adaptiven Image-Widgets jetzt einen Schlüssel aus ihrer vollständigen URL.
- Beim Wiederverwenden von Grid-/Favoritenkarten bleibt der Bildzustand damit an der tatsächlichen Quelle gebunden; unterschiedliche Händlercover werden nicht mehr durch einen identischen Literal-Schlüssel verwechselt.
- Eine Widgetregression prüft beide URL-Schlüssel. Der bestehende Canvas-/HTML-Fallback und die Bildgrößenbegrenzung bleiben erhalten.

## Update 15.10.2026 – Cache-Prospektpreise lokal sichern

- Ein validierter gecachter Prospektstand wird beim Offline-Start nun ebenfalls durch den regulären Preisbeobachtungspfad geführt.
- Gespeichert werden nur aktuelle, branch-belegte und nachgewiesene reguläre Preise; der befristete Angebotspreis bleibt ausgeschlossen.
- Eine deterministische Regression prüft den vollständigen Preisfluss bis zum Einkaufslisten-Zitat; die AppShell-Widgetprüfung bleibt wegen des instabilen SharedPreferences-Test-Harnesses bewusst aus dem CI.

## Update 15.10.2026 – Mehrdeutige Open-Prices-Filialen bleiben unbekannt

- Der Preisadapter übernimmt einen standortlosen Open-Prices-Treffer nur bei genau einer passenden konfigurierten Filiale.
- Bei mehreren gleichnamigen Märkten im selben Ort bleibt der Preis unbekannt, bis der Anbieter eine eindeutige Standort-ID liefert; dadurch wird keine falsche Routebasis erzeugt.
- Die Regression läuft zusammen mit den bestehenden EAN-, Orts-, Postleitzahl- und Branch-ID-Prüfungen.

## Update 15.10.2026 – Open Prices bleibt filialgenau

- Der Open-Prices-Adapter gruppiert Beobachtungen jetzt nach Händler und Quellfiliale statt nur nach dem sichtbaren Händlernamen.
- Zwei gleichnamige konfigurierte Filialen können dadurch ihre eigenen Preise, Standort-IDs und Aktualitätswerte behalten; unbekannte oder widersprüchliche Standorte werden weiterhin verworfen.
- Eine Fixture-Regression schützt die getrennte Rückgabe und verändert weder Cache-, Frische- noch Routenregeln.

## Update 15.10.2026 – Prospekt-Cover respektieren offene Gültigkeitsgrenzen

- Der Angebote-Reiter prüft jetzt auch ein allein geliefertes `validFrom` und blendet zukünftige Cover aus; ein fehlendes `validUntil` macht einen Datensatz nicht automatisch aktuell.
- Abgelaufene und umgekehrte optionale Zeiträume werden als unbrauchbare Evidenz behandelt. Unbegrenzte Metadaten ohne Datumsangabe bleiben als Quelle sichtbar.
- Unit- und Widgetregressionen decken die offene Datumsgrenze und den Angebote-Reiter ab.

## Update 15.10.2026 – Bonzeilen mit expliziten Produktvorschlägen

- Unklare Bonpositionen können jetzt direkt am Eintrag aus bis zu drei Namens-/Alias-Treffern des vorhandenen Katalogs ausgewählt werden.
- Die Auswahl bleibt manuell und trennt Vorschlag, Identitätsbestätigung und Preisprojektion; breite Kategorie-Treffer werden nicht als Produktidentität angeboten.
- Unit- und Widget-Tests prüfen Trefferfilterung, Begrenzung und die notwendige explizite Auswahl.

## Update 15.10.2026 – OSRM-Caches bleiben filialgenau

- Ein gespeicherter Matrixstand wird nur wiederverwendet, wenn er alle aktuell angeforderten exakten Filialschlüssel abdeckt.
- Bei neuen Branch-IDs liefert ein Offline-/Timeout-Fallback keinen alten gleichnamigen Marktstand zurück; die Route fällt transparent auf lokale Entfernungen zurück.
- Eine Regression schützt die Abgrenzung zwischen alter und neuer Filiale.

## Update 15.10.2026 – More-Routenansicht bleibt filialgenau

- Der RouteScreen im More-/Shell-Seitenpfad erhält jetzt denselben exakten Filialkatalog wie die direkte Routenansicht und der ShellRouting-Snapshot.
- Gleichnamige Märkte werden dadurch auch beim zweiten Einstieg mit Branch-ID, Ort und Adresse aufgelöst; Preis-, Quellen- und Offline-Fallback bleiben unverändert.

## Update 15.10.2026 – Route-UI bleibt filialgenau

- RouteScreen reicht den exakten Filialkatalog jetzt an RouteOptimizer und OSRM weiter; die Distanzmatrix wird nicht mehr auf den globalen Namenkatalog begrenzt.
- ShellRouting hält den Filialkatalog im Snapshot-Schlüssel. Ein Wechsel zwischen gleichnamigen Filialen verwirft den alten Optimierer deterministisch.
- Die Regression prüft Branch-ID und Adresse im Optimierer sowie die Snapshot-Invalidierung. Preisabdeckung, Mindestvorteil und Offline-Fallback bleiben unverändert.

## Update 15.10.2026 – Routenlimit auf sechs Projektmärkte erweitert

- Die Route erzeugt jetzt deterministisch jede nicht-leere Kombination bis zum konfigurierten maxStores-Limit. Damit werden vier bis sechs aktivierte Märkte nicht mehr stillschweigend ignoriert.
- MobilitySettings validiert gespeicherte Werte bis sechs Märkte; die Profileinstellung bietet denselben Bereich an.
- Die Regression prüft alle 63 Kombinationen des vollständigen Sechs-Markt-Katalogs und die JSON-Rundreise des neuen Limits. Preisabdeckung, Mindestvorteil, Fahrtkosten und Offline-Fallback bleiben unverändert.

## Update 15.10.2026 – Branch-stabile Fahrmatrizen

- Neue OSRM-Matrizen verwenden bei vorhandener Branch-ID stabile Filialschlüssel; identische Händlernamen können dadurch getrennte Distanz- und Fahrzeitwerte tragen.
- Ältere Matrizen mit sichtbaren Händlernamen sowie bestehende Distanz-Caches bleiben als Fallback lesbar.
- Die Regression deckt die exakte Filialreihenfolge, branch-getrennte Fahrtkosten und Fahrzeiten ab.

## Update 15.10.2026 – Routenplanung bleibt filialgenau

- Der RouteOptimizer kann neben dem bestehenden Standardkatalog einen immutable Filial-Snapshot erhalten. Das unterstützt spätere Quellenadapter, ohne die globale Marktstammdatenliste zu verändern.
- Bei identischer Preisabdeckung und identischem Planungswert entscheidet die Route jetzt über Branch-ID, Ort und Adresse statt nur über den sichtbaren Händlernamen.
- Die Regression deckt gleiche Händlernamen, getrennte sourceLocationId-Preise und stabile Auswahl unabhängig von der Eingangsreihenfolge ab.

## Update 14.10.2026 – OSRM-Reihenfolge nach Gesamtwegekosten

- Eine vollständige OSRM-Dauermatrix kann die Marktfolge jetzt anhand von Fahrtkosten und persönlichem Zeitwert bewerten.
- Bei fehlenden oder alten Dauerwerten bleibt die bestehende Distanz- und Geschwindigkeitsheuristik aktiv.
- Gleiche Ergebnisse bleiben über Distanz, Dauer und Marktnamen deterministisch.

## Update 14.10.2026 – Automatische Prospektpreise bereinigen

- Der reguläre Prospektpreis wird weiterhin atomar per stabiler Beobachtungs-ID gespeichert.
- Alte automatisch erzeugte Prospekt-Angebotsbeobachtungen werden beim nächsten datierten Feedlauf gezielt entfernt; reguläre Historie und manuell bestätigte Angebotsverläufe bleiben erhalten.
- Der Marktpreis-Projektor erhält damit aus dem Prospektpfad ausschließlich reguläre Preisbelege.

## Update 14.10.2026 – OSRM liefert Fahrzeit für die Routenplanung

- Die optionale OSRM-Matrix übernimmt neben Straßenentfernungen jetzt auch explizite Fahrzeiten aus den öffentlichen `duration`-Antwortfeldern.
- Die Dauer bleibt separat von der Distanz gespeichert und wird nur verwendet, wenn die komplette Rundtour-Matrix dafür Werte enthält; ältere Caches und Offline-Fallbacks nutzen unverändert die konfigurierte Mobilitätsgeschwindigkeit.
- RouteOptimizer, TravelEstimate und die Zeitkosten berücksichtigen damit reale Matrix-Fahrzeiten, ohne fehlende Daten als 0 Minuten zu erfinden.
- Fixture-Regressionen schützen OSRM-Parsing, Cache-Kompatibilität und den Heuristik-Fallback.

## Update 14.10.2026 – KaufDA-EAN bleibt an exakte Varianten gebunden

- Der optionale KaufDA-Adapter übernimmt explizit benannte EAN/GTIN-Felder
  normalisiert in den bestehenden Prospektdatensatz; fehlende oder ungültige
  Codes bleiben ohne Identitätsbehauptung.
- Ein Prospektlabel darf jetzt über genau eine übereinstimmende Katalog-EAN
  einer konkreten Variante zugeordnet werden, auch wenn der angezeigte Name
  verkürzt ist. Mehrdeutige oder nicht im Katalog belegte Codes bleiben im
  Review und fallen nicht auf eine ähnlich benannte Produktfamilie zurück.
- Feed-, Offer- und PriceObservation-Tests schützen die EAN-Herkunft,
  Packungsprüfung und den Mismatch-Fall.

## Update 14.10.2026 – EAN in Prospekt-Preisbeobachtungen

- Exakt aufgelöste Prospektprodukte führen ihre bereits bekannte Katalog-EAN jetzt in Angebot- und regulärer Preisbeobachtung mit.
- Unsichere, synthetische oder nicht aufgelöste Prospektlabels erhalten weiterhin keine EAN; es wird keine Identität aus dem Preislabel geraten.
- Damit bleiben Barcode-, Open-Prices- und Produktvergleichsdaten entlang der bestehenden Beobachtungspipeline nachvollziehbar.

## Update 14.10.2026 – Prospekt-Packungen exakt normalisieren

- Automatische Prospektpreise werden bei einer expliziten Packungsangabe jetzt auch dann exakt einer Katalogidentität zugeordnet, wenn der Katalogname die Packung als separates `unit`-Feld führt.
- Die Zuordnung vergleicht nur den kanonischen Produktkern und die normalisierte Packungsmenge; Varianten, Familien und unterschiedliche Größen bleiben getrennt oder unbekannt.
- Milligramm werden in Produktmatching und Grundpreisberechnung als Masseeinheit unterstützt.
- Die KaufDA-Importauflösung nutzt dieselbe strenge Packungskern-Regel; Alias- und Teilstring-Treffer werden dadurch nicht automatisch erweitert.

## Update 14.10.2026 – Reguläre Prospektpreise bleiben aktuell

- Wiederholte Feed-Refreshes upserten dieselbe reguläre Beobachtung über ihre stabile ID und aktualisieren dadurch den Erfassungszeitpunkt, ohne Duplikate anzulegen.
- Die sichtbare Normalpreiszahl stammt im Prospekt-Reiter aus der erfolgreich geschriebenen lokalen Preisbeobachtung; bei einem Schreibfehler wird der Feed beim nächsten Refresh erneut verarbeitet.
- Ein gleicher Angebots- und Durchstreichpreis gilt weiterhin als Angebotsnachweis, wird aber nicht als regulärer Normalpreis gespeichert.

## Update 14.10.2026 – KaufDA-Non-Food-Grenze und Adapter-CI

- Der optionale KaufDA-Parser verwirft jetzt klar erkennbare zusammengesetzte Non-Food-Bezeichnungen, auch wenn darin ein Lebensmittelwort vorkommt.
- Die vorhandene Kategoriepfad-Prüfung bleibt vorrangig; die neue Grenze ergänzt nur eng gefasste Produktklassen wie Kaffeemaschinen, Küchenmaschinen, Tomatenpflanzen und Fleischwölfe.
- Die anonymisierten Python-Fixtures für KaufDA, Bring und den Refresh-Adapter laufen jetzt als eigener Schritt in der normalen Flutter-CI.

## Update 14.10.2026 – Prospektseiten ohne progressive Lade-Rebuilds

- Der Prospektviewer zeigt bis zum ersten dekodierten Bildframe einen stabilen Platzhalter.
- Chunkweise Lade-Callbacks werden nicht mehr für jede Netzwerkantwort neu aufgebaut; das reduziert Rebuild- und Animationsdruck beim schnellen Scrollen.
- Die Canvas-first-Strategie, begrenzte Decode-Größen und der gezielte HTML-Fallback bleiben unverändert.

## Update 14.10.2026 – Artikelbilder aus belegten Prospektseiten ergänzen

- [x] Fehlt einem strukturierten Lebensmittelangebot ein eigenes Produktbild, übernimmt die Feedgrenze nur bei exakt gleicher Filiale und Prospektseite ein bereits validiertes Seitenbild.
- [x] Gültigkeitszeiträume werden beim Seitenfallback überschneidungssicher geprüft; alte oder mehrdeutige Seitenbilder bleiben leer.
- [x] Ein vorhandenes Artikelbild hat Vorrang. Der Fallback erfindet weder URLs noch Produktdaten und ist durch eine Parserregression geschützt.

## Update 14.10.2026 – Prospekt-Refresh berücksichtigt Tagesgrenzen

- [x] Der Fingerabdruck enthält neben den validierten Feedfeldern auch den aktuellen Kalendertag.
- [x] Ein unveränderter Feed wird beim Wechsel des Gültigkeitstages erneut normalisiert; neu gültige und abgelaufene Angebote erreichen dadurch dieselbe Filter-, Offer- und Preisbeobachtungspipeline.
- [x] Filterung und Persistenz verwenden denselben Zeitstempel, damit ein Tageswechsel keine gemischten Datenstände erzeugt.

## Update 14.10.2026 – Uneindeutige Prospektartikel manuell übernehmen

- [x] Aktuelle, filialbezogene und belegte Artikel mit uneindeutiger Katalogidentität können nach ausdrücklicher Bestätigung als exakter eigener Listeneintrag übernommen werden.
- [x] Die manuelle Übernahme erzeugt keine automatische Offer-/Routenpreisidentität; regionale, unbewiesene, abgelaufene und ungültige Datensätze bleiben gesperrt.
- [x] Compact- und Viewer-Karten zeigen den Prüfschritt transparent; eine Widget- und eine Produktauflösungs-Regression schützen den Pfad.

## Update 14.10.2026 – Offizielle Prospektkategorien belastbar normalisieren

- [x] Offizielle Quellen akzeptieren zusätzlich explizit benannte Unterkategorien, Abteilungen und begrenzte Kategoriepfade.
- [x] Verschachtelte Kategorieobjekte werden nur über bekannte Präsentationsfelder bis zu einer festen Tiefe gelesen; IDs, URLs und beliebige Objekte bleiben ausgeschlossen.
- [x] Kategorien bleiben reine Herkunfts-/Anzeigeinformation und verändern weder Produktidentität noch Preis- oder Routenentscheidungen.
- [x] Python-Fixtures schützen positive Aliasfälle und die Ablehnung nicht-textueller Kategorien.

## Update 14.10.2026 – kaufDA-Evidenzfelder tolerant normalisieren

- [x] Der optionale kaufDA-Adapter akzeptiert bekannte, explizit benannte Varianten für Artikelbild, Kategorie, Packungsgröße, Grundpreis und Normalpreis.
- [x] Verschachtelte Präsentationsfelder werden nur bis zu einer festen Tiefe und nur nach HTTP(S)-Prüfung übernommen; regionale Treffer bleiben regional.
- [x] Fixture-Regressionen schützen die Aliasnormalisierung und blockieren nicht öffentliche/ungültige Bildwerte.

## Update 14.10.2026 – Prospekt-Evidenzfelder tolerant normalisieren

- [x] Die App-Feedgrenze akzeptiert ausschließlich explizit benannte Varianten für Artikelbild, Kategorie, Packungsgröße und Grundpreis.
- [x] Verschachtelte öffentliche Felder wie `productImage.url` und `productCategory.title` werden validiert übernommen; beliebige URLs, Rabattwerte und Identitätsraten bleiben ausgeschlossen.
- [x] Coverseiten, Artikelbilder, Filialdaten, Gültigkeit, Nachweis und reguläre Normalpreise bleiben getrennte Evidenzsignale und werden nicht gegenseitig ergänzt.
- [x] Eine Fixture-Regression schützt die Aliasfelder und die bestehende Lebensmittel-/Filial-/Gültigkeitsprüfung.

## Update 14.10.2026 – Reguläre Prospektpreise tolerant normalisieren

- [x] Explizite Normalpreisfelder wie `originalPrice`, `regularPrice`, `normalPrice`, `wasPrice` und `oldPrice` werden an der Python- und Dart-Feedgrenze einheitlich gelesen.
- [x] Rabattwerte, UVP-/Listenpreise und beliebige numerische Felder werden nicht als Normalpreis interpretiert.
- [x] ALDI-/EDEKA-Varianten mit verschachtelten Preisobjekten behalten den belegten Normalpreis bis zur regulären PriceObservation.
- [x] Parserregressionen decken Aliasfelder und die bestehende strikte Validierung ab.

## Update 14.10.2026 – Prospektfeed-Parsing im Prozess wiederverwenden

- [x] Cache- und gebündelte Feedantworten werden pro Herkunft im laufenden Service nur einmal dekodiert.
- [x] Wiederholte lokale Reads beim Start und beim App-Fortsetzen verwenden dasselbe validierte Ergebnisobjekt, ohne Aktualitäts- oder Quellenregeln zu ändern.
- [x] Liveantworten bleiben separat memoisiert; ein lokaler Fallback kann daher keine Live-Herkunft überschreiben.

## Update 14.10.2026 – Prospektpreise beim App-Fortsetzen aktualisieren

- [x] AppShell registriert einen Lifecycle-Observer und startet beim Fortsetzen einen Hintergrund-Refresh, sobald der letzte validierte Feedstand älter als sechs Stunden ist.
- [x] Eine fehlende oder veraltete Zeitangabe löst einen Refresh aus; zukünftige Zeitstempel nach einer Geräteuhrkorrektur erzeugen keine Schleife.
- [x] Der lokale Prospektstand bleibt während des Netzabrufs sichtbar, und die bestehende Speicherung regulärer Normalpreise läuft unverändert über den bestehenden PriceObservation-Pfad.
- [x] Eine Policy-Regression deckt fehlende, frische, alte und zukünftige Zeitstempel ab.
- [x] Solange die App aktiv ist, plant AppShell höchstens einen sechs-stündigen Hintergrund-Refresh; beim Pausieren wird der Timer beendet und beim Fortsetzen neu gesetzt.

## Update 14.10.2026 – Prospektviewer-Schlüssel stabilisiert

- [x] Artikelkarten im Prospektviewer verwenden jetzt denselben deterministischen Fallback-Schlüssel wie die Suche, auch wenn eine Quelle keine `sourceId` liefert.
- [x] Dadurch bleiben mehrere Artikel einer geöffneten Prospektseite eindeutig, der Viewer stürzt beim Recycling/Scrollen nicht an doppelten Flutter-Keys ab und der Add-Button bleibt erreichbar.
- [x] Eine Widgetregression öffnet einen Viewer mit zwei sourceId-losen Artikeln, prüft beide Karten und übernimmt einen Artikel in die Einkaufsliste.

## Update 14.10.2026 – Bonpreise je Markt sichtbar, Zuordnung bleibt transparent

- [x] Generische Einkaufslistenartikel zeigen bestätigte und automatische Bon-Hinweise je Markt, statt unbestätigte importierte Preise vollständig auszublenden.
- [x] Automatische Zuordnungen sind in der Detailansicht als „Variante prüfen“ gekennzeichnet und bleiben aus routenfähigen Preisen ausgeschlossen.
- [x] Konkrete Varianten übernehmen weiterhin nur ihre exakte Belegzuordnung; Familienpreise werden nicht still auf eine andere Variante übertragen.
- [x] Widget- und Fachtests schützen Marktübersicht, Hinweisstatus und die Trennung zur Routenlogik.

## Update 14.10.2026 – Prospekt-Fallback und lokales Quota-Verhalten

- [x] Cache und gebündelter Feed werden bei Offline-/Fehler-Fallbacks anhand von `generatedAt` verglichen; ein alter Gerätestand kann keinen neueren App-Stand mehr verdrängen.
- [x] Ein erfolgreicher, aber älterer Netzwerkstand wird ebenfalls nicht vor einen neueren validierten lokalen Stand gesetzt.
- [x] Automatisch importierte Prospektangebote bleiben flüchtig und werden beim Refresh nicht mehr als dauerhafte Nutzerangebote gespeichert; dadurch wächst der lokale OfferStore nicht mit jedem Abruf.
- [x] Der Status kennzeichnet auch einen veralteten Cache sichtbar als veraltet. Gültigkeitsfilter und die Trennung von aktuellen Angeboten und historischen Preisbeobachtungen bleiben unverändert.

## Update 14.10.2026 – Routen-Snapshot wiederverwenden

- RouteScreen cached jetzt die abgeleiteten Ergebnisse eines unveränderten Eingangs-Snapshots: Preisabdeckung, Preisnachweise, Mehrmarkt-Alternativen, Fahrzeit, Empfehlung und Straßenroute werden bei kleinen UI-Rebuilds wiederverwendet.
- Der Cache wird bei geänderten Listen-, Preis-, Angebots-, Mobilitäts-, Entfernungs- oder historischen Kaufdaten über die bestehende RouteOptimizer-Identität und Referenzen invalidiert.
- Die fachliche Optimierung und die bestehende Behandlung fehlender oder historischer Preise bleiben unverändert; der Block reduziert nur wiederholte Berechnungen im Routenreiter.

## Update 14.10.2026 – Preise-Snapshot-Signatur
- [x] Der Preise-Reiter merkt sich die Signatur seiner unveränderten Listen-, Marktpreis-, Angebots-, Historien- und Marktauswahl-Snapshots.
- [x] Wiederholte Shell-Rebuilds iterieren nicht mehr über alle Preis- und Verlaufseinträge, solange derselbe immutable Eingabestand und derselbe Tag gelten.
- [x] Bei einer Snapshot- oder Tagesänderung wird die bestehende vollständige Signaturberechnung ausgeführt; Quote-, Abdeckungs- und Vergleichscaches bleiben weiterhin gekoppelt.
## Update 14.10.2026 – Unveränderte Prospekt-Refreshes überspringen
- [x] Der Prospekt-Refresh bildet aus allen preis-, gültigkeits-, quellen-, filial- und coverrelevanten Feldern einen stabilen Fingerabdruck.
- [x] Bei identischem Feed werden Angebot-Normalisierung, OfferStore-Schreibvorgang und reguläre Preisbeobachtungs-Persistenz übersprungen; der sichtbare Cache-/Zeitstatus wird weiterhin aktualisiert.
- [x] Ein Backup-Import setzt den Fingerabdruck zurück, damit die regulären Prospektpreise danach erneut vollständig aus dem Feed aufgebaut werden.
- [x] Der Fingerabdruck umfasst auch `capturedAt`, Seitenbilder, Zoomnachweise und Keywords; Änderungen an Herkunft oder Beleg führen daher nicht zu einem unbemerkten Skip.
## Update 14.10.2026 – Alternative Prospekt-Coverfelder
- [x] Der validierte Prospektimport akzeptiert neben `pageSamples.image` auch die dokumentierten Varianten `imageUrl`, `thumbnailUrl` und `url` sowie alternative Zoom- und Keywordfelder.
- [x] Covermetadaten können aus `coverUrl`, `coverImage`, `imageUrl` oder `image` übernommen werden; jede URL wird weiterhin strikt auf HTTP(S) geprüft.
- [x] Die bestehende Reihenfolge, Seitendeduplizierung, Gültigkeitsprüfung und Quellenherkunft bleiben unverändert; ein fehlendes Bild bleibt ein fehlendes Bild.
- [x] Eine Fixture-Regression deckt alternative Feldnamen, Seitennummern, Zoomnachweis und Coverdarstellung ab.
## Update 14.10.2026 – Gemeinsame Preis- und Routensnapshots
- [x] Der App-Shell-Build verwendet den bestehenden Routing-Snapshot-Cache; Mengenänderungen und Änderungen an Preisen, Angeboten, Filialen, Mobilität, Entfernungsmatrix oder Gültigkeitsgrenze invalidieren ihn deterministisch.
- [x] Der Preise-Reiter löst Produkt×Markt-Quotes einmal pro Eingabestand auf und teilt den Snapshot zwischen Abdeckung, Hervorhebungen und Marktvergleich.
- [x] Die lokale Preisbeobachtung bewahrt reguläre Prospektpreise getrennt von Angebotspreisen; wiederholte Refreshes bleiben über stabile IDs dedupliziert.
- [x] PR-CI für alle drei Arbeitspakete war mit Analyse, vollständiger Testsuite und Web-Build grün; es wurden keine Laufzeit-Benchmarks behauptet.

## Update 14.10.2026 – Reguläre Prospektpreise erreichen Vergleich und Route
- [x] Aktuelle reguläre Prospektbeobachtungen werden als eigene Prospektquelle in die bestehende MarketPrice-Projektion übernommen.
- [x] Angebotspreise bleiben im OfferStore und werden nicht als reguläre Prospekt-MarketPrices dupliziert.
- [x] Preise-Reiter und Routenevidenz zeigen die Herkunft als Prospekt; KaufDA-Adaptermetadaten bleiben als konkrete Quellkennung erhalten.
- [x] Eine Fixture-Regression schützt die Projektion aktueller Normalpreise und den Ausschluss von Prospekt-Angebotspreisen.

## Update 14.10.2026 – Automatische Prospektpreise nur aus aktueller Periode
- [x] Der automatische Lernpfad filtert vor dem Speichern auf den am Aktualisierungstag gültigen Prospektzeitraum.
- [x] Historische und zukünftige Feedzeilen bleiben für Diagnose/Preisverlauf erhalten, werden aber nicht als aktueller automatischer Preis in die lokale Preisbeobachtung übernommen.
- [x] Reguläre, belegte Normalpreise behalten weiterhin Filiale, Packungsgröße, Quelle, Nachweis und Erfassungszeit; Angebotszeilen ohne Normalpreis bleiben ausschließlich im aktuellen Angebotspfad.

## Update 13.10.2026 – Angebote-Cover progressiv laden
- Das Coverraster im Angebote-Reiter baut zunächst höchstens zwölf Karten auf; weitere gültige Prospekte werden über „Weitere Prospekte laden“ nachgeladen.
- Dadurch werden große öffentliche Feeds nicht mehr als vollständig shrink-wrappedes Bildraster beim ersten Öffnen erzeugt. Die Coverseiten bleiben vollständig erreichbar und öffnen weiterhin denselben Detailviewer.
- Ein Widget-Test schützt die sichtbare Seitenbegrenzung und das Nachladen; Quellen-, Gültigkeits- und Filialdaten bleiben unverändert.

## Update 13.10.2026 – Prospekt-Cover ohne Plattform-Views im Scrollweg
- Coverkarten im Angebote- und Prospekte-Reiter erzwingen jetzt den Canvas-Renderer; Browser-Plattform-Views werden im Überblick nicht mehr pro Händlerbild erzeugt.
- Der vollständige Prospektviewer behält seinen expliziten Fallback für einzelne Bilder, damit die Coverübersicht stabil bleibt und der Detailpfad erreichbar bleibt.
- Ein Widget-Test schützt die Renderer-Entscheidung; Datenquellen, Gültigkeit und manuelle Artikelübernahme bleiben unverändert.

## Update 13.10.2026 – Shell-Routing pro Build wiederverwenden
- Dashboard, Einkaufsabschluss und Seitensammlung verwenden je Build denselben Routing-Snapshot mit einem aktuellen und einem regulären Optimizer.
- Die teure Preis-/Alternativenaufbereitung wird dadurch nicht mehrfach für identische Eingaben gestartet; Preisabdeckung, Filialschlüssel und Tie-Breaker bleiben unverändert.
- Der Snapshot lebt nur während des Builds und wird bei einer neuen Shell-Eingabe neu erzeugt.

## Update 13.10.2026 – Angebote-Reiter memoisiert Produktzuordnung
- Händler- und Kategoriegruppen behalten die konkrete Katalogauflösung je Angebotsdatensatz zwischen Such-/Expand-Rebuilds lokal im Widget.
- Ein negatives Ergebnis bleibt ebenfalls zwischengespeichert; unbekannte oder nicht belegte Artikel werden dadurch weder automatisch routenfähig noch anders zugeordnet.
- Der Cache wird bei einem neuen Katalogsnapshot verworfen und ändert keine Gültigkeits-, Filial- oder Nachweisprüfung.

## Update 13.10.2026 – Mehrere OCR-Vorschläge im Prospektviewer
- Erkennt die lokale Seitenprüfung mehrere plausible Preiszeilen, zeigt der Viewer eine Auswahl mit Preis- und Sicherheitsstufe.
- Erst die ausdrücklich gewählte Zeile wird in das bestehende Angebotsformular übernommen; Abbrechen verwirft den OCR-Vorschlag ohne Speicherung.
- Produktidentität, Gültigkeit und Routenfähigkeit bleiben hinter dem bestehenden manuellen Review.

## Update 13.10.2026 – Bild-only-Prospektseiten mit lokalem OCR-Review
- Der Prospektviewer kann eine öffentliche Bildseite lokal auf explizite Preiszeilen prüfen und daraus unverbindliche Produktvorschläge mit hoher, mittlerer oder niedriger Sicherheit erzeugen.
- Jeder Vorschlag wird im bestehenden Seitenformular vorbefüllt, aber erst nach sichtbarer Nutzerprüfung als manuelles Angebot gespeichert; OCR bestätigt weder Produktidentität noch Preis automatisch.
- Web/macOS/Linux bleiben bei fehlender lokaler OCR-Unterstützung im verständlichen manuellen Pfad; Roh-OCR-Texte werden nicht gespeichert.

## Update 13.10.2026 – Prospekt-Feednormalisierung pro Ansicht memoisiert
- Die Prospektübersicht cached aktuelle Datensätze, Kategorien, Filialkarten und Gültigkeitsauswahl, solange sich der Feed-Snapshot nicht ändert.
- Suche, Filter und Favoritenwechsel berechnen dadurch nur noch ihre tatsächlich veränderte Ansicht; Quellen-, Filial- und Gültigkeitsregeln bleiben unverändert.
- Der Cache ist rein lokal pro Widget und führt keine zusätzliche Datenquelle oder Persistenz ein.

## Update 13.10.2026 – Prospekt-Produktzuordnung beim Scrollen memoisiert
- Suchergebnisse und Prospektseiten lösen die konkrete Produktidentität pro Angebotsdatensatz höchstens einmal je sichtbarem Delegaten auf.
- Positive und negative Identitätsentscheidungen bleiben zwischengespeichert; die bestehende konservative Zuordnungslogik, Filialprovenienz und Übernahmeprüfung ändern sich nicht.
- Dadurch sinkt die Arbeit beim schnellen Scrollen durch große Angebotslisten, ohne zusätzliche Datenquelle oder Abhängigkeit.

## Update 13.10.2026 – Prospektfeed zeigt lokalen Stand sofort
- Der Shell-Start lädt einen validierten Cache-/Bundle-Stand ohne Netzwerk vor.
- Danach läuft der öffentliche Feed wie bisher als normaler Refresh und ersetzt den lokalen Stand nur bei erfolgreicher Prüfung.
- Manuelles Aktualisieren überspringt den Vorab-Cache; Gültigkeit, Quellenstatus, Filialbezug und Angebotsnachweise bleiben unverändert.

## Update 13.10.2026 – Routenberechnung ohne wiederholte Arbeit
- Der Routenoptimierer memoisiert Alternativen, Einzelmarkt- und Empfohlenen-Plan pro unverändertem Eingabesnapshot.
- Der Preisresolver verwendet eine lokale Quote-Zwischenspeicherung je exakter Filiale, Produktvariante und Menge; unbekannte Preise bleiben dabei weiterhin unbekannt.
- Damit werden wiederholte UI-Neuberechnungen im Routen- und Preise-Reiter deutlich kürzer, ohne Quellenpriorität, Gültigkeit oder Tie-Breaker zu verändern.

## Update 13.10.2026 – Preis-Reiter zeigt den vollständigen Marktvergleich
- Der Preise-Reiter enthält jetzt pro Einkaufslistenposition eine aufklappbare
  Markt-Matrix für alle aktivierten Filialen.
- Aktuelle Preise, historische Hinweise und unbekannte Märkte werden je
  Händler getrennt dargestellt; fehlende Belege bleiben unbekannt und werden
  nicht als 0 € gerechnet.
- Packungsbasis, Grundpreis, Quelle und Preisalter bleiben in derselben
  Anzeige nachvollziehbar. Eine Widget-Regression schützt den Öffnen-/Scrollpfad.

## Update 13.10.2026 – Abgelaufene Prospektcover bleiben aus der aktuellen Anzeige
- Die sichtbare Prospektkarte übernimmt Seiten und Cover jetzt ausschließlich aus
  einem aktuell gültigen Zeitraum.
- Abgelaufene oder zeitlich unbekannte Seiten bleiben als veraltete Evidenz nicht
  in der aktuellen Coveransicht; die Karte zeigt stattdessen den verständlichen
  Hinweis „Keine aktuell gültigen Angebotsdaten geladen“ und behält den offiziellen
  Händlerlink sowie den Filialkontext.
- Eine Widget-Regression schützt diesen Filter, während aktuelle Coverseiten und
  der manuelle Artikelübernahmepfad unverändert bleiben.

## Update 13.10.2026 – Angebote-Reiter mit begrenztem Renderdruck
- Der Angebote-Reiter begrenzt den äußeren Scrollvorlauf auf den sichtbaren Bereich.
- Beim Öffnen einer Händler-/Kategoriegruppe wird die konkrete Produktzuordnung pro Datensatz nur einmal berechnet; die bisherige Nachweis- und Listenlogik bleibt unverändert.
- Ein Widget-Test schützt den Cache-Rahmen, damit spätere UI-Erweiterungen den Renderdruck nicht unbemerkt erhöhen.

## Update 13.10.2026 – Prospektviewer beschleunigt
- Der eingebettete Prospektviewer begrenzt den Scrollvorlauf jetzt explizit auf den sichtbaren Bereich. Dadurch werden beim schnellen Wischen keine zusätzlichen Seitenkarten und Netzwerkbilder vorab aufgebaut.
- Die bestehende Canvas-first-Bildstrategie, begrenzte Decode-Größen und der verzögerte HTML-Fallback bleiben unverändert; die Änderung reduziert nur den Speicher- und Decode-Druck im langen Seitenviewer.
- Der Widget-Test prüft den Viewer-Schlüssel und den gesetzten Scroll-Cache-Rahmen; die fachliche Angebots- und Filiallogik bleibt unverändert.

## Update 13.10.2026 – Vertrauensstufen im Bon-/OCR-Review

- Bonpositionen zeigen im Review jetzt die vier nachvollziehbaren Stufen **BELEGT**, **WAHRSCHEINLICH**, **UNSICHER** und **MANUELL_BESTÄTIGT**.
- Die Stufe wird aus dem vorhandenen Beleg- und Identitätsstatus abgeleitet; sie ändert kein gespeichertes Preisformat und macht einen Preis nicht allein durch das Badge routenfähig.
- Tooltips erklären die Stufe. Ein Widget-/Fachtest deckt Mapping, Legacy-Kompatibilität und die sichtbaren Labels ab.

## Update 13.10.2026 – Einkaufslisten- und Startplanung sichtbar abgeschlossen

- Die Einkaufsliste zeigt oberhalb der Positionen jetzt die aktuelle Preisabdeckung mit getrennten Zählungen für aktuelle, historische und unbekannte Werte.
- Der angezeigte Warenkorbwert summiert ausschließlich aktuelle, routenfähige Preisbelege; historische Orientierung und fehlende Preise werden nicht als 0 € eingerechnet.
- Der Start-Reiter zeigt den bereits berechneten Routenplan mit Händlerreihenfolge, Mobilität, Fahrtzeit, bestätigter Monatserparnis und Budgetprognose. Der Statusblock öffnet direkt die Route.
- Die Änderungen sind in PR #309 und PR #310 enthalten. Für Merge-SHA 9a7025cf7087b7c454c35820668df34bd335da8d waren Flutter CI 38437423865 und Release artifacts 38437424141 erfolgreich; Web-Deployment und Android-APK wurden erstellt.

# SparzamApp

## Update 13.10.2026 – Coverkarten im Angebote-Reiter
- Der Angebote-Reiter zeigt aktuelle, nach Gültigkeit gefilterte Prospekte jetzt
  als Coverkarten mit Favoritenrail und Raster.
- Ein Cover öffnet direkt den eingebetteten Seitenviewer; Marktfilter,
  Filialkontext und bestehende Artikelübernahme bleiben im selben Datenpfad.
- Die neue Ansicht nutzt begrenzte Bilddekodierung und Repaint-Grenzen, damit
  die Übersicht auch bei mehreren Händlern leichtgewichtig bleibt.


## Update 13.10.2026 – Händlerkürzel im Bonparser
- Der Bonparser erkennt ALDI Süd/ALDI SUED, PENNY und REWE mit Token-Grenzen.
- Ein generisches ALDI bleibt als unbestimmte Händlerangabe sichtbar und wird keiner ALDI-Region zugeordnet.
- EDEKA wird vor einem möglichen Netto-Steuertext erkannt.

## Update 13.10.2026 – Preisalter und Preisverlauf
- Preisdetails zeigen neben Quelle und Vergleichbarkeit jetzt das Alter der Preisbeobachtung.
- Erfassungszeitpunkte von Angeboten werden übernommen; fehlt ein Zeitpunkt, bleibt das Alter als unbekannt gekennzeichnet.
- Historische Bon- und Prospektwerte bleiben als historische Orientierung getrennt.

## Update 13.10.2026 – Empfohlene Route auf kleinen Ansichten
- Die Routen-Zusammenfassung zeigt ein sichtbares Kennzeichen „Empfohlene Route“.
- Bei fehlenden Preisbelegen wird stattdessen „Vorläufige Empfehlung“ angezeigt; dadurch bleibt die Teilroute klar von einem vollständigen Einkaufsplan getrennt.
- Ein Widgettest deckt beide Zustände ab.


## Update 13.10.2026 – Vergleichbarkeit in der Preis-Matrix
- Jede sichtbare Preiszeile kennzeichnet jetzt, ob eine explizite Packungsbasis vorliegt oder die Mengenbasis der Quelle nicht dokumentiert ist.
- Die Kennzeichnung ergänzt Quelle, Beobachtungs-/Gültigkeitsstand, Packungsgröße, Grundpreis und Ersparnis; sie ändert keine Preiswahl und erzeugt keinen fehlenden Preis.
- Fach- und Widgettests decken explizite 500-g-Basis sowie Legacy-Preise ohne Mengenbasis ab.


## Update 13.10.2026 – Angebotssparpotenzial in der Routenübersicht
- Die Routenübersicht zeigt jetzt die belegte Ersparnis aktiver Angebote, die für die konkrete Filiale, Variante, Menge und den aktuellen Gültigkeitszeitraum ausgewählt wurden.
- Abgelaufene, unbestätigte oder nicht zur Filiale passende Angebote fließen über den bestehenden RoutePriceResolver nicht in diese Anzeige ein.
- Bei einer Teilroute wird die Summe ausdrücklich als „belegte Angebotsersparnis“ gekennzeichnet; die Anzeige behauptet keine Ersparnis für fehlende Positionen.
- Fach- und Widgettests decken Mengenmultiplikatoren, abgelaufene Angebote und die sichtbare Zusammenfassung ab.


## Update 13.10.2026 – Prospektseiten beim Scrollen entlasten
- Der Seitenviewer rendert Vorschaubilder zuerst im günstigen Canvas-Pfad und erzeugt einen HTML-Plattform-Fallback erst nach einem tatsächlichen Decode-/CORS-Fehler.
- Dadurch werden beim langen Prospekt-Scrollen nicht vorsorglich für jede Seite Plattform-Views angelegt; die begrenzte 720×480-Dekodierung und die externe Großansicht bleiben erhalten.
- Eine Widgetregression prüft, dass lange Seitenlisten lazy aufgebaut und bis zur letzten Seite weiter bedienbar sind.
## Update 13.10.2026 – Packungs- und Grundpreis in der Einkaufslistenmatrix
- Aktuelle Marktpreise und Angebote behalten ihre belegte Packungsmenge und Einheit jetzt auch in der Einkaufslisten-Preismatrix.
- Die Preiszeile zeigt den normalisierten Grundpreis, sofern die Quelle eine gültige Mengenbasis liefert; fehlende Mengen bleiben unbekannt.
- Die Detailansicht kennzeichnet die Packung zusätzlich. Produktidentität, Angebotsgültigkeit und Routenpreislogik bleiben unverändert.
- Fach- und Widgetregressionen prüfen 500 g gegen 4,98 €/kg und den Interaktionspfad im Preisfenster.
## Update 13.10.2026 – Open-Prices-Dubletten deterministisch auflösen
- Mehrere gültige Beobachtungen derselben Filiale mit identischem Zeitstempel
  werden über die stabile Open-Prices-ID ausgewählt; die Antwortreihenfolge
  entscheidet nicht mehr zufällig über den Planungswert.
- Eine Regression deckt zwei gleich datierte Beobachtungen mit unterschiedlichem
  Preis ab. Ältere Zeitstempel, Veraltung und Quellenfilter bleiben unverändert.

## Update 13.10.2026 – Open-Prices-Filialkontext gegen widersprüchliche Quelldaten geschützt
- Liefert Open Prices eine konfigurierte Filial-ID, wird der Datensatz zusätzlich
  gegen Stadt, Postleitzahl und ein ausdrücklich erkanntes Händlerlabel geprüft.
- Widersprüchliche Kontextdaten werden verworfen, statt den Preis trotz passender
  ID dem falschen Markt zuzuordnen. Unbekannte Provider-IDs bleiben beim bereits
  vorhandenen konservativen Stadt-/Händler-Fallback.
- Zwei Regressionen decken eine falsche Stadt und einen falschen Händler bei
  identischer Filial-ID ab; Preisquelle, Cache und Veraltung bleiben unverändert.

## Update 13.10.2026 – Prospektseiten trotz CDN-CORS sichtbar
- Verifizierte Prospektseiten verwenden im Viewer weiterhin die begrenzte
  Vorschaugröße 720×480, dürfen bei fehlenden Canvas-CORS-Headern aber auf den
  Browser-Fallback wechseln.
- Dadurch bleiben Coverkarten und die eigentlichen Prospektseiten sichtbar;
  ein leerer Bildhalter wird nicht mehr als erfolgreiche Seitenanzeige gezeigt.
- Der vorhandene Seiten-/Scrolltest bleibt aktiv; der Web-Sichttest deckt das
  Nachladen von Cover und Seite gegen den veröffentlichten Prospektstand ab.

## Update 13.10.2026 – CDN-Cover bleiben in Karten sichtbar
- Prospektkarten verwenden für genau ein Cover je Markt den begrenzten
  Browser-Fallback, wenn ein Händler-CDN keine Canvas-CORS-Freigabe liefert.
- Der große Seitenviewer bleibt Canvas-only mit begrenzter Dekodiergröße; die
  Änderung erzeugt keine Plattformansicht pro Prospektseite.
- Eine Widgetregression schützt die Fallback-Renderstrategie für
  Cross-Origin-Cover.

## Update 13.10.2026 – Widersprüchliche Bon-Aliase bleiben im Review
- Treffen mehrere ausreichend bestätigte Produkt-IDs auf dieselbe Händler- und
  Bonbezeichnung, liefert der Alias-Store keine automatische Produktidentität.
- Eindeutige Treffer werden bei gleichem Preis-/Bestätigungsstand weiterhin
  deterministisch nach Bestätigungszahl und Aktualität gewählt.
- Damit können alte, widersprüchliche Aliasbestände weder eine falsche Variante
  vortäuschen noch spätere Preisbeobachtungen an das falsche Produkt binden.
- Eine Regression deckt den Legacy-Fall mit zwei bestätigten Produkt-IDs ab.

## Update 13.10.2026 – Prospektangebote behalten Packungs- und Grundpreisbasis
- Der öffentliche Prospekt-Refresh leitet aus einer ausdrücklich im Händlerlabel
  enthaltenen Packungsangabe jetzt `packageSize` und den normalisierten
  `priceByBaseUnit` ab. Einzel-, Mehrfach- und Zählpackungen werden dabei auf
  die Gesamtmenge der Packung bezogen.
- Variable Angaben wie `160 g – 175 g` oder `114/110/105 g` bleiben ohne
  Packungs- und Grundpreisbehauptung. Dadurch wird keine beliebige Variante als
  Vergleichsbasis gewählt.
- Die Metadaten laufen unverändert durch Feedparser, Angebotsdetail,
  Preisbeobachtung und Routenvergleich; bestehende Quellenwerte werden nicht
  überschrieben.
- `tool/tests/test_refresh_prospects.py` deckt Einzelpackung, Mehrfachpackung
  und beide unsicheren Bereichsformen ab. Der versionierte Feed enthält aktuell
  677 gültige Angebote, davon 283 mit sicherer Packungs- und Grundpreisbasis.

## Update 13.10.2026 – KaufDA-Umgebungsgrenze kann Abrufe hart stoppen
- `SPARZAM_KAUFDA_MAX_QUERIES=0` wird jetzt als absichtliche Nullgrenze
  übernommen und nicht mehr auf den Standardwert zurückgesetzt.
- Damit bleibt der optionale KaufDA-Adapter auch in kontrollierten Refresh-
  Umgebungen ohne Netzwerkabruf deaktivierbar; eine positive Query-Liste oder
  das Feature-Flag allein aktiviert weiterhin keinen Abruf ohne `enabled`.

## Update 13.10.2026 – Refresh respektiert HTTP-Zugriffsgrenzen
- Der gemeinsame öffentliche Prospekt-HTTP-Helper wiederholt einen HTTP-403
  nicht mehr mit einem Browser-User-Agent. Ein solcher Status bleibt ein
  Quellenfehler und aktiviert nur die vorhandenen Cache-/Asset-Fallbacks.
- Eine Python-Regression prüft, dass genau ein Abruf erfolgt und keine
  alternative Identität versucht wird.
- Der offizielle GitHub-Refresh setzt `SPARZAM_KAUFDA_ENABLED=0` explizit,
  sodass eine spätere Umgebungsänderung die optionale Quelle nicht unbemerkt
  produktiv aktiviert.

## Update 13.10.2026 – KaufDA-Parserfehler überschreiben keinen gültigen Cache
- Der optionale KaufDA-Adapter speichert einen Liveantwort-Body erst nach
  erfolgreichem `__NEXT_DATA__`-Parsing. Antwortformatänderungen bei HTTP 200
  können dadurch keinen geprüften Cache zerstören.
- Schlägt das Parsing live fehl, wird ein noch gültiger vorheriger Cache
  erneut versucht. Das Angebot behält dabei seinen echten ursprünglichen
  `capturedAt`-Zeitpunkt und die Formatstörung bleibt in der Quelldiagnose
  sichtbar.

## Update 13.10.2026 – Versionierter Prospektfeed ist je Filiale prüfbar
- Die sechs ausgelieferten Händlerquellen im versionierten Feed werden jetzt in
  einer Python-Regression gemeinsam geprüft. Jede Quelle muss einen aktuellen
  Gültigkeitszeitraum, Filial-ID/Ort/Adresse sowie eine HTTPS-Coverseite als
  Seite 1 liefern.
- Eine Flutter-Regression prüft dieselben Invarianten nach dem Parsen in
  `ProspectIssue`, damit der Importpfad Coverseiten oder Filialnachweise nicht
  still verliert.
- Damit bleibt die Prospektansicht gegen einen stillen Verlust von Coverseiten,
  Filialbezug oder veralteten Datensätzen geschützt; die Prüfung verwendet den
  im Asset gespeicherten `generatedAt`-Tag und führt keine Live-Händlerabfrage
  aus.

## Update 13.10.2026 – Prospekt-Sliver halten keine entfernten Karten fest
- Die Cover-, Suchergebnis-, Seiten- und Artikel-Sliver deaktivieren nicht
  benötigte automatische Keep-Alive-Wrapper. Repaint-Grenzen bleiben aktiv,
  damit große Händlerbestände weiter lazy aufgebaut und getrennt neu gezeichnet
  werden.
- Die Daten, Seitenreihenfolge und Add-to-List-Aktionen bleiben unverändert;
  die Änderung reduziert nur den Speicher- und Renderdruck beim Scrollen.

## Update 13.10.2026 – Gleichzeitige Prospekt-Refreshes werden gebündelt
- `ProspectFeedService` teilt eine bereits laufende `load()`-Future mit allen
  weiteren Aufrufern. Startup, AppShell und manuelles Aktualisieren erzeugen
  dadurch keine doppelten öffentlichen Feed-Anfragen.
- Erfolgs-, Cache- und Asset-Fallback sowie Fehlerweitergabe bleiben
  unverändert. Eine Regression prüft identische Futures und genau eine Anfrage.

## Update 13.10.2026 – Externe Fallback-Caches behalten ihre Reihenfolge
- Die Shared-Preferences-Adapter für Open Prices, Open Food Facts und den
  öffentlichen Prospektfeed serialisieren Reads und Writes jetzt je Cachetyp.
  Ein paralleler Refresh kann dadurch keinen älteren Rohantwort- oder
  Prospektstand nach einem frischeren Cachewert speichern.
- Cachefehler bleiben weiterhin best effort: Der Livepfad wird nicht blockiert,
  Barcode-Normalisierung und der datierte Offline-Fallback bleiben unverändert.
  Read-after-write-Regressionen decken Produkt- und Prospektcache ab.

## Update 13.10.2026 – Prospektfavoriten bleiben bei schnellen Umschaltungen konsistent
- `ProspectFavoritesStore` serialisiert Reads und Writes jetzt über denselben
  fehlerisolierten Scheduler. Schnelle Herz-Umschaltungen können dadurch
  keinen älteren Favoritenstand zurückschreiben.
- Sortierung, Dublettenbereinigung und der `null`-Fallback bei nicht
  verfügbarer Plattformpersistenz bleiben unverändert. Eine Regression prüft
  Read-after-write über getrennte Storeinstanzen.

## Update 13.10.2026 – Diagnoseeinträge bleiben bei parallelen Fehlern erhalten
- `DiagnosticLogService` serialisiert Reads, Einträge und Löschen jetzt über
  denselben fehlerisolierten Scheduler. Gleichzeitige Feed-, OCR- oder
  Speicherfehler können dadurch keinen Diagnoseeintrag durch einen älteren
  Read-Modify-Write-Stand verlieren.
- Das Fehlerprotokoll bleibt lokal, auf 100 Einträge begrenzt und darf den
  eigentlichen Fehler weiterhin nicht verschärfen. Eine Regression prüft zwei
  parallele Einträge.

## Update 13.10.2026 – Routen- und Preisquelleneinstellungen lesen konsistent aus der Queue
- `MobilitySettingsStore` und `PriceDataSettingsStore` serialisieren Reads und
  Writes jetzt je Storetyp über denselben fehlerisolierten Scheduler. Ein
  Einstellungswechsel kann dadurch nicht zwischen Start- oder Backup-Lesen
  verloren gehen.
- Mobilitätsmodus, Marktaufwand, Preisquellen-Schalter und konservative
  Standardwerte bleiben unverändert. Beide Store-Suites prüfen Read-after-write
  über getrennte Instanzen.

## Update 13.10.2026 – Budgetstände lesen konsistent aus der Queue
- `BudgetStore` serialisiert die drei Budgetfelder gemeinsam mit öffentlichen
  Reads und Writes. Ein Einkaufsabschluss oder eine Korrektur kann dadurch
  keinen gemischten Zwischenstand aus Monatsbudget, Lebensmittelbudget und
  Ausgaben in die Oberfläche zurückliefern.
- Die bestehende Nichtnegativ-/Endlichkeitsprüfung und der sichere Nullfallback
  bleiben erhalten. Eine Regression prüft Read-after-write über getrennte
  Storeinstanzen.

## Update 13.10.2026 – Eigener Produktkatalog liest konsistent aus der Queue
- `ProductCatalogStore` serialisiert öffentliche Reads, Ersetzungen und
  Read-Modify-Write-Aktionen jetzt über denselben fehlerisolierten Scheduler.
  Ein Scanner-/Open-Food-Facts-Import kann dadurch keinen älteren Katalogstand
  zwischen Persistenz und UI-Projektion zurückschreiben.
- EAN, Varianten, Aliase, Favoriten und die alphabetische Sortierung bleiben
  unverändert. Eine Regression prüft Read-after-write über getrennte
  Storeinstanzen.

## Update 13.10.2026 – Angebotsimports lesen konsistent aus der Queue
- `OfferStore` serialisiert öffentliche Reads, Ersetzungen und Upserts jetzt
  über denselben fehlerisolierten Scheduler. Ein paralleler Prospekt- oder
  KaufDA-Import kann dadurch keinen älteren Angebotsstand zwischen Persistenz
  und UI-Projektion zurückschreiben.
- Demo-Bereinigung, ID-Ersetzung und bestehende Quellen-/Nachweisfelder
  bleiben unverändert. Eine Regression prüft Read-after-write über getrennte
  Storeinstanzen mit einem KaufDA-Nachweis.

## Update 13.10.2026 – Kaufhistorie und Wiederkäufe lesen konsistent aus der Queue
- `PurchaseStore` und `RecentPurchaseStore` serialisieren öffentliche Reads,
  Ersetzungen und Read-Modify-Write-Aktionen jetzt je Storetyp über denselben
  fehlerisolierten Scheduler. Ein paralleler UI-Read kann dadurch keinen
  älteren Kaufstand zwischen einem laufenden Write und dessen Projektion sehen.
- Die bestehende ID-Zusammenführung, Chronologie und Begrenzung der letzten
  30 Wiederkäufe bleiben erhalten. Regressionen prüfen Read-after-write über
  getrennte Storeinstanzen.

## Update 13.10.2026 – Preisverlauf und Marktpreise lesen konsistent aus der Queue
- `PriceHistoryStore` und `MarketPriceStore` serialisieren öffentliche Reads,
  Ersetzungen und Upserts jetzt über denselben fehlerisolierten Scheduler je
  Storetyp. Ein verspäteter Read kann dadurch keinen älteren Zwischenstand
  zwischen einem laufenden Preis-Write und dessen UI-Projektion liefern.
- Der bestehende Demo-Historie-Fallback, die Branch-Slots und die Quellpriorität
  bleiben unverändert. Zwei Store-Regressionen prüfen Read-after-write über
  getrennte Storeinstanzen.

## Update 13.10.2026 – Zusätzlicher Marktaufwand fließt transparent in die Routenwahl
- Die Mobilitätseinstellungen bieten jetzt einen optionalen Kostenwert je Markt
  nach dem ersten. Der Wert wird lokal gespeichert und mit endlichen Werten
  zwischen 0 und 50 € validiert.
- `RouteOptimizer` verwendet ihn ausschließlich im `planningScore`; Warenkorb-
  und Fahrtkosten bleiben der erwartete Zahlbetrag. Mindestvorteil, Preisabdeckung
  und maximale Marktanzahl bleiben eigenständige Kriterien.
- Routenkarte, Alternativen und Empfehlungstext weisen den Marktaufwand separat
  aus. Regressionen prüfen Persistenz, ungültige Werte, Auswahl eines Einzelmarkts
  bei zusätzlichem Aufwand und die sichtbare Planungswert-Aufschlüsselung.

## Update 13.10.2026 – Lokale Reads und Writes werden gemeinsam serialisiert
- Preisbeobachtungen, Bonbeobachtungen, gelernte Bon-Aliase, Straßenentfernungen,
  Routenmatrizen und Einkaufslisten verwenden jetzt denselben generischen
  Operation-Scheduler je Store. Ein öffentlicher Read wird selbst eingereiht
  und kann keinen veralteten Zwischenstand zwischen zwei lokalen Writes sehen.
- Der Scheduler gibt Fehler weiterhin an den auslösenden Aufrufer weiter,
  hält aber nachfolgende lokale Operationen ausführbar.
- `sequential_write_queue_test.dart` schützt zusätzlich die Reihenfolge eines
  typisierten Reads hinter einem laufenden Write.

## Update 13.10.2026 – Gleichwertige Marktpreise werden deterministisch gewählt
- Planung und `RoutePriceResolver` verwenden bei identischem qualitätsbereinigtem
  Preis und identischem Beobachtungszeitpunkt dieselbe stabile Tie-Break-Regel.
- Quellenart, Adapter, Filiale und Nachweisfelder entscheiden nur diesen exakten
  Gleichstand; ältere, veraltete oder nicht nutzbare Preise werden weiterhin vor
  der Auswahl verworfen.
- `planning_market_prices_test.dart` schützt Planung und Routenquote gegen beide
  Eingabereihenfolgen.
- Die Bon-Familienprojektion verwendet dieselbe Regel, bevor sie je Markt einen
  Kandidaten an die zentrale Planung weiterreicht.

## Update 13.10.2026 – KaufDA-Cache bleibt bei Schreibabbruch lesbar
- Der optionale KaufDA-Cache schreibt neue JSON-Dokumente zuerst in eine
  temporäre Datei und ersetzt den Zielbestand erst nach vollständigem Schreiben.
- Bei einem simulierten Ersetzungsfehler bleibt der bisherige Offline-Stand
  unverändert und lesbar; temporäre Dateien werden aufgeräumt.
- Ein beschädigtes Cache-Root-Dokument wird als Cache-Miss behandelt und kann
  den optionalen Refresh nicht mehr aus dem isolierten Fehlerpfad werfen.
- Eine direkte Konfiguration mit `max_queries=0` führt jetzt garantiert zu
  keinem Abruf.
- Direkt gesetzte Filialmappings werden dabei über dieselben kanonischen
  Händlernamen aufgelöst wie die kontrollierte Umgebungs-Konfiguration.

## Update 13.10.2026 – Gleiche Marktpreise vergeben den Artikel stabil
- `RouteOptimizer.buildPlan` verwendet bei gleichem qualitätsbereinigtem
  Artikelpreis jetzt einen stabilen Schlüssel aus Händler, Filiale, Ort und
  Adresse. Die Zuweisung hängt damit nicht mehr von der Eingabereihenfolge der
  Stores ab.
- `route_multi_market_e2e_test.dart` prüft beide Reihenfolgen.
- Gleich günstige aktive Angebote verwenden zusätzlich einen stabilen
  Evidenz-Tie-Breaker, damit ihre Quelle nicht von der Feed-Reihenfolge abhängt.

## Update 13.10.2026 – Verzögerte Listen-Reads überschreiben keine Nutzereingabe
- Der Start-Read benannter Einkaufslisten merkt sich jetzt eine eigene
  Mutationsrevision. Sobald der Nutzer die sichtbare Liste ändert, darf ein
  später eintreffender alter Speicherstand weder UI noch Persistenz ersetzen.
- Ein Widgettest simuliert den verzögerten Read mit einem veralteten Listenstand.
- `ShoppingListStore` serialisiert jetzt zusätzlich seine direkten lokalen
  Reads/Writes über alle Store-Instanzen; ungültige gespeicherte Mengen werden
  beim Laden verworfen.

## Update 13.10.2026 – Datenabdeckung zählt Cover-Fallbacks korrekt
- Die Prospektabdeckung zählt ein validiertes `thumbnailUrl` ohne weitere
  Seiten jetzt als eine sichtbare Bildseite, genau wie der Viewer.
- Ungültige oder nicht unterstützte URL-Schemata bleiben bei null; die Anzeige
  erzeugt keine zusätzliche Bildquelle.
- `prospect_feed_status_test.dart` schützt beide Fälle.

## Update 13.10.2026 – Bildreicher aktueller Prospekt gewinnt deterministisch
- Liefern mehrere aktuell gültige Datensätze eines Händlers denselben Zeitraum,
  wählt die Prospektansicht jetzt den belastbarsten Eintrag mit vorhandenen
  Seiten, Cover und stabilen Metadaten statt blind den ersten Feed-Eintrag.
- Abgelaufene Zeiträume bleiben aus der Auswahl ausgeschlossen; der
  Fallbacksortierer bleibt bei gleicher Evidenz reproduzierbar.
- `prospects_screen_test.dart` schützt den Fall eines metadata-only Eintrags
  neben einem aktuellen Eintrag mit Coverseite.

## Update 13.10.2026 – Prospektseiten werden deterministisch normalisiert
- Der Feedparser verwirft Seitenproben ohne positive Seitennummer, dedupliziert
  wiederholte Seitennummern und sortiert die verbleibenden Seiten vor Viewer und
  Cover-Fallback.
- Die erste valide Quelle gewinnt bei einer doppelten Seitennummer; Bilder und
  Nachweise werden nicht aus anderen Datensätzen ergänzt.
- `prospect_feed_service_test.dart` schützt Reihenfolge, Deduplizierung und die
  bestehende Invalid-URL-Grenze.

## Update 13.10.2026 – Legacy-Prospekte behalten ihr erstes Cover
- Der Feedparser verwendet bei älteren Prospectformaten ohne eigenes
  `thumbnailUrl` das erste bereits validierte `pageSamples`-Bild als Cover.
- Dadurch bleiben vorhandene Händlerseiten im Karten- und Viewerpfad sichtbar;
  unzulässige oder fehlende URLs werden weiterhin nicht erfunden.
- `prospect_feed_service_test.dart` schützt den Fallback einschließlich der
  bestehenden HTTP-Validierung.

## Update 13.10.2026 – Zukünftige Preisbeobachtungen erreichen keine Marktpreisprojektion
- `marketPricesFromObservations` verwirft Beobachtungen jetzt bereits vor der
  `MarketPrice`-Projektion, wenn ihr `observedAt` nach dem Prüfdatum liegt.
- Damit können falsch datierte oder manipulierte Zukunftsbelege nicht mehr
  zuerst im gespeicherten Preisbestand erscheinen und erst später an der
  Routenauflösung scheitern.
- Die Regression steht in `price_observation_store_test.dart`; bestehende
  Gültigkeits- und Altersgrenzen bleiben unverändert.

## Update 13.10.2026 – Prospekt- und Listenpfad im veröffentlichten Webstand geprüft
- GETESTET: Ein Lidl-Prospekt öffnet mit fünf Seiten und sichtbaren Coverbildern;
  der Seiten-Scroll blieb stabil und die Browser-Konsole meldete keine Warnungen
  oder Fehler.
- GETESTET: „Artikel von Seite hinzufügen“ öffnet den Prüfdialog, verlangt einen
  gültigen Angebotspreis und bestätigt die Übernahme anschließend in der
  Einkaufsliste. Der Testeintrag blieb auf der temporären Prüfsitzung und wird
  nicht als Fixture oder Produktionsdaten übernommen.
- Der Test deckt den veröffentlichten Webstand ab; ein nativer iOS-/Android-
  Gerätestest bleibt wegen des fehlenden lokalen Flutter-SDKs offen.

## Update 13.10.2026 – KaufDA ergänzt offizielle Prospektzeiträume nicht ersetzend
- Der gemeinsame Prospektfilter bewertet pro Händler zuerst, ob ein Zeitraum
  mindestens einen nicht-KaufDA-Nachweis besitzt. Ein größerer optionaler
  KaufDA-Trefferbestand kann damit den offiziellen Zeitraum nicht verdrängen;
  KaufDA-Angebote dürfen den ausgewählten offiziellen Zeitraum weiterhin
  ergänzen.
- `tool/tests/test_refresh_prospects.py` schützt den Fall mit einem offiziellen
  Lidl-Record und drei Treffern aus einem abweichenden KaufDA-Zeitraum.

## Update 13.10.2026 – Fehlende Marktpreise bleiben unbekannt
- Die README beschreibt jetzt den tatsächlichen Resolver-Vertrag: Fehlt eine
  belastbare markt- und variantenspezifische Beobachtung, bleibt die
  Routenquote aus. Kategorie-Gruppenpreise werden nicht synthetisch erzeugt.
- Historische Bon-/Prospekthinweise bleiben als Orientierung sichtbar, werden
  aber weder als bestätigte Ladenpreise noch als aktuelle Routenpreise geführt.

## Update 13.10.2026 – Zukünftige Prospektbelege bleiben historisch unsichtbar
- Die historische Prospektstatistik prüft neben dem abgelaufenen
  Gültigkeitsende nun auch den taggenauen Erfassungstag. Ein zukünftiger
  `observedAt`-Wert kann dadurch keine historische Preisorientierung erzeugen.
- Die Zukunftsgrenze entspricht der zentralen Preisprojektion; eine Regression
  in `prospect_price_statistics_test.dart` deckt den Fall ab.

## Update 13.10.2026 – Zukünftige Bons bleiben aus Preisstatistiken ausgeschlossen
- Die lokale Bon-Preisstatistik verwirft Beobachtungen nach dem Prüfzeitpunkt
  jetzt bereits vor der Gruppierung. Ein falsch datierter oder importierter
  zukünftiger Bon kann dadurch weder Median noch letzten Historienpreis
  beeinflussen.
- Das Verhalten entspricht der bestehenden Route-Projektion und ist durch
  eine Regression in `receipt_price_statistics_test.dart` abgesichert.

## Update 13.10.2026 – Offline-Strecken akzeptieren normalisierte Startadressen
- Distanz- und Straßenmatrixcache verwenden jetzt dieselbe normalisierte
  Startadresse beim Schlüssel und bei der Inhaltsprüfung.
- Groß-/Kleinschreibung und überflüssiger Leerraum führen dadurch nicht mehr
  zu einem unnötigen Cache-Miss; unterschiedliche Startorte bleiben getrennt.
- Beide Store-Regressionen decken den Offline-Fallback ab.

## Update 13.10.2026 – Lokale Startdaten werden parallel geladen
- Die voneinander unabhängigen Speicher-Reads aus `main.dart` starten jetzt
  gemeinsam und werden weiterhin vollständig abgewartet, bevor der erste
  App-Snapshot an `SparzamApp` übergeben wird.
- Dadurch wird ein langsamer lokaler Speicherzugriff nicht mehr durch zehn
  nachfolgende Reads vervielfacht; Datenreihenfolge und Persistenzschlüssel
  bleiben unverändert.

## Update 13.10.2026 – KaufDA-Branchnachweise bewahren die Filialadresse
- Übergibt eine kontrollierte KaufDA-Abfrage neben `branchId` und Ort auch eine
  Adresse, bleibt diese bereits im geparsten Angebot erhalten.
- Die Python-Regression schützt damit die vollständige Filialherkunft vor der
  späteren Feed-Zusammenführung; ohne explizite Branch-Assertion bleibt der
  Treffer weiterhin regional und nicht routefähig.

## Update 13.10.2026 – Bon- und Preisbelege lesen konsistent aus der Schreibqueue
- `PriceObservationStore` und `ReceiptObservationStore` warten bei öffentlichen
  Reads jetzt auf laufende append/upsert/backup-Schreibvorgänge.
- Queue-interne Reads umgehen diese Wartefunktion gezielt, damit kein Deadlock
  entsteht; die bestehende append-only-/Merge-Logik bleibt erhalten.
- Neue Store-Regressionen sichern den parallelen Read-after-write-Fall.

## Update 13.10.2026 – Öffentlicher Prospektfeed identifiziert sich korrekt
- Der öffentliche Feed-Abruf sendet jetzt einen eigenen `Accept`- und
  `User-Agent`-Header. Der Abruf bleibt read-only und verwendet weiterhin
  Cache-/Asset-Fallbacks.
- Eine Feed-Regression prüft den Header am injizierten HTTP-Client.

## Update 13.10.2026 – EAN-Discovery trennt Varianten und Teilstrings
- Open-Food-Facts-Discovery akzeptiert Produktnamen jetzt nur bei echten
  Token-Grenzen und einer kompatiblen bekannten Produktfamilie/Variante.
- Abweichende Milch-Fettstufen und zusammengesetzte Teilstrings wie
  `Milch`/`Milchgetränk` bleiben dadurch unbekannt statt einen fremden EAN zu
  übernehmen.
- Zwei Fixture-Regressionen sichern die Ablehnung; bestätigte EANs und
  kompatible Mehrfachpackungen bleiben unverändert.

## Update 13.10.2026 – Open-Prices-Packungsbasis bleibt erhalten
- Der Open-Prices-Adapter übernimmt bei bekannten Katalogprodukten jetzt die
  explizite Packungsmenge/-einheit und berechnet daraus den Grundpreis.
- Diese Metadaten laufen dadurch durch `MarketPrice` und `PriceObservation`;
  die zentrale Packungs- und Identitätsprüfung kann inkompatible Daten weiter
  als unbekannt behandeln, statt einen unbestimmten EAN-Preis zu übernehmen.
- `open_prices_source_test.dart` prüft Standortnachweis, Packungsbasis und
  den normierten Grundpreis.

## Update 13.10.2026 – Historische Bon-Grundpreise werden einheitenrein verglichen
- Die Bonpreisstatistik führt bekannte `g`/`kg`- sowie `ml`/`cl`/`l`-Einzelpreise
  vor Median und aktuellem Historienwert auf `kg`, `l` bzw. `Stk` zurück.
- Die gekaufte Menge bleibt weiterhin nur die Vergleichbarkeitsprüfung; ein
  gedruckter Preis pro Einheit wird nicht versehentlich noch einmal mit der
  Packungsmenge multipliziert.
- Gemischte Dimensionen, unbekannte Einheiten und teilweise fehlende Mengen
  fallen wie zuvor transparent auf historische Packungspreise zurück.
- Die neuen Regressionen stehen in `receipt_price_statistics_test.dart`.

## Update 13.10.2026 – Open-Food-Facts-Mengenauflösung und Offline-Reads abgesichert
- Die Discovery erkennt strukturierte Mengenangaben wie `1 l`, `500 g`,
  `200 ml` und Mehrfachpackungen wie `4 x 125 g` wieder korrekt und verwirft
  weiterhin abweichende Packungsgrößen.
- Shell, Routen- und Filialansicht behandeln nicht lesbare lokale
  Distanzdaten als optionalen Cachefehler und rendern mit ihren hinterlegten
  Fallbackwerten.
- Cache-Lesevorgänge warten auf laufende lokale Schreibvorgänge, sodass ein
  Refresh oder Adresswechsel keinen veralteten Zwischenstand übernimmt.
- Die neue Discovery-Fixture deckt einen positiven EAN-Fund und eine
  abweichende Packungsgröße ab; Flutter-Prüfungen bleiben wegen des fehlenden
  lokalen SDKs offen. Der verfügbare Python-Lauf umfasst aktuell 85 Tests.

## Update 13.10.2026 – Prospekt-Grid bleibt ohne Plattform-Views
- Die scrollende Coverübersicht rendert externe Bilder jetzt strikt über den
  Canvas-Renderer. Der HTML-Fallback bleibt auf die kurze Favoritenleiste und
  den einzelnen Seitenviewer begrenzt, damit schnelles Scrollen keine Vielzahl
  von Plattform-Views erzeugt.
- Die Coverreferenz bleibt unverändert erhalten; bei fehlendem Canvas-CORS wird
  im Grid der vorhandene Bildplatzhalter angezeigt und der vollständige
  Nachweis bleibt im Viewer bzw. über den offiziellen Link erreichbar.

## Update 13.10.2026 – Beleg- und Mobilitätscallbacks bleiben nach Fehlern stabil
- Der Belegdialog übernimmt automatisch angelegte Produkte nach einem
  langsamen Callback nur noch, wenn er noch montiert ist.
- Das Speichern neuer Mobilitätseinstellungen bleibt auch bei einem defekten
  lokalen Strecken-Cache möglich; Route und Filialansicht verwenden dann ihre
  konfigurierten Fallbackdistanzen.

## Update 13.10.2026 – Straßenstrecken-UI bleibt bei Fehlern und Adresswechseln stabil
- Routen- und Filialansichten verwerfen jetzt verspätete OSRM-/Cache-Antworten,
  wenn inzwischen eine neue Startadresse oder Aktualisierung gilt.
- Routing- und Speicherfehler beenden den Ladezustand kontrolliert und zeigen
  einen verständlichen Hinweis; vorhandene Fallback-Entfernungen bleiben
  erhalten.
- Die Python-Regression bleibt grün; Flutter-Analyse, Flutter-Tests und
  Web-Build sind wegen des fehlenden lokalen SDKs weiterhin offen.

## Update 13.10.2026 – Belegdialog bleibt nach langsamen Imports stabil
- Der leere Ergebnis-/Fehlerpfad im Kassenbon-Import prüft nach allen
  asynchronen Speichervorgängen erneut den Widget-Lebenszyklus.
- Ein geschlossener Dialog wird dadurch nicht mehr durch einen verspäteten
  `setState`-Aufruf beschädigt.

## Update 13.10.2026 – Angebotsdatum bleibt nach Navigation stabil
- Der Angebotseditor und der manuelle Prospektseiten-Dialog aktualisieren ihr
  Datum nach einem DatePicker nur noch bei montiertem Editor.
- Antworten eines geschlossenen Editors werden verworfen; die sichtbare
  Angebots- und Quellenlogik bleibt unverändert.

## Update 13.10.2026 – KaufDA-Next-Daten tolerieren fehlendes type-Attribut
- Der optionale KaufDA-Parser akzeptiert ein exakt benanntes `__NEXT_DATA__`-
  Script auch ohne optionales `type="application/json"`-Attribut.
- Die neue Fixture-Regression hält die JSON- und Script-ID-Grenze fest; andere
  Markupvarianten bleiben Fehler und lösen keinen weiteren Abrufpfad aus.

## Update 13.10.2026 – Angebotscallbacks überschreiben keinen neuen Backup-Stand
- Das Speichern und Löschen manueller Angebote prüft jetzt ebenfalls die
  Shell-Datenrevision innerhalb der gemeinsamen Schreibwarteschlange.
- Ein verzögerter Prospektseiten-Callback wird nach einem Backup verworfen und
  kann den importierten Angebotsbestand nicht zurücksetzen.

## Update 13.10.2026 – Offline-Strecken bleiben für mehrere Startadressen erhalten
- `RoadDistanceStore` und `RoadRouteMatrixStore` speichern jetzt mehrere
  normalisierte Startadressen statt nur eines globalen Einzelwerts.
- Die alten v2-/v1-Schlüssel bleiben lesbar; Schreibvorgänge werden lokal
  serialisiert und überschreiben keine bereits gespeicherte andere Adresse.
- Neue Store-Regressionen prüfen Mehrfachadressen und Legacy-Fallbacks.

## Update 13.10.2026 – Externe Prospekt- und Discovery-Quellen abschaltbar
- Prospektfeed und Open-Food-Facts-Discovery unterstützen jetzt einen
  expliziten Netzwerk-Schalter.
- Bei deaktiviertem Netzwerk werden Cache/Asset genutzt oder ein klarer Fehler
  geliefert; kein externer Request und keine erfundene Produkt-/Preisbasis.

## Update 13.10.2026 – Non-Food-Angebote aus dem Prospektbestand entfernt
- Refresh- und App-Grenze erkennen jetzt zusätzlich Tierfutter, Badesalz/
  Medizin, Hygiene-/Haushaltsartikel und bepflanzte Gefäße. Fehlklassifizierte
  Händlerkategorien lassen belegte Lebensmittel wie Proteinriegel oder Shakes
  weiterhin durch.
- Der versionierte aktuelle Feed wurde um 15 klar belegte Non-Food-Datensätze
  bereinigt und enthält danach 677 aktuelle Angebote ohne abgelaufene oder
  formal ungültige Datensätze.
- Die Python-Regression deckt die neuen Gegenbeispiele ab; Flutter-Analyse,
  Flutter-Tests und Web-Build bleiben wegen des fehlenden lokalen SDKs offen.

## Update 13.10.2026 – Lokale Mutationen werden vor Backup-Überschreiben geschützt
- AppShell verwendet jetzt eine gemeinsame `SequentialWriteQueue` für
  Backup, Preis-/Open-Prices-Synchronisierung, Angebots-Historie, Katalog,
  Käufe, Einstellungen und Listen. Dadurch können diese lokalen
  Schreibvorgänge nicht mehr parallel dieselben Speicherbereiche
  überschreiben.
- Veraltete Preis-, Katalog- und Beobachtungsoperationen prüfen zusätzlich die
  Shell-Datenrevision, bevor sie starten oder ihren State anwenden. Ein neuerer
  Backup-Import kann dadurch keinen alten Callback zurück in die Oberfläche
  projizieren.
- Die vorhandene Queue-Regression bleibt grün; Flutter-Analyse, Flutter-Tests
  und Web-Build sind auf diesem Host weiterhin wegen des fehlenden Flutter-SDKs
  nicht ausführbar.

## Update 13.10.2026 – Backup-Import schützt vor verspäteten Start-Reads
- Ein Backup-Import invalidiert vor dem ersten Write die interne Shell-
  Datenrevision. Alte Listen-, Prospekt-, Bon- und Preis-Callbacks dürfen den
  importierten In-Memory-Stand danach nicht mehr überschreiben.
- Angebots- und Listen-Backups werden hinter die bestehenden Schreibqueues
  gestellt. `ReceiptObservationStore` serialisiert jetzt Import und
  vollständige Ersetzung über dieselbe Queue.
- Die neue Queue-Regression steht in `receipt_observation_store_test.dart`;
  Flutter-Analyse und -Tests bleiben auf diesem Host wegen des fehlenden SDKs
  offen.

## Update 13.10.2026 – Listenpreise respektieren die Routen-Verwendbarkeitsgrenze
- `shoppingQuotes` verwirft jetzt Marktpreise mit unsicherer Produktidentität
  oder ungültiger expliziter Mengenbasis. Manuelle und Open-Prices-Preise
  müssen zusätzlich die zentrale Aktualitätsprüfung bestehen.
- Sicher identifizierte alte Bonpreise bleiben als historische Hinweise
  sichtbar, erzeugen aber keine aktuelle Preisabdeckung. Eine Regression schützt
  den unsicheren Bonfall.

## Update 13.10.2026 – Prospekt-Übernahme bleibt nach Async-Callbacks stabil
- Angebotskarten aktualisieren ihren lokalen „Hinzugefügt“-Status nur noch,
  wenn sie nach dem Eltern-Callback noch montiert sind.
- Der manuelle Seitenflow prüft vor der Übernahme in die Einkaufsliste erneut
  den Screen-Lebenszyklus. Dadurch führen verzögerte Speichervorgänge nach
  Navigation oder Schließen des Screens nicht mehr in einen entfernten State.

## Update 13.10.2026 – Regionale KaufDA-Treffer bleiben an jeder Importgrenze gesperrt
- `resolveOfferImport` weist `regionalOnly` jetzt vor der Produktauflösung
  explizit zurück. Ein direkter Importaufruf kann dadurch keinen regionalen
  Publisher-Treffer als exaktes Angebot speichern.
- Die Rechercheansicht darf den Treffer weiter anzeigen; erst eine separat
  bestätigte Branch-ID macht den Datensatz für Angebot, Preisbeobachtung und
  Route nutzbar.
- `offer_import_test.dart` schützt den Bypass gegen Regression. Die lokale
  Flutter-Analyse und Flutter-Tests bleiben wegen des fehlenden SDK offen.

## Update 13.10.2026 – Gespeicherte regionale KaufDA-Altangebote werden nicht routefähig
- Die aktuelle Preiswahl prüft neben `regionalOnly`-Importdaten auch ältere
  gespeicherte KaufDA-Angebote: ohne `locationId` werden sie in Route,
  Preisfenster, Kandidaten und Vorschlägen ignoriert.
- Der Beobachtungsadapter vergibt für diesen Altfall keine exakte
  Identitäts-Confidence. Vier Regressionstests decken die Oberflächen ab.
- Auch eingehende KaufDA-Records ohne Branch-ID bleiben im Import- und
  Lernpfad regional, wenn ein altes oder manipuliertes Flag `regionalOnly: false`
  meldet.

## Update 13.10.2026 – Parallele Preis-Reads verlieren keine Beobachtungen mehr
- AppShell vereinigt allgemeine, Bon- und Prospekt-Leseergebnisse jetzt nach
  stabiler Beobachtungs-ID, bevor der sichtbare Preisverlauf ersetzt wird.
- Damit bleibt die append-only Evidenz auch bei konkurrierendem App-Start und
  Prospekt-Refresh erhalten. Der Merge ist in
  `price_observation_merge_test.dart` isoliert getestet.

## Update 12.10.2026 – Angebotsbasis bleibt in Preisbeobachtungen erhalten
- Importierte Angebote übernehmen Packungsmenge, Einheit und den
  normalisierten Grundpreis aus dem Prospektdatensatz in das gespeicherte
  `Offer`.
- `observationFromOffer` und `regularObservationFromOffer` führen diese Basis
  in die append-only `PriceObservation`-Historie weiter. So können Angebots-
  und Normalpreis dieselbe Mengenbasis verwenden.
- Eine explizit abweichende Angebots-Packung wird vor Route, Preisfenster,
  Suchkandidaten und Vorschlägen als Datenlücke verworfen; Legacy-Angebote
  ohne Mengenangabe bleiben lesbar.
- Alte Angebote ohne diese optionalen Felder bleiben lesbar; ihre fehlende
  Vergleichbarkeit wird nicht durch eine angenommene Packungsgröße ersetzt.

## Update 12.10.2026 – Bon-Dubletten berücksichtigen Mengenmetadaten
- Die Bon-Importprüfung verwendet neben dem bestehenden layoutstabilen
  Fingerprint jetzt einen Inhaltsfingerprint. Menge, Einheit, Einzelpreis,
  Rabattverknüpfung und der berechnete Betrag werden dabei einbezogen.
- Zahlungszeilen und physische OCR-/PDF-Zeilennummern bleiben ausgeschlossen;
  ein erneuter Import nach harmloser Layoutverschiebung wird weiterhin erkannt.
- Der alte Fingerprint bleibt für gespeicherte Beobachtungs- und Preis-IDs
  unverändert. Die Regression steht in `receipt_ledger_test.dart`.

## Update 12.10.2026 – Filialbezug in Such- und Preisoberflächen
- Die konfigurierte Filiale wird jetzt in Preisfenstern, Suchkandidaten und
  Vorschlägen sowohl für Marktpreise als auch für Angebote geprüft. Ein
  günstiger Datensatz einer anderen Filiale derselben Kette kann dadurch die
  lokale Planung nicht mehr über Händlername allein beeinflussen.
- Die gemeinsame Prüfung bleibt bei fehlender Quellfiliale rückwärtskompatibel
  und lehnt nur eindeutig abweichende bekannte Filialen ab.
- Die Branch-Regressionen sind ergänzt; Flutter-Analyse und -Tests bleiben auf
  diesem Host wegen des fehlenden SDK offen.

## Update 12.10.2026 – Angebotsnachweis in allen aktuellen Preisoberflächen
- Die Nachweisregel für externe Angebote gilt jetzt neben der Route auch für
  Preisfenster, Suchvorschläge und Produktkandidaten. Unbelegte Händler- oder
  Prospektdatensätze werden dort nicht mehr als aktuelle Preise gerankt.
- Manuelle Angebote bleiben ohne externe Referenz zulässig; die
  Angebotsübersicht behält den sichtbaren Nachweisstatus zur Prüfung.
- Drei Regressionstests decken die Oberflächen ab. Die Flutter-Prüfung bleibt
  auf diesem Host wegen des fehlenden SDK offen; die Python-Adapter-Suite lief
  zuletzt mit 82 Tests erfolgreich.
- Der Beobachtungsadapter verwendet dieselbe Regel auch für manuelle Angebote
  unabhängig von Groß-/Kleinschreibung; dafür gibt es eine zusätzliche
  Roundtrip-Regression.

## Update 12.10.2026 – KaufDA-Herkunft bleibt in der Preisbeobachtung sichtbar
- Die optionale `sourceAdapter`-Kennung wird beim Übergang von
  Prospektangeboten und gespeicherten Angeboten in `PriceObservation` und
  `MarketPrice` mitgeführt. Der technische Quellentyp und die belegte
  Erfassungszeit bleiben getrennt erhalten.
- Der Preisverlauf zeigt `KaufDA` als konkrete Herkunft, wenn diese Kennung
  vorhanden ist. Alte JSON-Einträge ohne das Feld bleiben lesbar.
- Die unabhängige Python-Adapter-Suite lief mit 82 Tests erfolgreich; der
  lokale Flutter-Gegencheck bleibt wegen des fehlenden SDK offen.

## Update 12.10.2026 – Unbelegte externe Angebote bleiben außerhalb der Route
- Der direkte `RoutePriceResolver`-Pfad verlangt für externe Angebote jetzt
  einen vertrauenswürdigen `proofRef`. Ein unvollständiger oder nachträglich
  veränderter Händler-/Prospektdatensatz kann dadurch trotz gültigem Zeitraum
  keinen unbelegten Routepreis erzeugen.
- Manuell erfasste Angebote bleiben ohne externen Nachweis zulässig. Die
  Regression liegt in `route_price_resolver_test.dart`; Flutter-Test und
  -Analyse bleiben auf diesem Host wegen des fehlenden SDK offen.

## Update 12.10.2026 – Preisabdeckung verwirft falsche Packungen
- Die Katalogübersicht zählt Marktpreise jetzt nur noch, wenn ihre explizite
  Mengenangabe zur konkreten Produktpackung passt. Ein 1-kg-Beleg erhöht damit
  weder die Open-Prices-Abdeckung eines 500-g-Produkts noch die Filialabdeckung.
- Solche Werte werden separat als Packungsdatenlücke gezählt und in der
  Katalogansicht benannt, statt stillschweigend als fehlende oder kostenlose
  Preise zu erscheinen.
- Die Übersicht überträgt den Katalog in dieselbe zentrale
  `marketPriceMatchesProduct`-Prüfung wie Route, Einkaufs-Preisfenster und
  Beobachtungsprojektion. Ohne übergebenen Katalog bleibt die ältere
  Store-Coverage-Hilfsfunktion für Diagnoseaufrufe kompatibel.
- Die Regression in `market_price_freshness_test.dart` prüft passende und
  abweichende Mengen gemeinsam.

## Update 12.10.2026 – Open-Food-Facts-Mengen bleiben vergleichbar
- Strukturierte Open-Food-Facts-Mengen wie `20 cl` werden jetzt ebenso wie
  Textmengen in die interne Vergleichseinheit `200 ml` überführt. Unbekannte
  Einheiten werden verworfen, statt eine nicht vergleichbare Packung zu
  behaupten.
- Die gemeinsame Mengenbasis erkennt Zentiliter auch in Produkt-, Prospekt-
  und Preisbelegen; `20 cl` und `200 ml` bleiben damit dieselbe Volumenbasis.
- `open_food_facts_product_source_test.dart` schützt die Normalisierung und
  die daraus gespeicherte Produktpackung.

## Update 12.10.2026 – Veröffentlichter Prospektpfad praktisch geprüft
- Im veröffentlichten Web-Build wurden die Lidl-Coverseite, der Viewer mit
  fünf Prospektseiten und das Weiter-Scrollen in die lazy geladenen
  Angebotskarten geprüft. Der Seitenpfad blieb nach mehreren Scrollschritten
  bedienbar.
- Ein Artikel von einer Prospektseite wurde zur Einkaufsliste hinzugefügt;
  der Button wechselte auf „Hinzugefügt“ und die Liste zeigte den Eintrag.
  Der lokale Browser-Testzustand wurde danach wieder auf den Ausgangsbestand
  reduziert. Dies ist ein Web-Smoketest, kein nativer iOS-/Android-Nachweis.

## Update 12.10.2026 – Gespeicherte Angebotsbilder bleiben render-sicher
- Angebots- und Katalogkarten validieren Bildreferenzen jetzt auch beim
  Rendern. Nur absolute HTTP(S)-URLs mit Host werden an `Image.network`
  weitergegeben.
- Alte lokale Werte wie `javascript:`, `data:` oder relative Pfade werden als
  fehlendes Bild behandelt. Preis-, Quellen- und Produktdaten bleiben dabei
  unverändert; der Scrollpfad führt keinen ungültigen Netzwerkwidget aus.
- Die reine URL-Regel ist in `safe_external_url_test.dart` mit gültigen,
  ungültigen und unvollständigen Beispielen abgedeckt.
- `offer_image_render_safety_test.dart` prüft zusätzlich, dass der
  Angebotsnachweis für eine unsichere gespeicherte Bildreferenz kein
  `Image`-Widget aufbaut.
- Beim Speichern eines Angebots übernimmt die Preisbeobachtung jetzt den
  belegten `capturedAt`-Zeitpunkt; nur manuelle/Legacy-Angebote ohne diesen
  Wert verwenden den aktuellen Speichermoment. Die Adapterregression prüft den
  KaufDA-Fall.

## Update 12.10.2026 – Preisbelege bleiben packungsgenau
- Routenresolver, Einkaufslisten-Preisfenster, Variantenempfehlungen und die
  zentrale Beobachtungsprojektion prüfen jetzt explizite Preis-Mengen gegen die
  konkrete Produktpackung.
- Eindeutige Einheiten aus dem Produktfeld (`500 g`, `4 x 125 g`, `3er-Schale`)
  werden als Vergleichsbasis normalisiert. Ein 1-kg-Beleg kann dadurch nicht
  mehr als 500-g-Preis erscheinen; mehrdeutige Bereiche bleiben unbekannt.
- Legacy-Preise ohne Mengenangabe bleiben kompatibel. Fachregressionen decken
  passende, abweichende und fehlende Mengen sowie Route und Preisfenster ab.

## Update 12.10.2026 – KaufDA-Regionstreffer bleiben suchbar, aber nicht routefähig
- Gespeicherte, aus dem Feed aufgelöste Angebote behalten jetzt zusätzlich die
  optionale Adapterkennung (`sourceAdapter`). KaufDA bleibt damit auch nach
  Neustart und Backup/Restore als konkrete Herkunft sichtbar. Der per Quelle
  gelieferte `capturedAt`-Zeitpunkt bleibt ebenfalls erhalten; die technische
  Preisquelle (`retailerWebsite`) bleibt unverändert.
- Die zentrale Importauflösung lehnt abweichende oder mehrdeutige KaufDA-
  Packungsgrößen ab. Beim Bearbeiten eines bestehenden Angebots bleiben
  Quellen- und Filialnachweis erhalten, solange Filiale und Produktidentität
  nicht gewechselt werden.
- Der aktivierte KaufDA-Adapter hält aktuelle Lebensmittel-Treffer ohne
  separat bestätigte Filiale jetzt als `regionalOnly` im Prospektfeed.
- Die Prospekt- und Suchkarten können diese Artikel mit Herkunft anzeigen;
  der bestehende Add-to-List-, Preislern- und Routenpfad lehnt sie weiterhin
  konservativ ab, bis eine exakte Branch-ID vorliegt.
- Bei identischen Händler-/Artikel-/Preis-/Zeiträumen bleibt der offizielle
  Händlernachweis gegenüber KaufDA primär; fehlende Bild- oder Kategorie-
  Metadaten dürfen aus KaufDA ergänzt werden.
- Mehrere Publisher aus einer KaufDA-Suche behalten ihre Prospektseiten und
  Laufzeiten jetzt getrennt; eine bestätigte Branch-Zuordnung aktualisiert
  den Prospektstatus nur für den passenden Händler.
- Karten und Quellenhinweise benennen regionale KaufDA-Treffer auch in der
  Übersicht ausdrücklich als nicht filialbestätigt.
- Der KaufDA-Parser toleriert zusätzlich eine begrenzte Umbenennung der
  verschachtelten Ergebniscontainer, akzeptiert dabei aber nur Listen mit
  erkennbaren Angebotsfeldern.
- `regionalOnly`-Angebote übernehmen keine Filial-ID, keinen Ort und keine
  Adresse aus einer autoritativen Händler-Quellenkarte; dadurch bleibt ihre
  unbestätigte Herkunft auch in der UI sichtbar.
- Ältere KaufDA-Feeds ohne das neue Regionalflag werden bei fehlender eigener
  Branch-ID ebenfalls konservativ als regional behandelt.

## Update 12.10.2026 – Marktpreise bleiben auch bei mehreren Filialen getrennt
- Der lokale Marktpreisspeicher ersetzt Beobachtungen jetzt nach Händler,
  Produkt und kanonischer Filial-ID. Ein Preis aus einer zweiten Filiale kann
  damit keinen exakten Branchennachweis überschreiben.
- Standortlose Legacy-Preise bleiben als eigener Fallback-Slot erhalten;
  `remove` und `removeProduct` entfernen weiterhin bewusst alle Filialen des
  ausgewählten Produkts.

## Update 12.10.2026 – Open-Prices-EAN bleibt im Parser explizit
- Der normalisierte EAN wird beim Live- und Cache-Parsing explizit an den
  internen Antwortparser übergeben.
- Dadurch bleibt der Antwortvergleich auf genau das angefragte Produkt
  begrenzt und der Parser verwendet keine außerhalb des Gültigkeitsbereichs
  liegende Variable.

## Update 12.10.2026 – Prospekt-Refresh schließt eigene HTTP-Ressourcen
- Automatisch erzeugte Prospekt-Importer schließen ihren HTTP-Client nach
  erfolgreichem, fehlgeschlagenem oder abgebrochenem Refresh.
- Injizierte Clients für Tests oder kontrollierte Aufrufer bleiben deren
  Besitz; dadurch ändern sich Cache-, Fehler- und Testlebenszyklen nicht.

## Update 12.10.2026 – Filial-IDs werden quellenübergreifend stabil verglichen
- Preisbelege und Angebote vergleichen Filialkennungen jetzt whitespace- und
  groß-/kleinschreibungsunabhängig, ohne Bindestrich-/Unterstrich-Aliase zu
  erfinden.
- Die Normalisierung gilt in Routenresolver, Planungsprojektion,
  Einkaufspreis-Matrix und Open-Prices-Marktzuordnung gemeinsam.
- Eine unbekannte oder abweichende Kennung bleibt weiterhin eine andere
  Filiale und kann nicht als exakter Nachweis durchrutschen.

## Update 12.10.2026 – Preis- und Angebotsnachweise bleiben filialgenau
- Der Routenresolver akzeptiert marktbezogene Preisbelege mit
  `sourceLocationId` nur für die ausgewählte `Store.branchId`; ein günstigerer
  Beleg einer anderen Filiale kann nicht mehr in die Route gelangen.
- Branchenspezifische Angebote werden nach derselben Regel gefiltert.
  Standortlose Legacy-Belege bleiben als ausdrücklicher Fallback nutzbar.
- Die Planungsprojektion bewahrt mehrere Filialen je Händler/Produkt bis zur
  Routenauflösung, statt sie vorher zu einem möglicherweise falschen Preis zu
  verschmelzen.

## Update 12.10.2026 – Prospektsuche bleibt beim Scrollen lazy
- Suchtreffer werden jetzt als Sliver-Liste aufgebaut. Bei großen Trefferlisten
  werden nur die sichtbaren Artikelkarten und Bilder gebaut; die bisherige
  komplette Spaltenstruktur entfällt.
- Bildreferenzen aus dem Feed und aus manuell übergebenen Karten werden vor
  `Image.network` auf HTTP(S) mit Host begrenzt. Ungültige Händler-Markups
  bleiben als fehlendes Bild sichtbar und können den Scrollpfad nicht crashen.
- Der Seitenviewer begrenzt zusätzlich die dekodierte Bildgröße und baut Seiten
  weiterhin als lazy Sliver auf; große Original-Cover werden nicht vollständig
  in den Scrollspeicher geladen.

## Update 12.10.2026 – KaufDA-Metadaten bleiben bis zur Preisprüfung erhalten
- Der App-Feed übernimmt optionale `sourceAdapter`-, `regionalOnly`-,
  `publisherId`-, `brochureId`- und `brochurePage`-Felder zusätzlich zu
  Packungsgröße, Grundpreis und Erfassungszeitpunkt.
- Regional-only-Treffer bleiben als Herkunftsinformation erkennbar, werden
  aber weder in die Einkaufsliste übertragen noch als aktuelle Routepreise
  oder Preisbeobachtungen gelernt.
- Packungsgrößen aus KaufDA werden für exakte Produktidentität und
  Grundpreisvergleich verwendet. Mehrfachpackungen behalten ihre
  Gesamtmenge; unklare Varianten werden weiterhin nicht geraten.

## Update 12.10.2026 – kaufDA-Cache behält den echten Erfassungszeitpunkt
- KaufDA-Treffer tragen bei der optionalen Refresh-Integration jetzt ihren
  tatsächlichen Abruf- oder Cache-Zeitpunkt am einzelnen Datensatz.
- Der Preislern-Pfad verwendet diesen Wert vor dem globalen Feedzeitpunkt.
  Dadurch wird ein zulässiger, älterer kaufDA-Cache nicht durch einen späteren
  Händler-Refresh künstlich als frischer Preisbeleg dargestellt.
- Ungültige optionale Zeitstempel werden am App-Eingang verworfen; ältere
  Feeds ohne dieses Feld bleiben kompatibel und nutzen weiterhin den
  Feedzeitpunkt.

## Update 12.10.2026 – Kaufland-Prospekt zeigt die öffentliche Coverseite
- Der strukturierte Kaufland-Refresh liest die aktuelle, filialbezogene
  Prospektverknüpfung für DE5103 und prüft deren Laufzeit.
- Die öffentlich sichtbare Seite 1 des aktuellen Viewers wird als Thumbnail
  und `pageSamples[0]` übernommen; Viewer-/Coverfehler blockieren den
  Angebotsimport nicht.
- Der versionierte Offline-Stand enthält den Covernachweis für Würzburg-
  Grombühl vom 12.10.2026 bis 17.10.2026.

## Update 12.10.2026 – ALDI-Süd-Prospekt zeigt die öffentliche Coverseite
- Der ALDI-Refresh liest zusätzlich den aktuellen öffentlichen Prospektlink
  und die zugehörige CMS-Coverreferenz aus der offiziellen Startseite.
- Kalenderwoche, Gültigkeitszeitraum und Bild werden geprüft; die Coverseite
  wird als `thumbnailUrl` und `pageSamples[0]` für die konfigurierte Filiale
  B384 abgelegt. Fällt der Coverabruf aus, bleiben die strukturierten
  ALDI-Angebote nutzbar.
- Der versionierte Offline-Stand enthält die verifizierte Titelseite für
  12.10.2026 bis 17.10.2026.

## Update 12.10.2026 – PENNY-Prospekt zeigt die öffentliche Coverseite
- Der PENNY-Adapter liest aus dem aktuellen Handout-Bereich der offiziellen
  Angebotsseite den ausgewiesenen Zeitraum und die große CMS-Coverreferenz.
- Die Coverseite wird als Seite 1 für die konfigurierte Filiale 230061
  übernommen; fehlende Handout-Markupdaten blockieren den strukturierten
  Kategorieimport nicht.
- Der versionierte Offline-Stand enthält die verifizierte Titelseite für
  12.10.2026 bis 17.10.2026.

## Update 12.10.2026 – EDEKA-Prospekt bleibt filialbezogen sichtbar
- Der EDEKA-Refresh verknüpft den aktuellen Prospektlink des Marktes 023738
  mit der öffentlichen Seite 1 des Blätterkatalogs.
- Zeitraum, Marktpfad und `bk_1.jpg` werden gemeinsam geprüft; der
  strukturierte EDEKA-Preisimport bleibt davon getrennt.
- Der versionierte Offline-Stand enthält die verifizierte Titelseite für
  Zellingen vom 12.10.2026 bis 17.10.2026.

## Update 12.10.2026 – Non-Food-Angebote bleiben aus dem Prospektbestand
- Der Refresh filtert Händlerkampagnen wie Haushaltswaren, Kleidung,
  Pflanzen, Körperpflege und Spielzeug vor dem versionierten Feed heraus.
- Der Dart-Parser wiederholt diese konservative Prüfung beim App-Eingang, damit
  auch ein älterer oder zwischengespeicherter öffentlicher Feed keine
  Non-Food-Artikel in Angebote, Preisbeobachtungen oder Routen bringt.
- Lebensmittelbegriffe wie Pflanzenöl und Halloween-Kürbis bleiben über
  Wortgrenzen erhalten; die Regression prüft positive und negative Beispiele.
- Die Quellenkarte zählt nach diesem Filter die tatsächlich nutzbaren
  Lebensmittelangebote; ein abweichender Rohwert bleibt als
  `rawRecordCount` nachvollziehbar.
- Der mitgelieferte Stand umfasst nach dieser Bereinigung 677 aktuelle
  Datensätze aus den sechs konfigurierten Märkten; der Feed-Zeitpunkt bleibt
  der belegte Erzeugungszeitpunkt.

## Update 12.10.2026 – Prospektkarten scrollen ohne unnötige Web-Plattform-Views
- Artikelkarten verwenden im Web strikt das Canvas-Rendering mit begrenzter
  Decode-Größe. Dadurch erzeugt eine große Trefferliste nicht für jedes
  Produktbild ein eigenes HTML-Plattform-View.
- Cover- und Angebotskacheln sind zusätzlich als getrennte Repaint-Bereiche
  isoliert, damit ein Bild- oder Favoritenupdate nicht die gesamte Liste neu
  zeichnet.
- Die Übersicht und der einzelne Seitenviewer dürfen den HTML-Fallback für
  wenige Cover-/Seitenbilder behalten, damit externe Händler-CDNs ohne
  Canvas-CORS weiterhin sichtbar bleiben.

## Update 12.10.2026 – Prospektfeed toleriert Metadatenformatwechsel
- Der App-Parser akzeptiert `recordCount` und Seitenzahlen auch als
  numerische JSON-Strings. Ein einzelnes Händler-Markup-Update verwirft damit
  nicht mehr den gesamten Feed.
- Preiswerte bleiben strikt numerisch; ein als Text gelieferter Preis wird
  weiterhin verworfen und kann keine Route oder Preisbeobachtung beeinflussen.

## Update 12.10.2026 – Barcodeeingaben werden konservativ normalisiert
- Scanner- und manuelle EAN-Eingaben entfernen nur Leerzeichen/Trennzeichen;
  nichtnumerische Werte werden verworfen.
- Zwölfstellige UPC-A-Werte werden für den exakten Vergleich als GTIN-13 mit
  führender Null dargestellt. Die Auflösung bleibt vollständig gleichheits-
  basiert und übernimmt keine Teilstring- oder Familienzuordnung.
- Nicht passende Kamera-Frames werden still ignoriert; nur eine manuelle
  ungültige Eingabe zeigt einen Fehler. Bestehende Katalogcodes bleiben ohne
  nachträgliche Prüfziffermigration kompatibel.
- Open Food Facts und Open Prices verwenden dieselbe Normalisierung vor
  Request, Cache und Antwortvergleich; dadurch bleibt ein Barcode über die
  gesamte Datenpipeline konsistent.
- Der lokale Produktdaten-Cache, die Katalog-Duplikatprüfung und die
  Kandidatenauflösung verwenden ebenfalls die kanonische Form. Ältere
  Cache-Einträge mit Rohschreibweise bleiben über den bisherigen Schlüssel
  lesbar und werden beim Laden kanonisiert.
- Der Produkteditor speichert dieselbe kanonische Form und blockiert
  nichtnumerische Barcodeangaben bereits vor dem Speichern.

## Update 12.10.2026 – Prospekt-Packungen bleiben vergleichbar
- Angebotslabels mit echter Mehrfachpackung wie `3 x 50 g` werden für die
  Preisbeobachtung auf die Gesamtmenge von 150 g normalisiert; dadurch entsteht
  ein belastbarer Grundpreis statt eines Stückpreis-Missverständnisses.
- Zählpackungen wie `3er-Schale` werden als Stückmenge geführt.
- Variantenbereiche und Alternativgrößen wie `100/95/90 g` oder `160 g – 175 g`
  bleiben bewusst ohne angenommene Packungsgröße und Grundpreis. Eine einzelne
  Variante wird nicht aus einem mehrdeutigen Händlerlabel geraten.

## Update 12.10.2026 – Feedzeitpunkt bleibt bei vollständigem Abrufausfall unverändert
- Der Prospekt-Refresh setzt `generatedAt` nur noch nach einer tatsächlich
  erfolgreichen Quellaktualisierung auf die aktuelle Zeit. Wenn alle Quellen
  ausfallen und nur noch gültige vorherige Datensätze übernommen werden, bleibt
  deren ursprünglicher Zeitpunkt erhalten; die App kann einen Fallback damit
  nicht versehentlich als frisch ausgeben.
- `--help` und unbekannte Quellargumente ändern den Feed nicht mehr. Die
  Refresh-Regression prüft beide Zeitstempelpfade.

## Update 12.10.2026 – Öffentlicher Prospektfeed funktioniert auch kalt offline
- Der zuletzt versionierte öffentliche Prospektfeed wird jetzt als App-Asset
  mitgebaut und verwendet, wenn Live-Abruf und lokaler Cache gleichzeitig
  nicht verfügbar sind.
- Der Stand bleibt im UI als nicht-live/Cache-Fallback gekennzeichnet; die
  bestehende Gültigkeitsprüfung filtert abgelaufene Angebote weiterhin vor
  Angeboten, Beobachtungen und Route.
- Der Fallback enthält keine privaten Belege oder Zugangsdaten und kann beim
  nächsten normalen Live-Refresh ersetzt werden.

## Update 12.10.2026 – Netto-Wochenprospekt liefert Coverseite
- Der offizielle Netto-Filialadapter erkennt den aktuellen
  `wochenprospekt`-Link mit `Filial-Angebote`-Cover für die konfigurierte
  Filiale Thüngersheim.
- Die Coverseite wird als `pageSamples[0]` mit URL, Gültigkeitszeitraum,
  Filialkontext und `thumbnailUrl` an den bestehenden Prospekt-Feed übergeben;
  der Jina-Reader-Fallback unterstützt dieselbe Struktur als Markdown.
- Die Übersicht verwendet vorhandene Vorschaubilder für die Karten; der
  Viewer zeigt bei einem Prospekt ohne strukturierte `pageSamples` trotzdem
  dessen belegtes Cover als Seite 1.
- Der versionierte Offline-Stand enthält jetzt zusätzlich das an der
  öffentlichen Filialseite verifizierte Netto-Cover für die Filiale 4371;
  der nächste autorisierte Refresh ersetzt diese datierte Referenz durch den
  dann geprüften Quellstand.

## Update 12.10.2026 – KaufDA-Prospektseiten aus Live-JSON erhalten
- Der optionale KaufDA-Adapter verarbeitet neben älteren numerischen
  Seitenwerten jetzt auch die aktuelle öffentliche Form
  `parentContent.page.number`.
- Prospektseiten werden am Angebot und zusätzlich in `pageSamples` der
  Prospektmetadaten gespeichert; die Publisher-ID bleibt als Herkunftsfeld
  erhalten.
- Ausgewiesene reguläre Preise werden übernommen, UVP-Werte bleiben bewusst
  außerhalb der Normalpreisprojektion. REWE wird als optionaler Publisher
  erkannt, bleibt ohne exakte Filialkonfiguration jedoch nur regional.
- Eine Fixture-Regression mit dieser Live-Struktur ergänzt die bestehende
  Prüfung auf aktuelle Lebensmittel, Ablauf, Grundpreis, Bild und Herkunft.

## Update 12.10.2026 – Prospektgültigkeit konservativ validieren
- [x] Falsch typisierte oder syntaktisch ungültige Angebotsfelder werden
  verworfen, statt als fehlende Angaben weiterzulaufen.
- [x] Widersprüchliche Zeiträume und ungültig ausgewiesene Normalpreise
  gelangen nicht in aktuelle Prospektangebote oder Preisprojektionen.
- [x] Eine synthetische Regression bewahrt valide Nachbarangebote und prüft
  die drei verworfenen Evidenzfälle.


## Update 11.10.2026 – Prospektartikel bis AppShell und Route durchgetestet
- Ein AppShell-Integrationstest prüft jetzt den sichtbaren Prospekte-Tab,
  die Suche, die Add-to-List-Aktion, die gespeicherte Angebotsprovenienz und
  den echten Neustartpfad bis zur Einkaufsroute.
- Der Startpfad bewahrt bei der Migration aus der alten Einzel-Listenablage
  vorhandene Artikel, wenn die benannte Liste vorübergehend leer gelesen wird.
- Die synthetische Regression erfindet keine Preise oder Belege; CI bestätigt
  Analyse, Flutter-Tests und den Web-Release-Build.

## Update 11.10.2026 – Filialadresse bleibt auch in der Importnormalisierung erhalten
- Der allgemeine `resolveOfferImport`-Pfad übernimmt die Quelladresse jetzt
  genauso wie die direkte Prospektproduktauflösung.
- Damit bleiben Filial-ID, Ort und Adresse über beide geprüften
  Angebotsimportwege gemeinsam nachvollziehbar; Preise, Identität und
  Gültigkeitsprüfung ändern sich nicht.

 – Projektstatus

## Update 11.10.2026 – Filialadresse bleibt am Prospektangebot
- Der Feed-Parser übernimmt die Adresse aus dem jeweiligen Angebotsdatensatz
  und fällt deterministisch auf die nachweisbare Quellenadresse zurück.
- Artikelkarten zeigen Ort und Adresse; die umgewandelten Angebote und lokalen
  Backups speichern diese Felder gemeinsam mit Händler, Nachweis und Gültigkeit.
- Produktidentität, Preisvergleich und Gültigkeitsprüfung bleiben unverändert.

## Update 11.10.2026 – Datensatz-Filialort in der Prospektansicht
- Angebots- und Prospektsuche zeigen jetzt den Ort aus dem jeweiligen Feed-Datensatz, wenn dieser vorhanden ist.
- Der Händler-/Issue-Ort und die konfigurierte Filiale bleiben nachvollziehbare Fallbacks; mehrere Datensatzorte werden gemeinsam sichtbar.
- Produktidentität, Preis, Nachweis und Gültigkeit bleiben unverändert.

## Update 11.10.2026 – Filialkontext bleibt an jedem Feed-Datensatz
- Der Prospekt-Refresh schreibt den konfigurierten Filialschlüssel, Ort und Adresse jetzt zusätzlich an jedes erzeugte Angebot und jede Prospektseite.
- Bereits vorhandener Anbieter-Kontext gewinnt; fehlende Felder fallen deterministisch auf die konfigurierte Filiale zurück.
- Die Daten bleiben damit bis zur UI-Übernahme nachvollziehbar, ohne fehlende Filialen oder Preise zu ergänzen.

## Update 11.10.2026 – Veraltete Prospektfeeds sichtbar
- Die Prospekt- und Angebotsansicht kennzeichnet einen Live-Feed älter als 48 Stunden als veraltet und bietet weiterhin die direkte Aktualisierung an.
- Gültigkeitsprüfung und Quellenregeln bleiben unverändert: Die Warnung macht die Datenlage sichtbar, verlängert kein Angebot und erzeugt keinen Preis.
- Der Schwellenwert ist über einen deterministischen Zeitparameter testbar, damit Feed-Frische und Cache-Hinweise im UI nachvollziehbar bleiben.

## Update 11.10.2026 – Bildseiten mit geprüfter manueller Übernahme
- Bildbasierte Prospektseiten bieten jetzt eine ausdrückliche manuelle
  Übernahme mit Bezeichnung, Angebots-/Normalpreis und Gültigkeitsende.
- Der Seitenlink, das Bild, die Filiale und der Ort bleiben am gespeicherten
  Angebot und an der Preisbeobachtung erhalten; der Nutzer bestätigt die
  Angaben vor dem Speichern.
- Automatische OCR bleibt davon getrennt und erzeugt weiterhin keine
  ungeprüften Routenpreise.

> Diese Datei ist der Einstiegspunkt für jeden neuen Chat und jeden Work-Lauf.
> Vor Änderungen immer zuerst PROJECT_STATUS.md, ARCHITECTURE.md, ROADMAP.md und DECISIONS.md lesen und danach den aktuellen GitHub-Stand prüfen.

## Update 11.10.2026 – Fehlende Angebotsnachweise in der Abdeckung sichtbar
- Die Prospektabdeckung weist je Markt jetzt aus, wie viele strukturierte
  Angebotsdatensätze einen vorhandenen Originalnachweis tragen.
- Fehlende Nachweise bleiben als Datenlücke sichtbar; es wird kein Link,
  Preis oder Identitätsbezug ergänzt.
- Fach- und Widgetregressionen decken vollständige und fehlende Nachweise ab.

## Update 11.10.2026 – Offizielle Prospektlinks bleiben HTTP(S)-gebunden
- Der Prospektreader öffnet den offiziellen Händlerlink nur noch, wenn der
  Feed einen gültigen HTTP- oder HTTPS-Link mit Host liefert.
- Ungültige oder fremde URI-Schemes bleiben sichtbar als Prospektmetadaten,
  erzeugen aber keine externe Aktion. Eine Widgetregression sichert diesen
  Review-Fall ab.

## Update 11.10.2026 – Prospektartikel direkt nach Händler filtern
- Die Prospektansicht bietet neben Volltext und Kategorie jetzt eine direkte
  Marktauswahl. Händlerchips filtern die aktuell gültigen Artikel über dieselbe
  sichere Nachweis- und Identitätsauflösung.
- Eine leere Auswahl zeigt weiterhin alle Märkte; ein gefilterter Treffer bleibt
  mit Ort, Bild, Gültigkeit, Originalnachweis und Add-to-List-Aktion verbunden.
- Eine Widget-Regression prüft die Auswahl eines Händlers über zwei Märkte.

## Update 11.10.2026 – Filialort in Prospekt-Treffern sichtbar
- Marktübergreifende Such- und Kategorienergebnisse zeigen unter dem Händler
  zusätzlich den vorhandenen Filialort aus dem Prospektfeed.
- Fehlt die Quellangabe, wird kein Ort ergänzt oder aus Textähnlichkeit
  abgeleitet. Artikelidentität, Preis, Gültigkeit und Add-to-List-Regeln bleiben
  unverändert.
- Eine Widget-Regression prüft den Filialort im Trefferpfad.

## Update 11.10.2026 – Originalnachweis an Prospektartikelkarten
- Nachgewiesene Prospektartikel zeigen in kompakter und großer Darstellung
  einen direkten Link zum vorhandenen HTTP(S)-Originalnachweis.
- Ohne gültigen Nachweis wird kein Link angezeigt; der bestehende Add-to-List-
  Schutz für fehlende oder mehrdeutige Identitäten bleibt unverändert.
- Eine Widget-Regression prüft sichtbare Nachweise für belegte Karten und deren
  Abwesenheit bei unbelegten Artikeln.

## Update 11.10.2026 – Prospektartikel nach Quellenkategorie filtern
- Die Prospektansicht bietet neben der Volltextsuche schnelle Kategorienchips
  für die aktuell gültigen Händlerartikel. Die Auswahl filtert marktübergreifend
  und führt direkt zu den bestehenden Artikelkarten.
- Kategorien stammen ausschließlich aus dem Händlerfeed oder der sichtbaren
  Darstellungsklassifikation. Sie verändern weder Produktidentität noch Preis,
  Gültigkeit oder Routenstatus.
- Eine Widget-Regression prüft, dass die Kategorieauswahl nur passende Artikel
  zeigt; Nachweis-, Ambiguitäts- und Add-to-List-Regeln bleiben unverändert.

## Update 11.10.2026 – Prospektartikel marktübergreifend auffindbar
- Die Prospektansicht bietet jetzt eine Suche über alle aktuell gültigen
  Händlerangebote. Artikel lassen sich aus dem Suchergebnis direkt mit ihrem
  bestehenden Nachweis, Bild und Gültigkeitszeitraum zur Einkaufsliste
  hinzufügen.
- Die Suche verwendet nur sichtbare Quellfelder wie Händler, Produktlabel und
  Kategorie. Sie verändert keine Produktidentität und erzeugt keine Preise;
  nicht nachweisbare oder mehrdeutige Artikel bleiben entsprechend den
  bestehenden Review-Regeln nicht auswählbar.
- Die Marktansicht mit Prospektseiten und Filialdaten bleibt unverändert
  erreichbar. Eine Widget-Regression prüft die Suche über zwei Märkte und den
  Add-to-List-Flow.

## Update 11.10.2026 – Prospektgültigkeit bleibt bei fehlerhaften Feedwerten sicher
- Der Feedparser verwirft Angebote mit syntaktisch ungültigem Startdatum,
  widersprüchlichem Angebotszeitraum oder fehlerhaftem ausgewiesenem Normalpreis.
- Ein kaputtes optionales Startdatum wird nicht mehr als fehlendes Datum
  interpretiert und kann dadurch kein scheinbar aktuelles Angebot erzeugen.
- Regressionen prüfen, dass valide Nachbarangebote erhalten bleiben und keine
  ungesicherten Datensätze in die aktuelle Angebots- oder Preisprojektion gelangen.

## Update 11.10.2026 – Widersprüchliche Bon-Aliase bleiben im Review
- Wenn ältere oder zusammengeführte Aliasdaten denselben Bontext mehreren
  Produkten mit ausreichender Bestätigungszahl zuordnen, wird kein Eintrag mehr
  stillschweigend bevorzugt.
- Der Bontext bleibt auswählbar und prüfbar; erst eine eindeutige Lernhistorie
  darf eine automatische Zuordnung und spätere Preisbeobachtung auslösen.
- Eine Regression schützt den mehrdeutigen Legacy-Fall.

## Stand
- Repository: bndkxbqf2g-stack/SparzamApp
- Hauptbranch: main
- Letzter geprüfter Code-Stand auf main: `4a9800e` (Bon-Aliase auf
  konfigurierte Marktidentitäten normalisiert); der aktuelle Feed-Stand ist
  `ec1227e`.
- PR #248 wurde mit den CI-Läufen `38039823586` und `38039837524` geprüft und
  in main gemergt. Main-CI `38040080993` sowie Release `38040080990` waren mit
  Analyse, Tests, Web-/Pages-Deployment und Android-APK erfolgreich.
- App: Flutter-Prototyp für intelligent geplante Lebensmitteleinkäufe.
- Arbeitsweise: kleine, nachvollziehbare Schritte; modular; nach jedem abgeschlossenen Paket testen, committen, pushen und diese Datei aktualisieren.

## Update 10.10.2026 – Main- und Release-Abnahme nach PR #248
- Der veröffentlichte Stand `4a9800e` wurde im Web geladen; Einkaufsliste,
  aktuelle Angebote, Produktdatenlücken und die Aktion „Sparroute prüfen“ sind
  sichtbar.
- Die vollständige lokale Dart-Analyse von `lib` und `test` ist ohne Befund.
  Der lokale Flutter-Wrapper bleibt wegen des nicht beschreibbaren globalen
  Engine-Caches eingeschränkt; die vollständige Flutter-Analyse, Test- und
  Web-/Android-Prüfung ist durch die grünen GitHub-Läufe belegt.
- PR #248 vereinheitlicht die Marktidentität gelernter Bon-Aliase, ohne
  unbekannte Händlerlabels automatisch zuzuordnen.

## Update 10.10.2026 – Bon-Aliase verwenden die konfigurierte Marktidentität
- Gültige Bon-Aliase werden beim Speichern und Nachschlagen auf die
  konfigurierte Marktidentität normalisiert. OCR-Varianten wie „ALDI SUED“
  sowie Händlertexte mit Ortszusatz teilen dadurch dieselbe Lernhistorie.
- Unbekannte Händlerbezeichnungen bleiben unverändert und werden nicht
  automatisch einem Markt zugeordnet. Die Regression deckt Bestätigung,
  erneutes Lernen und die Abwärtskompatibilität unbekannter Händler ab.

## Update 10.10.2026 – Bekannte Suchfamilien öffnen die Produktauswahl
- Beim freien Fallback einer bekannten Anfrage wie „Milch“ öffnet die
  Einkaufsliste jetzt direkt die konkrete Variantenauswahl mit belegten Preisen.
  Dadurch wird eine bekannte Familienanfrage nicht versehentlich als
  unbepreister Eigenartikel gespeichert.
- Unbekannter Freitext bleibt unverändert als eigener Listenartikel möglich.
  Produktauswahl, Angebotssichtbarkeit und Preisquellen bleiben getrennt.
- Die Widget-Regressionen prüfen beide Wege. Die lokale Dart-Analyse ist ohne
  Befund; der lokale Flutter-Test bleibt wegen der nicht beschreibbaren
  Flutter-Engine-Cachedateien CI-seitig zu prüfen.

## Update 10.10.2026 – Preis-Datenlücken öffnen die konkrete Produktauswahl
- Eine unbestimmte Listenposition wie „Milch“ führt aus der Routenansicht jetzt
  direkt in die vorhandene Kandidatenauswahl. Dort werden aktuelle Angebote,
  bekannte Marktpreise sowie klar gekennzeichnete historische Bon- und
  Prospektwerte gemeinsam angezeigt.
- Die Auswahl ersetzt nur die betroffene Listenposition und übernimmt Menge,
  Notiz und Prüfstatus. Unbekannter Freitext bleibt beim manuellen Preiseintrag,
  weil dafür keine sichere Produktidentität vorliegt.
- Die Erkennung und das positionsgenaue Ersetzen sind durch Regressionstests
  abgesichert. Die lokale Dart-Analyse ist ohne Befund; der gezielte
  Flutter-Test bleibt wegen der nicht beschreibbaren lokalen Flutter-Engine-
  Cachedateien CI-seitig zu prüfen.

## Update 10.10.2026 – Kurze Suchtexte bleiben während der Eingabe ruhig
- Ein einzelner, noch unvollständiger Buchstabe filtert nicht mehr den gesamten
  Katalog nach zufälligen Teilstring-Treffern. Dadurch erscheinen beim Start
  der Eingabe keine fachfremden Angebote wie Bier oder Mixer.
- Bekannte Produktidentitäten wie „Ei“ bleiben direkt suchbar; unbekannter
  Freitext wartet nur bis zum zweiten Zeichen. Produktidentität, Preisquellen
  und die Reihenfolge vollständiger Suchtreffer bleiben unverändert.

## Update 10.10.2026 – Eier-Suche blendet Schokoladeneier aus
- Die allgemeine Suche nach „Eier“ behandelt Schokoladenprodukte wie „Kinder
  Maxi Ei“ nicht mehr als Haushalts-Eier. Die Bezeichnung wird vor der
  generischen Eierfamilie als Süßware erkannt.
- Produktidentität und Einkaufsvorschläge sind mit einer positiven und einer
  negativen Regression abgesichert; Preise und Angebotsdaten bleiben unverändert.

## Update 10.10.2026 – Milchsuche blendet Keks- und Süßwarenangebote aus
- Die allgemeine Suche nach „Milch“ ordnet Produktlabels mit einer
  Milch-Geschmacksangabe nach einer Keks-, Waffel- oder Kuchenbezeichnung nicht
  mehr der normalen Milchpreisfamilie zu. Dadurch erscheint zum Beispiel
  „LEIBNIZ Keks'n Cream … Milch“ nicht mehr als Milchvorschlag.
- Die Korrektur bleibt generisch an Produktwortfamilien gebunden und erfindet
  keine Variante oder Preisidentität. Produktidentitäts- und
  Einkaufsvorschlagstests schützen die negative Zuordnung.

## Update 10.10.2026 – Einheitliche Prospektkategorien bei fehlenden Quellkategorien
- Die Angebots- und Prospektansicht verwenden jetzt dieselbe
  presentation-only Fallback-Kategorisierung, wenn ein Händler keine Kategorie
  liefert. Kaffee und Espresso erscheinen dadurch in beiden Ansichten unter
  „Kaffee & Snacks“ statt je nach Screen unterschiedlich.
- Händlerkategorien, Produktidentitäten, Preise und Routen bleiben unverändert;
  die Fallback-Kategorie dient ausschließlich der sichtbaren Gruppierung.
- Regressionen prüfen die gemeinsame Zuordnung für Kaffee, Getränke, Vorrat und
  unbekannte Artikel. Die lokale Dart-Analyse der betroffenen Dateien ist ohne
  Befund; der gezielte Flutter-Test bleibt wegen der nicht beschreibbaren lokalen
  Flutter-Engine-Cachedateien CI-seitig zu prüfen.

## Update 10.10.2026 – Bonkürzel `KH-Milch` wird als H-Milch geöffnet
- Kassenbonzeilen mit `KH-Milch` werden jetzt genauso wie `K.H-Milch` als
  unvollständige H-Milch-Angabe erkannt. Die Einkaufsliste öffnet dafür die
  kompatiblen normalen Milchvarianten und lässt die Fettstufen als getrennte
  Preisidentitäten bestehen.
- Produktidentitäts- und Vorschlagstests decken die Schreibweise ohne Punkt und
  Bindestrich ab. PR #235 (`a25127a`, Merge `848c3a6`) enthält den Fix. Die
  nachgelagerte Main-/Release-CI `38028993248` und `38028993254` war vollständig
  erfolgreich.

## Update 10.10.2026 – Deutscher Kalendertag für Prospekt-Refresh
- Der automatische Prospekt-Refresh verwendet für Angebotswoche, Ablaufprüfung
  und gültige Fallbackdaten jetzt den Kalendertag Europe/Berlin. Dadurch kann
  ein Lauf kurz nach deutscher Mitternacht nicht versehentlich die vorherige
  Woche auswählen.
- Der Feed-Zeitstempel bleibt als UTC-Zeit nachvollziehbar; Angebotsdaten und
  Händlergültigkeit werden nicht verändert. Parserregressionen prüfen die
  Berliner Tagesbasis und den Samstag als Ende der Händlerwoche.
- PR #236 (`3ed3853`, Merge `3849ba6`) hat beide CI-Läufe `38029453039` und
  `38029469906` erfolgreich durchlaufen. Die nachgelagerte Flutter-CI
  `38029961007`, der Prospekt-Refresh `38029961330` und der Release-Lauf
  `38030097081` waren ebenfalls erfolgreich.
- Der erneuerte Feed `ec1227e` enthält 702 gültige Angebote aus allen sechs
  Märkten; der Zeitstempel lautet `2026-10-10T06:11:48Z`.

## Update 10.10.2026 – Aktuelle Wochenprospekte lassen sich manuell aktualisieren
- Angebote und Prospekte haben jetzt einen sichtbaren Aktualisieren-Knopf. Damit
  kann ein neuer Wochenfeed geladen werden, ohne die App neu zu starten.
- Während des Abrufs wird der Knopf gesperrt. Parallele Feed-Abrufe und damit
  doppelte Preislernläufe werden verhindert. Die bestehende Prüfung von
  Gültigkeit, Cache-Status und Nachweis bleibt unverändert.
- PR #233 (`90f5130`, Merge `8e8e71f`) ergänzt UI-Regressionen für den ersten
  Abruf und die Aktualisierung aus dem Prospektbildschirm. Die PR-CI-Läufe
  `38027482353` und `38027489183` waren mit Analyse, vollständigen Tests und
  Web-Build erfolgreich.

## Update 10.10.2026 – Fehlende Prospektkategorien führen Kaffeeangebote in die richtige Gruppe
- Wenn ein Händler keine Kategorie liefert, ordnet die Angebotsansicht Kaffee,
  Espresso, Tee und Snacks jetzt unter „Kaffee & Snacks“ ein. Die Heuristik
  greift nur bei fehlender Quellkategorie; Händlerkategorien bleiben unverändert.
- Dadurch sind Standardartikel wie Kaffee auch bei unvollständigen Feed-Metadaten
  in der erwarteten Gruppe auffindbar, ohne Preis- oder Produktidentitäten aus
  der Darstellung abzuleiten.
- PR #231 (`ee0e4e0`, Merge `0f3e423`) ergänzt einen Widget-Regressionstest. Die
  PR-CI-Läufe `38026506929` und `38026513572` waren mit Analyse, vollständigen
  Tests und Web-Build erfolgreich.

## Update 10.10.2026 – Prospekt-Metadaten bleiben auch ohne Bildseiten nutzbar
- Der Prospektfeed bewahrt jetzt auch Einträge ohne Bildseiten. Gültigkeitszeitraum,
  Filialbezug, Standort, Titel und offizieller Link bleiben damit sichtbar, statt
  als unbekannte oder nicht geladene Quelle zu erscheinen.
- Ein gültiger Metadaten-Prospekt wird in der Prospektansicht als aktueller Stand
  behandelt. Die App zeigt weiterhin transparent, dass keine strukturierten
  Angebotsdaten oder Bildseiten vorliegen; Preise und Produktidentitäten werden
  nicht aus den Metadaten erfunden.
- PR #229 (`b12f8ac`, Merge `cb63c13`) ergänzt Parser- und UI-Regressionen. Die
  beiden PR-CI-Läufe `38025561255` und `38025569445` waren mit Analyse,
  vollständigen Tests und Web-Build erfolgreich.

## Update 10.10.2026 – Bonpreis-Familien übernehmen die gemeinsame Qualitätsauswahl
- Die aus Kassenbonbeobachtungen abgeleitete Produktfamilien-Projektion wählt
  je Händler und Produkt jetzt mit derselben Qualitätsbewertung wie die
  Routenplanung. Ein neuerer, aber als Rabattpreis erkannter Bon ersetzt damit
  nicht mehr automatisch eine ältere, belastbarere Normalpreisbeobachtung.
- Händler, Quelle, Beobachtungsdatum, Rabattstatus und der beobachtete Betrag
  bleiben unverändert nachvollziehbar. Die Änderung beeinflusst nur die
  Auswahl des gemeinsamen aktuellen Familienpreises; historische
  Beobachtungen bleiben getrennt erhalten.
- PR #227 (`45afcde`, Merge `554339f`) ergänzt eine Regression für älteren
  Normalpreis gegen neueren Rabattpreis. Die PR-CI-Läufe `38024008103` und
  `38024019028`, Main-CI `38024260076` sowie Release `38024260061` waren mit
  Analyse, vollständigen Tests, Web-/Pages-Build, Deployment und Android-APK
  erfolgreich.

## Update 10.10.2026 – Demoangebote bleiben auch aus der Route ausgeschlossen
- Die Erkennung reservierter Legacy-Demoangebote liegt jetzt im gemeinsamen
  Angebotsfilter. Der Route-Resolver verwirft dieselben Beispiele wie
  Einkaufssuche und Kandidatenauswahl, bevor ein Angebot als Routenpreis
  betrachtet wird.
- Nutzerangebote mit gleicher Produkt- und Händlerangabe bleiben erhalten;
  ausgeschlossen werden nur die bekannten Demo-Identitäten mit passendem
  reserviertem Preis. Eine Regression prüft den direkten Resolver-Aufruf ohne
  Umweg über die UI.
- PR #225 (`1283d63` + Import-Fix `2d700f6`, Merge `cbb78c9`) wurde nach einem
  zunächst fehlgeschlagenen Import-Check korrigiert. Die erfolgreichen
  Nachlauf-PR-CI-Läufe `38022650394` und `38022653045`, Main-CI
  `38022883281` sowie Release `38022883322` liefen mit Analyse, vollständigen
  Tests, Web-/Pages-Build, Deployment und Android-APK erfolgreich.

## Update 10.10.2026 – Preis-Matrix und Preis-Badge folgen der gemeinsamen Qualitätsauswahl
- Die Produkt×Markt-Matrix wählt aktuelle Bon-, eigenen und Open-Prices jetzt
  mit derselben Quellen- und Unsicherheitsbewertung wie Produktsuche und Route.
  Ein historischer Bonpreis kann dadurch keinen aktuellen Preisbeleg mehr
  verdrängen, auch wenn er nominal günstiger ist.
- Aktuelle Beobachtungen werden vor historischen Bonpreisen angezeigt. Aktive
  Angebote bleiben vorrangig; sichtbarer Betrag, Quelle, Händler und Datum
  bleiben unverändert nachvollziehbar.
- Das hervorgehobene Preis-Badge übernimmt dieselbe Matrixentscheidung und
  zeigt nicht mehr unabhängig davon den zuletzt gesehenen Bonpreis.
- PR #223 (`c6b2bc5`, Merge `5066e5c`) ergänzt Regressionen für Matrixauswahl
  und sichtbare UI-Auswahl. Die PR-CI-Läufe `38021129351` und `38021137839`,
  Main-CI `38021373268` sowie Release `38021373215` waren mit Analyse,
  vollständigen Tests, Web-/Pages-Build, Deployment und Android-APK
  erfolgreich.

## Update 10.10.2026 – Produktsuche und Route bewerten aktuelle Preise einheitlich
- Die Produktsuche verwendet für aktuelle Bon- und Open-Prices jetzt dieselbe
  Unsicherheitsbewertung wie die Routenplanung. Ein nominal günstiger,
  rabattierter Bonpreis kann dadurch nicht allein wegen seines niedrigeren
  Betrags eine sicherere aktuelle Preisbeobachtung verdrängen.
- Aktive Angebote bleiben vorrangig. Die Qualitätsbewertung verändert nur die
  Reihenfolge; der angezeigte beobachtete Preis, Quelle und Händler bleiben
  unverändert nachvollziehbar. Historische Preis-Hinweise werden weiterhin
  getrennt von aktuellen Planungswerten behandelt.
- PR #221 (`d91e80f`, Merge `94047ce`) ergänzt Regressionen für den direkten
  Preis-Hinweis und die Reihenfolge der Produktsuche. Die PR-CI-Läufe
  `38019658401` und `38019665970`, Main-CI `38019920523` sowie Release
  `38019920514` waren mit Analyse, vollständigen Tests, Web-/Pages-Build,
  Deployment und Android-APK erfolgreich.

## Update 10.10.2026 – Konfigurierte Open-Prices-Frist erreicht Route und Marktübersicht
- Die eingestellte maximale Gültigkeitsdauer für Open Prices wird jetzt durch
  die gemeinsame Preis-Auswahl, die Planungsprojektion, den Route-Resolver,
  die Routenoptimierung und die Marktübersicht gereicht. Damit bleibt die
  Einstellung auch dann wirksam, wenn ein Aufrufer eine ungefilterte
  Beobachtungsliste übergibt.
- Veraltete Open-Prices-Beobachtungen werden nicht als Marktpreis,
  Angebotsvergleich oder Ersparnisgrundlage verwendet. Manuelle Preise,
  Bonpreise, Quellen und Beobachtungsdaten behalten ihre bisher getrennten
  Frische- und Vertrauensregeln.
- PR #219 (`65e10ee`, Merge `d4509d2`) ergänzt Regressionen für Resolver und
  Planungsprojektion sowie die Weitergabe bis in Route, Budget, Marktansicht
  und Angebotsdetails. Die PR-CI-Läufe `38018075829` und `38018068741`,
  Main-CI `38018335346` sowie Release `38018335352` waren mit Analyse,
  vollständigen Tests, Web-/Pages-Build, Deployment und Android-APK
  erfolgreich.

## Update 10.10.2026 – Kandidatenauswahl übernimmt die Open-Prices-Altersgrenze
- Wenn ein bestehender Listeneintrag auf konkrete Produktvarianten geprüft
  wird, verwendet die Kandidatenauswahl jetzt dieselbe konfigurierte
  Open-Prices-Altersgrenze wie Suche, Preis-Matrix und Route.
- Dadurch können veraltete Open-Prices-Beobachtungen nicht mehr über den
  unveränderten Standardwert von 60 Tagen in diesen Auswahlfluss gelangen.
- PR #217 (`1153416`, Merge `dd0f967`) ergänzt die Regression für eine
  abweichend konfigurierte Altersgrenze. Die beiden PR-CI-Läufe
  `38016502530` und `38016510045`, Main-CI `38016758983` sowie Release
  `38016758994` waren mit Analyse, Tests, Web-/Pages-Build, Deployment und
  Android-APK erfolgreich.

## Update 10.10.2026 – Open Prices bleiben in Einkaufsliste und Produktsuche sichtbar
- Aktivierte, frische Open-Prices-Beobachtungen werden jetzt in der
  Einkaufslisten-Preis-Matrix und in den Produktempfehlungen angezeigt, statt
  nur in der Routenplanung zu wirken.
- Quelle und Beobachtungsdatum bleiben als „Open Prices“ sichtbar. Die
  konfigurierte Altersgrenze wird durch Preis-Matrix, Suche,
  Kandidatenauswahl und Route gereicht; veraltete oder zukünftige Werte
  bleiben ausgeschlossen.
- PR #215 (`d88ac5a`, Merge `a52e323`) ergänzt Regressionen für sichtbare,
  veraltete und produktspezifisch ausgewählte Open-Prices-Preise. Die beiden
  PR-CI-Läufe `38014955579` und `38014958719`, Main-CI `38015267132` sowie
  Release `38015267142` waren mit Analyse, Tests, Web-/Pages-Build,
  Deployment und Android-APK erfolgreich.

## Update 10.10.2026 – Zukünftige Marktpreise bleiben aus Liste und Route
- Marktpreise mit einem Datum nach dem aktuellen Tag werden jetzt unabhängig von
  ihrer Quelle als nicht beobachtet behandelt. Das verhindert, dass ein
  fehlerhaft datierter manueller Preis vor seinem Datum als aktueller
  Einkaufslisten- oder Routenpreis erscheint.
- Manuelle Preise bleiben für vergangene und heutige Erfassungsdaten weiterhin
  unbegrenzt nutzbar. Bonpreise und externe Preisbeobachtungen behalten ihre
  bestehende Alterslogik; historische Belege werden weiter getrennt angezeigt.
- PR #213 (`9f1ae61`, Merge `9ec6e20`) ergänzt Regressionen für Preisquelle,
  Preis-Matrix und Route. Die beiden PR-CI-Läufe `38013380077` und
  `38013383505`, Main-CI `38013669883` sowie Release `38013669844` waren mit
  Analyse, Tests, Web-/Pages-Build, Deployment und Android-APK erfolgreich.

## Update 10.10.2026 – Nachgewiesene unbekannte Prospektartikel bleiben routbar
- Aktuelle, nachgewiesene Prospektlabels ohne lokale Katalogidentität werden
  jetzt mit ihrem exakten Label und dem zugehörigen Angebotsnachweis bis in die
  Routenplanung übernommen. Dadurch kann ein konkret ausgewählter Artikel aus
  dem Prospekt direkt als Angebotspreis geplant werden.
- Es wird dabei keine Produktfamilie erraten und kein Preis auf eine andere
  Variante übertragen. Die Auswahl des konkreten Prospektartikels bleibt im
  Einkaufslistenfluss sichtbar und reversibel.
- PR #211 (`5d94bbf`, Merge `cdb9202`) ergänzt den Regressionstest vom
  unbekannten Prospektlabel bis zur Einmarkt-Route. Die beiden PR-CI-Läufe
  `38012318605` und `38012328432` waren erfolgreich; Main-CI und Release für
  `cdb9202` werden nach dem Status-Merge geprüft.

## Update 10.10.2026 – Bevorzugte Produktvarianten bleiben nach dem Speichern erhalten
- Die Speicherung bevorzugter Produktvarianten schreibt jetzt die tatsächlichen
  Gruppen- und Produkt-IDs. Dadurch bleiben gelernte Auswahlentscheidungen auch
  nach dem erneuten Laden und beim Wiederherstellen eines Backups erhalten.
- Eine Regression prüft mehrere Zuordnungen gleichzeitig und verhindert, dass
  die Platzhalterdarstellung versehentlich wieder eingeführt wird.
- PR #209 (`51a29ac`, Merge `fc8fd61`) ist mit den beiden erfolgreichen
  PR-CI-Läufen `38010928894` und `38010938613` in `main` gelandet; die
  nachgelagerten Main-/Release-Läufe für `fc8fd61` werden noch geprüft.

## Update 10.10.2026 – Bonbeobachtungen bleiben bei OCR-Layoutänderungen idempotent
- Bonbeobachtungen verwenden jetzt eine stabile Produktzeilen-Ordnung innerhalb
  des Beleg-Fingerprints. Die physische PDF-/OCR-Zeilennummer bleibt als
  Nachweis erhalten, erzeugt aber bei eingefügten Layoutzeilen keine neue
  Beobachtungsidentität.
- Der lokale Beobachtungsspeicher führt alte `Fingerprint|Zeile`-IDs und neue
  `Fingerprint|item:n`-IDs über Fingerprint, Zeileninhalt und Auftretensreihenfolge
  zusammen. Wiederholte gleiche Produkte bleiben als getrennte Zeilen erhalten.
- Ein erneuter Import löscht keine bereits bestätigte oder automatisch angelegte
  Produktidentität, wenn die zweite Prüfung die Zeile unmarkiert lässt. Preise,
  Mengen, Einheit, Händler und Beobachtungsdatum bleiben an der eingelesenen
  Zeile nachvollziehbar.
- PR #207 (`a4435bc`, Merge `ed046c6`) ergänzt die Regressionen. Die beiden
  PR-CI-Läufe `38009599922` und `38009618694` waren mit Analyse, Tests und
  Web-Build erfolgreich; die nachgelagerten Main-/Release-Läufe sind für
  `ed046c6` gestartet.

## Update 10.10.2026 – Suche nach Milch führt in die aktuelle Sparroute
- Der aktuelle, versionierte Prospektfeed wird jetzt durch den sichtbaren
  Alltagsfluss geprüft: Die Suche nach „Milch“ findet eine aktuelle
  offerbasierte Produktvariante mit Händlernachweis und Preis.
- Die ausgewählte Variante bleibt dieselbe Produktidentität in der
  Routenplanung. Eine Einmarkt-Route kann den Angebotsartikel mit seinem
  aktuellen Preis belegen; fehlende oder unsichere Identitäten werden dabei
  nicht still auf einen anderen Katalogartikel übertragen.
- PR #205 (`64659fa`, Merge `25d6902`) ergänzt die End-to-End-Regression. Die
  beiden PR-CI-Läufe `38008127689` und `38008136671` waren mit Analyse,
  611 Tests und Web-Build erfolgreich.

## Update 10.10.2026 – Aktueller Sechs-Märkte-Prospektfeed als End-to-End-Matrix
- Der versionierte Feed `assets/prospects/current.json` wird jetzt als
  Regression für alle sechs konfigurierten Märkte geprüft: Lidl, ALDI Süd,
  EDEKA, Kaufland, PENNY und Netto bleiben im Prospekt- und Angebotsbestand
  sichtbar.
- Je Markt läuft mindestens eine aktuelle, nachgewiesene Feedzeile durch die
  Preislernstrecke. Unbekannte Labels bleiben dabei bewusst historische
  Evidenz mit Identitäts-Confidence 0; ein offerbasiertes Produkt kann trotzdem
  sichtbar und route-tauglich vorgeschlagen werden. Eine exakte Identität wird
  nur bei passendem Katalognamen und belegter Packungsbasis übernommen.
- Abgelaufene Zeilen bleiben für die Historie erhalten, werden aber aus den
  aktuellen Angeboten ausgeschlossen. Es werden keine Produktidentitäten oder
  Preise aus fehlenden Angaben ergänzt.
- PR #202 (`faf4fbf`, Merge `a23acc2`) ergänzt diese Regression. Die beiden
  PR-CI-Läufe `38005765741` und `38005775386` waren mit Analyse, 610 Tests und
  Web-Build erfolgreich.

## Update 10.10.2026 – Aktuelle Prospekt-Lebensmittel werden generisch suchbar
- Die zentrale Produktidentität erkennt weitere aktuelle Lebensmittelangebote
  auf Familienebene: frisches Obst und Gemüse, zusammengesetzte Fisch- und
  Fleischlabels, zusätzliche Käsevarianten, Desserts und Backwaren.
- Auch Vorrat und Frühstück werden gefunden, darunter Saucen, Suppen,
  asiatische Nudeln, Müsli, Haferflocken, Backzutaten, Nüsse und
  Trockenfrüchte. Getränke wie Bier, Wein, Spirituosen, Energy-Drinks und
  Ingwer-Shots erhalten passende Familien- bzw. Typidentitäten.
- Dekorative Kürbisse, Feinkostsalate und andere Fremdprodukte bleiben von
  den frischen Lebensmittelidentitäten getrennt. Dadurch kann eine Suche nach
  „Kürbis“, „Salat“ oder „Käse“ keine fachfremden Preise übernehmen.
- PR #199 (`0063112`, Merge `29d8aed`) ergänzt Identitäts- und
  Einkaufssuchtests. Die PR-CI-Läufe `38003290934` und `38003299640` waren mit
  Analyse, 608 Tests und Web-Build erfolgreich.

## Update 10.10.2026 – Prospekt-Mehrfachpackungen behalten ihre Gesamtmenge
- Unbekannte, aber geprüfte Prospektartikel übernehmen jetzt Mehrfachpackungen
  wie „3 x 50-g-Packg.“ oder „6 x 1,5-l-Fl.“ vollständig. Die sichtbare
  Packungsangabe bleibt erhalten; zusätzlich werden Gesamtmenge und Einheit
  gespeichert.
- Damit werden Grundpreis, Mengenvergleich und gelernte Prospektbeobachtung
  nicht mehr versehentlich nur auf die Einzelportion bezogen. Unklare Angaben
  ohne belastbare Mengeneinheit bleiben weiterhin ohne erfundene Packungsbasis.
- PR #194 (`106eab3`) ergänzt Regressionen für Mehrfachpackungen. Die PR-CI,
  Main-CI und Release-Läufe waren erfolgreich.

## Update 10.10.2026 – Zusammengesetzte Lebensmittel-Prospektlabels werden gefunden
- Die Produktidentität erkennt jetzt weitere aktuelle Prospektkomposita
  generisch: Fleischkäse und Hähnchensalami als Wurst, Hähnchenflügel als
  Fleisch, Sahnepudding und Sprühsahne als Dessert bzw. Sahne, Schafskäse,
  Grill-/Pfannen-/Reibekäse und Pizzakäse als Käse sowie Gemüsepfannen und
  Steinofenpizza als Gemüse bzw. Pizza.
- Zusätzlich werden Frühlingsquark, Rübenzucker, Schokoladenkränze,
  Kokoswasser und Eisbecher in den passenden Familien gefunden. Zutaten- und
  Fremdprodukt-Sonderfälle bleiben getrennt, zum Beispiel Pizzakäse von Pizza,
  Erdnussbutter von Butter und Gemüsemais von der allgemeinen Gemüsefamilie.
- PR #196 (`5598a4f`) ergänzt Identitäts- und Einkaufssuchtests. Die beiden
  PR-CI-Läufe `37999315281` und `37999328616` waren mit Analyse, Tests und
  Web-Build erfolgreich.

## Update 09.10.2026 – Preis-Datenlücken direkt in der Marktansicht bearbeiten
- Die Marktansicht zeigt fehlende, vergleichbare Preise weiterhin als Datenlücke und bietet jetzt direkt den Button „Preis ergänzen“.
- Der bestehende Preis-Editor wird dafür aus der Einkaufsliste über Angebotsdetails und Marktansicht weitergereicht. So kann ein fehlender Marktpreis genau an der Stelle ergänzt werden, an der die Lücke auffällt; die gespeicherte Quelle bleibt ein eigener Marktpreis und wird sofort für Liste und Route verwendet.
- PR #159 (`ea8dfac`) ergänzt die Widget-Regression für den direkten Bedienfluss. PR-CI `37904049421`, Main-CI `37904457340` und Release `37904457343` waren mit 575 Tests, Analyse, Web-/Pages-Build, Deployment und Android-APK erfolgreich.

## Update 09.10.2026 – Datenlücken nach bekanntem Bedarf priorisieren
- Offene Preisnachweise erhalten jetzt einen deterministischen Datenlücken-Score,
  der nur bereits bekannte Signale verwendet: Anteil fehlender Märkte,
  gewünschte Menge, bestätigte Kaufhäufigkeit und den exakten historischen
  Medianpreis, sofern vorhanden.
- Fehlt eine historische Basis, wird neutral mit dem Faktor eins gerechnet.
  Der Score ist ausschließlich ein Priorisierungsindex für die Reihenfolge
  gleichrangiger Lücken; er erzeugt keinen Marktpreis und verändert weder
  Angebotsgültigkeit noch Routenpreise.
- PR #161 (`4d12d9c`) ergänzt Fachregressionen für die Score-Berechnung und
  ihre neutrale Behandlung ohne Historie. Die beiden PR-CI-Läufe
  `37906553696` und `37906563186` waren erfolgreich.

## Update 09.10.2026 – Kombinierte Datenlücken-Relevanz wirkt in der Reihenfolge
- Die Datenlückenliste wendet den kombinierten Score jetzt vor den einzelnen
  Tie-Breakern an. Eine Position mit größerer bekannter Auswirkung aus Menge,
  bestätigter Kaufhäufigkeit, historischer Preisbasis und fehlender
  Marktdeckung kann dadurch eine häufige, aber kleinere Lücke überholen.
- Die Reihenfolge bleibt nach Marktdeckung und Grundbedarf nachvollziehbar;
  bei gleicher Relevanz greifen Kaufhäufigkeit, Historie, Menge, Produktname
  und Produkt-ID weiterhin deterministisch.
- PR #163 (`ec4c78d`) ergänzt eine Regression für die kombinierte Bewertung.
  PR-CI `37908383382` und `37908396540`, Main-CI `37908816819` sowie Release
  `37908816658` waren mit Analyse, Tests, Web-/Pages-Build, Deployment und
  Android-APK erfolgreich.

## Aktuell funktionsfähig
- Einkaufsliste mit mehreren Listen, Mengen, Notizen, Kategorien und lokalem Zustand.
- Produktkatalog inkl. Barcode/Open Food Facts.
- Preisvergleich und Routenlogik.
- Bon-Import für textbasierte PDF/TXT/CSV und lokale Kaufhistorie.
- Bestätigte Bonpreise haben Vorrang vor externen/geschätzten Preisen.
- Open Prices als optionale Preisquelle.
- Angebote/Prospekte als eigener Bereich.
- Exakte gelernte Preisbeobachtungen sind im Preisdialog eines Listenartikels
  getrennt vom aktuellen Angebot und vom Routenpreis einsehbar.
- Budget- und Diagnosefunktionen.

## Update 09.10.2026 – Zukünftige externe Preise bleiben aus der Planung
- Kassenbon- und Open-Prices-Beobachtungen mit einem Datum nach dem aktuellen
  Tag werden zentral als nicht nutzbar behandelt. So können importierte oder
  fehlerhaft datierte externe Werte weder als aktueller Suchpreis noch als
  Routenpreis erscheinen.
- Manuelle Preise bleiben davon getrennt zulässig. Die Einkaufssuche blendet
  zukünftige Bonbeobachtungen ebenfalls aus, während historische Belege weiter
  datiert sichtbar bleiben.
- PR #166 (`d941771`) ergänzt die Zeitprüfung und Regressionen. PR-CI
  `37920677029` und `37920692175`, Main-CI `37921104437` sowie Release
  `37921104249` waren mit Analyse, Tests, Web-/Pages-Build, Deployment und
  Android-APK erfolgreich.

## Update 09.10.2026 – Alte Bonpreise bleiben sichtbar, aber historisch
- Ältere Kassenbonpreise bleiben als Preisverlauf und Orientierung in der
  Einkaufsliste sichtbar, werden aber eindeutig als „Historischer Bonpreis“
  bezeichnet.
- Die Marktübersicht zählt nur frische Bonpreise als aktuelle Preisdeckung.
  Historische Bonpreise werden nicht still als aktuelle Marktpreise verwendet;
  aktuelle Angebote und frische Belege behalten Vorrang.
- PR #168 (`a904184`) ergänzt die Kennzeichnung und Regressionen. PR-CI
  `37958814205` und `37958826961`, Main-CI `37959324782` sowie Release
  `37959324909` waren erfolgreich.

## Update 09.10.2026 – Günstiger belegter Marktpreis schlägt unbestätigtes Angebot
- Die Routenplanung verwendet ein aktives Angebot nur dann als günstigere Position,
  wenn es gegenüber einem vorhandenen Markt- oder Katalogpreis tatsächlich nicht
  teurer ist. Ein nicht verifizierter Normalpreis im Angebot darf damit keinen
  belegten Bon- oder Marktpreis verdrängen.
- Reine Angebotsdaten ohne vorhandenen Normalpreis bleiben weiterhin routbar; die
  App erfindet dafür keinen Vergleichspreis und zeigt auch keine unbelegte
  Ersparnis an.
- PR #170 (`c108275`) ergänzt die Regression für beide Fälle. Die korrigierten
  PR-CI-Läufe `37962180211` und `37962186250`, Main-CI `37962650886` sowie Release
  `37962650885` waren erfolgreich.

## Update 09.10.2026 – Zusammengesetzte Milch-Prospektlabels werden gefunden
- Prospektlabels wie „Haltbare Berg- & Alpenmilch“ werden jetzt generisch als
  Milchfamilie erkannt. Dadurch erscheinen aktuelle, belegte Angebote auch bei
  einer einfachen Suche nach „Milch“ in der Einkaufsliste.
- Die Identität bleibt konservativ: Kondensmilch, Milchreis, Milchschnitte und
  Käseprodukte mit Milchbestandteil bleiben von der normalen Milchsuche getrennt.
- PR #172 (`9001ffe`) ergänzt Identitäts- und Einkaufssuchtests. Die PR-CI-Läufe
  `37965347328` und `37965359717`, Main-CI `37965821978` sowie Release
  `37965821968` waren erfolgreich.

## Update 09.10.2026 – Spezialmilch bleibt von normaler Milch getrennt
- Prospektlabels wie „Buttermilch-Drink“ und „Kokosmilch“ werden jetzt als
  spezielle Milchgetränke erkannt. Dadurch erscheinen ihre Preise nicht bei
  einer einfachen Suche nach normaler Milch.
- Buttermilch sowie Kokos-, Soja-, Hafer- und Mandelmilch behalten jeweils
  einen eigenen Produkttyp. Eine gezielte Suche kann sie weiterhin finden,
  ohne die Preisidentität für normale Kuhmilch zu verwässern.
- PR #184 (`465155d`) ergänzt Identitäts- und Einkaufssuchtests. Die PR-CI-Läufe
  `37982283850` und `37982298335`, Main-CI `37982752368` sowie der nach einem
  externen Maven-Downloadfehler erfolgreich wiederholte Release-Lauf
  `37982752555` waren erfolgreich.

## Update 09.10.2026 – Säuglingsmilch bleibt von normaler Milch getrennt
- Prospektlabels wie „Folgemilch“, „Anfangsmilch“, „Säuglingsmilch“,
  „Babymilch“ und „Kindermilch“ werden jetzt als eigene Babynahrungsfamilie
  erkannt. Dadurch erscheinen ihre Preise nicht bei einer einfachen Suche
  nach normaler Milch.
- Folgemilch und die weiteren Typen behalten ihre eigene Identität. Eine
  gezielte Suche kann sie weiterhin finden, ohne die Preisidentität für
  normale Kuhmilch zu verwässern.
- PR #186 (`975363e`) ergänzt Identitäts- und Einkaufssuchtests. Die PR-CI-Läufe
  `37985510403` und `37985523126`, Main-CI `37985945304` sowie Release
  `37985945543` waren mit Analyse, Tests, Web-/Pages-Build, Deployment und
  Android-APK erfolgreich.

## Update 09.10.2026 – Tee- und Eis-Suchen bleiben frei von Fremdprodukten
- Fertiggetränke wie „Teegetränk“ werden von heißem Tee getrennt; Tee-Gläser
  werden als Haushalt erkannt. Ein allgemeiner Tee-Vorschlag kann dadurch
  keine Getränke- oder Geschirrpreise übernehmen.
- Nicht-Lebensmittel wie ein erotischer Adventskalender mit dem Label „EIS“
  werden aus der Eisfamilie ferngehalten. Eine gezielte Suche nach Eistee
  bleibt weiterhin möglich.
- PR #188 (`254bf46`) ergänzt Identitäts- und Einkaufssuchtests. Die PR-CI-Läufe
  `37988247409` und `37988253971`, Main-CI `37988690763` sowie Release
  `37988690791` waren erfolgreich.

## Update 09.10.2026 – Zusammengesetzte Prospektlabels bleiben fachlich getrennt
- Holz-Spielzeug mit „Kaffee und Kuchen“, Protein-Eisriegel, herzhafte
  Feinkost-Cremes und Tierfutter mit „Protein“ werden nicht mehr als Kaffee,
  Eis, Sahne oder Proteinartikel vorgeschlagen.
- Käsecreme bleibt eine Käsevariante. Skyr wird als Joghurtvariante erkannt,
  damit Standard-Suchen die tatsächliche Lebensmittelgruppe behalten.
- PR #189 (`2b74e32`) ergänzt Identitäts- und Einkaufssuchtests. Die PR-CI-Läufe
  `37989837352` und `37989841549`, Main-CI `37990310996` sowie Release
  `37990311009` waren mit Analyse, Tests, Web-/Pages-Build, Deployment und
  Android-APK erfolgreich.

## Update 09.10.2026 – Fleisch-, Käse- und Schoko-Reis-Labels bleiben getrennt
- Hähnchen-Käse-Ecken werden als Snack erkannt; Schoko-Reis-Tafeln bleiben
  Schokolade. Dadurch tauchen sie nicht als normale Käse- oder Reisprodukte
  in der Einkaufsliste auf.
- Schinkenkrustenbraten, Eisbein und Schnitzel bleiben Fleisch. Piccolinis
  werden als Pizza gefunden, ohne als Salami-Wurst in die Wurstsuche zu fallen.
- PR #191 (`b0a99dc`) ergänzt Identitäts- und Einkaufssuchtests. Die erfolgreichen
  PR-CI-Läufe `37992927870` und `37992934178`, Main-CI `37993296482` sowie
  Release `37993296407` waren mit Analyse, Tests, Web-/Pages-Build, Deployment
  und Android-APK erfolgreich.

## Update 09.10.2026 – Zusammengesetzte Wurst-Prospektlabels werden gefunden
- Prospektlabels wie „Grobe Bratwurst“, „Zwiebelmettwurst“ und „Leberwurst“
  werden jetzt generisch als Wurstfamilie erkannt. Dadurch erscheinen aktuelle,
  belegte Angebote auch bei einer einfachen Suche nach „Wurst“ in der
  Einkaufsliste.
- Ganze Wurst- und Schinkenkomposita werden erkannt, während Sonderfälle wie
  Fleischsalat getrennt bleiben und Käsesalami weiterhin als Wurst-Untertyp
  behandelt wird.
- PR #174 (`a015314`) ergänzt Identitäts- und Einkaufssuchtests. Die PR-CI-Läufe
  `37967975722` und `37967996937`, Main-CI `37968440727` sowie Release
  `37968440900` waren mit Analyse, Tests, Web-/Pages-Build, Deployment und
  Android-APK erfolgreich.

## Update 09.10.2026 – Zusammengesetzte Brot-Prospektlabels werden gefunden
- Prospektlabels wie „Weizenmischbrot“ und „Bauernbaguette“ werden jetzt
  generisch als Brot erkannt. Dadurch erscheinen aktuelle, belegte Angebote
  auch bei einer einfachen Suche nach „Brot“ in der Einkaufsliste.
- Die Erkennung bleibt konservativ: „Marzipanbrot“, „Brotzeit“ und
  Brotaufstriche werden nicht als normales Brot eingeordnet; bekannte
  Brotvarianten wie Mischbrot behalten ihren Typ.
- PR #176 (`1a7ab0d`) ergänzt Identitäts- und Einkaufssuchtests. Die PR-CI-Läufe
  `37971039385` und `37971054217`, Main-CI `37971501454` sowie Release
  `37971501681` waren mit Analyse, Tests, Web-/Pages-Build, Deployment und
  Android-APK erfolgreich.

## Update 09.10.2026 – Zusammengesetzte frische Salat-Prospektlabels werden gefunden
- Prospektlabels wie „Feldsalat“, „Romanasalat“ und „Salatherzen“ werden jetzt
  generisch als frische Salatfamilie erkannt. Dadurch erscheinen aktuelle,
  belegte Angebote auch bei einer einfachen Suche nach „Salat“ in der
  Einkaufsliste.
- Zubereitete Salate wie Feinkost-, Fleisch-, Kartoffel- und Nudelsalat sowie
  Salatgurken bleiben getrennt und liefern keine stillen Salatpreise.
- PR #178 (`30a7a8d`) ergänzt Identitäts- und Einkaufssuchtests. Die PR-CI-Läufe
  `37973902382` und `37973915491`, Main-CI `37974386063` sowie Release
  `37974386012` waren mit Analyse, Tests, Web-/Pages-Build, Deployment und
  Android-APK erfolgreich.

## Update 09.10.2026 – Zusammengesetzte Joghurt-Prospektlabels werden gefunden
- Prospektlabels wie „Almighurt“, „Obstgarten“ und „Frucht & Knusper“ werden
  jetzt als Joghurtfamilie erkannt. Dadurch erscheinen aktuelle, belegte
  Angebote auch bei einer einfachen Suche nach „Joghurt“ in der Einkaufsliste.
- Joghurt als Zutat in Frischkäsezubereitungen, Dressings, Dips und Saucen
  bleibt getrennt und liefert keinen stillen Joghurtpreis.
- PR #180 (`47d3614`) ergänzt Identitäts- und Einkaufssuchtests. Die PR-CI-Läufe
  `37977196606` und `37977202950`, Main-CI `37977679983` sowie Release
  `37977679931` waren mit Analyse, Tests, Web-/Pages-Build, Deployment und
  Android-APK erfolgreich.

## Update 09.10.2026 – Zusammengesetzte Butter-Prospektlabels bleiben getrennt
- Prospektlabels wie „Butterkäse“ und „Buttergemüse“ werden jetzt als Käse
  beziehungsweise Gemüse erkannt. Dadurch erscheinen ihre aktuellen,
  belegten Preise nicht bei einer einfachen Suche nach „Butter“.
- Normale Butter wie „Landliebe Butter oder Die Streichzarte“ bleibt in der
  Butterfamilie. Die Identität bleibt damit für Butterpreis und Routenplanung
  getrennt von Käse- und Gemüsepreisen.
- PR #182 (`f6884e4`) ergänzt Identitäts- und Einkaufssuchtests. Die PR-CI-Läufe
  `37979914225` und `37979930037`, Main-CI `37980376909` sowie Release
  `37980376915` waren mit Analyse, Tests, Web-/Pages-Build, Deployment und
  Android-APK erfolgreich.

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

## Update 08.10.2026 – Gelernte Bon-Aliase bleiben prüfbar
- Ein aus wiederkehrenden Bonzeilen gelernter Händleralias darf die Einkaufssuche
  weiterhin vorbefüllen, wird aber als „Gelernter Alias“ mit seiner bisherigen
  Bestätigungsanzahl angezeigt und bleibt bis zur ausdrücklichen Prüfung
  provisorisch.
- Die Vorbefüllung erzeugt dadurch weder eine bestätigte Produktidentität noch
  einen exakten Routenpreis oder eine neue Preisbeobachtung. Erst das bewusste
  Bestätigen der Zeile, die manuelle Produktauswahl oder das Anlegen eines neuen
  Produkts macht die Zuordnung für diese Preislogik nutzbar.
- Abwählen einer Vorschlagszeile entfernt den Vorbefüllungsmarker wieder. So
  bleibt der Review-Schritt reversibel und automatische Alias-Lernen kann keine
  stillen Fehlzuordnungen in die Sparroute übernehmen.
- PR #155 (`1da02a7`) ergänzt Fach- und Auswahlregressionen. PR-CI
  `37792946917` und `37792978661`, Main-CI `37793492647` mit 572 Tests sowie
  Release `37793492726` mit Web-/Pages- und Android-Artefakt waren erfolgreich.

## Update 09.10.2026 – Milch-Suche trennt Snacks
- Die veröffentlichte Suche hat `MILCH-SCHNITTE` bei der allgemeinen Eingabe
  „Milch“ als Treffer geführt. Die zentrale Produktidentität ordnet
  Milchschnitten jetzt der Snackfamilie zu, bevor die allgemeine Milchregel
  greift.
- Dadurch können Angebotspreise von Snacks weder die Milch-Empfehlung noch
  die Preisrangfolge für normale Milch beeinflussen. Die bestehende Suche nach
  konkreten Milchvarianten bleibt unverändert.
- PR #157 (`ea919c5`) ergänzt Identitäts- und Einkaufslistenregressionen.
  PR-CI `37859022514` und `37859038946`, Main-CI `37860539455` mit 574 Tests
  sowie Release `37860539475` mit Web-/Pages- und Android-Artefakt waren
  erfolgreich.

## Update 02.10.2026 – Lokales Backup für den Alltag
- Das Profil bietet jetzt „Lokales Backup exportieren“ und „Lokales Backup
  importieren“. Die Sicherung ist eine lesbare JSON-Datei und braucht keinen
  Server- oder Supabase-Zugang.
- Gesichert werden Listen und Listenpräferenzen, Budget, Mobilität,
  Preisdaten-Einstellungen, eigene Produkte, aktuelle Nutzerangebote,
  Marktpreise, Kauf-/Preisbeobachtungen, Bon-Aliase, bekannte Artikel,
  Markt-/Gangreihenfolge, Kachelansicht und vorhandene Routendaten.
- Import und Export bewahren Quelle, Nachweisreferenz, Angebotsgültigkeit,
  Mengenbasis und Vertrauensstatus. Der Import prüft Schema-Version, Datum,
  Zahlenbereiche und Datenformen strikt, bevor lokale Stores geändert werden.
- Originale Bondateien und Diagnoseprotokolle werden nicht kopiert;
  vorhandene Nachweisreferenzen bleiben erhalten. Der aktuelle Prospektfeed
  bleibt eine eigene, zeitabhängige Quelle und wird durch ein Backup nicht
  künstlich verlängert.
- PR #149 (`ee7dc9f`) ergänzte drei Fachtests und einen Widget-Test. PR-CI,
  Main-CI `37010345548` und Release `37010345631` waren mit 568 Tests,
  Analyse, Web-Build, Pages-Deployment und Android-APK erfolgreich.

## Update 02.10.2026 – Bonledger mit Zwischensumme und Warenkorbrabatt
- Eine lokale Kaufland-Bonprüfung mit einer Zwischensumme und einem
  separaten Warenkorbrabatt wurde gegen den Ledger simuliert: Die gedruckte
  und die berechnete Summe stimmen überein, ohne ungeklärte Ledgerzeilen.
- `Zwischensumme` wird nicht als Produkt oder Preisbeobachtung übernommen.
  Der separate `Rabattaktion`-Block bleibt ein Warenkorbrabatt ohne stille
  Zuordnung zum letzten Produkt.
- Mehrfachmengen, Pfand, Leergutrückgabe, XTRA-Artikelrabatte und die zwei
  getrennten `K.H-Milch`-Zeilen bleiben als eigene, prüfbare Ledgerdaten
  erhalten. Die Produktidentität und Preisbestätigung bleiben weiterhin ein
  separater Review-Schritt.
- Die private Quelldatei wurde nur lokal geprüft und nicht in das Repository
  oder eine Test-Fixture kopiert. PR #151 (`3690251`) ergänzt die Regression;
  Main-CI `37013615016` und Release `37013614899` waren mit 568 Tests,
  Analyse, Web-Build, Pages-Deployment und Android-APK erfolgreich.

## Update 02.10.2026 – Prospekt-Datenabdeckung je Markt
- Die Prospektansicht zeigt jetzt eine aufklappbare Abdeckungskarte für alle
  sichtbaren Märkte. Sie trennt strukturierte Angebotszeilen, Prospektbildseiten,
  Produktbilder, Kategorien sowie Filial-ID, Ort, Adresse und Gültigkeitszeitraum.
- Die Zählung verwendet nur die bereits datumsgefilterten aktuellen Datensätze
  und den ausgewählten Prospektstand. Fehlende Quellfelder bleiben als Lücke
  sichtbar; daraus werden weder Preise noch Produktidentitäten abgeleitet.
- PR #153 (`0debc98`) ergänzt Fach- und Widgetregressionen. PR-CI,
  Main-CI `37017836279` und Release `37017836256` waren einschließlich
  Pages-Deployment und Android-APK erfolgreich.

## Update 02.10.2026 – Exakter Preisverlauf im Listenartikel
- Der Preisdialog eines Einkaufslistenartikels bietet jetzt einen eigenen
  „Preisverlauf“. Er zeigt bestätigte, exakt derselben Produkt-ID zugeordnete
  Beobachtungen mit Markt, Quelle, Angebots-/Normalpreisart, Beobachtungsdatum,
  Preis und optionalem Gültigkeitsende.
- Provisorische oder nur familienweit zuordenbare Beobachtungen werden aus
  diesem exakten Verlauf herausgehalten. Abgelaufene Beobachtungen bleiben als
  Historie sichtbar, werden aber nicht als aktueller Regal- oder Routenpreis
  dargestellt.
- Aktive Angebote, aktuelle Bon-/eigene Preise und historische Prospektmediane
  behalten ihre bestehende Rangfolge. Der Verlauf ist Evidenzansicht und ändert
  keine Planungswerte.
- PR #145 (`89fec09`) ergänzt Fach- und Widget-Regressionen. Main-CI
  `37002100088` und Release `37002100094` waren mit 564 Tests, Analyse,
  Web-Build, Pages-Deployment und Android-APK erfolgreich.

## Update 02.10.2026 – Evidenzdetails im exakten Preisverlauf
- Der exakte Preisverlauf zeigt zusätzlich Menge, Einheit und einen vorhandenen
  Grundpreis. So bleibt die Packungsbasis für die Sparentscheidung sichtbar.
- Jede Zeile kennzeichnet außerdem, ob eine Nachweisreferenz hinterlegt ist;
  der Referenzwert selbst wird nicht als privater Dateipfad in die Oberfläche
  übernommen.
- Die Darstellung bleibt rein erklärend. Sie verändert weder Angebotsrangfolge
  noch aktuelle Marktpreise oder Routenwerte.
- PR #147 (`a987274`) ergänzt die UI- und Fachregressionen. Main-CI
  `37005197693` und Release `37005197686` waren mit 564 Tests, Analyse,
  Web-Build, Pages-Deployment und Android-APK erfolgreich.

## Update 02.10.2026 – Provisorische Bonartikel bleiben preisfrei
- Automatisch angelegte `receipt_auto_*`-Produkte bleiben in der Einkaufssuche
  sichtbar und werden mit „Früher gekauft · Sorte und Packung prüfen“ markiert.
- Die Bonpreisstatistik führt jetzt die Identitätsbestätigung mit. Unbestätigte
  automatische Zuordnungen erzeugen weder einen historischen Suchmedian noch
  einen Preis im Variantenfenster oder im Preis-Hinweis der Einkaufsliste.
- Bestätigte Produktzuordnungen und reine, generische Familienbeobachtungen
  bleiben für die jeweils passende Preislogik nutzbar; Preise werden nicht
  gelöscht, sondern bis zur Bestätigung aus den konkreten Empfehlungen
  herausgehalten.
- PR #135 (`3a0dbc3`) ergänzte drei Regressionen. Beide PR-CI-Läufe mit 556
  Tests, Analyse und Web-Build waren erfolgreich.

## Update 02.10.2026 – Korrigierte Bonzuordnung wird als Änderung erkannt
- `ReceiptObservationStore.addMany` zählt neben neuen Beobachtungen jetzt auch
  echte Änderungen, zum Beispiel die nachträgliche Bestätigung eines zuvor
  provisorischen Bonartikels.
- Ein unveränderter erneuter Import bleibt bei null Änderungen; dadurch werden
  Wiederholungen nicht als neue Lernbelege gezählt.
- Der Importdialog kann eine korrigierte Zuordnung auch dann erfolgreich
  abschließen, wenn daraus wegen fehlender Packungssemantik noch kein direkter
  Marktpreis entsteht.
- PR #137 (`bbf6332`) ergänzt die Persistenzregressionen. Beide PR-CI-Läufe
  mit 558 Tests, Analyse und Web-Build waren erfolgreich.

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

## Update 02.10.2026 – Eindeutige Bon-Aliase vor Variantenfamilien
- Das Bon-Review berücksichtigt Produktnamen und gelernte Aliase jetzt als
  exakte Identitätsbelege.
- Ein eindeutiger Alias (z. B. `K.H-Milch`) gewinnt vor kompatiblen
  Geschwistervarianten; widersprüchliche exakte Aliase bleiben offen.
- Unbestätigte automatische Zuordnungen werden dadurch weiterhin nicht zu
  direkten Routenpreisen.
- PR #131 (`d5ac287`) ergänzt zwei Fachregressionen. PR-CI mit 550 Tests,
  Analyse und Web-Build; Main-CI `36981928067` und Release-Lauf
  `36981927972` waren nach dem Merge erfolgreich.

## Update 02.10.2026 – Bon-Simulation trennt Produktvarianten
- Die bereitgestellte Kaufland-PDF wurde lokal mit dem Ledger geprüft: 78
  Artikelzeilen, ausgeglichene Summe und erkannter Bon vom 26.05.2026.
- `Pizza-Donut Schin.` bleibt getrennt von Tiefkühlpizza und wird als
  schinkenhaltige Backware vorgeschlagen.
- `KLC.Kn.Mäuse Salz` wird nicht mehr als Kartoffelchip identifiziert; der
  belegte Produktname bleibt als eigene Knabbermäuse-Identität auswählbar.
- Passata und gehackte Tomaten tragen getrennte Identitätsvarianten, sodass
  ihre Bonpreise unabhängig gelernt werden können. Die zwei unklaren
  `bev...`-Labels bleiben zur Prüfung offen.
- PR #133 (`4272ab3`) ergänzt die Identitäts- und Bon-Review-Regressionen.
  PR-CI mit 553 Tests, Analyse und Web-Build; Main-CI `36985426027` und
  Release-Lauf `36985426094` waren nach dem Merge erfolgreich.

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
- Lernendes Produktmatching, Alias-/Zuordnungswissen und Review-Signale weiter
  ausbauen; bestätigte und unsichere Identitäten bleiben getrennt.
- Preisbeobachtungen stärker von Produktstammdaten trennen.
- Confidence-/Review-Logik für unsichere Zuordnungen ausbauen.
- Wiederkehrende Käufe für schnellere, zuverlässigere Zuordnung nutzen.
- Native Geräteabnahme für Kamera, lokale Bild-OCR, Neustart und Offlinebetrieb
  durchführen.
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

## Update 02.10.2026 – Aktuelle Sparvariante in der Produktsuche markieren
- Die normale Einkaufssuche kennzeichnet bei mehreren passenden Varianten die
  erste aktuell belegte Sparvariante sichtbar als „Empfehlung“.
- Eine aktive Angebots-, eigene Marktpreis- oder aktuelle Bonpreis-Evidenz
  darf die Markierung auslösen. Ein historischer Prospektmedian bleibt eine
  Orientierung und wird nicht zur stillen Produktauswahl.
- Die Identitäts- und Preisrangfolge bleibt unverändert; der Hinweis macht die
  bereits angewendete Angebotspriorität im Eingabefluss nachvollziehbar.
- PR #129 (`8f45121`) ergänzt Such-, Widget- und Screenregressionen. Die
  PR-CI bestand mit 548 Tests, Analyse und Web-Build; Main-CI `36979865886`
  und Release `36979865819` sind nach dem Merge erfolgreich, einschließlich
  Pages-Deployment und Android-APK.
- Der veröffentlichte Web-Smoke mit `?v=903a10c` zeigt bei „Milch“ die
  PENNY-Frischmilch für 0,99 € als „Empfehlung“ vor getrennten H-Milch- und
  Fettstufenvarianten.

## Update 02.10.2026 – Strukturierte Prospektdatenlücke sichtbar
- Ein aktuell gültiger, durchblätterbarer Prospekt ohne ausgelesene
  strukturierte Angebotsdaten wird in der Prospektkarte jetzt ausdrücklich als
  „Keine aktuell gültigen Angebotsdaten geladen“ gekennzeichnet.
- Die offiziellen Seiten und der Händlerlink bleiben dabei erreichbar; die
  Statusanzeige behauptet keine geladenen Preise, wenn nur die Quelle vorliegt.
- PR #139 (`f5c118b`) ergänzt die Widgetregression für diesen Fall. Die PR-CI
  bestand mit 558 Tests; Main-CI und Release-Artefakte sind nach dem Merge
  einschließlich Pages-Deployment und Android-APK grün.

## Update 02.10.2026 – Prospektlernen verlangt einen Feed-Zeitstempel
- Prospektpreise werden nur noch dann in die historische Preisbeobachtung
  übernommen, wenn der Feed einen `generatedAt`-Zeitpunkt liefert.
- Fehlt dieser Provenienznachweis, bleiben aktuelle Angebote sichtbar, werden
  aber nicht mit der Ladezeit als frisch gelernt markiert.
- PR #141 (`34d8590`) ergänzt die Regression für einen Feed ohne Zeitstempel.
  Die PR-CI bestand mit 558 Tests; Main-CI und Release-Artefakte sind nach dem
  Merge einschließlich Pages-Deployment und Android-APK grün.

## Update 02.10.2026 – Fallbackangebote werden nicht frisch gelernt
- Angebotszeilen eines Marktes, dessen Quelle im Feed nicht erfolgreich
  aktualisiert wurde, bleiben als geprüfter Fallback sichtbar.
- Für die Preis-Historie werden sie nicht mit dem globalen Feed-Zeitpunkt als
  neue Beobachtung datiert; gelernt werden nur Datensätze der erfolgreich
  aktualisierten Märkte.
- PR #143 (`f7d3fc2`) ergänzt die Regression für frische und nicht aktualisierte
  Märkte. Die PR-CI bestand mit 558 Tests; Main-CI und Release-Artefakte sind
  nach dem Merge einschließlich Pages-Deployment und Android-APK grün.




## Update 13.10.2026 – Marktvergleich im Preise-Reiter schrittweise laden
- [x] Große Einkaufslisten bauen zunächst nur zwölf Preisvergleichskarten; weitere Positionen werden bewusst über „Weitere Preisvergleiche laden“ nachgeladen.
- [x] Aktuelle Preisabdeckung, historische Hinweise und unbekannte Preise bleiben vollständig berechnet und unverändert sichtbar.
- [x] Der Preis-Reiter verwendet keinen zusätzlichen Cache-Vorrat für Offscreen-Karten; dadurch bleiben Scrollen und Expansion bei langen Listen reaktionsfähig.
- [x] Widgetregression prüft das Nachladen der dreizehnten Position.


## Update 13.10.2026 – Fehlende Preise direkt aus dem Preise-Reiter auflösen
- [x] Jede aufgeklappte Marktvergleichskarte kann eine fehlende aktuelle Evidenz direkt an die bestehende Preis-/Produktauswahl übergeben.
- [x] Die Auflösung verwendet weiterhin `PriceGapPriority` mit exakter Listenposition und sichtbarer Zahl fehlender Märkte; kein Preis wird geschätzt.
- [x] Der Shell-Callback nutzt denselben Editorpfad wie Einkaufsliste und Route.
- [x] Widgetregression prüft Produktidentität und Marktanzahl des übergebenen Datenlückenobjekts.


## Update 13.10.2026 – Routenoptimierer bei stabilen UI-Rebuilds wiederverwenden
- [x] Der Route-Reiter hält den `RouteOptimizer` für unveränderte Listen-, Angebots-, Preis-, Mobilitäts- und Streckenreferenzen wieder.
- [x] Eine neue Preis-/Angebotsreferenz, ein neuer Streckenstand oder ein Tageswechsel invalidiert den Snapshot; dadurch bleiben Angebotsgültigkeit und Preisalter korrekt.
- [x] Die Optimierungsfachlogik bleibt unverändert; nur die wiederholte Konstruktion bei UI-Rebuilds entfällt.
- [x] Die bestehende Route-Planungs-Cache-Regression bleibt die fachliche Absicherung der stabilen Ergebniswiederverwendung.


## Update 14.10.2026 – Einkaufsliste mit vielen Warengruppen schrittweise rendern
- [x] Der Listen-Reiter baut zunächst acht Warengruppen und lädt weitere Gruppen über eine sichtbare Aktion nach.
- [x] Gruppenreihenfolge, Artikel, Preisbelege, Angebote und Kaufaktionen bleiben unverändert; nur der Renderumfang des ersten Frames ist begrenzt.
- [x] Der Offscreen-Scrollcache der langen Liste ist deaktiviert, damit weniger nicht sichtbare Karten vorgebaut werden.
- [x] Widgetregression prüft das Nachladen der neunten Gruppe.


## Update 14.10.2026 – Prospektimport speichert automatisch nur reguläre Preise
- [x] Der automatische Feed-Lernpfad verwendet jetzt ausschließlich Beobachtungen mit belegtem originalPrice/Streichpreis (PriceObservationKind.regular).
- [x] Der zeitlich befristete Angebotspreis bleibt im aktuellen OfferStore und wird nicht zusätzlich als automatische Preis-Historie gespeichert.
- [x] Angebotszeilen ohne regulären Preis bleiben für die Angebotsansicht verfügbar, erzeugen aber keine reguläre Datenbankbeobachtung.
- [x] Identität, Filiale, Packungsgröße, Quelle, Nachweis, Erfassungszeit und Angebotszeitraum werden beim regulären Preis unverändert mitgeführt.
- [x] Bestehende historische Beobachtungen werden additiv bewahrt; der neue Importpfad löscht keine lokalen Daten.
- [x] Regression prüft regulären Preis, Angebotspreis und offer-only Zeile getrennt.

## Update 14.10.2026 – Browser-Speicher beim Prospektimport geschützt
- [x] Automatische externe Preisbeobachtungen werden lokal mit einem begrenzten Verlauf pro Produkt-/Markt-/Quellschlüssel gespeichert.
- [x] Bei einem bereits übergroßen Bestand wird beim nächsten Preisimport zuerst eine normale Verdichtung und bei einem Browser-Quota-Fehler ein kleinerer Wiederherstellungsversuch ausgeführt.
- [x] Bon-, manuelle und andere nutzernahe Belege bleiben von dieser automatischen Verdichtung ausgeschlossen.
- [x] Die Prospektanzeige und der Live-/Cache-Fallback bleiben unabhängig von einem lokalen Preis-Historien-Schreibfehler.
- [x] Eine Regression simuliert `QuotaExceededError` und prüft, dass die neuesten automatischen Daten verdichtet und Bonbelege erhalten bleiben.
## Update 14.10.2026 – Hauptreiter behalten ihren Zustand
- [x] Besuchte Hauptreiter bleiben in einem `IndexedStack` gemountet; noch nicht besuchte Reiter werden weiterhin lazy als Platzhalter angelegt.
- [x] Prospektsuche, Scrollposition und Routen-/Belegcontroller werden beim Wechsel zwischen Liste, Prospekte und Preise nicht mehr verworfen.
- [x] Regression prüft, dass die Prospektsuche nach einem Wechsel in die Einkaufsliste erhalten bleibt.



## Update 15.10.2026 – Selektiver Cover-Fallback bei Canvas-/CORS-Problemen

- [x] Coverkarten verwenden weiterhin den Canvas-first-Pfad mit begrenzter Decode-Größe, damit schnelles Scrollen keine Plattform-Views pro Karte erzeugt.
- [x] Nur ein Bild, dessen Canvas-Decodierung tatsächlich fehlschlägt, wechselt einmalig auf den HTML-Fallback; erfolgreiche Cover bleiben im schnellen Pfad.
- [x] Favoritenrail und Coverraster teilen dieselbe begrenzte Decode-Größe und vermeiden dadurch doppelte Bildcache-Einträge.
- [x] Der Angebote-Widgettest schützt Coverdarstellung und Seitenansicht.

## Update 15.10.2026 – Vollständiger Prospekt-Seitenimport für Issue #409
- [x] Die offiziellen Katalogquellen werden seitenvollständig eingelesen und
  nicht mehr auf die Coverseite reduziert: ALDI Süd (36), EDEKA (40),
  Kaufland Lebensmittelprospekt (72), Lidl je Kampagne (vollständige
  Publisher-Seitenliste) und Netto (aktueller Publitas-Katalog).
- [x] Kaufland trennt das parallel veröffentlichte `-OD`-Drogerieblatt vom
  Lebensmittelprospekt; die Lebensmittelkampagne wird bei identischer
  Gültigkeit bevorzugt. Ein Cover-only-Fallback bleibt sichtbar, wenn keine
  weitergehende öffentliche Seite nachweisbar ist.
- [x] Lidl-Kampagnen werden nach Händlerkampagne dedupliziert, statt mehrere
  regionale Kopien als dieselbe Filialausgabe zu zählen. Dictionary-basierte
  Publisher-Produktlisten werden in der Seitenabdeckung korrekt gezählt.
- [x] Netto und ALDI verwenden `data.json`/`spreads.json` nur mit dem vom
  Publisher gelieferten `cacheToken`; fehlende Seiten werden als `partial`
  ausgewiesen und niemals ergänzt.
- [x] Jeder Prospekt führt jetzt `pageCount`, `loadedPageCount`,
  `missingPageNumbers`, `pageStatus`, `pageCountKnown` und die Seitenquelle.
  Die Abdeckungskarte zeigt geladene/angekündigte Seiten und fehlende Seiten;
  fehlende Unsicherheitszahlen werden ausdrücklich als nicht ausgewiesen
  markiert.
- [x] PENNY bleibt bei der nachweisbaren Coverseite, weil der öffentliche
  Händlerstand keinen vollständigen Seitenkatalog bereitstellt. Es werden
  keine Seiten oder Artikel aus dem Cover erfunden.
- [x] Ein Refresh hält gültige Lidl-Angebote aus dem letzten geprüften Feed,
  wenn nur der unabhängige Filial-Endpunkt temporär ausfällt. Der originale
  Erfassungszeitpunkt bleibt dabei erhalten.
- [x] Der lokale Prospektcache ersetzt weiterhin genau einen Feed-Eintrag und
  lehnt UTF-8-Inhalte über 4 MiB ab. Die App bleibt bei Cachefehlern mit Live-
  oder Bundle-Feed funktionsfähig.
- [x] Die Seitenmetadaten werden beim Filial-Resolver und im Feed-Fingerprint
  erhalten, damit ein vollständigerer Katalog erneut verarbeitet wird.

## Update 15.10.2026 – Bonpreisauflösung bis zur Route verbessert
- [x] Bestätigte Händlerprodukt-IDs überbrücken abweichende oder unleserliche
  Bon-/OCR-Labels, ohne die Packungs- und Mengenumrechnung zu umgehen.
- [x] Gespeicherte Familien-Identitäten werden bei unleserlichem Label als
  Familienpreis verwendet; unsichere automatische Produkt-IDs bleiben aus der
  Routenprojektion ausgeschlossen.
- [x] Ein erkennbares spezifisches Label bleibt stärker als veraltete
  Familienmetadaten, insbesondere bei der Trennung von Tomatenmark und frischen
  Tomaten.
- [x] Regressionen prüfen die Übernahme über `receiptFamilyMarketPrices`,
  `planningMarketPrices` und `RouteOptimizer`.

## Update 15.10.2026 – Branchlose Prospektpreise bleiben historische Evidenz

Der zentrale `PriceObservation → MarketPrice`-Adapter verwirft reguläre
Prospektbeobachtungen ohne exakte Filial-ID bereits vor der Marktpreisprojektion.
Damit können alte oder direkt importierte branchlose Datensätze weiterhin für
Nachvollziehbarkeit und Statistik geladen werden, aber nicht als aktueller
Routenpreis dienen. Nicht-prospektbezogene manuelle, Bon- und andere Quellen
behalten ihre bisherigen Projektionsregeln.

## Update 15.10.2026 – Preisfelder aus Händlerfeeds konservativ normalisiert

Der Dart-Feedparser akzeptiert für Aktionspreise jetzt neben JSON-Zahlen auch
strikt formatierte deutsche Preisangaben mit `€` oder `EUR`. Reguläre Preise
können zusätzlich aus begrenzten, benannten Preisobjekten gelesen werden.
Freie Beschreibungen und nackte Zahlenstrings bleiben ungültig. Dadurch gehen
verwertbare Händlerangebote nicht mehr nur wegen ihrer Darstellungsform verloren,
ohne dass beliebige Quellzahlen zu Preisbelegen werden.


## Update 16.10.2026 – Veraltete reguläre Prospektpreise nach Refresh gesperrt

- [x] Ein bestätigter Händler-Refresh markiert reguläre Beobachtungen, die im
  aktuellen Feed fehlen, als nicht aktuell und behält sie für Historie und
  Nachvollziehbarkeit.
- [x] Nicht aktuelle automatische Prospektbeobachtungen werden weder in
  MarketPrice noch in Route und Preisvergleich projiziert; fehlende Preise
  bleiben unbekannt.
- [x] Die Reconciliation ist auf ausdrücklich aktualisierte Händler begrenzt;
  Offline-/Fehlerläufe ohne bestätigten Refresh verändern keinen Preisbestand.
- [x] Regressionen prüfen entfernte Artikel, unberührte Händler, JSON-Abwärts-
  kompatibilität und den unveränderten Normalpreis-/Aktionspreisvertrag.


## Update 16.10.2026 – Preise-Ledger respektiert aktuelle Reconciliation

- [x] Der Preise-Reiter blendet als historisch markierte reguläre Prospektbelege
  aus der Liste „Aktuelle gespeicherte Normalpreise“ aus.
- [x] Historische Preisstatistik bleibt unverändert verfügbar; nur die
  aktuelle Ledger-Projektion folgt jetzt demselben isCurrent-Vertrag wie
  Route und MarketPrice.
- [x] Eine Widget-/Fachregression schützt den Fall eines nach Refresh
  supersedierten, weiterhin gültigen Belegs.
