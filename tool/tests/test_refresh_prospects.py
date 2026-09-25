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


    def test_lidl_store_search_prefers_zellingen_postal_code(self):
        payload = """
        [
          {"storeKey": "SK-near", "postalCode": "97753", "name": "Karlstadt", "distance": 500},
          {"storeKey": "SK-zellingen", "postalCode": "97225", "name": "Zellingen", "distance": 7300}
        ]
        """
        self.assertEqual(
            refresh._lidl_store_key(payload),
            "SK-zellingen",
        )
        url = refresh._lidl_store_search_url()
        self.assertIn("input=97225", url)
        self.assertIn("latitude=49.91009", url)
        self.assertIn("longitude=9.81492", url)

    def test_lidl_store_offer_reads_price_normal_price_dates_and_pack(self):
        payload = """
        {
          "offers": [
            {
              "id": "fe494b54",
              "offerType": "StoreSpecialPriceDiscount",
              "redemptionChannel": "Store",
              "imageUrl": "https://static-coupons.lidlplus.com/thunfisch.jpg",
              "priceBox": {
                "strikethrough": true,
                "largePartNumeric": 3.79,
                "smallPartNumeric": 5.79
              },
              "title": "Saupiquet MSC Thunfisch-Salat",
              "brand": "SAUPIQUET",
              "startValidityDate": "2026-09-24T00:00:01+00:00",
              "endValidityDate": "2026-09-26T23:59:59+00:00",
              "startValidityDateUTC": "2026-09-23T22:00:01Z",
              "endValidityDateUTC": "2026-09-26T21:59:59Z",
              "packaging": "Je 2x 160 g (Max. 24 Stück)\\nNormalpreis: 3.99\\n1 kg = 12.47"
            }
          ]
        }
        """
        offers, _ = refresh.parse_lidl_store_offers(payload)
        self.assertEqual(len(offers), 1)
        self.assertEqual(
            offers[0]["productLabel"],
            "Saupiquet MSC Thunfisch-Salat Je 2x 160 g",
        )
        self.assertEqual(offers[0]["offerPrice"], 3.79)
        self.assertEqual(offers[0]["originalPrice"], 3.99)
        self.assertEqual(offers[0]["validFrom"], "2026-09-24")
        self.assertEqual(offers[0]["validUntil"], "2026-09-26")
        self.assertEqual(
            offers[0]["imageUrl"],
            "https://static-coupons.lidlplus.com/thunfisch.jpg",
        )

    def test_lidl_store_offer_skips_percentage_and_x_for_y(self):
        payload = """
        {
          "offers": [
            {
              "id": "percent",
              "offerType": "StorePercentageOnProductDiscount",
              "redemptionChannel": "Store",
              "priceBox": {"largePartNumeric": null, "largePartString": "-15%"},
              "title": "auf alle Frischkäse",
              "startValidityDate": "2026-09-24T00:00:01+00:00",
              "endValidityDate": "2026-09-26T23:59:59+00:00"
            },
            {
              "id": "multi",
              "offerType": "StoreXforYDiscount",
              "redemptionChannel": "Store",
              "priceBox": {"largePartNumeric": 1.30},
              "title": "Schokobrötchen",
              "packaging": "Je 3 Stück",
              "startValidityDate": "2026-09-24T00:00:01+00:00",
              "endValidityDate": "2026-09-26T23:59:59+00:00"
            }
          ]
        }
        """
        offers, _ = refresh.parse_lidl_store_offers(payload)
        self.assertEqual(offers, [])

    def test_lidl_overview_reads_active_flyer_metadata(self):
        payload = """
        {
          "categories": [
            {
              "subcategories": [
                {
                  "flyers": [
                    {
                      "id": "019f-test",
                      "name": "Aktionsprospekt",
                      "title": "28.09.2026 – 03.10.2026",
                      "offerStartDate": "2026-09-28",
                      "offerEndDate": "2026-10-03",
                      "status": "next",
                      "pdfUrl": "https://assets.leaflets.schwarz/test.pdf",
                      "thumbnailUrl": "https://imgproxy.leaflets.schwarz/test.jpg",
                      "flyerUrlAbsolute": "https://www.lidl.de/l/prospekte/aktionsprospekt-28-09-2026-03-10-2026-321560/ar/0",
                      "regions": [{"code": 0}]
                    }
                  ]
                }
              ]
            }
          ]
        }
        """
        prospects = refresh.parse_lidl_overview(payload)
        self.assertEqual(len(prospects), 1)
        self.assertEqual(
            prospects[0]["title"],
            "Aktionsprospekt 28.09.2026 – 03.10.2026",
        )
        self.assertEqual(prospects[0]["offerStartDate"], "2026-09-28")
        self.assertEqual(prospects[0]["offerEndDate"], "2026-10-03")
        self.assertIn(
            "flyer_identifier=aktionsprospekt-28-09-2026-03-10-2026-321560",
            prospects[0]["apiUrl"],
        )
        self.assertIn("region_code=0", prospects[0]["apiUrl"])

    def test_lidl_detail_url_prefers_explicit_flyer_json(self):
        url = refresh._lidl_detail_url({
            "flyerJson": "https://endpoints.leaflets.schwarz/v4/flyer?flyer_identifier=abc"
        })
        self.assertEqual(
            url,
            "https://endpoints.leaflets.schwarz/v4/flyer?flyer_identifier=abc",
        )

    def test_penny_market_region_uses_exact_market(self):
        payload = """
        [
          {"wwIdent": "111111", "sellingRegion": "15-999"},
          {"wwIdent": "230061", "sellingRegion": "15-001"}
        ]
        """
        self.assertEqual(
            refresh._penny_market_region(payload, "230061"),
            "15-001",
        )

    def test_penny_catalog_meta_reads_week_and_categories(self):
        html = """
        <div data-current-week="2026-39" data-category-name="top-angebote"></div>
        <div data-current-week="2026-39" data-category-name="kuehlregal"></div>
        """
        categories, week = refresh._penny_catalog_meta(html)
        self.assertEqual(week, "2026-39")
        self.assertEqual(categories, ["top-angebote", "kuehlregal"])
        start, end = refresh._penny_week_dates(week)
        self.assertEqual(start.isoformat(), "2026-09-21")
        self.assertEqual(end.isoformat(), "2026-09-26")

    def test_penny_api_reads_offer_regular_price_quantity_and_image(self):
        payload = """
        {
          "offerTiles": [
            {
              "title": "MILPRIMA Schmand",
              "quantity": "je 200 g",
              "price": "0.69*",
              "crossOutPrice": "0.79",
              "uuid": "43a5c357-b337-48e2-8a9c-c1f4fa6a86f8",
              "imageRendition": {
                "tileLg": "https://cdn.penny.de/schmand.png"
              }
            }
          ]
        }
        """
        offers, _ = refresh.parse_penny_api(
            payload,
            "https://www.penny.de/markt/zellingen/230061/penny-retzbach-am-guessgraben-1",
            refresh.date(2026, 9, 21),
            refresh.date(2026, 9, 26),
        )
        self.assertEqual(len(offers), 1)
        self.assertEqual(offers[0]["productLabel"], "MILPRIMA Schmand je 200 g")
        self.assertEqual(offers[0]["offerPrice"], 0.69)
        self.assertEqual(offers[0]["originalPrice"], 0.79)
        self.assertEqual(offers[0]["imageUrl"], "https://cdn.penny.de/schmand.png")
        self.assertEqual(offers[0]["validFrom"], "2026-09-21")
        self.assertEqual(offers[0]["validUntil"], "2026-09-26")

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

    def test_kaufland_selector_reads_store_code(self):
        self.assertEqual(
            refresh._kaufland_selector(
                "https://filiale.kaufland.de/service/filiale.storeName%3DDE5103.html"
            ),
            "DE5103",
        )

    def test_kaufland_structured_offer_reads_price_old_price_and_image(self):
        payload = {
            "component": "OfferTemplate",
            "props": {
                "offerData": {
                    "cycles": [
                        {
                            "categories": [
                                {
                                    "offers": [
                                        {
                                            "offerId": "offer-1",
                                            "klNr": "123",
                                            "dateFrom": "2026-09-24",
                                            "dateTo": "2026-09-30",
                                            "title": "Kerrygold",
                                            "subtitle": "Butter",
                                            "unit": "je 250-g-Packung",
                                            "formattedPrice": "1,99",
                                            "formattedOldPrice": "2,49",
                                            "listImage": "https://example.test/butter.jpg"
                                        },
                                        {
                                            "offerId": "offer-xtra-only",
                                            "klNr": "456",
                                            "dateFrom": "2026-09-24",
                                            "dateTo": "2026-09-30",
                                            "title": "XTRA Produkt",
                                            "formattedPrice": "0,00",
                                            "loyaltyFormattedPrice": "1,49"
                                        }
                                    ]
                                }
                            ]
                        }
                    ]
                }
            }
        }
        html = "<script>window.SSR['offers'] = " + refresh.json.dumps(payload) + ";</script>"
        offers, _ = refresh.parse_kaufland_api(
            html,
            refresh.KAUFLAND_OVERVIEW_URL,
            {"123", "456"},
        )
        self.assertEqual(len(offers), 1)
        self.assertEqual(
            offers[0]["productLabel"],
            "Kerrygold Butter je 250-g-Packung",
        )
        self.assertEqual(offers[0]["offerPrice"], 1.99)
        self.assertEqual(offers[0]["originalPrice"], 2.49)
        self.assertEqual(offers[0]["validFrom"], "2026-09-24")
        self.assertEqual(offers[0]["validUntil"], "2026-09-30")
        self.assertEqual(
            offers[0]["imageUrl"],
            "https://example.test/butter.jpg",
        )

    def test_kaufland_structured_offer_respects_store_availability(self):
        payload = {
            "component": "OfferTemplate",
            "props": {
                "offerData": {
                    "cycles": [{
                        "categories": [{
                            "offers": [
                                {
                                    "offerId": "local",
                                    "klNr": "111",
                                    "dateFrom": "2026-09-24",
                                    "dateTo": "2026-09-30",
                                    "title": "Lokales Produkt",
                                    "formattedPrice": "0,88"
                                },
                                {
                                    "offerId": "other",
                                    "klNr": "222",
                                    "dateFrom": "2026-09-24",
                                    "dateTo": "2026-09-30",
                                    "title": "Andere Region",
                                    "formattedPrice": "0,69"
                                }
                            ]
                        }]
                    }]
                }
            }
        }
        html = refresh.json.dumps(payload)
        offers, _ = refresh.parse_kaufland_api(
            html,
            refresh.KAUFLAND_OVERVIEW_URL,
            {"111"},
        )
        self.assertEqual(len(offers), 1)
        self.assertEqual(offers[0]["productLabel"], "Lokales Produkt")

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
