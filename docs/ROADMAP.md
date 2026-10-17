## Update 17.10.2026 – Preisqualitätslücken und Filialabdeckung

- [x] Nicht routenfähige Preisbelege im Preise-Reiter nach einem primären Grund ausweisen.
- [x] Aktuelle Belege zusätzlich anhand der belegten Filial-ID gruppieren.
- [x] Regressionen für Frische, Identität, Mengenbasis, Vertrauensstufe und Filialdarstellung ergänzen.

## Update 17.10.2026 – Atomarer Preis-Snapshot für Planung

- [x] Beobachtungssnapshot aus Einzelpreis, Batch und Open Prices im Coordinator zurückgeben.
- [x] Beobachtung, aktuellen Marktpreis und Verlauf gemeinsam in den Shell-Stand übernehmen.
- [x] Regressionen für Einzel-, Batch- und Open-Prices-Belege ergänzen; Angebotsrollen bleiben getrennt.

## Update 17.10.2026 – Bekannte Produktdaten in der Einkaufsliste

- [x] Exakte Produkt-IDs nach Listenladen und Prospekt-Refresh gegen den lokalen Katalog abgleichen.
- [x] Produktmetadaten aktualisieren, ohne Menge, Notiz oder Abhakstatus zu verlieren.
- [x] Keine Ersetzung bei unbekannten oder mehrdeutigen IDs; Regression für den Metadaten-Refresh ergänzen.

## Update 17.10.2026 – Produktmetadaten in lokalen Listen

- [x] Legacy-Listen speichern die vorhandenen Produktfelder vollständig.
- [x] Alte Listen ohne optionale Felder bleiben rückwärtskompatibel.
- [x] Der Scan-to-List-Regressionstest prüft Marke, Packungsgröße, Aliase und Bild nach dem Neustart.

## Update 17.10.2026 – Preisqualität in Matrix und Highlight vereinheitlicht

- [x] Gleich bewertete aktuelle Nicht-Angebotspreise zuerst nach Beobachtungsalter auswählen.
- [x] Quellenpriorität nur nach Qualität und Aktualität als Tie-Breaker verwenden.
- [x] Hervorgehobenen Einkaufslistenpreis und Marktzeile über denselben Comparator führen.
- [x] Regression für Matrix und hervorgehobenen Preis ergänzen.

## Update 17.10.2026 – Prospekt-/Angebotsstatus beschleunigt

- [x] Regulären Preiszähler im bestehenden Prospekt-Derived-Snapshot halten.
- [x] Statushinweise der Angebotsansicht mit eigenem Listen-/Tages-Schlüssel cachen.
- [x] Coverauswahl und Statushinweise getrennt invalidieren.

## Update 17.10.2026 – Einkaufsvorschläge beschleunigt

- [x] Wiederholte Vorschlagsberechnung während eines UI-Rebuilds memoisierten.
- [x] Verwandte Interpretationen an den identischen Vorschlagssnapshot binden.
- [x] Tageswechsel sowie alle preis- und produktrelevanten Eingangslisten als Cachegrenzen verwenden.
- [x] Bestehende Eingabe-, Preis- und Identitätsregressionen über die vollständige CI ausführen.

## Update 17.10.2026 – Routenberechnung beschleunigt

- [x] Wiederholte Fahrtrouten pro `RouteOptimizer`-Snapshot cachen.
- [x] Filialidentität und `distanceKm` in die Cache-Signatur aufnehmen.
- [x] Fallback-Reihenfolge und deterministische Straßenmatrix-Auswahl unverändert lassen.
- [x] Regression für wiederholte Fahrtrouten ergänzen.

## Update 17.10.2026 – Prospektfavoriten ohne lineare Wiederholungssuche

- [x] Favoritenschlüssel für Coveransicht und Prospektübersicht als lokalen Set-Index halten.
- [x] Exakte Branch-Favoriten und Legacy-Händlerfavoriten unverändert auflösen.
- [x] Regression für Branch-Isolation, Legacy-Fallback und falsche Händlerzuordnung ergänzen.

## Update 17.10.2026 – KaufDA-Abfragen beschleunigt

- [x] Öffentliche KaufDA-Suchseiten werden in einer kleinen, konfigurierbaren
  Batch vorab geladen.
- [x] Parser, Cache, Fehlerfallback und Ergebnisreihenfolge bleiben
  deterministisch; Test-/Offline-Fetcher bleiben seriell.
- [x] Die KaufDA-Quelle bleibt opt-in und zwischen Batches rate-limitiert.

## Update 17.10.2026 – Reguläre Prospektpreise bleiben von Angebotspreisen getrennt

- [x] Der Preise-Reiter zählt aktuelle importierte Angebotspreise ohne belegten
  Normalpreis separat.
- [x] Die Anzeige macht sichtbar, dass diese Angebotspreise nicht in die
  reguläre Preisbasis geschrieben werden.
- [x] Die bestehende Speicherung von Streichpreisen, Filiale, Gültigkeit und
  Quellenbeleg bleibt unverändert.

## Update 17.10.2026 – Preise-Reiter aktualisiert Prospektpreise auf Wunsch

- [x] Der Preise-Reiter kann den aktuellen Prospektfeed direkt anstoßen.
- [x] Der Refresh verwendet weiterhin den bestehenden automatischen
  Persistenzpfad und speichert nur ausdrücklich belegte reguläre Normalpreise.
- [x] Aktionspreise bleiben getrennt; Filial-, Gültigkeits- und Quellenbeleg
  werden unverändert durch die Preisbeobachtung erhalten.

## Update 17.10.2026 – Preise-Reiter verarbeitet neue Preisstände

- [x] Quote-Cache von Eingangssignatur und Ergebnis-Signatur trennen.
- [x] Neue Marktpreise nach einem Prospektrefresh sofort im Preise-Reiter
  anzeigen.
- [x] Änderungen an gespeicherten regulären PriceObservations in die
  Snapshot-Invalidierung einbeziehen.
- [x] Widget-Regression für einen Preiswechsel ergänzen.

## Update 17.10.2026 – Filialscharfer Prospekt-Refresh

- [x] Erfolgreiche Quellrefreshes als ProspectRefreshScope mit Branch-ID
  weiterreichen.
- [x] Automatische reguläre Prospektpreise nur innerhalb des bestätigten
  Filial-Scopes lernen und reconciliieren.
- [x] Legacy-Aufrufer mit refreshedStores kompatibel halten.
- [x] Regressionen für zwei gleichnamige Filialen mit unterschiedlichem
  Refreshstatus ergänzen.

## Update 17.10.2026 – Händlerlabel-Varianten im Routenfilter

- [x] Aktivierte Märkte über den gemeinsamen Präsentationsschlüssel filtern.
- [x] LIDL/Lidl und ALDI SUED/ALDI Süd mit einer Regression absichern.
- [x] Exakte Filialidentität und Branch-IDs unverändert lassen.

## Update 17.10.2026 – Coverage bei Händler-Schreibvarianten

- [x] Issues und Angebotszeilen über den gemeinsamen Match-Schlüssel zusammenführen.
- [x] Persistierte Branch-Zähler auch bei abweichender Händler-/Branch-Schreibweise auflösen.
- [x] Coverage-Regression für LIDL/Lidl ergänzen.
## Update 17.10.2026 – Coverübersicht gruppiert Schreibvarianten

- [x] Coverkarten über den normalisierten Händler-/Filialschlüssel deduplizieren.
- [x] Händlerfilter bei abweichender Schreibweise zusammenführen.
- [x] Regression für LIDL/Lidl ergänzen.
## Update 17.10.2026 – Händler-Schreibvarianten in Angebotsquellenhinweisen

- [x] Quellhinweise über den gemeinsamen Händlervergleichsschlüssel zuordnen.
- [x] Regionalstatus bei abweichender Schreibweise sichtbar halten.
- [x] Widget-Regression für LIDL/Lidl ergänzen.
## Update 17.10.2026 – KaufDA-Branchschutz

- [x] Geerbte KaufDA-Adapterkennung ohne explizite Angebots-Filiale regional markieren.
- [x] Quellen-Filialmetadaten nicht als exakten KaufDA-Nachweis verwenden.
- [x] Parser-Fixture für den routegesperrten Regionalfall ergänzen.

## Update 17.10.2026 – Prospektpreise mit Datensatz-Zeitpunkt speichern

- [x] Einen belegten `capturedAt`-Zeitpunkt als Fallback für fehlendes Feed-`generatedAt` verwenden.
- [x] Zeitlose Datensätze weiterhin aus der automatischen Preisbasis ausschließen.
- [x] End-to-End-Regression für Lernen, Speicherung und regulären Preis ergänzen.

## Update 17.10.2026 – Strukturierte Kategoriepfade

- [x] Listenförmige und verschachtelte Kategoriepfade aus bekannten Feedfeldern normalisieren.
- [x] Kategoriepfade begrenzen, deduplizieren und für den bestehenden Non-Food-Filter verwenden.
- [x] Lebensmittel- und Non-Food-Regression mit anonymisiertem Fixture ergänzen.

## Update 17.10.2026 – Verschachtelte Angebotsgültigkeit

- [x] Bekannte verschachtelte Gültigkeitscontainer für Prospektseiten und Angebote normalisieren.
- [x] Fehlende, ungültige und widersprüchliche Datumswerte weiterhin konservativ verwerfen.
- [x] Gültigen Zeitraum und malformed Gegenprobe als Parser-Fixture testen.

## Update 17.10.2026 – Verschachtelter Filialnachweis

- [x] Bekannte verschachtelte Filialobjekte in Feed-Quelle, Prospekt und Angebot normalisieren.
- [x] Branch-ID, Ort und Adresse getrennt erhalten und bei mehreren gleichnamigen Filialen nicht vermischen.
- [x] Regression für exakte Filialzuordnung und Prospektseiten-Kontext ergänzen.

## Update 17.10.2026 – Verschachtelte Prospektbild-Aliase

- [x] Häufige Thumbnail-, Cover- und Original-URL-Aliase in bekannten Bildobjekten auflösen.
- [x] Bildauflösung weiterhin auf absolute HTTP(S)-URLs und feste Rekursionstiefe begrenzen.
- [x] Verschachteltes `images[].thumbnailUrl` mit einem Parser-Fixture testen.

## Update 17.10.2026 – Artikelbilder aus öffentlichen Listenfeldern

- [x] Produktbilder aus begrenzten öffentlichen Listenformaten (`images`, `imageUrls`, `productImages`, `media`, `assets`) auflösen.
- [x] Nur absolute HTTP(S)-URLs übernehmen und Produktbild-Provenienz im bestehenden Importmodell beibehalten.
- [x] Regressionstest für verschachtelte Listen- und `src`-Felder ergänzen.

## Update 17.10.2026 – OCR trennt Dezimalstellen nicht mehr falsch

- [x] OCR-Geldtokens mit Leerraum um Komma oder Punkt werden normalisiert.
- [x] Der Euro-/EUR-Marker bleibt zwingend; unmarkierte Seiten- und Packungszahlen werden nicht zu Angeboten.
- [x] Angebot und Vorher-Preis behalten ihre getrennte Evidenz.


## Update 17.10.2026 – Prospekt-OCR toleriert Währungsformatvarianten

- [x] Währung vor oder nach dem OCR-Betrag wird erkannt.
- [x] Bare Zahlen ohne Euro-/EUR-Marker bleiben aus konservativer Angebotsdetektion ausgeschlossen.
- [x] Mehrere Beträge pro Zeile werden weiterhin als Angebot plus ausdrücklich erkannten Vorher-Preis getrennt.
## Update 17.10.2026 – Route-Suche erhält eine harte Marktgrenze

- [x] `RouteOptimizer` übernimmt nur noch Werte zwischen 1 und `maximumSupportedRouteStores`.
- [x] Überhöhte Konfigurationen werden vor der Kombinationserzeugung sicher begrenzt.
- [x] Die vorhandenen Mehrmarkt- und Tie-Breaker-Regressionen bleiben unverändert.
## Update 17.10.2026 – Preis-Reconcile trennt aktuelle und historische Werte

- [x] Preisänderungen im gleichen Produkt-/Filial-Slot historisieren den alten regulären Beleg.
- [x] Die neue Beobachtungs-ID bleibt aktuell; unveränderte IDs werden weiterhin nur aktualisiert statt dupliziert.
- [x] Die Regression prüft, dass die lokale Projektion nach einer Preisänderung genau einen aktuellen Wert behält.
## Update 17.10.2026 – Bonauflösung schlägt kompatible Identitäten vor

- [x] Nicht generische Belegbezeichnungen verwenden die zentrale Produktidentität für Kandidatenvorschläge.
- [x] Varianten und Packungsgrößen bleiben als prüfpflichtige Kandidaten sichtbar; kein Vorschlag wird automatisch bestätigt.
- [x] Fachlich getrennte Familien wie frische Tomaten und Passata werden aus den primären Treffern ausgeschlossen.
- [x] Generische Kategorien behalten ihre bisherige Kategorieauflösung.
## Update 17.10.2026 – Open-Prices-Sync wird bei großen Katalogen sparsamer

- [x] Kandidaten mit derselben Produkt-ID werden vor externen Abfragen dedupliziert.
- [x] Der Live-Abgleich bündelt externe Open-Prices-Anfragen in einer kleinen,
  deterministischen Batch und hält Fortschritt sowie Fehlerliste in
  Katalogreihenfolge; eingespritzte Test-/Offline-Fetcher bleiben seriell.
- [x] Abbruchsignale greifen bereits in der optionalen Barcode-/Produktentdeckung.
- [x] Die bestehende Identitätsgrenze für entdeckte EANs und der lokale Cache bleiben unverändert.


## Update 17.10.2026 – Produktkatalog erhält dieselbe Identitätshierarchie

- [x] Katalogtreffer werden über die zentrale Produktidentität auf kompatible Varianten begrenzt.
- [x] Familienpfad und Variante sind in der Katalogzeile sichtbar; Preis- und Routenidentität bleiben getrennt.
- [x] Unbekannte Suchtexte verwenden weiterhin Marke, Kategorie, Alias und EAN als Fallback.
- [x] Regressionen prüfen frische Tomaten gegen Passata sowie konkrete Milchvarianten.


