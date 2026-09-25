import importlib.util
import pathlib
import unittest

MODULE = pathlib.Path(__file__).resolve().parents[1] / "refresh_prospects.py"
spec = importlib.util.spec_from_file_location("refresh_prospects", MODULE)
refresh = importlib.util.module_from_spec(spec)
spec.loader.exec_module(refresh)

class ProspectParserTest(unittest.TestCase):
    def test_edeka_api_reads_market_offers_and_dates(self):
        payload = """
        {
          "gueltig_von": "2026-09-21",
          "gueltig_bis": "2026-09-26",
          "docs": [
            {
              "angebotid": 12345,
              "titel": "K.Frischer Schmand",
              "preis": 0.69,
              "originalPrice": "0,89 €",
              "nachlass": "22%",
              "bild_app": "https://offer-images.api.edeka/schmand.jpg"
            }
          ]
        }
        """
        offers, _ = refresh.parse_edeka_api(
            payload,
            "https://www.edeka.de/maerkte/023738/",
        )
        self.assertEqual(len(offers), 1)
        self.assertEqual(offers[0]["productLabel"], "K.Frischer Schmand")
        self.assertEqual(offers[0]["offerPrice"], 0.69)
        self.assertEqual(offers[0]["originalPrice"], 0.89)
        self.assertEqual(offers[0]["validFrom"], "2026-09-21")
        self.assertEqual(offers[0]["validUntil"], "2026-09-26")
        self.assertEqual(
            offers[0]["imageUrl"],
            "https://offer-images.api.edeka/schmand.jpg",
        )
        self.assertTrue(offers[0]["proofRef"].endswith("#offer-12345"))

    def test_edeka_api_does_not_invent_regular_price_from_discount(self):
        payload = """
        {
          "gueltig_von": "2026-09-21",
          "gueltig_bis": "2026-09-26",
          "docs": [
            {
              "angebotid": 7,
              "titel": "Butter",
              "preis": "1,49",
              "nachlass": "25%"
            }
          ]
        }
        """
        offers, _ = refresh.parse_edeka_api(
            payload,
            "https://www.edeka.de/maerkte/023738/",
        )
        self.assertEqual(offers[0]["offerPrice"], 1.49)
        self.assertNotIn("originalPrice", offers[0])

    def test_edeka_api_url_uses_market_id(self):
        url = refresh._edeka_api_url(
            "https://www.edeka.de/maerkte/023738/",
        )
        self.assertIn("marketId=023738", url)
        self.assertIn("limit=99999", url)

    def test_edeka_uses_public_fixed_price_not_app_price(self):
        html = """<p>Gültig vom 21.09.2026 bis zum 26.09.2026.</p><h3>Angebot: Schmand</h3><p>Gültig ab 21.09.2026</p><p>App Preis von 0.59€</p><p>Festpreis von 0.69€</p>"""
        offers, _ = refresh.parse_edeka(html, "https://www.edeka.de/maerkte/023738/")
        self.assertEqual(len(offers), 1)
        self.assertEqual(offers[0]["offerPrice"], 0.69)
        self.assertNotIn("originalPrice", offers[0])

    def test_edeka_parses_script_embedded_offer_markup(self):
        html = """
        <script type="application/json">
          Angebot: Havana Club Rum
          9.99 App App Preis von 9.99€ 10.99 Festpreis von 10.99€
          verschiedene Sorten
          Angebot: MM Extra Sekt
          Gültig ab 24.09.2026 2.77 Festpreis von 2.77€
          Alle Angebote gültig bis Samstag, den 26.09.2026, KW39/2026.
        </script>
        """
        offers, _ = refresh.parse_edeka(
            html,
            "https://www.edeka.de/maerkte/023738/",
        )
        by_name = {offer["productLabel"]: offer for offer in offers}
        self.assertEqual(by_name["Havana Club Rum"]["offerPrice"], 10.99)
        self.assertNotIn("originalPrice", by_name["Havana Club Rum"])
        self.assertEqual(by_name["Havana Club Rum"]["validFrom"], "2026-09-21")
        self.assertEqual(by_name["Havana Club Rum"]["validUntil"], "2026-09-26")
        self.assertEqual(by_name["MM Extra Sekt"]["offerPrice"], 2.77)
        self.assertEqual(by_name["MM Extra Sekt"]["validFrom"], "2026-09-24")

    def test_edeka_normalizes_accessible_short_start_date(self):
        html = """
        <script>
          Angebot: MM Extra Sekt 2.77 Festpreis von 2.77€
          Angebot: MM Extra Sekt ab 24.09. 2.77 Festpreis von 2.77€
          Alle Angebote gültig bis Samstag, den 26.09.2026, KW39/2026.
        </script>
        """
        offers, _ = refresh.parse_edeka(
            html,
            "https://www.edeka.de/maerkte/023738/",
        )
        self.assertEqual(len(offers), 1)
        self.assertEqual(offers[0]["productLabel"], "MM Extra Sekt")
        self.assertEqual(offers[0]["validFrom"], "2026-09-24")
        self.assertEqual(offers[0]["validUntil"], "2026-09-26")

    def test_aldi_api_reads_structured_offer_and_regular_price(self):
        payload = """
        {
          "meta": {"pagination": {"offset": 0, "limit": 60, "totalCount": 2}},
          "data": [
            {
              "sku": "000000000000297348",
              "name": "Orangensaft 1 l",
              "brandName": "VALENSINA",
              "urlSlugText": "valensina-orangensaft-1-l",
              "price": {
                "amount": 149,
                "amountRelevant": 149,
                "amountRelevantDisplay": "1,49 €",
                "wasPriceDisplay": "2,49 €"
              }
            },
            {
              "sku": "000000000000111111",
              "name": "Bananen",
              "brandName": "",
              "urlSlugText": "bananen",
              "price": {
                "amount": 88,
                "amountRelevant": 88,
                "amountRelevantDisplay": "0,88 €",
                "wasPriceDisplay": ""
              }
            }
          ]
        }
        """
        offers, total = refresh.parse_aldi_api_page(
            payload,
            refresh.date(2026, 9, 21),
        )
        self.assertEqual(total, 2)
        self.assertEqual(len(offers), 2)
        self.assertEqual(offers[0]["productLabel"], "VALENSINA Orangensaft 1 l")
        self.assertEqual(offers[0]["offerPrice"], 1.49)
        self.assertEqual(offers[0]["originalPrice"], 2.49)
        self.assertEqual(offers[0]["validFrom"], "2026-09-21")
        self.assertEqual(offers[0]["validUntil"], "2026-09-26")
        self.assertTrue(
            offers[0]["proofRef"].endswith(
                "valensina-orangensaft-1-l-000000000000297348"
            )
        )
        self.assertEqual(offers[1]["offerPrice"], 0.88)
        self.assertNotIn("originalPrice", offers[1])

    def test_aldi_api_url_is_scoped_and_paginated(self):
        url = refresh._aldi_api_url(refresh.date(2026, 9, 24), 60)
        self.assertIn("serviceType=walk-in", url)
        self.assertIn("servicePoint=B384", url)
        self.assertIn("limit=60", url)
        self.assertIn("offset=60", url)
        self.assertIn("promotionKey=2026-09-24", url)

    def test_aldi_keeps_stated_regular_price(self):
        html = """<a href="/produkt/joghurt">Kühlung MILSANI Premium-Joghurt 200 g Spare 20 % 0,39 € 0,49 €</a>"""
        offers, _ = refresh.parse_aldi(html, "https://www.aldi-sued.de/")
        self.assertEqual(len(offers), 1)
        self.assertEqual(offers[0]["storeName"], "ALDI Süd")
        self.assertEqual(offers[0]["offerPrice"], 0.39)
        self.assertEqual(offers[0]["originalPrice"], 0.49)


    def test_penny_keeps_public_offer_and_stated_regular_price(self):
        html = """
        <a href="/angebot/gyros">
          Streichpreis 7.45 € Angebotspreis 5.99 € 5.99 -19%
          MITAKOS Hähnchengyros* je 750 g (1 kg = 7.99)
        </a>
        """
        offers, _ = refresh.parse_penny(
            html,
            "https://www.penny.de/markt/zellingen/230061/penny-retzbach-am-guessgraben-1",
        )
        self.assertEqual(len(offers), 1)
        self.assertEqual(offers[0]["productLabel"], "MITAKOS Hähnchengyros")
        self.assertEqual(offers[0]["offerPrice"], 5.99)
        self.assertEqual(offers[0]["originalPrice"], 7.45)

    def test_netto_reads_stated_regular_and_offer_price(self):
        html = """
        <p>Filial-Angebote gültig von Montag, 21.09.26 - Samstag, 26.09.26</p>
        <a href="/angebot/paprika">
          Paprika-Mix 500 g 2.98 / kg Niederlande / Spanien, Kl. I
          -16 % statt 1.79 1.49*
        </a>
        """
        offers, _ = refresh.parse_netto(
            html,
            "https://www.netto-online.de/filialen/thuengersheim/am-strassacker-1/4371",
        )
        self.assertEqual(len(offers), 1)
        self.assertEqual(offers[0]["offerPrice"], 1.49)
        self.assertEqual(offers[0]["originalPrice"], 1.79)
        self.assertEqual(offers[0]["validFrom"], "2026-09-21")
        self.assertEqual(offers[0]["validUntil"], "2026-09-26")

    def test_rewe_reads_public_action_price(self):
        html = """
        <p>Diese Woche 21.9. bis 27.9.</p>
        <h3>Dr. Oetker Ristorante Pizza Salame</h3>
        <p>tiefgefroren, je 320-g-Pckg.</p>
        <p>Knaller</p>
        <p>1,79 €</p>
        """
        offers, _ = refresh.parse_rewe(
            html,
            "https://www.rewe.de/angebote/veitshoechheim/461683/rewe-markt-pont-leveque-allee-1/",
        )
        self.assertEqual(len(offers), 1)
        self.assertEqual(offers[0]["productLabel"], "Dr. Oetker Ristorante Pizza Salame")
        self.assertEqual(offers[0]["offerPrice"], 1.79)


    def test_rewe_api_reads_current_market_offers(self):
        payload = """
        {
          "data": {
            "offers": {
              "current": {
                "available": true,
                "fromDate": "2026-09-21",
                "untilDate": "2026-09-27",
                "categories": [
                  {
                    "offers": [
                      {
                        "title": "Dr. Oetker Ristorante Pizza Salame",
                        "priceData": {
                          "price": "1,79 €",
                          "regularPrice": "2,99 €"
                        },
                        "rawValues": {"nan": "1234567"}
                      },
                      {
                        "title": "Red Bull Energy Drink",
                        "priceData": {
                          "price": "0,88 €",
                          "regularPrice": "Aktion"
                        },
                        "rawValues": {"nan": "7654321"}
                      }
                    ]
                  }
                ]
              }
            }
          }
        }
        """
        offers, _ = refresh.parse_rewe_api(
            payload,
            "https://www.rewe.de/api/stationary-offers/461683",
        )
        self.assertEqual(len(offers), 2)
        self.assertEqual(offers[0]["offerPrice"], 1.79)
        self.assertEqual(offers[0]["originalPrice"], 2.99)
        self.assertNotIn("originalPrice", offers[1])
        self.assertEqual(offers[0]["validFrom"], "2026-09-21")
        self.assertEqual(offers[0]["validUntil"], "2026-09-27")

    def test_kaufland_extracts_sale_and_regular_price(self):
        html = """<p>Gültig vom 24.09.2026 bis 30.09.2026</p><a href="/angebot/bananen">Ecuador./kolumb. Bananen, lose je kg-31%0.88 1.29</a>"""
        offers, _ = refresh.parse_kaufland(html, "https://filiale.kaufland.de/service/filiale.storeName%3DDE5103.html")
        self.assertEqual(len(offers), 1)
        self.assertEqual(offers[0]["offerPrice"], 0.88)
        self.assertEqual(offers[0]["originalPrice"], 1.29)

    def test_kaufland_card_xtra_price_is_not_universal(self):
        html = """<p>Gültig vom 24.09.2026 bis 30.09.2026</p><a href="/angebot/butter">KERRYGOLD Extra XXL -46% 2.49 4.69 Mit Kaufland Card XTRA ** 1.99</a>"""
        offers, _ = refresh.parse_kaufland(html, "https://filiale.kaufland.de/service/filiale.storeName%3DDE5103.html")
        self.assertEqual(offers, [])

if __name__ == "__main__":
    unittest.main()
