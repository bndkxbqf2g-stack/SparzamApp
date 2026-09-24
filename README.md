# SparzamApp

SparzamApp ist ein Flutter-Prototyp für intelligent geplante Lebensmitteleinkäufe. Die App verbindet Einkaufsliste, Produktkatalog, reale Preisbeobachtungen, Angebote, Preisvergleich, Routenoptimierung, Kaufhistorie und Lebensmittelbudget. Der aktuelle Stand arbeitet lokal auf einem Gerät; Benutzerkonto, Cloud-Backup und Mehrgeräte-Synchronisierung sind noch nicht Bestandteil der App.

> **Dokumentationsziel:** Diese README beschreibt den tatsächlich implementierten Funktions- und Logikstand. Bei Änderungen an Funktionen, Berechnungen, Preislogik oder Datenmodellen soll sie mitgepflegt werden. Für Entwicklungsentscheidungen ergänzen `docs/PROJECT_STATUS.md`, `docs/ARCHITECTURE.md`, `docs/ROADMAP.md` und `docs/DECISIONS.md` diese Übersicht.

## 1. Hauptbereiche

### Start / Dashboard
- Zeigt Einkaufs-/Routeninformationen, Budgetstatus, Sparpotenzial, aktive Angebote und Wiederkaufhinweise.
- Verwendet die aktuelle optimierte Route und eine Ein-Markt-Vergleichsroute als Grundlage für Kosten- und Sparanzeigen.
- Monatswerte werden aus der lokalen Kaufhistorie gebildet.

### Einkaufsliste
- Mehrere benannte Einkaufslisten.
- Listen- und Kachelansicht.
- Mengen, Notizen, Erledigt-Status und speicherbare Reihenfolge der Warengruppen.
- Bekannte bzw. zuletzt gekaufte Produkte unterstützen die Produktauswahl.
- Eigene freie Produkte können angelegt werden.
- Barcode-Scanner verwendet vorhandene Katalogdaten bzw. Open Food Facts.
- Historische Bonpreise werden als Preis-Hinweis am Produkt angezeigt.
- Exakte Produkt-ID-Historie hat Vorrang. Fehlt sie, darf eine passende Produktfamilie als konservativer historischer Hinweis dienen.
- Familienhinweise sind **keine Behauptung, dass zwei Varianten identisch sind**. Beispiel: Rinderhack und gemischtes Hack bleiben unterschiedliche Produktidentitäten.
- Nicht vergleichbare Packungspreise werden als historische Werte mit Prüfhinweis behandelt und nicht allein wegen des niedrigsten Betrags als günstigster Markt gewertet.

### Produktkatalog
- Enthält Basiskatalog und lokal angelegte Produkte.
- Produktdaten können u. a. ID, Name, Einheit, Gruppe, Alias, EAN, Marke, Packungsmenge/-einheit und Bild-URL enthalten.
- Eigene Produkte werden lokal gespeichert.
- Neue erkannte Bonprodukte können automatisch in den Katalog wachsen.
- Barcode/Open Food Facts kann Produktstammdaten ergänzen.
- Preisabdeckung nach Quellen wird dargestellt.

### Preise
Preisquellen bleiben unterscheidbar:
- Kassenbon
- manuell gepflegter eigener Preis
- Open Prices
- Angebot
- interne Schätzung

Eine Schätzung wird nicht stillschweigend zu einem bestätigten Marktpreis.

### Angebote / Prospekte
- Angebote werden getrennt von Produktidentitäten behandelt: ein Angebot erzeugt grundsätzlich kein neues Produkt.
- Angebotszeiträume werden berücksichtigt.
- Marken-/Text-Matching kann passende Angebote zu Produkten finden.
- Coupon, Cashback und Mehrfachkauf werden rechnerisch berücksichtigt, soweit die Angebotsdaten diese Bedingungen enthalten.

### Route
- Vergleicht aktivierte Märkte und mögliche Kombinationen bis zur eingestellten maximalen Marktzahl.
- Produkte werden nur anhand nicht geschätzter Preise einer Route verbindlich zugeordnet.
- Fahrtstrecken können über OpenStreetMap/Nominatim und OSRM ermittelt und lokal zwischengespeichert werden.
- Verkehrsmittel, Fahrtkosten, maximale Marktzahl und Mindestvorteil für einen zusätzlichen Markt sind einstellbar.
- Produkte ohne belastbaren Preis bleiben für die Route unzugeordnet; dadurch wird keine scheinbar günstige Route aus Schätzpreisen erzeugt.