## Update 17.10.2026 – Preisänderungen atomar in Liste und Route übernehmen

- [x] Mehrfachbelege werden über einen gemeinsamen Koordinator in Beobachtung, Marktpreis und Verlauf projiziert.
- [x] Die Shell setzt nach einem Batch genau einen neuen Preis-/Routen-Snapshot.
- [x] Aktionspreise bleiben getrennt und werden nicht als reguläre Verlaufspreise gespeichert.

## Update 17.10.2026 – Quellpriorität und Preisbasis vereinheitlicht

- [x] Eine gemeinsame Evidenzrangfolge wird in Planung, Route und Bon-Familienprojektion verwendet.
- [x] Konfidenz- und Packungsbasisgrenzen werden vor dem Ranking geprüft; fehlende Evidenz bleibt unbekannt.
- [x] Input-Reihenfolge, Quellenpriorität und exakte Filialslots sind durch Fixture-Tests abgesichert.

## Update 17.10.2026 – Händler-Schreibvarianten im Preis-Refresh

- [x] Der Preislernkreis verwendet denselben Normalisierungsschlüssel wie Suche und Coverage.
- [x] Umlaut- und `ae/oe/ue`-Schreibweisen werden nur für den Refresh-Vergleich zusammengeführt.
- [x] Filial-IDs, sichtbare Namen und die getrennte Behandlung von Aktions-/Normalpreisen bleiben unverändert.

## Update 17.10.2026 – Reconcile bleibt bei Händler-Schreibvarianten aktuell

- [x] Der Persistenz-Reconcile verwendet denselben präsentationsbezogenen Händlervergleich wie der Lernfilter.
- [x] Nicht erneut belegte Normalpreise werden auch bei `Süd/SUED`-Schreibvarianten aus der aktuellen Projektion entfernt.
- [x] Ein Regressionstest schützt die Trennung von sichtbarem Händlerlabel und exakter Filial-ID.

## Update 17.10.2026 – Prospekt-Import verbindet Händler-Schreibvarianten

- [x] Feed-Metadaten, Coverseiten und Angebotszeilen verwenden einen gemeinsamen Präsentationsschlüssel.
- [x] Umlaut- und `ae/oe/ue`-Varianten verlieren dadurch keine Filial- oder Seitenbildzuordnung.
- [x] Eine Parser-Regression prüft Herkunft und Prospektseitenbild bei abweichender Händlerdarstellung.

## Update 17.10.2026 – Bestätigte Preisabdeckung bleibt aktuell

- [x] Der Status der lokalen Normalpreisspeicherung zählt nur reguläre Beobachtungen mit `isCurrent=true`.
- [x] Abgelöste historische Belege bleiben im Ledger, werden aber nicht als aktuelle Bestätigung oder Routenpreis gemeldet.
- [x] Eine Regression schützt die gemeinsame Grenze von Persistenzstatus und Preisprojektion.

## Update 17.10.2026 – Prospekt-Suchpfad bleibt bei Händlerformatvarianten filialgenau

- [x] Suche, Filialabdeckung und sichtbare Prospektgruppen verwenden einen gemeinsamen normalisierten Händlervergleich.
- [x] Groß-/Kleinschreibung, Leerraum und deutsche Schreibvarianten ändern keine bestehende Filial-ID.
- [x] Eine Regression schützt die Normalisierung ohne Zusammenlegung verschiedener Branches.

## Update 17.10.2026 – Evidenzsichere Produktauflösung

- [x] Angebote- und Prospekte-Reiter teilen einen validierungsrelevanten Memo-Schlüssel.
- [x] Exakte Filiale und EAN-/Packungs-/Preis-/Gültigkeits-/Nachweisfelder invalidieren einen alten Auflösungstreffer.
- [x] Eine Regression schützt Branch- und Identitätstrennung; CI bestätigt Analyse, Volltests und Web-Build.

## Update 17.10.2026 – Branch-sichere Prospektkarten

- [x] Suchkarten, Grid-Karten und die lokale Produktauflösung verwenden denselben Schlüssel aus Händler, Quell-ID und vorhandener Filial-/Ortsherkunft.
- [x] Gleiche Quellartikel aus gleichnamigen Filialen bleiben beim Lazy-Scroll getrennt und behalten unabhängige Add-to-List-Zustände.
- [x] Eine Regression prüft zwei Branches mit identischer Quell-ID; Analyse, Volltests und Web-Build laufen im CI.

## Update 17.10.2026 – Filialgenaue Prospektangebote im Cache- und Live-Merge

- [x] Transiente Prospektangebote werden mit Angebots-ID, Händler und exakter Filial-/Ortsherkunft geschlüsselt.
- [x] Derselbe Quellartikel bleibt dadurch in zwei gleichnamigen Filialen getrennt sichtbar; die Preis- und Routenlogik erhält beide Filialnachweise.
- [x] Automatisch gespeichert werden weiterhin nur reguläre Prospektpreise; Aktionspreise bleiben flüchtige Offer-Evidenz.

## Update 17.10.2026 – KaufDA-Rohcache begrenzt

- [x] Der optionale Rohantwort-Cache hält höchstens 16 gültige Einträge und 8 MiB.
- [x] Beschädigte, übergroße und ältere Werte werden beim Schreiben begrenzt entfernt; die Byte-Größe wird nach kompakter Serialisierung geprüft.
- [x] Die Cache-Grenze verändert keine Händlerabfrage, Gültigkeitsprüfung oder Preisrollen.

## Update 17.10.2026 – Cache-Prospektangebote vor Live-Refresh nutzbar

- [x] Ein validierter Cache-Feed projiziert aktuelle Angebote sofort in den transienten Shell-Snapshot.
- [x] Einkaufsliste und Routenhinweise können dadurch offline starten, während reguläre Preisbeobachtungen separat lokal persistiert werden.
- [x] Ein späterer Live-Feed ersetzt den transienten Stand deterministisch.

## Update 16.10.2026 – Coverkarten füllen feste Zellen

- [x] Favoritenrail und Coverraster füllen ihre festen Kartenhöhen vollständig, damit kein dunkler Leerstreifen unter den Metadaten entsteht.
- [x] Der Inhalt bleibt an Coverbild, Filiale, Gültigkeit, Quellen-/Seitenstatus und Aktionen gebunden.
- [x] Eine Widgetregression prüft die festen Höhen beider Covervarianten.

## Update 16.10.2026 – Kürzere Vorlade-Reserve im Prospekte-Tab

- [x] Der äußere Prospekte-Scroll verwendet einen 180-Pixel-Vorlauf.
- [x] Cover- und Seitenlisten behalten ihre getrennten Cache-Grenzen und Lazy-Pfade.
- [x] Prospektgültigkeit, Quellenherkunft und Artikelübernahme bleiben unverändert.

## Update 16.10.2026 – Kürzere Vorlade-Reserve im Angebote-Scroll

- [x] Der äußere Angebote-Scroll verwendet einen kleinen 180-Pixel-Vorlauf für die nächste Coverzeile.
- [x] Cover-Favoritenleiste und Coverraster behalten ihren eigenen Cache-Vorlauf 0.
- [x] Die Vorschaubild-, Gültigkeits- und Add-to-List-Funktionen bleiben unverändert.

## Update 16.10.2026 – Cover-Scroll hält Offscreen-Karten nicht fest

- [x] Cover-Favoritenleiste und Coverraster recyceln Offscreen-Karten ohne automatische Keep-Alives.
- [x] Der verschachtelte Coverpfad verwendet keinen zusätzlichen Bild-Cache neben dem übergeordneten Offers-Scroll.
- [x] Seitenweises Nachladen und die bestehende Bild-Fallback-Grenze bleiben erhalten.

## Update 16.10.2026 – Prospektparser bleibt bei malformed Collections nutzbar

- [x] Falsch typisierte Feed-Collections werden übersprungen, ohne valide Märkte oder Cache-Fallbacks zu verlieren.
- [x] Verschachtelte Prospekt-/Seiten-Collections bleiben bei falschem Datentyp leer, statt den Parser zu beenden.
- [x] Eine versionskontrollierte Regression schützt diesen Fehlerpfad.

## Update 16.10.2026 – Routen-Refresh bleibt bei Cachefehlern aktuell

- [x] Ein frischer OSRM-/Straßenmatrix-Abruf bleibt sichtbar, wenn das lokale Schreiben eines Cachepfads fehlschlägt.
- [x] Matrix- und Distanz-Cache werden unabhängig versucht; die Live-Routenberechnung bleibt von lokaler Persistenz getrennt.
- [x] Regressionen prüfen den Matrix- und Distanz-Cachefehler ohne Netzwerkanfragen.

## Update 16.10.2026 – Adapterherkunft pro Angebotszeile

- [x] Der erzeugte offizielle Prospektfeed führt die verwendete Adapterstrecke pro Angebotszeile in sourceAdapter.
- [x] Provider-eigene Quellenkennungen bleiben vorrangig; die bestehende Preis-, Filial- und Gültigkeitsprüfung bleibt unverändert.
- [x] Eine versionskontrollierte Feed-Regression schützt die Herkunft bis zum Import.

## Update 15.10.2026 – Angebots-Hinweise bleiben tagesaktuell

- [x] Der Angebote-Reiter reicht nur die bereits nach Gültigkeit gefilterten Prospekt-Issues an seine Statuskarten weiter.
- [x] Abgelaufene oder zukünftige Prospekte erzeugen dadurch keinen sichtbaren Hinweis im aktuellen Angebotsfluss.
- [x] Eine Widgetregression schützt den current-only-Pfad.

## Update 15.10.2026 – Prospektfilter aktualisiert den Kalendertag

- [x] Angebote- und Prospekte-Reiter invalidieren ihre Tages-Caches auch dann, wenn der Shell-Aufruf keinen expliziten Referenzzeitpunkt liefert.
- [x] Abgelaufene oder noch nicht gestartete Datensätze können nach Mitternacht nicht aus dem alten Tagessnapshot sichtbar bleiben.
- [x] Eine Fachregression schützt den Wechsel des Cache-Schlüssels am Kalendertag.


## Update 15.10.2026 – Routen-Cache erkennt Mengenänderungen

- [x] Der direkte RouteScreen bildet Produkt-/Packungsdaten und Listenmenge in einer Eingabesignatur ab; eine in-place geänderte Menge verwirft den alten Optimierungsplan.
- [x] Preisabdeckung, Fahrtkosten, Mindestvorteil und Marktanzahl bleiben vollständig im bestehenden RouteOptimizer.
- [x] Eine Fachregression schützt denselben ListItem-Verweis vor einem veralteten Mengenplan.

## Update 15.10.2026 – Einkaufsliste aktualisiert Quotes nach Katalog-Laden

- [x] Der Einkaufslisten-Quote-Snapshot nimmt die Katalogreferenz in seinen
  Cache-Vertrag auf; verspätet geladene Prospektvarianten erscheinen dadurch
  sofort in Preisabdeckung und Marktmatrix.
- [x] Die bestehende generische Familienauflösung bleibt unverändert und
  verlangt weiterhin exakte Identität, Packungsbasis, Filiale, Gültigkeit und
  Nachweis vor einer sichtbaren aktuellen Preiszeile.
- [x] Eine fachliche Regression prüft den Wechsel von „unbekannt“ zu einem
  belegten aktuellen Prospektangebot nach dem Katalog-Update.


## Update 15.10.2026 – Generische Prospektangebote im Preise-Reiter

- [x] Der Preise-Reiter reicht den vorhandenen Katalog in die gemeinsame
  Angebotsauflösung durch; generische Listenfamilien können dadurch belegte
  konkrete Varianten aus dem Prospekt anzeigen.
- [x] Filial-, Gültigkeits-, Nachweis- und Identitätsprüfungen bleiben vor der
  sichtbaren Preiszeile aktiv; es wird keine Produktidentität verschmolzen.
- [x] Eine Widgetregression schützt den Weg vom generischen Listeneintrag über
  die konkrete Katalogvariante bis zum aktuellen Prospektangebot.

## Update 15.10.2026 – Coverkarten zeigen exakte Filialherkunft

- [x] Eine vorhandene Filial-ID wird neben der technischen Quellenkennung auf
  Coverkarten und im Bring-Überblick angezeigt.
- [x] Händlername, Ort und Filial-ID bleiben getrennte Nachweise; fehlende
  Filial-IDs werden nicht erfunden.
- [x] Die bestehende Regression prüft Quellen-, Seiten- und Filialherkunft
  zusammen im sichtbaren Coverpfad.

## Update 15.10.2026 – Coverkarten zeigen Quellen- und Seitenstatus

- [x] `sourceAdapter` wird auf der Coverkarte als technische Feed-Herkunft
  angezeigt, sofern die Quelle sie liefert.
- [x] Bekannte Gesamtseiten, geladene Vorschauen und gemeldete fehlende Seiten
  werden kompakt getrennt ausgewiesen; unbekannte Angaben werden nicht erfunden.
- [x] Eine Widgetregression prüft Herkunft und partielle Seitenabdeckung im
  bestehenden Cover-/Scrollpfad.

## Update 15.10.2026 – Zukunftszeitpunkte nicht als Preisbeleg übernehmen

- [x] Aktuelle reguläre Prospektpreise mit einem individuellen zukünftigen
  `capturedAt` bleiben aus der automatischen Preisbasis ausgeschlossen.
- [x] Gültige Nachbardatensätze werden weiter gelernt; Feed-, Laufzeit- und
  Filialprüfungen bleiben unverändert.
- [x] Eine Fachregression schützt den Provenienzfilter.

## Update 15.10.2026 – Preisbeleg-Ledger im Preise-Reiter

- [x] Aktuell gültige reguläre Prospektbeobachtungen werden mit Produkt,
  exakter Filiale, Gültigkeit, Quelle und Nachweis sichtbar.
