# sparzamapp

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Block D – Preishistorie & Preisampel
- lokale Preisbeobachtungen via SharedPreferences
- Normalpreis als Median der bisherigen Preise
- bester beobachteter Preis
- Preisampel: sehr günstig / normal / teuer
- Preisverlauf als Bottom Sheet in der Angebotskarte

## Block E – Coupon-Logik
- Prozent-Coupons und feste Euro-Coupons im Angebotsmodell
- rückwärtskompatibel zu bisherigen `coupon: true`-Daten
- eigenständiger Coupon-Rechner statt Berechnung im UI
- Angebotskarte zeigt den tatsächlichen Preis nach Coupon
- Coupon-Art wird als Tag dargestellt

## Block F – Cashback & effektiver Endpreis
- Prozent-Cashback und feste Euro-Cashbacks im Angebotsmodell
- eigener Cashback-Rechner, getrennt vom UI
- zentraler Effektivpreis: Angebot → Coupon → Cashback
- Kassenpreis und effektiver Preis bleiben bewusst getrennt
- Angebotskarte zeigt Cashback-Art und tatsächlichen Endpreis

## Block G – Routenoptimierung mit Effektivpreisen
Die Routenberechnung verwendet jetzt aktive Angebote sowie Coupon, Cashback und Mehrfachkauf. Pro Markt und Artikel wird der wirtschaftlich günstigere Preis aus Normalpreis und aktivem Effektivpreis verwendet. Fahrtkosten bleiben im MVP bei 0,22 €/km für Hin- und Rückfahrt pro Markt.

## Block K – Einkaufsabschlüsse & Monatsersparnis
- bestätigte Einkäufe werden lokal als Historie gespeichert
- Warenkorb, Fahrt, Gesamt, Vergleichswert und Ersparnis bleiben je Einkauf erhalten
- Lebensmittelbudget wird beim Abschluss automatisch um den Warenkorb belastet
- Fahrtkosten werden nicht als Lebensmittelausgabe gebucht
- Monatsersparnis im Dashboard basiert nur auf bestätigten Einkäufen
- nach Bestätigung wird die aktuelle Einkaufsliste geleert