### Bon / Kaufhistorie
- Textbasierte PDF-, TXT- und CSV-Bons können eingelesen werden.
- Mehrere Dateien können in einem Import verarbeitet werden.
- Doppelte PDF-Bons werden über einen Bon-Fingerprint erkannt.
- Kaufhistorie kann bearbeitet oder gelöscht werden.
- Fotos/Scans ohne auslesbare Textebene besitzen noch keine automatische OCR.

### Budget
- Lebensmittelbudget und bisherige Lebensmittelausgaben werden lokal geführt.
- Geplanter Einkauf und Monatsprognose werden berechnet.
- Fahrtkosten gehören nicht zum Lebensmittelbudget.

### Diagnose
- Technische Flutter-/Async-Fehler und wichtige Datenaktionen werden lokal protokolliert.
- Praxistest-Beobachtungen können ergänzt und für Fehleranalyse kopiert werden.

## 2. Bon- und Produktlogik

### 2.1 Bonprüfung
Der Bonparser liest Händler, Datum, Produktzeilen, Mengen, Preise, Rabatte und Bon-Summe aus unterstützten Textlayouts. Preisbeobachtungen werden nur aus vollständig geprüften/ausgeglichenen Bons erzeugt.

Pfand, Leergut-Rückgaben und reine Rabattzeilen werden nicht als Produkte angelegt. Rabattinformationen können dagegen mit der zugehörigen Produktzeile verknüpft werden.

### 2.2 Jede echte Produktzeile bleibt erhalten
Eine erkannte echte Produktposition wird als `ReceiptObservation` gespeichert. Enthalten sind:
- Bon-Fingerprint und Zeilennummer
- Rohbezeichnung
- Produktfamilie
- Markt
- Datum
- Gesamtpreis
- Menge und Einheit
- ggf. Einzel-/Grundpreis
- Rabattstatus
- optional konkrete Produkt-ID

Damit gehen Preisbeobachtungen nicht verloren, nur weil die konkrete Variante zunächst unklar ist.

### 2.3 Automatisches Katalogwachstum
Bei einem ausgeglichenen Bon werden echte erkannte Produktpositionen automatisch dem Katalog zugeführt, wenn noch keine sichere bzw. exakt aliasgleiche Produktidentität vorhanden ist.

Die automatische Anlage ist konservativ:
- Bonbezeichnung wird als vorläufiger Produktname/Alias verwendet.
- Bekannte Produktfamilie wird separat gespeichert.
- Nicht auf dem Bon vorhandene Variantendetails werden nicht erfunden.
- `K.H-Milch` wird daher nicht automatisch zu 1,5 % oder 3,5 % erklärt.
- Exakt normalisierte vorhandene Namen/Aliase werden wiederverwendet, um unnötige Dubletten zu vermeiden.
- Automatische Zuordnung zählt nicht als explizite Nutzerbestätigung für das Alias-Lernen.

### 2.4 Produktfamilie und Variante
Produktfamilie und konkrete Produktidentität sind getrennte Dimensionen.

Beispiele:
- Familie `hackfleisch` kann gemischtes Hackfleisch und Rinderhack enthalten.
- Familie `milch` kann H-Milch 1,5 % und 3,5 % enthalten.
- Konkrete Varianten erhalten getrennte Produkt-IDs und getrennte exakte Preisstatistiken.

Familienwerte dienen nur als Fallback/Hinweis, wenn keine exakte Historie vorhanden ist.

### 2.5 Händlerbezogene Alias-Lernlogik
Explizite Nutzerzuordnungen bilden ein Lernsignal aus Händler + normalisierter Bonbezeichnung → Produkt-ID.

- Erst zwei gleiche Bestätigungen machen die Zuordnung zu einem gelernten Vorschlag.
- Eine widersprechende Korrektur setzt die Bestätigung für die neue Zuordnung zurück.
- Gelernte Treffer bleiben prüf- und änderbar.
- Eine automatisch erzeugte Produktzuordnung gilt nicht als explizite Nutzerbestätigung.

## 3. Historische Bonpreis-Statistik

Bonbeobachtungen werden standardmäßig über ein Fenster von **90 Tagen** betrachtet. Rabattierte Beobachtungen werden aus dem Normalpreis-Median ausgeschlossen.

