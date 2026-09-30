# Tests und Qualitätssicherung

## Aktueller CI-Vertrag

`.github/workflows/flutter_ci.yml` führt für Pushes und Pull Requests aus:

```sh
flutter pub get
flutter analyze
flutter test
flutter build web --release
```

Weitere Workflows aktualisieren Prospektdaten, erzeugen Release-Artefakte oder beobachten Releases. Sie sind getrennt vom Flutter-CI zu beurteilen: ein fehlgeschlagener Release-/Watcher-Lauf macht den Analyse-/Test-/Webbuild nicht automatisch rot, muss aber bei Release-Aufträgen untersucht werden. Der Release-Watcher muss `gh workflow run release.yml --ref main --repo "$REPOSITORY"` verwenden, weil der geplante Watcher keinen lokalen Checkout hat. Die Korrektur des bisher fehlenden `--repo`-Arguments wird mit diesem PR ausgeliefert; ein manueller Dispatch wird während der Prüfung vermieden, damit kein Release veröffentlicht wird.

## Bestehende Abdeckung und Regressionen

Die Testsuite enthält Domänen-, Store-, Service-, Widget- und Ablaufprüfungen. Relevante Anker:

- Angebote und Preise: `offer_filter_test.dart`, `offer_input_validation_test.dart`, `effective_price_test.dart`, `offer_store_safety_test.dart`, `offer_without_regular_price_test.dart`, `expired_offer_date_picker_test.dart`.
- Produktidentität/Normalisierung: `product_identity_test.dart`, `product_family_test.dart`, `product_hierarchy_test.dart`, `product_match_candidates_test.dart`, `product_package_validation_test.dart`, `quantity_normalizer_test.dart`.
- Datenqualität/Quellen: `offer_import_test.dart`, `open_prices_service_test.dart`, `receipt_observation_store_test.dart`, `receipt_price_review_test.dart`, `prospect_feed_service_test.dart`, `real_receipt_evidence_e2e_test.dart`.
- Route: `route_price_resolver_test.dart`, `route_price_quality_test.dart`, `route_road_distance_test.dart`, `route_recommendation_test.dart`, `route_multi_market_e2e_test.dart`, `list_to_route_flow_test.dart`, `route_to_purchase_flow_test.dart`.
- UI/Flows: `widget_test.dart`, `store_screen_test.dart`, `prospects_screen_test.dart`, `shopping_price_badge_visuals_test.dart`, `scan_to_list_flow_test.dart`, `receipt_import_display_test.dart`.

Bei jedem behobenen Fehler kommt ein enger Test für Ursache und Gegenbeispiel hinzu. Datenqualitätskorrekturen dürfen nicht allein anhand des erwarteten UI-Texts getestet werden: prüfe den resultierenden Preis-/Identitäts-/Routenstatus.

## Visuelle Tests

Flutter `testWidgets` ermöglicht reproduzierbare Widget- und Interaktionsregressionen. `widget_test.dart` prüft zusätzlich einen 390×844-Viewport auf Flutter-Layoutfehler; das ist ein schmaler mobiler Widget-Smoke-Test, kein iPhone-Simulatornachweis. Der aktuelle CI-Workflow führt keinen Golden-Datei-Abgleich, Screenshot-Vergleich oder nativen iOS-Build aus. Für eine konkrete Layoutänderung:

1. Widget-/Flow-Test für Zustand und Interaktion ergänzen.
2. Auf den relevanten kleinen und großen Layoutbreiten rendern und Overflow/Bedienbarkeit prüfen.
3. Golden/Screenshot nur hinzufügen, wenn Theme, Fonts, Locale, Testdaten und Flutter-Version fixiert sind und die Baseline tatsächlich visuell geprüft wurde.
4. Für iPhone-spezifische Aussagen einen realen iOS-/Simulatorlauf ausweisen; ein Web-Build allein belegt das nicht.

Keine privaten Bons, Preislisten oder Kundendaten in Goldens, Snapshots oder CI-Artefakte aufnehmen.

## Abschlussgate

- `flutter analyze` grün.
- `flutter test` grün.
- `flutter build web --release` grün.
- GitHub Flutter CI grün.
- Bei Daten-/Preis-/Routenänderungen die passenden Regressionen benennen; bei UI-Änderungen die geprüften Screens/Viewport dokumentieren.
- Release-Workflow separat bewerten, falls er durch den Auftrag berührt wird.
