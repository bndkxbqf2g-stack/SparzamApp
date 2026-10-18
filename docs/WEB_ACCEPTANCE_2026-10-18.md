# Web-Abnahme Prospekt-, Preise- und Routen-Reiter (2026-10-18)

Diese Abnahme dokumentiert den ausgelieferten main-Stand nach PR #683,
Commit a845f712ff5a8984b74ffe86f633b64106563ccc, unter
https://bndkxbqf2g-stack.github.io/SparzamApp/?v=deployed-685-20261018.

## GETESTET

- CI und Release: Flutter CI 39080826864 sowie Release artifacts
  39080826627 sind erfolgreich. Der Release umfasst Analyse, Flutter-Tests,
  Web-Release-Build, Android-APK und den Pages-Deploy.
- Teilroute: Bei 1 von 3 Listenpositionen mit aktuellem Marktpreis zeigt
  der Listen-Reiter jetzt Teilroute prüfen. Der Preise-Reiter verwendet bei
  derselben Abdeckung ebenfalls Teilroute prüfen; fehlende Preise werden
  weiterhin als unbekannt erklärt und nicht als 0 € gerechnet.
- Prospekt-Cover: Das Kaufland-Cover ist im Prospektkartenraster sichtbar.
  Der Viewer zeigt die exakte Filiale Würzburg/Nürnberger Straße und 70/70
  geladene Seiten; beim Nachladen späterer Seiten trat kein sichtbarer Abbruch
  auf.
- Preisgrenze: Der Preise-Reiter zeigt aktuelle, historische und unbekannte
  Positionen getrennt. Reguläre Prospekt-Normalpreise bleiben als eigene
  Evidenz ausgewiesen; Aktionspreise werden nicht zur Normalpreis-Basis.
- Datenhygiene: Die Prüfung verwendete nur vorhandene lokale Beispieldaten.
  Es wurden keine persönlichen Belege, Logins oder externen Schreibzugriffe
  verwendet.

## OFFEN

- Eine native Geräteabnahme für Kamera, Neustart, Offline-Speicher und
  bildbasierte OCR bleibt offen. Diese Grenze ist fachlich und kein fehlendes
  Flutter-SDK im aktuellen CI-/Release-Stand.
- Ein Web-Renderer-Test mit echten Händler-CDNs bleibt eine separate
  Testumgebungsgrenze; die normalen Fixtures bleiben vollständig offline.