- [x] Angebots- und abgelaufene Beobachtungen bleiben aus dem Ledger heraus;
  die bestehende route-taugliche Preisprojektion bleibt unverändert.
- [x] Der Shell-Pfad reicht die lokale Beobachtungshistorie und den Katalog ohne
  neue Netzwerkanfragen in den Preise-Reiter durch.
- [x] Widgetregressionen prüfen Filialnachweis, Gültigkeit und die Trennung vom
  Angebotspreis.

## Update 15.10.2026 – Automatische Normalpreisspeicherung im Preise-Reiter

- [x] Der Preise-Reiter zeigt Feed-Zeitpunkt, Cache-Herkunft und den bestätigten
  Status der lokalen Speicherung regulärer Prospektpreise.
- [x] Die Anzeige trennt erkannte, laufende, bestätigte und unbekannte
  Speicherstände; eine bestätigte Nullspeicherung bleibt sichtbar.
- [x] Markt-/Filialabdeckung wird aus dem bestehenden Persistenzsnapshot
  übernommen; Angebotspreise werden nicht als Normalpreise gezählt.
- [x] Widgetregressionen sichern den bestätigten und den nicht bestätigten
  Shell-Status.

## Update 15.10.2026 – KaufDA-UVP bleibt aus regulären Preisen

- [x] Explizit als UVP oder Herstellerpreis beschriftete Vergleichswerte werden unabhängig von der Quellfeldform nicht als durchgestrichener Normalpreis übernommen.
- [x] Ein ausgewiesener höherer Normalpreis ohne UVP-Kennzeichnung bleibt für die bestehende Preisbeobachtungspipeline verfügbar.
- [x] Die KaufDA-Adaptertests decken die zusätzliche Label-Variante ab.

## Update 15.10.2026 – Adapterherkunft am Prospekt-Viewer

- [x] Feed-Metadaten führen `sourceAdapter` bis zum `ProspectIssue`; sichtbare Issue-Rebuilds und der manuelle Seiten-/OCR-Pfad verlieren die Herkunft nicht.
- [x] Fingerprint- und UI-Regressionen prüfen den Wechsel zwischen offizieller Quelle und optionalem KaufDA-Adapter.

## Update 15.10.2026 – Provenienz für geprüfte Prospektseiten

- [x] Manuelle Prospekt-/OCR-Übernahmen speichern `capturedAt` am Offer-Datensatz und behalten optionale Adapterherkunft.
- [x] Die bestehende Review-Grenze bleibt aktiv: Ohne Bestätigung entstehen weder automatische Identität noch route-tauglicher Preis.

## Update 15.10.2026 – Seitenviewer begrenzt Plattform-Fallbacks

- [x] Nur die ersten zwei sichtbaren Prospektseiten dürfen nach einem Canvas-Fehler auf einen HTML-Plattform-View wechseln.
- [x] Spätere Seiten bleiben ohne Plattform-View im begrenzten Canvas-Pfad; ein CDN/CORS-Fehler erzeugt beim Scrollen keine unbeschränkte View-Kaskade.
- [x] Eine Regression schützt das feste Fallback-Budget.

## Update 15.10.2026 – Aktuellste reguläre Prospektquelle pro Filiale

- [x] Überlappende Prospektzeiträume derselben Produkt-/Filialkombination werden bei der Routenprojektion auf den neuesten belegten regulären Anspruch reduziert.
- [x] Die historische append-only Beobachtung bleibt vollständig erhalten; nur die aktuelle MarketPrice-Projektion wird dedupliziert.
- [x] Unterschiedliche exakte Filialen bleiben über ihre Branch-ID getrennt und erhalten jeweils ihren eigenen regulären Preis.

## Update 15.10.2026 – Preisregel im Prospekt-Reiter sichtbar

- [x] Der Status weist ausdrücklich aus, dass nur belegte durchgestrichene Normalpreise lokal als Preisbasis gespeichert werden.
- [x] Aktionspreise bleiben im aktuellen, datumsgebundenen Angebotsfluss und werden nicht als reguläre Preisbeobachtung gespeichert.
- [x] Eine Widgetregression schützt die verständliche Trennung der beiden Preisrollen.

## Update 15.10.2026 – Preise-Reiter zeigt Herkunft und Route-Fähigkeit

- [x] Aktuelle, veraltete und unvollständige gespeicherte Marktpreise werden in einer kompakten Qualitätsübersicht getrennt gezählt.
- [x] Prospekt-Normalpreise bleiben als eigene Quelle sichtbar; Prospekt-Angebotsnachweise werden ausdrücklich separat ausgewiesen.
- [x] Die Übersicht zeigt die aktuelle Belegabdeckung je Markt, ohne die bestehende Preis- oder Routenauflösung zu verändern.

## Update 15.10.2026 – Formatierte Normalpreise werden aus Prospekten gespeichert

- [x] Prospektfelder wie `7,99 €` werden als regulärer, durchgestrichener Preis erkannt; freie Texte wie `UVP 7,99 €` bleiben ungültig.
- [x] Angebots- und Normalpreis bleiben getrennt: Nur der strikt höhere Normalpreis läuft in die automatische lokale Preisbeobachtung.
- [x] Parser- und Persistenzregression prüfen den Weg vom Feed über `PriceObservationStore` bis zur regulären Preisbeobachtung.

## Update 15.10.2026 – Recycelte Prospektbilder behalten keinen alten Fallback

- [x] Verzögerte HTML-Fallbacks werden nur noch aktiviert, wenn die fehlgeschlagene URL noch zum aktuell montierten Prospektbild gehört.
- [x] Beim schnellen Lazy-Scroll können alte Bildfehler dadurch weder neue Cover noch ganze Prospektseiten in den teureren Browserpfad schalten.
- [x] Eine Regression prüft die URL-Zuordnung für alte und aktuelle Bildfehler.

## Update 15.10.2026 – Filialgenaue Prospektkarten beim Lazy-Scroll

- [x] Cover-, Öffnen- und Favoriten-Elemente verwenden den vollständigen Prospekt-/Filialschlüssel statt nur des Händlernamens.
- [x] Gleichnamige Filialen können dadurch beim Recycling des Prospektgitters keinen Bild- oder Aktionszustand untereinander übernehmen.
- [x] Eine Widgetregression prüft getrennte Schlüssel für zwei Lidl-Filialen.

## Update 15.10.2026 – Filialgenauer Distanz-Cache und Routenanzeige

- [x] Einzelmarkt-Entfernungen werden bei vorhandener Branch-ID unter einem stabilen Filialschlüssel gespeichert.
- [x] Legacy-Namensschlüssel werden bei identifizierten Filialen nicht mehr als fremde Filialdistanz verwendet.
- [x] Routenalternativen zeigen Händler und Ort gemeinsam, damit gleichnamige Filialen sichtbar getrennt bleiben.
- [x] Regressionen decken getrennte Fallback-Distanzen und die sichtbare Ortsbezeichnung ab.

## Update 15.10.2026 – Routenalternativen bleiben filialgenau

- [x] Route-Alternativen werden nach Branch-ID, Ort und Adresse dedupliziert; gleichnamige Filialen bleiben eigenständige Stopps.
- [x] Die UI-Deduplizierung verwendet denselben stabilen Routenschlüssel wie die deterministische Optimierer-Reihenfolge.
- [x] Eine Regression schützt zwei gleichnamige Lidl-Filialen mit unterschiedlichen Fahrwegen.

## Update 15.10.2026 – Einkaufs-Preis-Matrix zeigt exakte Filiale

- [x] Preiszitate übernehmen Branch-ID sowie vorhandenen Standort, Ort und Adresse aus Marktpreis- und Angebotsbelegen.
- [x] Preis-Matrix und Detailansichten zeigen die ausgewählte exakte Filiale; fehlende Standortdaten bleiben sichtbar unbekannt.
- [x] Ein deterministischer Branch-Tiebreaker verhindert, dass gleich teure Belege vom Eingabearray abhängen.

## Update 15.10.2026 – Reguläre Prospektpreise vor Cache-Rennen schützen

- [x] Ein später Cache-Lauf kann einen frischeren Live-Preis nicht mehr über denselben Beobachtungsbeleg überschreiben.
- [x] Alte automatische Prospekt-Angebotsbeobachtungen werden auch bei fehlendem Feed-Zeitstempel entfernt; nur reguläre Preisbelege bleiben für die automatische Preisbasis.
- [x] Store- und Persistenzregressionen prüfen Frische, Zeitstempel und die getrennte Behandlung von Angebotspreisen.

## Update 15.10.2026 – Prospektartikel bleiben filialgenau

- [x] Aktuelle Prospektartikel werden nach Händler und vorhandener Branch-ID getrennt gruppiert; gleichnamige Filialen vermischen keine Artikel mehr.
- [x] Händlername und Standort bleiben in der Anzeige lesbar; interne Schlüssel, Kategorien und Nachweise bleiben exakt filialbezogen.
- [x] Eine Widgetregression schützt getrennte Lidl-Gruppen für Zellingen und Würzburg.

## Update 15.10.2026 – Prospekt-Cover bleiben filialgenau

- [x] Coverkarten und Artikelgruppen verwenden jetzt Händlername plus vorhandene Branch-ID als stabilen Schlüssel; gleichnamige Lidl-/Netto-Filialen bleiben getrennt.
- [x] Fehlende Branch-IDs bleiben bewusst auf dem bisherigen Händler-Schlüssel; nicht belegte Filialidentitäten werden nicht erfunden.
- [x] Eine Widgetregression schützt zwei anonymisierte Filialen derselben Kette inklusive Favoritenleiste und Raster.

## Update 15.10.2026 – Prospekt-Cover bleiben beim Scrollen eindeutig

- [x] Adaptive Coverbilder verwenden jetzt einen URL-spezifischen Widget-Schlüssel; zwei unterschiedliche Prospektbilder können beim Grid-/Favoriten-Recycling nicht denselben Image-State teilen.
- [x] Der Canvas-Pfad und der begrenzte HTML-Fallback bleiben unverändert; es entstehen weiterhin keine zusätzlichen Plattformansichten für erfolgreiche Decodes.
- [x] Eine Widgetregression schützt zwei unterschiedliche Cover-URLs und damit den schnellen Scrollpfad.

## Update 15.10.2026 – Prospekt-Normalpreise erreichen die Einkaufsliste

- [x] Eine deterministische Regression deckt den vollständigen Pfad vom Speichern eines aktuellen regulären Prospektpreises über die Projektion bis zum Einkaufslisten-Zitat ab.
- [x] Die Prüfung verwendet eine konfigurierte Filiale und bleibt damit kompatibel mit der exakten Branch-Prüfung der Listenpreise.
- [x] Angebotspreise, abgelaufene Beobachtungen und unsichere Produktidentitäten bleiben außerhalb der route-tauglichen Liste.

## Update 15.10.2026 – Cache-Prospektpreise lokal sichern

- [x] Ein validierter Cache-/Bundle-Feed speichert beim Offline-Start ebenfalls nur aktuell gültige, explizit angegebene reguläre Preise.
- [x] Der Angebotspreis bleibt ausschließlich Angebotsbeleg; er wird aus diesem automatischen Cache-Lernpfad nicht als Normalpreis gespeichert.
- [x] Ein späterer Live-Refresh darf dieselben Beobachtungs-IDs sicher aktualisieren; die Preis-Historie bleibt append-only nachvollziehbar.

## Update 15.10.2026 – Mehrdeutige Open-Prices-Filialen bleiben unbekannt

- [x] Ohne eindeutige Quellfilial-ID wird ein Treffer bei mehreren gleichnamigen Filialen im selben Ort verworfen, statt die erste Filiale zu wählen.
- [x] Eine Regression schützt exakte Filialtreue und lässt eindeutig auflösbare Einzel-Filialen unverändert.
- [x] Der Adapter behandelt die Datenlücke weiterhin sichtbar als unbekannt; es wird kein Preis erfunden oder in die Routenplanung übernommen.

## Update 15.10.2026 – Open Prices bewahrt gleichnamige Filialen

- [x] Der Open-Prices-Adapter verwendet die Quellfiliale als Preis-Slot und legt zwei gleichnamige Märkte nicht mehr zusammen.
- [x] Branch-ID, Preis und Erfassungszeit bleiben je exakter Filiale getrennt; der bestehende Standort- und Altersfilter bleibt unverändert.
- [x] Eine anonymisierte Regression schützt zwei gleichnamige Lidl-Filialen mit unterschiedlichen Open-Prices-IDs.

## Update 15.10.2026 – Prospekt-Cover berücksichtigen offene Gültigkeitsgrenzen

- [x] Ein Prospekt mit künftigem Startdatum wird im Angebote-Reiter nicht als aktuelles Cover angezeigt, auch wenn der Feed noch kein Enddatum liefert.
- [x] Abgelaufene und widersprüchliche offene Zeiträume bleiben aus der aktuellen Coveransicht ausgeschlossen.
- [x] Fach- und Widgetregressionen schützen die gemeinsame Datumsgrenze.

## Update 15.10.2026 – Bonzeilen erhalten explizite Katalogvorschläge

- [x] Unklare Bonpositionen zeigen bis zu drei passende Namens-/Alias-Treffer aus dem vorhandenen Katalog.
- [x] Ein Vorschlag bleibt eine sichtbare Evidenz; erst die manuelle Auswahl setzt die Zuordnung.
- [x] Kategorie-only-Treffer werden aus der direkten Bonzuordnung herausgehalten und bleiben damit ohne falsche Produktidentität.

## Update 15.10.2026 – OSRM-Cache deckt aktuelle Filialen vollständig ab

- [x] Eine Matrix wird nur als Offline-Fallback verwendet, wenn sie alle aktuell angeforderten Branch-Schlüssel abdeckt.
- [x] Teil- oder Altmatrizen dürfen bei gleichnamigen, aber geänderten Filialen keine alten Distanzwerte weiterreichen; lokale Fallback-Distanzen bleiben sichtbar.
- [x] Eine Fixture-Regression prüft den Ausfall bei einem neuen exakten Filialschlüssel.