Gruppierung:
1. Ist eine konkrete Produkt-ID vorhanden, wird nach Produkt-ID + Markt aggregiert.
2. Andernfalls wird nach Produktfamilie + Markt aggregiert.

Pro Gruppe werden gespeichert/abgeleitet:
- letzter Preis
- Datum der letzten Beobachtung
- Anzahl der Beobachtungen
- Median
- Vergleichbarkeitsstatus
- Preisbasis

Der Median wird auf Cent gerundet.

### Vergleichbarkeit
Sind für alle Beobachtungen Einzel-/Grundpreise vorhanden, wird aktuell eine vergleichbare Statistik gebildet. Fehlt diese Basis, wird der Packungspreis verwendet und ausdrücklich als **„historisch, Packung prüfen“** behandelt.

In der Einkaufsliste:
- exakte Produktstatistik zuerst,
- sonst Familien-Fallback,
- bei vergleichbaren Treffern Auswahl nach Median,
- bei nicht vergleichbaren Packungspreisen Auswahl nach Aktualität statt nach niedrigstem Betrag.

Damit wird z. B. ein 9,99-€-XXL-Paket nicht allein wegen seines absoluten Packungspreises sinnvoll oder unsinnig gegen ein 4,79-€-Paket bewertet.

## 4. Marktpreis-Priorität und Speicherung

Ein `MarketPrice` ist durch Markt + Produkt identifiziert. Beim Aktualisieren gelten Schutzregeln:
- Ein neuer Bonpreis überschreibt keinen manuell gepflegten Preis.
- Ein älterer Bonpreis überschreibt keinen neueren vorhandenen Preis.
- Open-Prices-Daten überschreiben keinen manuellen Preis.
- Open-Prices-Daten ersetzen einen vorhandenen Wert nur, wenn sie nach der implementierten Aktualitätslogik neuer sind.

Bestätigte reale Einkaufs-/Bonpreise bleiben dadurch gegenüber externen Daten besonders geschützt.

## 5. Angebotsberechnungen

### Coupon
Ausgangspunkt ist der Angebotspreis.

Bei Prozentcoupon:

`Couponpreis = Angebotspreis × (1 - Prozent / 100)`

Bei zusätzlichem Eurobetrag wird dieser anschließend abgezogen. Prozentwerte werden auf 0–100 % begrenzt; Euroabzug maximal auf den verbleibenden Preis. Ergebnis auf Cent gerundet.

### Cashback
Cashback kann prozentual und/oder als fester Betrag vorliegen:

`Cashback = Prozentanteil vom Preis + fester Betrag`

Der Wert wird auf 0 bis zum zugrunde liegenden Preis begrenzt und auf Cent gerundet.

### Effektivpreis
`Kassenpreis = Couponpreis, falls vorhanden, sonst Angebotspreis`

`Effektivpreis = Kassenpreis - Cashback`

Der Effektivpreis wird auf Cent gerundet. Kassenbelastung und spätere Erstattung bleiben im Modell getrennt.

### Mehrfachkauf
Wenn `buyQuantity` und `payQuantity` gültig sind:

`bezahlte Einheiten = floor(Menge / buyQuantity) × payQuantity + Rest`

Ungültige oder nicht sparende Mehrfachkaufdefinitionen werden wie normale Mengen behandelt.

## 6. Preisauflösung und Schätzungen

Für einen Artikel in einem Markt wird zunächst nach beobachteten/gespeicherten Preisen gesucht. Die Route berücksichtigt außerdem gültige Angebote.

Fehlt ein belastbarer regulärer Preis, existiert eine interne Schätzung. Sie dient der Anzeige/Orientierung und wird mit `isEstimated` gekennzeichnet.

Schätzlogik:
1. Falls für genau diese Produkt-ID andere beobachtete Marktpreise existieren, wird deren Median verwendet.
2. Sonst gelten derzeit Gruppen-Fallbacks:
   - Butter: 1,89 €
   - Milch: 1,29 €
   - Obst: 1,59 €
   - Fleisch: 4,99 €
   - Nudeln: 0,89 €
   - sonstige Gruppen: 2,49 €

Diese Werte sind **keine bestätigten Ladenpreise**.

## 7. Routenberechnung

### Warenkorb
Für einen Markt:

`Warenkorb = Summe der aufgelösten Artikel-Gesamtkosten`

### Fahrtkosten
`Fahrtkosten = optimierte Streckenkilometer × Euro pro Kilometer`

Standardwert im Optimierer: **0,22 €/km**, sofern keine andere Einstellung übergeben wird.

