# SparzamApp

SparzamApp ist ein Flutter-Prototyp zur Planung von Lebensmitteleinkäufen. Die App verbindet Einkaufsliste, Produktkatalog, Angebote, Preisvergleich, Routenempfehlung und Lebensmittelbudget. Sie ist derzeit eine lokal gespeicherte Einzelgeräte-App; eine Anmeldung oder Synchronisierung zwischen Geräten gibt es noch nicht.

## Was bereits funktioniert

- **Home:** Sparpotenzial, Routen- und Budgetübersicht, aktive Angebote und Vorschläge für häufig benötigte Produkte.
- **Liste:** Produkte suchen, ergänzen, Mengen ändern und erledigte Artikel entfernen. Eigene Produkte und bekannte Einkäufe unterstützen spätere Eingaben. Der Barcode-Scanner erkennt vorhandene Produkte oder fragt Produktdaten bei Open Food Facts ab; unbekannte Artikel lassen sich anlegen.
- **Route:** Vergleicht verfügbare Preise und Angebote für ausgewählte Märkte. Einstellbar sind Startadresse, Verkehrsmittel, maximale Marktzahl, Mindestvorteil eines weiteren Marktes und beim Auto Fahrtkosten. Straßendistanzen werden über OpenStreetMap/Nominatim und OSRM abgerufen; die App speichert ermittelte Werte lokal.
- **Bon:** Bestätigte Einkäufe erscheinen in einer lokalen Historie und können bearbeitet oder gelöscht werden. Der Warenkorb belastet das Lebensmittelbudget, Fahrtkosten nicht.
- **Profil:** Mobilitäts- und Marktauswahl, Produktkatalog, eigene Marktpreise und Einstellungen für Open Prices. Der Katalog zeigt auch die Abdeckung durch EANs und Preisdaten.
- **Angebote:** Eigene Angebote mit Laufzeit, Mehrfachkauf, Coupon und Cashback. Für den Vergleich zählt der berechnete Effektivpreis; Kassenpreis und Erstattung bleiben getrennt.

## Datenquellen und Grenzen

Der integrierte Beispielkatalog und Beispielangebote dienen als Ausgangspunkt. Eigene Produkte und Marktpreise lassen sich ergänzen. Der Scanner fragt bei Bedarf Open Food Facts nach Produktinformationen; das liefert keine verlässlichen Ladenpreise. Open Prices kann aktuelle EUR-Preise pro Produkteinheit für Produkte mit EAN abrufen, wenn Marktname und Stadt zum bekannten Markt passen. Falls beide Postleitzahlen vorliegen, müssen sie ebenfalls übereinstimmen. Datensätze ohne passende Ortsangabe sowie Rabatt- und Gewichtspreise werden nicht übernommen. Es gibt daher **keine vollständige oder garantierte Preisabdeckung**. Ein Preis kann zudem veraltet sein; in den Preisdaten-Einstellungen lässt sich die zulässige Aktualität ändern oder Open Prices abschalten. Der automatische Abgleich beim Öffnen des Katalogs ist standardmäßig aus.

Einkaufsliste, eigene Produkte, Preise, Preisverlauf, Angebote, Kaufhistorie, Budget, Mobilitäts- und Preisdaten-Einstellungen werden auf dem jeweiligen Gerät mit `shared_preferences` gespeichert. Die externen Dienste für Produktdaten, Preise und Straßendistanzen benötigen eine Internetverbindung. Die App hat noch keinen Benutzeraccount, Cloud-Backup oder geräteübergreifende Synchronisierung. Lokale App-Daten können bei einer Deinstallation verloren gehen.

## Projekt lokal ausführen

Flutter mit einer zu `pubspec.yaml` kompatiblen Dart-Version und ein passendes Zielgerät beziehungsweise einen Browser bereitstellen. Im Projektverzeichnis:

```sh
flutter pub get
flutter run
```

Vor einer Änderung prüfen:

```sh
flutter analyze
flutter test
flutter build web --release
```

Die GitHub-Actions-Workflowdatei `.github/workflows/flutter_ci.yml` führt zusätzlich `flutter pub get` und diese drei Prüfungen bei Push und Pull Request aus. Änderungen sollen klein und modular bleiben; `lib/features/` enthält Oberflächen und anwendungsnahe Logik, `lib/models/` die Datenmodelle und `lib/services/` Speicherung sowie externe Abrufe. Zugehörige Tests liegen in `test/`.

## Nächste Etappen

Der Open-Prices-Abgleich zeigt gefundene Preise, Fortschritt und Fehler an. Längere Abgleiche können abgebrochen werden; bereits gefundene Preise bleiben erhalten. Fehlgeschlagene Produktabfragen können einzeln erneut geprüft werden.

1. Weitere Preiserfassung und Produktabdeckung priorisieren.
2. Anmeldung und Cloud-Synchronisierung als eigenständigen späteren Schritt planen.

## Abnahme vor Version 1

CI prüft Analyse, automatisierte Tests und den Web-Build. Für eine Freigabe fehlen noch diese manuellen Prüfungen auf einem echten Zielgerät:

1. App frisch installieren, eigenes Produkt mit Barcode anlegen, per Kamera scannen und einen unbekannten Barcode über Open Food Facts oder die manuelle Eingabe ergänzen. Kamera-Berechtigung und erneute Suche nach einem erfolglosen Abruf prüfen.
2. Produkte und Mengen zur Einkaufsliste hinzufügen, abhaken, Mengen ändern und die App neu starten. Liste, eigene Produkte und bevorzugte Artikel müssen erhalten bleiben.
3. Einen eigenen Marktpreis und ein Angebot mit Mehrfachkauf oder Coupon eintragen. Route und angezeigten Effektivpreis mit einer nachvollziehbaren Beispielrechnung vergleichen; fehlende und veraltete Preise prüfen.
4. Einen Einkauf bestätigen, Bon und Lebensmittelbudget prüfen, den Einkauf bearbeiten und löschen. Nach jedem Schritt die App neu starten und die gespeicherten Werte vergleichen.
5. Internetverbindung beim Produkt- und Preisabruf unterbrechen. Fehlermeldung, Teilerfolge und Wiederholung prüfen; bereits gespeicherte Daten dürfen nicht verloren gehen.
6. Vor einem Release Demo-Preise und Beispielangebote deutlich als solche kennzeichnen, die gewünschte Preisabdeckung festlegen und den vollständigen Kernablauf vom Nutzer abnehmen lassen.

Automatisierte Tests ersetzen diese Geräteprüfung nicht. Anmeldung, Cloud-Backup und Synchronisierung gehören derzeit nicht zu Version 1.