## Update 15.10.2026 – Jeder Routen-Einstieg bleibt filialgenau

- [x] Der RouteScreen im More-/Shell-Seitenpfad erhält denselben exakten Filialkatalog wie AppShell, ShellRouting und die direkte Routenaktion.
- [x] Der zweite Einstieg kann gleichnamige Filialen nicht mehr auf den globalen Namenskatalog zurückfallen lassen; Branch-ID, Ort und Adresse bleiben bis zur Anzeige erhalten.

## Update 15.10.2026 – Branch-stabile Fahrmatrizen

- [x] Neue OSRM-Matrizen verwenden bei vorhandener Branch-ID einen stabilen Filialschlüssel; gleichnamige Märkte bleiben im Matrixknoten getrennt.
- [x] Ältere Matrizen mit sichtbaren Händlernamen bleiben über einen deterministischen Fallback lesbar.
- [x] Fallback-Distanzen und die Anzeige der real geladenen Märkte akzeptieren beide Schlüsselvarianten.
- [x] Eine Fixture-Regression prüft getrennte Distanzen und Fahrzeiten für zwei gleichnamige Filialen.

## Update 15.10.2026 – Exakte Filialkataloge in der Routenplanung

- [x] RouteOptimizer akzeptiert für einen Rechenlauf einen explizit aufgelösten Filialkatalog; der bisherige Projektkatalog bleibt der Standard.
- [x] Preisgleiche Routen unterscheiden gleiche Händlernamen über Branch-ID, Ort und Adresse, damit eine exakte Filiale deterministisch erhalten bleibt.
- [x] OSRM-Reihenfolgen verwenden dieselben Filialmerkmale als letzten Tie-Breaker; Preis-, Quellen- und Fahrtkostenlogik bleiben unverändert.
- [x] Eine Regression prüft zwei gleichnamige Lidl-Filialen mit unterschiedlichen Marktpreisen und stellt die Branch-ID im Ergebnis sicher.

## Update 14.10.2026 – Artikelbilder aus belegten Prospektseiten

- [x] Strukturierte Angebote können bei fehlendem Artikelbild das bereits validierte Bild derselben Prospektseite verwenden.
- [x] Store, Seitennummer und überschneidender Gültigkeitszeitraum sind Pflicht für den Fallback; alte oder uneindeutige Seiten bleiben ohne Bild.
- [x] Der Nachweis bleibt unverändert am Angebot, und eigene Quellbilder werden nie überschrieben.

## Update 14.10.2026 – Artikelübernahme bei uneindeutiger Identität

- [x] Eindeutig belegte Prospektartikel bleiben direkt hinzufügbar; uneindeutige, aber gültige Datensätze erhalten einen sichtbaren Bestätigungsdialog.
- [x] Der bestätigte Pfad übernimmt nur die exakte Quellbezeichnung als Listeneintrag und verändert keine Offer-/Routenpreisidentität.
- [x] Regional-only, fehlende Nachweise, abgelaufene und ungültige Angebote bleiben deaktiviert.

## Update 14.10.2026 – Offizielle Prospektkategorien erweitern

- [x] Unterkategorien, Abteilungen und begrenzte Kategoriepfade offizieller Quellen werden transparent übernommen.
- [x] Die Normalisierung bleibt auf benannte Präsentationsfelder beschränkt und erzeugt keine Produkt- oder Preisidentität.
- [x] Nicht-textuelle oder nur technische Kategoriewerte bleiben als sichtbare Datenlücke bestehen.

## Update 14.10.2026 – Prospekt-Evidenzfelder an der App-Grenze

- [x] Explizite Bild-, Kategorie-, Packungs- und Grundpreisvarianten werden an der Dart-Feedgrenze einheitlich und nachvollziehbar normalisiert.
- [x] Verschachtelte Quellobjekte werden nur über benannte Präsentationsfelder gelesen; fehlende Daten bleiben sichtbar und werden nicht geraten.
- [x] Der bestehende Filial-, Gültigkeits-, Nachweis- und Lebensmittel-Filter bleibt vor jeder Anzeige und Preisprojektion aktiv.

## Update 14.10.2026 – Prospektpreise beim App-Fortsetzen aktualisieren
- [x] Beim Fortsetzen der App wird ein validierter Prospektstand älter als sechs Stunden automatisch im Hintergrund aktualisiert.
- [x] Der aktuelle Einkauf, die Route und die Prospektansicht bleiben während des Abrufs bedienbar; der lokale Cache wird sofort weiterverwendet.
- [x] Die Prüfung ist timestamp-basiert, begrenzt doppelte Resume-Ereignisse und erzeugt keine zusätzliche dauerhafte Datenquelle.
- [x] Während die App aktiv bleibt, plant sie höchstens einen sechsstündigen Refresh; bei Pause wird der Timer beendet.

## Update 13.10.2026 – Coverraster progressiv laden
- [x] Große Prospekt-Coverlisten im Angebote-Reiter zunächst seitenweise rendern und weitere Karten ausdrücklich nachladen lassen.
- [x] Den bestehenden Detailviewer, die Quellenbelege und die aktuelle Gültigkeitsprüfung unverändert weiterverwenden.

## Update 13.10.2026 – Prospekt-Cover-Scroll stabilisieren
- [x] Coverkarten im Überblick auf Canvas-only umstellen, damit Flutter Web beim schnellen Scrollen keine Plattform-Views pro CDN-Bild anlegt.
- [x] Detailviewer-Fallback für einzelne Bilder und Test für die Renderer-Grenze beibehalten.

## Update 13.10.2026 – Shell-Routing-Snapshot
- [x] Dashboard, Kaufabschluss und Seitensammlung teilen je Build einen
  aktuellen und regulären RouteOptimizer für identische Eingaben.
- [x] Wiederholte Preis-/Alternativenaufbereitung wird damit aus demselben
  Build entfernt; ein neuer Datenstand erzeugt bewusst einen neuen Snapshot.

## Update 14.10.2026 – OSRM-Fahrzeitmatrix für Planung

- [x] OSRM-Tabellenantworten können neben Entfernungen auch explizite Fahrzeiten übernehmen.
- [x] Alte lokale Matrizen ohne Fahrzeiten bleiben lesbar und fallen deterministisch auf die konfigurierte Mobilitätsgeschwindigkeit zurück.
- [x] Zeitwert, TravelEstimate und Routenzusammenfassung verwenden die Fahrzeit nur bei vollständiger, gültiger Rundtour-Evidenz.

# SparzamApp – Roadmap

Diese Roadmap ist eine Prioritätenliste, kein starres Releaseversprechen.

## Update 15.10.2026 – Routenoptimierung bis sechs Märkte

- [x] Die Kombinationserzeugung unterstützt alle sechs konfigurierten Projektmärkte statt einer fest verdrahteten Dreimarktgrenze.
- [x] Das Routenlimit bleibt über maxStores und den Mindestvorteil steuerbar; fehlende Preise werden weiterhin als unbekannt behandelt.
- [x] Mobilitätseinstellungen und lokale Altformate akzeptieren bis zu sechs Märkte; die bestehende Ein-, Zwei- und Dreimarktlogik bleibt unverändert.

## Update 15.10.2026 – Route-UI bleibt filialgenau

- [x] RouteScreen und ShellRouting verwenden denselben exakten Filialkatalog wie der RouteOptimizer.
- [x] OSRM-Ziele, Fallback-Distanzen und sichtbare Routenpfade behalten Branch-ID, Ort und Adresse; ein gleichnamiger Händler wird nicht stillschweigend vertauscht.
- [x] Der Shell-Snapshot wird bei einem geänderten Filialkatalog invalidiert und bleibt bei unveränderten Eingaben wiederverwendbar.

## Phase A – Solide Datengrundlage
- Bon-Parsing stabilisieren.
- Stück-, Gewichts- und Grundpreise korrekt unterscheiden.
- Produktvarianten zuverlässig auseinanderhalten.
- Nutzerkorrekturen sicher speichern.
Status: weit fortgeschritten, weitere reale Bons dienen als Praxistest.

## Phase B – Lernende Preisdatenbank
- Gemeinsame append-only Preisbeobachtungen für bestehende Quellen speichern; aktuelle Marktpreise als Projektion ableiten, ohne Historie zu verlieren.
- Provider/Adapter schrittweise anschließen: Bon, manuell, Open Prices, Angebote, später geprüfte Händlerdaten und Regalbilder; keine produktbezogene Sonderlogik.
- Confidence aus Herkunft und Alter getrennt modellieren und fehlende Preise als Unsicherheitsbereich behandeln; knappe Routenentscheidungen kennzeichnen.
- [x] Datenlücken-Relevanz aus fehlender Marktdeckung, Menge, bestätigter Kaufhäufigkeit und belastbarer Historie für häufige, teure und entscheidungsrelevante Einkaufspositionen priorisieren; die Beleganforderung bleibt UI-gesteuert.
- Produktidentität von Preisbeobachtungen trennen.
- Frische Tomatenvarianten im Basiskatalog getrennt von verarbeiteten
  Tomatenprodukten anbieten.
- Händler-/Bon-Aliase lernen.
- Confidence für automatische Zuordnungen.
- Wiederkehrende Käufe bevorzugt erkennen.
- Korrekturen des Nutzers als Lernsignal verwenden.
- Preisverlauf pro Produkt/Markt.

## Update 09.10.2026 – Datenlücken-Relevanz abgeschlossen
- Der deterministische Datenlücken-Score ist implementiert und wird vor den
  einzelnen Tie-Breakern angewendet. Dadurch kann eine Position mit größerer
  bekannter Auswirkung eine nur häufige, aber kleinere Lücke überholen.
- Der Score bleibt ein Priorisierungsindex. Er erzeugt keinen Preis, verlängert
  keine Angebotsgültigkeit und wird nicht als direkte Routenbasis verwendet.
- PR #163 und der nachgelagerte Main-/Release-Check sind in
  `docs/PROJECT_STATUS.md` dokumentiert.

## Phase C – Angebote intelligent einbeziehen
- Angebote zeitlich begrenzen.
- Normalpreis und Angebotspreis getrennt halten.
- Effektivpreise korrekt vergleichen.
- Einkaufsliste gegen aktuelle Angebote prüfen.
- Keine künstlichen Produktduplikate durch Angebote erzeugen.
- [x] Sichtbare Rubrik „Angebote“ zunächst ausschließlich auf den aktuellen
  Prospektfeed und gültige Prospektzeiträume begrenzen.
- [x] Den zuletzt validierten öffentlichen Prospektfeed bei vorübergehendem
  Offline-Abruf als datierten Fallback nutzen, ohne abgelaufene Angebote zu
  reaktivieren.
- [x] Einen validierten lokalen Cache-/Bundle-Stand beim Shell-Kaltstart vor dem Netzwerkabruf anzeigen und anschließend im Hintergrund aktualisieren.
- [x] Den versionierten öffentlichen Feed auch beim Kaltstart ohne Netzwerk und
  ohne lokalen Cache als App-Asset laden; der Stand bleibt als nicht-live
  gekennzeichnet und wird weiterhin auf Angebotsgültigkeit geprüft.
- [x] Bei einem vollständigen Refresh-Ausfall den ursprünglichen
  `generatedAt`-Zeitpunkt erhalten, damit Fallback-Daten nicht künstlich frisch
  erscheinen.
- [x] Artikelbilder in großen Prospektlisten im Web strikt im Canvas rendern;
- [x] Der Seitenviewer verwendet für Canvas/CORS-Fehler ein eigenes,
  freigebendes HTML-Fallback-Budget; jede validierte Seite kann damit beim
  Sichtbarwerden wiederhergestellt werden, ohne unbeschränkte Plattform-Views
  oder zusätzliche Scroll-Last.
  die wenigen Cover- und Viewerbilder dürfen bei einem Bild-/CORS-Problem auf
  HTML-Plattform-Views zurückfallen. Dadurch bleibt der große Scrollpfad ohne
  unnötige Plattform-Views.
- [x] Non-Food-Kampagnenartikel an Refresh- und App-Grenze aus dem aktuellen
  Angebotsbestand ausschließen, ohne Lebensmittelbegriffe mit ähnlichen
  Wortteilen zu verlieren.
- [x] Die sichtbare Quellenabdeckung nach dem Filter zählen und abweichende
  Provider-Rohmengen separat als `rawRecordCount` erhalten.
- [x] Eine verifizierte Coverseite des Netto-Filialprospekts im Offline-Stand
  mit Zeitraum, Seite und exakter Filiale anzeigen.
- [ ] Prospektfeed weiter auf vollständige Artikelbilder, Kategorien,
  Filialbezug und belastbare Gültigkeit ausbauen.
- [x] Konkrete Produktzuordnung in Such-, Seiten- und erweiterten
  Händler-/Kategoriegruppen je sichtbarem Angebotsdatensatz memoisiert, damit
  große Prospekte und der Angebote-Reiter keine wiederholte
  Identitätsauflösung ausführen.
- [x] Feednormalisierung, Kategorien und sichtbare Filialkarten zwischen
  Suche-/Favoriten-Rebuilds wiederverwenden, solange der Eingabesnapshot gleich
  bleibt.
- [x] Bildseiten ermöglichen eine geprüfte manuelle Artikelübernahme mit
  Seitenlink, Preis, Gültigkeitsende und bestehender Filialprovenienz.

## Phase D – Alltagstaugliche Datenerfassung
- Kassenbons möglichst automatisch.
- [x] JPG/PNG- und Kamera-Bons auf Android/iOS lokal per OCR lesen und in den bestehenden Bonreview führen.
- [x] Bildbasierte PDFs ohne Textebene auf Android/iOS lokal rendern und über den geprüften OCR-/Review-Pfad verarbeiten.
- Barcode als sichere Produktidentität nutzen.
- Open Prices/Open Food Facts sinnvoll ergänzen.
- Regalvideo-Erfassung evaluieren: Lesbarkeit von Preisschildern, Produktbezug, Dubletten, Aufwand und Datenschutz.
- Erst nach erfolgreicher Evaluation Video-Pipeline implementieren.

