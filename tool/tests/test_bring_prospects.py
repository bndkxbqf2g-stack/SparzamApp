import pathlib
import sys
import unittest
from datetime import date

ROOT = pathlib.Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tool import bring_prospects as bring


class BringProspectTest(unittest.TestCase):
    def test_share_links_are_specific_brochure_references(self):
        cases = {
            "Netto": "218538",
            "PENNY": "218915",
            "Lidl": "218970",
            "Kaufland": "213278",
            "EDEKA": "219070",
            "Aldi Süd": "219091",
        }
        for title, brochure_number in cases.items():
            with self.subTest(title=title):
                brochure_id = "brn:bring-de:offersbrochure:" + brochure_number
                url = (
                    "https://enjoy.getbring.com/ZAzR?"
                    "af_web_dp=https%3A%2F%2Fdeeplink.getbring.com%2Fview%2Foffers%2F"
                    "bring-de%2F" + brochure_id.replace(":", "%3A") + "%2F0"
                    "&af_og_title=" + title.replace(" ", "%20")
                    "&af_og_image=https%253A%252F%252Fofferscdn.bringapi.app%252F"
                    "content%252Foffers%252Fbring-de%252F28%252F"
                    + brochure_number
                    + "%252F1790000000000%252F00001_1500x2500_example.jpeg"
                )
                parsed = bring.parse_share_url(url)
                self.assertEqual(parsed["brochureId"], brochure_id)
                self.assertIn("/" + brochure_number + "/", parsed["coverImage"])
                self.assertTrue(parsed["deepLink"].endswith("/" + brochure_id + "/0"))

    def test_structured_hotspot_becomes_leaflet_offer_with_image_and_prices(self):
        offer = {
            "brn": "brn:bring-de:offersbrochure:218970",
            "title": "Lidl",
            "activeFrom": "2026-09-28T00:00:00Z",
            "activeTo": "2026-10-03T23:59:59Z",
            "company": {"title": "Lidl"},
            "pages": [{"image": {"imageUrl": "https://cdn.example/cover.jpg"}}],
        }
        detail = {
            "pages": [
                {
                    "page": 1,
                    "image": {"imageUrl": "https://cdn.example/page-1.jpg"},
                    "discounts": [
                        {
                            "name": "Milbona Schmand",
                            "description": "200 g",
                            "price": 69,
                            "oldPrice": 89,
                            "imageUrl": "https://cdn.example/schmand.png",
                        }
                    ],
                }
            ]
        }

        parsed = bring.transform_bring_brochure(
            offer,
            detail,
            today=date(2026, 9, 29),
        )

        self.assertIsNotNone(parsed)
        self.assertEqual(parsed["storeName"], "Lidl")
        self.assertEqual(parsed["prospect"]["pageCount"], 1)
        self.assertEqual(parsed["prospect"]["pageSamples"][0]["image"], "https://cdn.example/page-1.jpg")
        self.assertEqual(len(parsed["offers"]), 1)
        item = parsed["offers"][0]
        self.assertEqual(item["productLabel"], "Milbona Schmand 200 g")
        self.assertEqual(item["offerPrice"], 0.69)
        self.assertEqual(item["originalPrice"], 0.89)
        self.assertEqual(item["source"], "leaflet")
        self.assertEqual(item["imageUrl"], "https://cdn.example/schmand.png")
        self.assertIn("brn:bring-de:offersbrochure:218970/0", item["proofRef"])

    def test_expired_brochure_is_not_imported(self):
        parsed = bring.transform_bring_brochure(
            {
                "brn": "brn:bring-de:offersbrochure:1",
                "activeFrom": "2026-09-01",
                "activeTo": "2026-09-05",
                "company": {"title": "Lidl"},
            },
            {"pages": [{"page": 1, "image": {"imageUrl": "https://cdn.example/1.jpg"}}]},
            today=date(2026, 9, 29),
        )
        self.assertIsNone(parsed)

    def test_unsupported_retailer_is_not_imported(self):
        parsed = bring.transform_bring_brochure(
            {
                "brn": "brn:bring-de:offersbrochure:2",
                "activeFrom": "2026-09-28",
                "activeTo": "2026-10-03",
                "company": {"title": "REWE"},
            },
            {"pages": [{"page": 1, "image": {"imageUrl": "https://cdn.example/1.jpg"}}]},
            today=date(2026, 9, 29),
        )
        self.assertIsNone(parsed)


if __name__ == "__main__":
    unittest.main()
