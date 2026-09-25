# Reale Bon-Testmatrix

Stand: 2026-09-25

## Zweck
Diese Matrix enthält ausschließlich Boninformationen, die durch vorhandene Regressionstests oder die im Projekt bereitgestellten Originalbelege belegt sind. Fehlende Produkte, Preise, Märkte oder Daten werden nicht ergänzt oder geschätzt.

## Automatisch abgesicherte Originalfälle

| Originalfall | Markt / Datum | Belegte Daten | Besonderheit | Regression |
| --- | --- | --- | --- | --- |
| Kaufland-Originalbon | Kaufland Würzburg-Grombühl · 23.07.2026 | Bonsumme 94,99 €; u. a. K.Frischer Schmand 0,79 € | K-Card-Artikelrabatt nach Produktzeile; Produktzeilenpreis bleibt historische Evidenz | `test/real_receipt_evidence_e2e_test.dart` |
| EDEKA `Kassenbon_2026-01-17_10.45.pdf` | EDEKA Frischemarkt · 17.01.2026 | 9 Artikelzeilen; Bonsumme 25,65 € | `NETTO` steht nur in der Steuerübersicht; `1,39 € x 2 = 2,78 €` wird als Menge/Einzelpreis gelesen | `test/real_edeka_receipt_evidence_test.dart` |
| gewichtete Kaufland-Bananen | Kaufland · 23.07.2026 | `Bananen kg 0,498 kg 0,64 €` | gekaufte Masse bleibt erhalten; kein nicht gedruckter Grundpreis wird erfunden; 1-kg-Vergleich wird mathematisch aus Gesamtpreis/Masse normiert | `test/receipt_price_review_test.dart`, `test/receipt_family_market_prices_test.dart` |
| `Lidl Plus.pdf` | Lidl Zellingen · 07.05.2026 | Bonsumme 34,23 € | 0,414 kg Banane mit 1,29 €/kg; Mehrfachmengen; Lidl-Plus-Rabatte; Preisvorteile; Pfand | `test/real_lidl_plus_receipt_test.dart` |
| `Lidl Plus 2.pdf` | Lidl Zellingen · 18.07.2026 | Bonsumme 44,84 € | Mehrfachmengen bis 3 Stück; Lidl-Plus-Rabatte; Preisvorteile; Mehrfachpfand | `test/real_lidl_plus_receipt_test.dart` |

Der Schmand-End-to-End-Test verfolgt die belegte Kette:
`ReceiptObservation → PriceObservation → MarketPrice → planningMarketPrices → RoutePriceResolver → RouteOptimizer`.

Die zentrale 30-Tage-Grenze bleibt erhalten: ältere Bons bleiben Evidenz, werden aber nicht als aktuelle exakte Routenpreise projiziert.

## Weitere Originalbelege im letzten Quellenpaket

Die folgenden Dateien liegen im zuletzt bereitgestellten Quellen-ZIP. Sie wurden beim Quellen-Audit mit dem aktuellen Parser gegen ihre gedruckte Bonsumme geprüft und balancieren vollständig; sie sind jedoch noch nicht jeweils als vollständige Repository-Fixture eingecheckt.

| Datei | Markt / Datum | Bonsumme | Belegtes Formatmerkmal |
| --- | --- | ---: | --- |
| `20260923_100433.pdf` | Kaufland Würzburg · 19.09.2026 | 32,47 € | Mengenzeile `2 * 0,88 = 1,76 €`; Artikel-/Mengenrabatte |
| `20260923_100457.pdf` | Kaufland Würzburg · 23.07.2026 | 94,99 € | zahlreiche K-Card-Rabatte; Inline- und Folgezeilenmengen; gewichtete Bananen |
| `20260923_100506.pdf` | Kaufland Würzburg-Grombühl · 26.05.2026 | 184,08 € | große Mischbon-Struktur mit Pfand, Rabatten und Mehrfachmengen |
| `Netto_Kassenbon_20260731-170322.pdf` | Netto Thüngersheim · 31.07.2026 | 54,81 € | vorangestellte Mengen; gewichtete Bananen mit gedrucktem `EUR/kg`; Warenkorbrabatt |
| `Netto_Kassenbon_20260824-131113.pdf` | Netto Thüngersheim · 24.08.2026 | 49,76 € | vorangestellte Mengen, Pfand und Rabattzeilen |

## Noch nicht rekonstruierbare UI-Fälle

Im aktuellen App-Screenshot werden zusätzlich diese beiden Dateien verwendet:
- `Kassenbon_2026-07-24_19.19.pdf`
- `Kassenbon_2026-01-16_11.53.pdf`

Diese beiden Original-PDFs befinden sich weder in den aktuellen Gesprächsdateien noch im letzten Quellen-ZIP. Deshalb wird für ihre derzeitige Summenabweichung kein Parser-Fix geraten oder aus dem Screenshot erfunden. Sobald die Originaltexte verfügbar sind, werden die fehlenden Zeilenformate gezielt als Regression ergänzt.

## Bildbasierte Lidl-Plus-PDFs

Die beiden Lidl-Plus-Originaldateien enthalten keine auslesbare PDF-Textebene. Die Regression basiert deshalb auf einer visuellen Transkription der Originalseite. Der Parser unterstützt das belegte Lidl-Layout (`Lidl`, `zu zahlen`, Datum ohne `Datum`-Präfix, Gewichts- und Mehrfachmengen, Rabatt-/Pfandzeilen). Die automatische OCR von Bild-PDFs bleibt davon getrennt und ist weiterhin offen.

## Regeln
- keine fehlenden Produkte ergänzen,
- keine Preise schätzen,
- synthetische Tests nicht als Originalbon deklarieren,
- unbalancierte Bons nicht als belastbare Preisbeobachtung speichern,
- Originalbelege schrittweise als Regressionen in die Parser-/Preis-/Routenpipeline überführen.