## Phase E – Intelligente Einkaufsplanung
- Persönliche Wiederkaufrhythmen.
- Preisniveau und typische Preise lernen.
- [x] Sparpotenzial je Einkauf aus aktuell belegten Angeboten und dem vollständigen Routenvergleich.
- Für jede Einkaufsposition belastbare Preise je Markt zusammenführen und hinsichtlich Aktualität/Herkunft/Confidence bewerten.
- Ein-Markt-Strategien und sinnvolle Kombinationen aus mehreren Märkten für den gesamten Warenkorb vergleichen.
- Markt-/Routenoptimierung unter Berücksichtigung des tatsächlichen Mehrwegs und der daraus entstehenden Fahrtkosten.
- Persönlichen Zeitwert optional monetarisieren, ohne ihn mit tatsächlichen
  Kassen- oder Fahrtkosten zu vermischen.
- Fehlende Preisbelege direkt aus der Routen-Datenlücke zur bestehenden
  Marktpreis-Eingabe führen, ohne historische Werte zu bestätigen.
- Routenempfehlung erklärt vollständige Preisabdeckung gegenüber einer unvollständigen Einzelmarkt-Teilroute.

## Update 15.10.2026 – Bonpreise hierarchisch bis zur Route nutzen

- [x] Bestätigte Händlerprodukt-Identitäten bleiben auch bei abweichendem
  OCR-/Bontext routenfähig, sofern die Packungsbasis belegbar ist.
- [x] Familienpreise dürfen ein unleserliches Label unterstützen, ohne eine
  konkrete Variante zu erfinden.
- [x] Spezifische Labels überschreiben keine Produktfamilie in Richtung einer
  fachlich falschen Identität; Tomatenmark bleibt von frischen Tomaten getrennt.
- [x] Regression deckt die Kette Bonbeleg → Familien-/Marktpreis → Planung →
  Routenoptimierung ab.
- Einen zusätzlichen Markt nur wählen, wenn die Ersparnis des gesamten Teilwarenkorbs den zusätzlichen Aufwand wirtschaftlich rechtfertigt.
- Primäres Ergebnis: konkrete Empfehlung der wirtschaftlichsten Einkaufsstrategie (z. B. nur Lidl, Lidl + Aldi oder nur Kaufland), nicht bloß eine Liste billiger Einzelpreise.
- Vorschläge nur dann, wenn sie praktisch relevant sind.

## Phase F – Synchronisierung / Mehrbenutzer
- Freiwillige Übermittlung geeigneter eigener Beobachtungen an Open Prices und später Community-Daten nur mit expliziter Freigabe und bereinigten Belegen.
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

- [x] Gespeicherte exakte Preisbeobachtungshistorie als Eingang der bestehenden Marktpreis-/Routenprojektion verwenden, statt nur den zuletzt projizierten Marktpreis zu sehen.

- [x] Bonbeobachtungen in die gemeinsame Preisbeobachtungshistorie adaptieren, ohne Familienmatches als exakte Produktidentität auszugeben.
- [x] Angebote mit Gültigkeit in die gemeinsame Preisbeobachtungshistorie adaptieren und abgelaufene Angebote aus der exakten Routenprojektion ausschließen.
- [x] Packungs-/Mengengleichheit und Variantenvergleichbarkeit werden zentral vor dem Preisranking geprüft.


## WORK QUEUE

Work wird nur für Aufgaben eingesetzt, bei denen eine längere, selbstständige Arbeitskette einen klaren Vorteil gegenüber kleinen Änderungen im Projektchat hat. Bereits erledigte Pakete werden nicht erneut bearbeitet, außer ein konkreter Fehler erfordert es.

| Status | Aufgabe | Warum Work | Startvoraussetzung |
| --- | --- | --- | --- |
| DONE | End-to-End-Audit der Preis- und Routenlogik | Identitäts-Bypässe, Projektion und Preis-/Routenfluss repo-weit geprüft; belegte Fehler mit Regressionen geschlossen | abgeschlossen 25.09.2026 |
| WAITING | Reale Preisdatenquellen und Provider-Adapter | Recherche, Quellenprüfung, Mapping, Implementierung und Validierung als zusammenhängender Arbeitslauf | Beobachtungs-/Confidence-Schnittstellen stabil |
| WAITING | Migration auf PriceObservation als direkte Planungsbasis | Größeres Refactoring über Stores, Route und UI mit Rückbau von Übergangsschnittstellen | PriceObservation deckt Bon, Angebot, fehlende Preise und Vergleichbarkeit ab |
| WAITING | Meilenstein-Qualitätssicherung | App-/Repo-weite Tests, CI, Datenflussprüfung, Fehlerbehebung und Dokumentationsabgleich | vor dem nächsten größeren Produktmeilenstein |

### Work-Regel
- Projektchat: kleine klar abgegrenzte Pakete, Architekturentscheidungen, gezielte Implementierung, Tests, Commits und CI-Kontrolle.
- Work: nur freigegebene Einträge dieser Queue; keine eigenständige Wiederholung bereits abgeschlossener Pakete.
- Ein Queue-Eintrag wechselt erst auf READY, wenn seine Startvoraussetzung erfüllt ist.
- Nach Work-Abschluss: Status/Dokumentation aktualisieren, CI grün herstellen und nächsten Queue-Status eindeutig festhalten.

## Update 24.09.2026 – Vergleichbarkeitspaket abgeschlossen
- [x] Mengen-/Einheitennormalisierung für g/kg, ml/l und Stück.
- [x] Exakte Packungsabweichungen vor der Routenprojektion blockieren.
- [x] Familienpreise nur mit sicherer Mengenbasis normalisieren.
- [x] Generische Familienwünsche von konkreten Geschwistervarianten trennen.
- [x] Open-Prices-Sync auf aktuelle Einkaufsnachfrage begrenzen.
- [x] Fehlende EAN konservativ über Open Food Facts entdecken, ohne Discovery als bestätigte Identität auszugeben.
- [x] Automatische Bon-Vorschläge nicht als bestätigte exakte Produktidentität speichern.

### WORK QUEUE Statusänderung
Die Startvoraussetzung „Mengen-/Packungs-/Variantenvergleich abgeschlossen“ ist erfüllt. Der Eintrag **End-to-End-Audit der Preis- und Routenlogik** ist damit **READY**. Beim nächsten Work-Lauf soll dieser Audit als erstes freigegebenes Paket bearbeitet werden. Die übrigen Einträge bleiben WAITING, bis ihre jeweiligen Voraussetzungen erfüllt sind.


## Update 25.09.2026 – End-to-End-Audit abgeschlossen
- Der Audit des Datenflusses `ReceiptObservation → PriceObservation → MarketPrice → planningMarketPrices → RoutePriceResolver → RouteOptimizer` ist für die aktuell vorhandenen, belegten Daten abgeschlossen.
- Identitäts-Bypässe aus automatischen Bonzuordnungen wurden geschlossen; unbestätigte automatische Identitäten dürfen nicht als exakte Routenpreise auftreten.
- Ein im Audit verbliebener Projektionsfehler wurde behoben: mehrere exakte Beobachtungen derselben Produkt×Markt-Kombination werden vor der Route nicht mehr blind auf den neuesten Zeitstempel reduziert. Die Auswahl verwendet jetzt zentral denselben qualitätsbereinigten Preiswert wie der Route-Resolver.
- Die vollständige Sieben-Bon-Matrix bleibt separat offen, weil zwei im UI sichtbare Originalbelege weiterhin nicht als Quelldatei vorliegen. Dieser Datenblocker wird nicht durch erfundene Parserannahmen umgangen.
- Nächster Featureblock nach nachweislich grüner CI: hierarchische Produkt-/Suchauflösung sowie weitere Absicherung von Quellpriorität und Angebot/Normalpreis.


## Update 25.09.2026 – Suchhierarchie und Angebotsnachweis
- [x] Familie/Variante in der Einkaufssuche sichtbar machen.
- [x] Verwandte Interpretationen getrennt von identitätskompatiblen Treffern anzeigen; Referenzfall „Tomate“.
- [x] Häufige Grundbedarfs- und Grundvorratsfamilien mit getrennten Varianten in den Basiskatalog aufnehmen.
- [x] Häufige Bonabkürzungen und Händlerpräfixe über die zentrale Identität auffindbar machen; unklare Codes bleiben im Review.
- [x] Externe Angebotsimporte ohne belastbaren Nachweis von exakter Preisprojektion ausschließen.
- [x] Ausgewiesenen Normalpreis eines belegten Angebots als getrennte reguläre Preisbeobachtung erhalten.
- [ ] Hierarchie über weitere Produktfamilien systematisch ausbauen; die vollständige Katalogmigration bleibt offen.
- [x] Scanner- und manuelle EAN-Eingaben werden ohne Identitätsraten
  normalisiert; UPC-A und getrennte Eingabeformatierung bleiben exakt
  vergleichbar.
- [ ] Angebotsquellen automatisiert aus realen Prospekten/Bildern einspeisen und Gültigkeit/Filialbezug prüfen.


## Update 29.09.2026 – Bring-Hotspotadapter
- [x] Share-Link-Struktur für die sechs Zielhändler analysiert; feste Prospekt-BRN von dauerhaftem „aktuell“-Abruf getrennt.
- [x] Optionalen standortbezogenen Bring-Adapter für aktuelle Prospektseiten, strukturierte Produkt-Hotspots, Bilder, Angebots- und Normalpreise implementiert.
- [x] Bring-Angebote laufen mit Gültigkeit und Nachweis durch den bestehenden Angebots-/PriceObservation-Vertrag.
- [ ] Live-Abruf in GitHub aktivieren, sobald die drei Bring-Zugangsdaten als Repository-Secrets hinterlegt sind; bis dahin bleiben die offiziellen Händleradapter führend.
- [x] Bild-only-Prospektseiten können lokale OCR-Vorschläge mit Confidence anzeigen; bei mehreren Treffern wählt der Nutzer eine Zeile, bevor sie ausschließlich über das bestehende Nutzer-Review in ein manuelles Angebot überführt wird.

## Update 01.10.2026 – Preisabdeckung direkt in der Einkaufsliste
- [x] Das Preisfenster zeigt für jeden aktivierten Markt eine eigene Zeile.
- [x] Aktive Angebote werden je Markt vor Bon- und eigenen Preisbelegen gewählt;
  Märkte ohne exakte Evidenz bleiben als fehlend sichtbar.
- [x] Bei leerer Marktauswahl werden die sechs konfigurierten Projektmärkte
  dargestellt. Die Anzeige erzeugt keinen geschätzten Preis und verändert nicht
  die verbindliche Routenzuordnung.

## Update 01.10.2026 – Historische Prospektorientierung je Markt
- [x] Gelernte Prospekt-Mediane werden in der Einkaufsliste je Markt als
  historische Orientierung gezeigt, wenn ein aktueller Preisbeleg fehlt.
- [x] Aktuelle Angebote und aktuelle Marktpreise haben Vorrang; historische
  Prospektwerte bleiben aus aktueller Preisabdeckung und Routenplanung heraus.
- [x] Preisstand und historische Kennzeichnung sind im Preisfenster sichtbar
  und durch Fach-/Widgettests abgesichert.

## Update 01.10.2026 – Prospekt-Historie als Detailansicht
- [x] Die Einkaufsliste bietet pro Produkt eine optionale Detailansicht der
  abgeschlossenen Prospektbeobachtungen je Markt.
- [x] Median, Beobachtungsanzahl, Quellart und letztes Gültigkeitsende bleiben
  in der Historie nachvollziehbar.
- [x] Die Detailansicht ist erklärend; historische Werte werden nicht in die
  aktuelle Preisabdeckung oder Routenplanung übernommen.

## Update 01.10.2026 – Neue Prospektartikel aus dem Angebotstab
- [x] Aktuelle, nachgewiesene Prospektlabels ohne Katalogidentität können aus
  dem Angebotstab zur Einkaufsliste übernommen werden.
- [x] Der Fallback bleibt an das exakte Händlerlabel gebunden und erfindet
  weder Variante noch Alias; Preis- und Quellenbeleg bleiben am Prospektfluss.
- [x] Der sichtbare Add-to-List-Flow ist als Widget-Regression abgesichert.
- [x] Der Fallback bleibt bei fehlendem Nachweis oder mehrdeutiger Identität
  gesperrt.

## Update 01.10.2026 – Vorauswahl der belegten Spar-Variante
- [x] Generische Wünsche wählen im Variantenfenster die erste aktuell belegte
  Spar-Variante vor.
- [x] Historische Prospektwerte bleiben Hinweise und lösen keine stille
  Produktwahl aus.
- [x] Die Empfehlung bleibt manuell änderbar und ist im Übernahme-Flow
  getestet.

## Update 01.10.2026 – Deterministische Routen-Gleichstände
- [x] Gleiche Preisabdeckung und gleiche Planungswerte werden über weniger
  Märkte und danach kanonische Marktnamen stabil aufgelöst.
- [x] Eine Regression prüft den Gleichstand zwischen EDEKA und Lidl und schützt
  die Auswahl vor einer zufälligen Quellreihenfolge.

## Update 01.10.2026 – Mehrmarkt-End-to-End-Fixture
- [x] Ein versionierter Warenkorb wird gegen vollständige 1-, 2- und
  3-Markt-Kombinationen verglichen.
- [x] Die Fixture prüft die gemeinsame Warenkorbepreisung, Rundfahrtkosten und
  den Wechsel zurück zum Einzelmarkt bei hohen Fahrtkosten.

## Update 01.10.2026 – Händleranzahl konsistent halten
- [x] Profil, Marktfilter und Route verwenden dieselbe konfigurierte
  Händlerliste; die leere Auswahl zählt die sechs Projektmärkte.

## Update 01.10.2026 – Teilwarenkörbe in der Marktansicht kennzeichnen
- [x] Unbepreiste oder nur geschätzte Listenpositionen werden in der
  Markt-Detailansicht als Datenlücke aufgelistet.
- [x] Warenkorb-, Ersparnis- und Fahrtkostenwerte werden bei Lücken als
  Teilwarenkorb bezeichnet; eine vollständige Markt-Empfehlung bleibt aus.
