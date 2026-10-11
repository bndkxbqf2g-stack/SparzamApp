# SparzamApp – Projektstatus

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