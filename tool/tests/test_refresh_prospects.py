import importlib.util
import pathlib
import unittest

MODULE = pathlib.Path(__file__).resolve().parents[1] / "refresh_prospects.py"
spec = importlib.util.spec_from_file_location("refresh_prospects", MODULE)
refresh = importlib.util.module_from_spec(spec)
spec.loader.exec_module(refresh)

class ProspectParserTest(unittest.TestCase):
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

    def test_aldi_keeps_stated_regular_price(self):
        html = """<a href="/produkt/joghurt">Kühlung MILSANI Premium-Joghurt 200 g Spare 20 % 0,39 € 0,49 €</a>"""
        offers, _ = refresh.parse_aldi(html, "https://www.aldi-sued.de/")
        self.assertEqual(len(offers), 1)
        self.assertEqual(offers[0]["storeName"], "ALDI Süd")
        self.assertEqual(offers[0]["offerPrice"], 0.39)
        self.assertEqual(offers[0]["originalPrice"], 0.49)

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