- [x] Regressionen decken Datenmodell, Empfehlungsstatus und sichtbare UI-Warnung
  ab.

## Update 01.10.2026 – Dashboard vor Teilrouten schützen
- [x] Das Dashboard zeigt eine unvollständige Route ausdrücklich als vorläufige
  Teilroute und verlinkt zur Preisabdeckung.
- [x] Teilkosten werden nicht als Sparpotenzial behauptet und nicht in die
  Budgetplanung übernommen.
- [x] Daten- und Widgettests decken die Teilroute ab.

## Update 01.10.2026 – Kaufabschluss gegen Teilrouten absichern
- [x] Eine Teilroute kann nicht als vollständiger Einkauf bestätigt werden.
- [x] Fehlende Artikel und die vorläufige Ersparnis werden im Abschluss sichtbar
  genannt.
- [x] Der App-Handler blockiert Teilrouten auch außerhalb der UI.

## Update 01.10.2026 – Sparroute direkt aus der Einkaufsliste
- [x] Eine gefüllte Einkaufsliste zeigt jetzt direkt die Aktion „Sparroute
  prüfen“.
- [x] Der Einstieg führt dieselbe aktuelle Liste in die vorhandene
  Routenberechnung, damit Angebote, Marktpreise, Datenlücken und Fahrtkosten
  ohne Umweg gemeinsam bewertet werden.
- [x] Der sichtbare Klickpfad ist als Widgetregression abgesichert; bei einer
  leeren Liste oder ohne Route-Callback erscheint die Aktion nicht.

## Update 01.10.2026 – Prospektquellen zeigen den konkreten Markt
- [x] Alle sechs offiziellen Prospektquellen tragen jetzt die konfigurierte
  Filial-ID, den Ort und die Adresse im Feed-Metadatenblock.
- [x] Die Prospektkarten und die Prospektdetailansicht zeigen den Ort, damit
  ein Angebot eindeutig als Zellingen, Thüngersheim oder Würzburg erkennbar
  bleibt.
- [x] Parser- und Widgetregressionen sichern die vollständige Zuordnung der
  sechs Quellen; Artikelbilder, Kategorien und OCR für bild-only Seiten bleiben
  weiterhin getrennte offene Ausbaustufen.

## Update 01.10.2026 – OCR-Geldtokens robust gegen Nullverwechslung
- [x] Der Bon-Parser erkennt die häufige OCR-Verwechslung `@` für `0` in
  Geldbeträgen und normalisiert sie nur innerhalb des Geldtokens.
- [x] Negative Rabatte, Stückpreise und Zeilenbeträge bleiben dabei derselben
  Quellen- und Mengenprüfung unterworfen.
- [ ] Vollständige Bild-OCR, Produktidentität und Geräteakzeptanz bleiben
  separate offene Ausbaustufen; ungeklärte Mengen- oder Bilanzabweichungen
  werden weiterhin zur Nutzerprüfung vorgelegt.

## Update 01.10.2026 – Prospektfeed-Frische sichtbar
- [x] Angebote und Prospekte zeigen den Zeitstempel des geladenen Feeds.
- [x] Offline-Fallback wird als letzter geprüfter Stand gekennzeichnet, ohne
  abgelaufene Angebote wieder gültig zu machen.
- [ ] Artikelbilder, Kategorien, bild-only OCR und Geräteakzeptanz bleiben
  separate Ausbaustufen für die vollständige Prospektabdeckung.

## Update 01.10.2026 – Händlerkategorien als Quellenmetadatum
- [x] Explizite Kategorien strukturierter Händlerantworten werden im Feed
  erhalten und in Angebote/Prospekte für Gruppierung und Suche verwendet.
- [x] Fehlt eine Kategorie, bleibt die bestehende sichtbare Fallback-Kategorie
  aktiv; Identität und Preise werden dadurch nicht verändert.
- [ ] Vollständige Artikelbilder, Kategorieabdeckung in jedem Live-Feed,
  bild-only OCR und Geräteakzeptanz bleiben offene Datenqualitätsstufen.

## Update 01.10.2026 – Händlerkategorien lesbar gruppieren
- [x] Technische Nummern- und Slugwerte der Händlerquellen werden in eine
  einheitliche UI-Darstellung normalisiert.
- [x] Die Rohkategorie bleibt als Quellenmetadatum erhalten; die Darstellung
  greift nicht in Identität, Preis, Gültigkeit oder Route ein.
- [ ] Fehlende Kategorien in ALDI-, EDEKA- und Netto-Live-Antworten werden erst
  ergänzt, wenn die Händlerquelle sie belastbar liefert; UI-Klassifikation
  ersetzt keine Quellenangabe.

## Update 01.10.2026 – Netto-Labels auf verwertbare Produkte begrenzen
- [x] Offensichtliche Netto-Platzhalter und reine Rabatt-/Herkunftszeilen
  werden vor der Feed-Erzeugung verworfen.
- [x] Gültige Produktlabels bleiben in Kachel-, Link- und Text-Fallbacks
  erhalten; ein Regressionstest deckt die Abgrenzung ab.
- [ ] Die Netto-Quelle muss weiterhin belastbare Produktdaten und Bilder
  liefern, bevor die fehlenden aktuellen Angebote wieder ergänzt werden
  können. Der Adapter erfindet diese Daten nicht.
- [x] Der Bestands-Fallback entfernt dieselben unvollständigen Labels, wenn
  die offizielle Netto-Seite vorübergehend nicht auslesbar ist.

## Update 01.10.2026 – Angebotsquellen transparent ausweisen
- [x] Märkte ohne aktuelle Angebotsdatensätze bleiben im Tab „Angebote“ mit
  Händler- und Filialstatus sichtbar.
- [x] Abruffehler, fehlende strukturierte Produktdaten und ein leerer aktueller
  Angebotszeitraum werden getrennt benannt; kein Status erzeugt einen Preis.
- [ ] Belastbare Netto-Produktdaten und Bilder bleiben eine Quellaufgabe und
  werden erst bei nachweisbarer Händlerantwort wieder als Angebote angezeigt.
- [x] Der Status führt direkt zum offiziellen Händlerprospekt, ohne die
  fehlende Quelle durch einen Preis zu ersetzen.

## Update 01.10.2026 – Netto-Reader-Fallback
- [x] Der offizielle öffentliche Reader-Fallback liest Netto-Markdown-Kacheln
  mit Produktlink, Preis, Packung, Bild und Gültigkeitsende.
- [x] Die sechs konfigurierten Märkte liefern wieder einen sichtbaren
  Quellenstatus; Netto-Angebote werden nur mit ihrem offiziellen Nachweis und
  eigenem Gültigkeitsfenster übernommen.
- [x] Parserregressionen sichern den Fallback gegen reine Rabatt-/Sorten- und
  Herkunftsplatzhalter ab.

## Update 01.10.2026 – Aktive Fallbackangebote kenntlich machen
- [x] Gültige Bestandsangebote eines vorübergehend nicht erreichbaren
  Händlerfeeds bleiben sichtbar, solange ihr eigenes Angebotsfenster gilt.
- [x] Der Angebotstab kennzeichnet diesen Stand als letzten geprüften
  Prospekt und zeigt die fehlende automatische Aktualisierung ohne Preis- oder
  Identitätserfindung.
- [ ] Die Händlerquelle muss weiterhin regelmäßig erfolgreich aktualisieren,
  damit der Hinweis wieder in einen frischen Live-Status übergeht.

## Update 02.10.2026 – Fallback-Provenienz in Angebote und Prospekte
- [x] Beide Prospektansichten kennzeichnen gültige Bestandsangebote eines
  fehlgeschlagenen Händlerabrufs als letzten geprüften Prospektstand.
- [x] Die Prospektkarte zeigt dabei die Anzahl der gültigen Datensätze; die
  Detailansicht bleibt preisfrei und verweist auf die fehlende Aktualisierung.
- [x] Karten- und Detailpfad sind als Widgetregression abgesichert.

## Update 02.10.2026 – Sparorientierte Reihenfolge verwandter Varianten
- [x] Verwandte Interpretationen werden nach aktueller Angebots-/Preisevidenz
  und danach nach dem belastbaren Preis sortiert.
- [x] Unbelegte Varianten bleiben sichtbar und als Interpretation getrennt;
  die Sortierung erweitert keine Preisidentität.
- [x] Der offene `K.H-Milch`-Fall ist mit einer Preisrangfolge-Regression
  abgesichert.

## Update 02.10.2026 – Normale Milch aus unklaren Bonkürzeln auswählbar
- [x] `K.H-Milch` öffnet neben getrennten H-Milch-Fettstufen auch eindeutig
  normale Milchprodukte für den Preisvergleich.
- [x] Aktuelle Angebote für normale Milch werden im Such- und Kandidatenpfad
  zuerst berücksichtigt, ohne Produktidentitäten oder Preise zu verschmelzen.
- [x] Regressionen sichern beide Auswahlpfade und den bestehenden Schutz vor
  unbestätigten Varianten ab.

## Update 11.10.2026 – Prospektkategorien direkt durchsuchbar
- [x] Aktuelle Prospektartikel können zusätzlich zur Volltextsuche über ihre
  vorhandene Händler- oder Darstellungskategorie gefiltert werden.
- [x] Der Kategorienfilter bleibt reine Navigation: Herkunft, Gültigkeit,
  Produktidentität und sichere Add-to-List-Auflösung werden nicht verändert.
- [x] Widgetregression prüft die Auswahl einer Kategorie über mehrere Märkte.

## Update 11.10.2026 – Originalnachweis an jeder belegten Artikelkarte
- [x] Belegte kompakte und große Prospektkarten öffnen ihren vorhandenen
  HTTP(S)-Originalnachweis direkt aus der Artikelansicht.
- [x] Fehlende oder ungültige Nachweise erzeugen keinen Link und bleiben nach
  den bestehenden Identitätsregeln nicht auswählbar.
- [x] Widgetregression prüft die sichtbare Nachweisaktion und den Review-Fall.

## Update 11.10.2026 – Filialort in Suchtreffern
- [x] Marktübergreifende Prospektartikel zeigen den vorhandenen Filialort direkt
  unter dem Händlernamen.
- [x] Fehlende Filialdaten bleiben leer; es werden keine Standorte aus Labels
  oder Händlerähnlichkeiten erfunden.
- [x] Widgetregression deckt den sichtbaren Ort im Trefferpfad ab.

## Update 11.10.2026 – Prospektartikel nach Händler auswählen
- [x] Die Prospektansicht bietet Händlerchips für die direkte Marktfilterung.
- [x] Die Filterung nutzt nur aktuell gültige Datensätze und den bestehenden
  Nachweis-/Identitätsvertrag; sie erzeugt keinen Preis oder Marktbezug.
- [x] Widgetregression prüft die Auswahl eines Händlers gegenüber einem zweiten
  Markt.

## Update 11.10.2026 – Offizielle Prospektlinks validieren
- [x] Der offizielle Händlerlink im Prospektreader wird vor dem Öffnen auf ein
  gültiges HTTP(S)-Ziel mit Host geprüft.
- [x] Ungültige URI-Schemes bleiben ohne externe Aktion; Prospektdaten und
  Angebotsidentität werden dadurch nicht verändert.

## Update 11.10.2026 – Angebotsnachweise in der Abdeckung ausweisen
- [x] Die Abdeckungskarte zählt pro Markt die strukturierten Angebotsdatensätze
  mit vorhandenem Originalnachweis.
- [x] Fehlende Nachweise bleiben als sichtbare Datenlücke bestehen und werden
  weder durch einen Händlerlink noch durch eine Preis- oder Identitätsannahme
  ersetzt.
- [x] Ungültige URI-Schemes oder URLs ohne Host werden nicht als belastbarer
  Originalnachweis gezählt.


## Update 13.10.2026 – Preisvergleich für lange Listen
- [x] Preisvergleichskarten im Preise-Reiter werden in kleinen Seiten aufgebaut, damit lange Einkaufslisten nicht beim ersten Öffnen alle Detailkarten rendern.
- [x] Die bestehende Preisabdeckung bleibt vollständig; nur die sichtbare Vergleichsliste wird schrittweise erweitert.
- [x] Der Nachladepfad ist widgetgetestet und ändert keine Preis-, Angebots- oder Routenlogik.


## Update 13.10.2026 – Fehlende Preisbelege schneller erfassen
- [x] Der Preise-Reiter führt fehlende Marktpreise je Listenposition direkt in die bestehende Datenlückenauflösung.
- [x] Produkt-/Preiswahl, Quellenprüfung und Speicherung bleiben im vorhandenen `openPriceGapEditor`-Pfad gebündelt.
- [x] Die neue Aktion erzeugt keine Ersatzpreise und ändert keine Routenentscheidung ohne bestätigte Evidenz.


## Update 13.10.2026 – Route-Rebuilds beschleunigen
- [x] Der Route-Reiter cached den Optimierungs-Snapshot über stabile Eingabereferenzen und invalidiert bei Daten- oder Tageswechsel.
- [x] Preisabdeckung, Mindestvorteil, Fahrtkosten und Marktanzahl werden weiterhin ausschließlich vom bestehenden `RouteOptimizer` berechnet.
- [x] Der Performance-Block ändert keine Preisquelle und führt keine zusätzlichen Netzwerkanfragen ein.


## Update 14.10.2026 – Lange Einkaufslisten beschleunigen
- [x] Warengruppen werden im Einkaufsliste-Reiter seitenweise aufgebaut; zusätzliche Gruppen bleiben über „Weitere Warengruppen laden“ erreichbar.
- [x] Der bestehende Preis-, Angebots- und Kaufaktionsfluss wird unverändert an jede Gruppe weitergegeben.
- [x] Die neue Begrenzung ist lokal und reversibel und erzeugt keine zusätzlichen Datenabrufe.