### Gesamtkosten
`Gesamt = Warenkorb + Fahrtkosten`

### Marktzuordnung
Für jeden Artikel wird innerhalb einer betrachteten Marktkombination der günstigste **nicht geschätzte** Preis gesucht. Gibt es keinen belastbaren Preis, bleibt der Artikel unzugeordnet.

Eine Route wird nur als vollständige Alternative berücksichtigt, wenn keine Artikel unzugeordnet bleiben.

### Marktkombinationen
Der Optimierer erzeugt Kombinationen bis zur konfigurierten Marktzahl; die Implementierung unterstützt Kombinationen aus 1, 2 und 3 Märkten.

Innerhalb derselben Marktanzahl wird nach Gesamtkosten sortiert. Bei gleichen Kosten wird die kleinere Marktzahl bevorzugt.

### Mindestvorteil zusätzlicher Märkte
Ausgehend von der besten Ein-Markt- bzw. kleinsten verfügbaren vollständigen Lösung wird ein zusätzlicher Markt nur übernommen, wenn:

`bisherige Gesamtkosten - neue Gesamtkosten >= Mindestvorteil × zusätzliche Märkte`

So kann ein kleiner theoretischer Preisvorteil einen zusätzlichen Einkaufsstopp vermeiden.

## 8. Budgetberechnungen

### Restbudget
`Rest = Lebensmittelbudget - bisher ausgegeben`

### Nach geplantem Einkauf
`Rest nach Einkauf = Rest - geplanter Einkauf`

Ein negativer Wert bedeutet Budgetüberschreitung.

### Monatsprognose
Für den aktuellen Monat:

`Ausgaben nach Plan = max(0, bisher ausgegeben + geplanter Einkauf)`

`Tagesrate = Ausgaben nach Plan / vergangene Kalendertage`

`Prognose Monatsausgaben = Tagesrate × Kalendertage des Monats`

`Prognose Rest = Lebensmittelbudget - Prognose Monatsausgaben`

### Wöchentlich verfügbar
`Rest nach Plan = max(0, Budget - Ausgaben nach Plan)`

`Wochenbudget = Rest nach Plan / verbleibende Tage × 7`

Am letzten Monatstag beträgt dieser Wert 0.

### Budgetstatus
`Quote = prognostizierte Monatsausgaben / Lebensmittelbudget`

- über 100 % → `overBudget`
- ab 90 % bis einschließlich 100 % → `warning`
- unter 90 % → `onTrack`

Bei Lebensmittelbudget ≤ 0 gilt die Prognose als nicht konfiguriert.

## 9. Wiederkauflogik

Wiederkaufvorschläge werden aus der Kaufhistorie pro konkreter Produkt-ID berechnet.

- Käufe desselben Produkts am selben Kalendertag werden mengenmäßig zusammengefasst.
- Standardmäßig sind mindestens **2 Kauftage** nötig.
- Aus den Abständen zwischen Kauftagen wird der Median in Tagen gebildet.
- Bei gerader Anzahl von Intervallen wird der Mittelwert der beiden mittleren Werte gerundet.
- `Fällig am = letzter Kauf + Medianintervall`.
- Standardmäßig wird ein Produkt angezeigt, wenn es bereits fällig ist oder innerhalb von **3 Tagen** fällig wird.
- Produkte, die schon auf der aktuellen Einkaufsliste stehen, werden nicht vorgeschlagen.
- Durchschnittsmenge = Gesamtmenge / Zahl der Kauftage.
- Sortierung: zuerst früheste/überfällige Fälligkeit, dann höhere Kaufanzahl, dann Produktname.

## 10. Open Food Facts und Open Prices

### Open Food Facts
Wird zur Produktidentifikation bzw. Ergänzung von Produktdaten per EAN verwendet. Daraus wird kein verlässlicher Ladenpreis abgeleitet.

### Open Prices
Kann EUR-Preise für Produkte mit EAN liefern. Die Implementierung prüft Markt-/Ortsbezug und Aktualität. Open Prices bleibt eine eigene Quelle und ist in den Einstellungen abschaltbar.

Preisdatensätze ohne ausreichend passenden Ortsbezug sowie nicht unterstützte Rabatt-/Gewichtspreise werden nicht als normale Marktpreise übernommen. Der automatische Abgleich beim Öffnen des Katalogs ist standardmäßig deaktiviert.

## 11. Lokale Datenspeicherung