## Update 14.10.2026 – Bestätigte Normalpreisspeicherung in den Prospektansichten
- [x] Der Angebotstab verwendet für den Hinweis „als Preisbasis gespeichert“ ausschließlich die vom lokalen Preisbeobachtungslauf bestätigte Anzahl.
- [x] Ein fehlgeschlagener oder noch nicht abgeschlossener Speichervorgang erzeugt keinen falschen Bestätigungsstatus, obwohl der Feed einen ausdrücklich ausgewiesenen Normalpreis enthält.
- [x] Die Standalone-Ansicht behält ihren konservativen Feed-Fallback, wenn kein Shell-Persistenzwert übergeben wird.


## Update 14.10.2026 – Reguläre Preisbasis je Händler nachvollziehbar
- [x] Der Prospektfeed führt die Anzahl ausdrücklich ausgewiesener Normalpreise je Händler bis in die Abdeckungskarte.
- [x] Die Anzeige trennt feed-seitig lernbare Normalpreise von den tatsächlich in `PriceObservationStore` gespeicherten Beobachtungen.
- [x] Bei einem fehlgeschlagenen Persistenzlauf bleibt der Speicherstatus unbekannt beziehungsweise null; ein Angebotspreis wird niemals als regulärer Preis gezählt.

## Update 14.10.2026 – Erfolgreiche Preisprüfung zeigt auch Nullspeicherung
- [x] Ein erfolgreicher Persistenzlauf wird je Händler mit `0 gespeichert` ausgewiesen, wenn der aktuelle Feed keinen belegten regulären Preis enthält.
- [x] `null` bleibt dem nicht übergebenen oder fehlgeschlagenen Speicherstatus vorbehalten; der UI-Fallback erfindet keine Bestätigung.
- [x] Die Statusprojektion wird mit einer Regression für leere Händlerkarten abgesichert.

## Update 14.10.2026 – Regulärer Prospektpreis im Preisvergleich sichtbar
- [x] Preisbeobachtungen behalten die Evidenzart `regular` bis in die Preisansicht.
- [x] Ausdrücklich ausgewiesene Normalpreise werden als `Prospektpreis · Normalpreis` gekennzeichnet und bleiben vom aktiven Angebot getrennt.
- [x] Widget- und Fachtests sichern die Kennzeichnung, ohne Legacy-Preise oder die Routenbewertung zu verändern.


## Update 14.10.2026 – Quellen- und Refresh-Provenienz geschützt
- [x] Ein Feed-Refresh ordnet Händlernamen nur nach Groß-/Kleinschreibung und Rand-Whitespace zu; unterschiedliche Märkte bleiben getrennt.
- [x] Die lokale Kompaktierung hält automatische Beobachtungen je Adapter getrennt, damit KaufDA- und Händlerdaten ihre Herkunft behalten.
- [x] Regressionen sichern den Refresh-Filter und die Quota-Buckets ohne zusätzliche Netzwerkanfragen.


## Update 14.10.2026 – Persistenzstatus in Angebote und Prospekte eindeutig
- [x] Die Tabs unterscheiden Feed-Erkennung, laufende Speicherung, bestätigte Speicherung und unbekannten Speicherstatus.
- [x] Eine bestätigte Nullspeicherung wird sichtbar als `0` ausgewiesen; ein Fehler wird nicht als `0 gespeichert` ausgegeben.
- [x] Standalone-Ansichten behaupten keine lokale Speicherung ohne Shell-Nachweis.


## Update 14.10.2026 – Abdeckungskarte mit Persistenzstatus
- [x] Die Prospekt-Abdeckungskarte unterscheidet bestätigte Speicherung von laufender, fehlgeschlagener und nicht bestätigter Preisbeobachtung.
- [x] Ein fehlgeschlagener Lauf zeigt keine `0 gespeichert`-Aussage und bleibt als unbekannt sichtbar.
- [x] Die Einzelmarkt-Details verwenden denselben Status wie die Kopfzeile.


## Update 14.10.2026 – Tägliche Prospektaktualisierung
- [x] Der öffentliche Händlerfeed wird täglich um 04:15 Uhr Europe/Berlin-nah aktualisiert.
- [x] Der bestehende Refresh bleibt auf die sechs konfigurierten offiziellen Filialquellen begrenzt; KaufDA bleibt opt-in und ersetzt keine exakte Filiale.
- [x] Neue reguläre Normalpreise gelangen nach dem Feed-Refresh automatisch in den lokalen `PriceObservationStore`; Angebotspreise bleiben davon getrennt.

## Update 14.10.2026 – Explizite Normalpreisfelder toleranter auslesen

- [x] Händleradapter akzeptieren zusätzliche ausdrücklich benannte Vorher-/Streichpreisfelder (CamelCase und snake_case), ohne Rabattprozente, UVPs oder beliebige Zahlen als Normalpreis zu deuten.
- [x] Die Alias-Auflösung bleibt vor dem Angebotspreisvergleich und speichert nur Werte, die mindestens so hoch wie der Angebotspreis sind.
- [x] Parser-Fixtures decken die zusätzlichen Feldnamen ab; Datenmodell, Quellenpriorität und aktive Angebotspreise bleiben unverändert.

## Update 14.10.2026 – Quellenmetadaten für Bilder und Kategorien erweitern

- [x] Offizielle Prospektadapter akzeptieren zusätzliche ausdrücklich benannte Bildfelder und flache beziehungsweise verschachtelte Renditions, wenn die Quelle eine gültige HTTP(S)-URL liefert.
- [x] Zusätzliche sichtbare Kategoriebezeichnungen werden als Quellenmetadatum übernommen; IDs, URLs und beliebige nicht-textuelle Werte bleiben ausgeschlossen.
- [x] Die Erweiterung ändert weder Produktidentität noch Preis-/Gültigkeitslogik und ist mit Parser-Fixtures abgesichert.

## Update 15.10.2026 – Aktuelle reguläre Prospektpreise nach Refresh-Provenienz projizieren

- [x] Append-only Normalpreisbeobachtungen bleiben vollständig historisch gespeichert.
- [x] Für dieselbe Produkt-/Filial-/Gültigkeitskombination ersetzt ein neuerer regulärer Prospektnachweis die ältere aktuelle Projektion auch dann, wenn sich die Prospektseite oder `proofRef` geändert hat.
- [x] Die aktuelle Preisprojektion und Route verwenden dadurch keinen niedrigeren, veralteten Normalpreis aus einer früheren Feedfassung; Nachweis und Historie bleiben sichtbar.
- [x] Eine Regression deckt den Wechsel des Prospektnachweises bei identischer Produkt-/Filial-/Gültigkeitsidentität ab.

## Update 15.10.2026 – Selektiver Cover-Fallback bei Canvas-/CORS-Problemen

- [x] Coverkarten verwenden weiterhin den Canvas-first-Pfad mit begrenzter Decode-Größe, damit schnelles Scrollen keine Plattform-Views pro Karte erzeugt.
- [x] Nur ein Bild, dessen Canvas-Decodierung tatsächlich fehlschlägt, wechselt einmalig auf den HTML-Fallback; erfolgreiche Cover bleiben im schnellen Pfad.
- [x] Favoritenrail und Coverraster teilen dieselbe begrenzte Decode-Größe und vermeiden dadurch doppelte Bildcache-Einträge.
- [x] Der Angebote-Widgettest schützt Coverdarstellung und Seitenansicht.

## Update 15.10.2026 – Issue #409: Seitenvollständigkeit und Datenabdeckung
- [x] Offizielle EDEKA-`catalog.xml`-Bereiche und ALDI-/Netto-Publitas-
  `spreads.json`-Listen vollständig und mit Cache-Token importieren.
- [x] Kaufland-Lebensmittelkampagne gegenüber dem gleichzeitigen `-OD`-
  Drogerieblatt auswählen und alle offiziellen Leaflet-v4-Seiten übernehmen.
- [x] Lidl-Kampagnen nach Zeitraum deduplizieren, vollständige Seitenlisten
  behalten und Dictionary-Produktanzahlen korrekt ausweisen.
- [x] Fehlende oder nicht abrufbare Seiten, Cover-only-Quellen und unbekannte
  Publisher-Gesamtzahlen im Feed und in der Prospekt-Abdeckung anzeigen.
- [x] Seitenabdeckung beim Branch-Resolver und in der Tages-Fingerprint-Logik
  erhalten; Wiederholungsimports bleiben idempotent.
- [x] Den bestehenden `ReceiptObservation → PriceObservation → MarketPrice →
  planningMarketPrices → RoutePriceResolver → RouteOptimizer`-Pfad unverändert
  weiterverwenden; belegte Normalpreise und Angebote bleiben getrennt.
- [x] Den lokalen Feedcache auf einen begrenzten, ersetzbaren Eintrag mit
  4-MiB-Grenze beschränken und Originalbelege außerhalb dieses Caches nicht
  antasten.
- [x] OCR-/Hotspot-Kandidaten werden nur als sichtbare, unsichere
  Artikelreview ergänzt, wenn die Quelle keinen strukturierten Artikel liefert;
  automatische Identitäts- oder Preisprojektion bleibt ohne Bestätigung gesperrt.
- [x] Nach dem Speichern eines geprüften OCR-Artikels bleibt die Evidenzstufe
  `MANUELL_BESTÄTIGT` in Angebot, Preisbeobachtung und Marktpreis-Projektion
  erhalten; ältere Datensätze bleiben ohne diese optionale Metadaten-Spalte
  abwärtskompatibel lesbar.
## Update 15.10.2026 – Exakte Filiale für automatische Normalpreise

- [x] Der automatische Persistenzschritt speichert reguläre Prospektpreise nur
  mit einem ausdrücklich gelieferten Filialschlüssel.
- [x] Prospektzeilen ohne Filiale bleiben für sichtbare Prüfung und historische
  Evidenz verfügbar, werden aber nicht als aktueller `MarketPrice` projiziert.
- [x] Die bestehende Herkunfts-, Gültigkeits-, Nachweis- und
  Packungsgrößenprüfung bleibt unverändert; eine Regression schützt die
  fehlende-Filiale-Grenze.
## Update 15.10.2026 – Alte automatische Angebotsbeobachtungen bereinigen

- [x] Der Persistenzlauf entfernt neben dem aktuellen `prospect|`-Format auch
  ältere automatische `offer|import|`-Angebotsbeobachtungen.
- [x] Manuell geprüfte Seitenangebote bleiben anhand ihrer eigenen ID und
  Evidenz erhalten; reguläre Preisbeobachtungen werden nicht gelöscht.
- [x] Eine Fixture-Regression schützt die Trennung zwischen Altbereinigung und
  dem ausschließlich regulären Normalpreisbestand.

## Update 15.10.2026 – Branchlose Prospektprojektionen gesperrt

- [x] Reguläre Prospektbeobachtungen ohne exakte Filial-ID bleiben im lokalen Verlauf sichtbar, werden aber nicht mehr als `MarketPrice` für Route und Preisvergleich projiziert.
- [x] Die Projektion akzeptiert branchlose Beobachtungen aus manuellen, Bon- und sonstigen nicht-prospektbezogenen Quellen weiterhin nach den bestehenden Regeln.
- [x] Eine Regression schützt die Grenze zwischen historischer Evidenz und route-fähigem aktuellem Preis.

## Update 15.10.2026 – Formatierte Aktionspreise sicher normalisieren

- [x] Aktionspreise aus öffentlichen Feeds akzeptieren neben JSON-Zahlen auch ausdrücklich als EUR/€ gekennzeichnete deutsche Anzeigewerte.
- [x] Benannte verschachtelte Preisfelder (`amount`, `value`, `formattedPrice` usw.) werden begrenzt gelesen; freie Texte und nackte Zahlenstrings bleiben ungültig.
- [x] Eine Parserregression schützt den Weg vom Feed über den regulären Normalpreis bis zur lokalen Speicherung.

## Update 15.10.2026 – Begrenzter Prospekt-Scrollvorlauf

- [x] Der äußere Angebote-Scroll wärmt maximal eine Kartenreihe vor, damit Coverbilder und erste Artikel vor dem Sichtbereich dekodiert werden.
- [x] Cover- und Seitenlisten behalten ihre eigenen Seiten-/Fallback-Limits; der Vorlauf materialisiert nicht den vollständigen Feed.
- [x] Eine Widgetregression schützt den festen Vorlauf von 360 Pixeln.

## Update 15.10.2026 – Startbereinigung alter Prospektaktionspreise

- [x] Der lokale Preisbeobachtungsspeicher entfernt beim Start nur veraltete automatische `prospect|`-/`offer|import|`-Aktionszeilen.
- [x] Reguläre Normalpreisbelege sowie manuelle und Bon-Evidenz bleiben bei Offline-/Feedfehlern erhalten.
- [x] Eine Fixture-Regression schützt die Bereinigung ohne aktuellen Feed.

## Update 15.10.2026 – EAN-Enrichment übernimmt konkrete Packungsgrößen

- [x] Open Food Facts ersetzt den generischen lokalen Einheitstext `Artikel`
  beim EAN-Abgleich durch eine verifizierte Menge, sofern die Quelle sie liefert.
- [x] Eine ausdrücklich gesetzte lokale Einheit bleibt maßgeblich; strukturierte
  `packageAmount`-/`packageUnit`-Daten werden trotzdem übernommen.
- [x] Regressionen sichern lokale Produktidentität, Packungsgröße und die
  Trennung zwischen Quellenmetadaten und manueller Einheit.

## Update 15.10.2026 – Begrenzter Vorlauf im Prospekte-Reiter

- [x] Der vertikale Prospekte-Feed wärmt höchstens eine Kartenreihe vor, damit
  Coverbilder bei schnellen Wischbewegungen früher dekodiert werden.
- [x] Der Vorlauf bleibt auf 360 Pixel begrenzt; Seitenviewer und Cover-Fallback
  behalten ihre eigenen Speichergrenzen.
- [x] Eine Widgetregression prüft den festen Vorlauf ohne zusätzliche Abrufe.

## Update 15.10.2026 – Preise-Ledger bleibt filialgenau

- [x] Der aktuelle Prospekt-Normalpreis-Ledger zeigt nur Beobachtungen mit
  ausdrücklich gespeicherter exakter Filial-ID.