Die aktuelle App verwendet `shared_preferences`. Lokal gespeichert werden je nach Feature u. a.:
- Einkaufslisten, Mengen, Notizen und Erledigt-Status
- eigene Produkte
- Marktpreise und Preisverlauf
- Bonbeobachtungen
- Händler-/Bon-Aliaswissen
- Angebote
- Kaufhistorie und bekannte Einkäufe
- Budget
- Mobilitäts-/Markteinstellungen
- Open-Prices-Einstellungen
- Strecken-/Routingdaten
- Diagnoseinformationen

Es gibt aktuell kein Benutzerkonto, Cloud-Backup oder geräteübergreifende Synchronisierung. Eine Deinstallation kann lokale Daten entfernen.

## 12. Externe Dienste

- **Open Food Facts:** Produktinformationen/EAN.
- **Open Prices:** externe Preisbeobachtungen.
- **OpenStreetMap/Nominatim:** Geokodierung.
- **OSRM:** Straßendistanzen/Routenmatrix.

Diese Funktionen benötigen eine Internetverbindung.

## 13. Bekannte Grenzen

- Keine automatische OCR für Bonfotos oder gescannte PDFs ohne Textebene.
- Keine garantierte vollständige Preisabdeckung.
- Historische Bonpreise sind Beobachtungen und keine Garantie für den heutigen Regalpreis.
- Familien-Fallbacks dürfen Varianten nicht als identisch ausgeben.
- Die aktuelle Vergleichbarkeitsprüfung historischer Bonpreise verlangt vorhandene Einzel-/Grundpreise, prüft aber noch nicht in jedem Fall eine vollständig normalisierte gemeinsame Maßeinheit.
- Händlerprospekte aus proprietären Händler-Apps werden nicht automatisch importiert.
- Keine Cloud-/Mehrbenutzer-Synchronisierung.
- Die Regalvideo-Erfassung befindet sich weiterhin nur in Evaluation und verändert ohne separate Entscheidung keine App-Daten.

## 14. Projektstruktur

- `lib/features/`: UI und anwendungsnahe Geschäftslogik
- `lib/models/`: Datenmodelle
- `lib/services/`: lokale Speicherung und externe Datenquellen
- `lib/data/`: Basiskatalog/-daten
- `test/`: automatisierte Tests
- `docs/`: Projektstatus, Architektur, Roadmap, Entscheidungen und Release-Unterlagen

Grundregel: kleine, klar verantwortliche Module; keine unnötige doppelte Logik.

## 15. Entwicklung und CI

Voraussetzung: Flutter/Dart gemäß `pubspec.yaml` (Dart SDK aktuell `^3.13.4`).

```sh
flutter pub get
flutter run
```

Vor Abschluss eines Arbeitspakets:

```sh
flutter analyze
flutter test
flutter build web --release
```

Die GitHub Flutter CI führt diese Prüfungen bei Push/Pull Request aus. Nach der verbindlichen Projektregel gilt ein Code-Arbeitspaket erst als abgeschlossen, wenn diese CI vollständig grün ist.

Der Release-Workflow erzeugt für `main` zusätzlich Web-/GitHub-Pages-Ausgaben und eine Android-APK.

## 16. Dokumentationsregel

Bei jeder Änderung, die Verhalten der App verändert, ist zu prüfen, ob diese README angepasst werden muss. Besonders dokumentationspflichtig sind:
- neue oder entfernte Funktionen,
- Berechnungsformeln,
- Preisprioritäten und Fallbacks,
- Matching-/Lernlogik,
- Datenquellen,
- Persistenzregeln,
- Routen-/Budget-/Sparlogik,
- bekannte Grenzen.

Dauerhafte Architektur-/Produktentscheidungen gehören zusätzlich in `docs/DECISIONS.md`; der aktuelle Arbeitsstand in `docs/PROJECT_STATUS.md`.

## Abnahme vor Version 1

Die ausführbare manuelle Checkliste liegt in `docs/RELEASE_ACCEPTANCE.md`. Automatisierte Tests ersetzen die Geräteprüfung nicht. Anmeldung, Cloud-Backup und Synchronisierung gehören derzeit nicht zu Version 1.


Historische Bonbeobachtungen werden bei jeder Statistikberechnung erneut anhand ihrer originalen Bonbezeichnung einer Produktfamilie zugeordnet. Verbesserte Erkennungsregeln gelten dadurch automatisch auch für bereits gespeicherte Bons und für alle Produkte.