- [x] Branchlose Altbeobachtungen bleiben für Historie und Prüfung erhalten,
  werden aber weder als aktueller Ledger-Preis noch als Routenpreis ausgegeben.
- [x] Eine Fachregression schützt die Grenze zwischen sichtbarer Historie und
  aktueller Filialabdeckung.
## Update 15.10.2026 – Bring-Normalpreisfelder explizit auswerten

- [x] Der optionale Bring-Adapter übernimmt benannte Streich-/Vorherpreisfelder in CamelCase, snake_case und deutschen Feldnamen.
- [x] Rabattprozente, UVP-Felder und beliebige numerische Felder bleiben ausgeschlossen; ein Normalpreis muss mindestens so hoch wie der Angebotspreis sein.
- [x] Die Änderung erweitert nur die Normalpreis-Erkennung; Gültigkeitszeitraum, Filiale, Nachweis und die Trennung von Angebotspreis und Preisbasis bleiben unverändert.
## Update 15.10.2026 – Cover-Metadaten bei Quellfehlern erhalten

- [x] Ein fehlgeschlagener Händler-Refresh löscht keinen noch gültigen, zuvor validierten Prospektcover.
- [x] Der Fallback bleibt an die exakte Filiale gebunden und verwirft abgelaufene Seiten weiterhin.
- [x] Der Fehlerstatus und die alte Erfassungsherkunft bleiben sichtbar; neue Angebote werden bei einem Quellfehler nicht erfunden.
## Update 16.10.2026 – Bewegliche Grundpreis-Fixture

- [x] Die Prospektmatrix prüft weiterhin belegte Packungs- und Grundpreise, ohne einen einzelnen Tageswert als dauerhaftes Angebot vorauszusetzen.
- [x] Einheit, Preisbasis und sichere unaufgelöste Mehrfachmengen bleiben im Testfall erhalten.
## Update 16.10.2026 – Dart-Feedparser für Normalpreise tolerant

- [x] Der Dart-Parser übernimmt dieselben ausdrücklich benannten Vorher-/Streichpreisfelder wie die Quelladapter.
- [x] UVP-, Rabatt- und beliebige Zahlenfelder bleiben ausgeschlossen; nur ein positiver, expliziter Normalpreis wird gespeichert.
- [x] Die Parserregression führt die Aliaswerte bis in die reguläre Prospektpreis-Evidenz.

## Update 16.10.2026 – Unveränderter Prospektfeed reconciliert den Preisstand

- [x] Ein unveränderter, erneut geladener Feed schreibt explizite reguläre
  Prospektpreise erneut idempotent in den lokalen Beobachtungsspeicher.
- [x] Ein zwischenzeitlich geleerter oder fehlgeschlagener lokaler Preisstand
  bleibt damit beim nächsten Feedlauf reparierbar, ohne Angebotsdaten neu zu
  materialisieren.
- [x] Die Regression prüft die Wiederherstellung ausschließlich des belegten
  Normalpreises; der Aktionspreis bleibt aus dem Preisledger ausgeschlossen.
## Update 16.10.2026 – Angebotsabdeckung auch im Angebotstab

- [x] Der Angebotstab zeigt dieselbe pro Händler aufgeschlüsselte Datenabdeckung wie der Prospekte-Reiter.
- [x] Explizit fehlende Normalpreise bleiben je Filiale als unbekannt beziehungsweise `0/Artikel` sichtbar; Aktionspreise werden nicht als Preisbasis gezählt.
- [x] Die Abdeckung nutzt ausschließlich aktuelle Datensätze und den lokalen Persistenzstatus und ändert keine Preis- oder Routenentscheidung.

## Update 16.10.2026 – Produktkatalog seitenweise rendern

- [x] Der Produktkatalog baut zunächst höchstens 40 Produktkarten auf und lädt weitere Karten explizit nach.
- [x] Eine neue Suche setzt den sichtbaren Seitenstand zurück; Produkt-, Preis- und Open-Prices-Daten bleiben unverändert.
- [x] Der Nachladepfad ist widgetgetestet und erzeugt keine zusätzlichen Datenabrufe.

## Update 16.10.2026 – Food-only Prospektfeed konsequent halten

- [x] Eindeutig als Non-Food gekennzeichnete Badartikel und Halloween-Dekorationen werden vor dem aktuellen Angebotsfeed entfernt.
- [x] Lebensmittel in gemischten Händlerkategorien bleiben erhalten; die Sperre nutzt explizite Artikel-/Kategorienachweise.
- [x] Der versionierte Feed und Parserregressionen prüfen gemeinsam, dass aktuelle Prospektangebote food-only bleiben.

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
  aktuelle Ledger-Projektion folgt jetzt demselben isCurrent-Vertrag wie Route
  und MarketPrice.
- [x] Eine Widget-/Fachregression schützt den Fall eines nach Refresh
  supersedierten, weiterhin gültigen Belegs.


## Update 17.10.2026 – Bildherkunft in Prospektangeboten
- [x] Prospektangebote unterscheiden jetzt zwischen einem vom Adapter gelieferten Artikelbild und einem als Nachweis verwendeten Prospektseitenbild. Die Abdeckungsanzeige und Angebotskarten zeigen diese Herkunft ausdrücklich; fehlende oder ältere Bilddaten bleiben dadurch sichtbar.


## Update 17.10.2026 – Produktmetadaten-Abdeckung in Prospektangeboten
- [x] Die Prospektabdeckung weist vorhandene EAN/GTIN-, Packungsgrößen- und Grundpreisfelder je aktuellem Angebot getrennt aus.
- [x] Fehlende Metadaten bleiben als sichtbare Lücke erhalten; aus Produktnamen werden keine EANs oder Packungsgrößen erfunden.
- [x] Die Zusatzanzeige ändert weder Produktidentität noch Preis-/Routenprojektion und ist mit Parser- und Widgetregressionen abgesichert.


## Update 17.10.2026 – Favoritenstreifen im Prospekte-Reiter begrenzt
- [x] Der ältere Prospekte-Ansichtspfad verwendet für den horizontalen Favoritenstreifen keinen zusätzlichen Scrollvorlauf.
- [x] Offscreen-Coverkarten werden dort nicht automatisch gehalten; Repaint-Grenzen bleiben aktiv.
- [x] Eine Widgetregression schützt den begrenzten Cache beim vertikalen Wischen, ohne Prospekt-, Preis- oder Listenlogik zu ändern.


## Update 17.10.2026 – Prospektsuche berücksichtigt Quellenmetadaten
- [x] Angebote- und Prospekte-Reiter durchsuchen neben Name und Kategorie auch vorhandene EAN/GTIN-, Packungsgrößen- und Grundpreisfelder.
- [x] Die Suche verwendet ausschließlich bereits importierte Quellenwerte; Produktidentität, Preise und Gültigkeitsprüfung bleiben unverändert.
- [x] Widgetregressionen prüfen EAN- und Packungsgrößensuche in beiden Ansichten.

## Update 17.10.2026 – Prospektpreis-Persistenz migriert und Cache-Status geklärt

- [x] Alte automatische Prospekt-Rabattbelege werden beim lokalen Bereinigungslauf auch erkannt, wenn ältere JSON-Daten kein `kind` mehr enthalten und nur `discounted=true` bewahren.
- [x] Reguläre Beobachtungen im selben ID-Namensraum bleiben erhalten; manuelle und Bon-Evidenz werden nicht gelöscht.
- [x] Ein zuerst sichtbarer Cache-Feed zeigt während der lokalen Normalpreis-Projektion ausdrücklich `Speicherung läuft`; alte bestätigte Zähler werden nicht auf den neuen Feed übertragen.
- [x] Regressionen sichern Migration, Statuswechsel und die unveränderte Trennung von Aktionspreis und regulärer Preisbasis.

## Update 17.10.2026 – Prospektparser-Filialgrenze vereinheitlicht

- [x] Filial-IDs aus Quellenmetadaten, Prospektseiten und Angebotszeilen über
  \`canonicalBranchId\` zusammenführen, wenn nur Leerraum oder Groß-/Kleinschreibung
  abweichen.
- [x] Originale Filialwerte für Nachweis und Anzeige erhalten; unbekannte oder
  abweichende Filialen bleiben getrennt.
- [x] Regression für Quelle, Ort, Adresse und Prospektseitenbild ergänzt.

## Update 17.10.2026 – KaufDA-Taxonomie und Artikelbilder

- [x] Singuläre und plurale KaufDA-Kategoriepfade begrenzt auswerten.
- [x] Gemischte Lebensmittel-Taxonomien wie Obst/Gemüse/Pflanzen nicht wegen
  eines Sammelbegriffs verwerfen.
- [x] Explizite Produktbildlisten und zusätzliche Mengenfelder übernehmen,
  ohne URLs oder Identitäten zu erfinden.
- [x] Regressionen für Non-Food-Taxonomien, Kategoriepfade, Bilder und
  Packungsgrößen ergänzen.

## Update 17.10.2026 – KaufDA-Erfassungszeitpunkt über Suchbegriffe vereinheitlicht

- [x] Händlergruppen aus mehreren KaufDA-Suchbegriffen auf den neuesten
  erfolgreichen Erfassungszeitpunkt fortschreiben.
- [x] Gemischte Live-/Cache-Herkunft über \`cacheUsed\` sichtbar halten.
- [x] Regression für älteren Cache vor späterem Live-Treffer ergänzen.

## Update 17.10.2026 – KaufDA verschachtelte Gültigkeit und Packungsgröße

- [x] Ausdrücklich benannte verschachtelte Start-/Endfelder aus öffentlichen
  KaufDA-Daten begrenzt normalisieren.
- [x] Mengenobjekte mit Betrag und Einheit als Packungsgröße übernehmen.
- [x] Unvollständige Zeiträume verwerfen und Regressionen für beide Fälle
  ergänzen.

## Update 17.10.2026 – KaufDA öffentliche Feldaliasse

- [x] Händler- und Angebots-ID-Aliase sowie Händlerobjekte begrenzt erkennen.
- [x] Verschachtelte Preisobjekte aus bekannten Betragsfeldern normalisieren.
- [x] Die Erkennung verschachtelter Ergebnislisten mit synthetischen Daten testen.

## Update 17.10.2026 – Aktuelle Preisbasis bei lokaler Begrenzung

- [x] Aktuelle automatische Beobachtungen bei gleicher exakter Quelle vor
  älteren historischen Zeilen priorisieren.
- [x] Begrenzte Historie und globale Obergrenze unverändert beibehalten.
- [x] Regression für einen aktuellen regulären KaufDA-Beleg ergänzen.


## Update 17.10.2026 – KaufDA-Herkunft bei mehreren Filialen
- [x] Eine eindeutige gemeinsame Adapterherkunft bleibt sichtbar, wenn ein Händler im Feed mehrere Filialen hat.
- [x] Branchlose KaufDA-Treffer werden dadurch weiterhin als regional erkannt angezeigt und bleiben für Preis-/Routenprojektion gesperrt.
- [x] Bei gemischten Adaptern oder widersprüchlicher Filialherkunft bleibt die Zuordnung unbekannt.


## Update 17.10.2026 – Prospektsuche paginiert
- [x] Große Prospektsuchen materialisieren zuerst höchstens 40 Ergebnisartikel.
- [x] Weitere aktuelle Treffer werden über einen sichtbaren Nachladebutton
  ergänzt; Suchanzahl und Filial-/Quellenlogik bleiben vollständig.
- [x] Die Begrenzung reduziert den ersten Layout- und Bildaufwand beim Scrollen.


## Update 17.10.2026 – Prospekt-Coverraster paginiert
- [x] Der Prospekte-Reiter baut zunächst höchstens 12 Coverkarten auf.
- [x] Weitere aktuelle Prospekte bleiben über einen sichtbaren Nachladebutton
  erreichbar; Favoriten und Seitenviewer werden nicht verändert.
- [x] Der begrenzte erste Rasteraufbau reduziert Bilddekodierung und Scrollarbeit.

## Update 17.10.2026 – Prospektseiten progressiv laden
- [x] Der Seitenviewer baut zunächst höchstens zwölf Seitenkarten auf.
- [x] Weitere validierte Seiten bleiben über eine sichtbare Nutzeraktion
  erreichbar; Seitenzahlen und Quellenbelege werden nicht verändert.
- [x] Die lange Viewer-Regression deckt das Nachladen bis zur letzten Seite ab.

## Update 17.10.2026 – Preise-Reiter zeigt günstigste Hinweise zuerst
- [x] Aktuelle Preis-Hinweise werden nach dem belastbaren Vergleichswert
  aufsteigend sortiert.
- [x] Gleichstände werden über Produkt- und Marktnamen deterministisch gelöst.
- [x] Die Sortierung verändert weder gespeicherte Belege noch die
  Routenberechnung.


## Update 17.10.2026 – Routenpreise tolerieren Händler-Schreibvarianten

- [x] Reine Präsentationsvarianten von Händlerlabels im RoutePriceResolver zusammenführen.
- [x] Exakte Filial-ID weiterhin separat prüfen und nicht über die Labelnormalisierung ersetzen.
- [x] Regressionen für Angebotspreis und gespeicherten Marktpreis ergänzen.


## Update 17.10.2026 – Gemeinsame Händlerlabel-Normalisierung

- [x] RoutePriceResolver und Preis-Marktmatrix verwenden denselben Präsentationsschlüssel.
- [x] Aktivierte Märkte erkennen Groß-/Kleinschreibung, Diakritika und `ae/oe/ue`-Varianten.
- [x] UI- und Matrix-Regressionen sichern die konfigurierte Anzeige und den Quelllabel-Nachweis.


## Update 17.10.2026 – Branchschutz bei Händler-Schreibvarianten

- [x] Filialprüfung über den gemeinsamen Händlerlabel-Schlüssel ausführen.
- [x] Exakte Branch-ID weiterhin als harte Grenze behandeln.
- [x] Regressionen für passende und fremde Filialen mit abweichendem Händlerlabel ergänzen.