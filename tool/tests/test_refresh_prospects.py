import importlib.util
import pathlib
import tempfile
import unittest
from datetime import datetime
from unittest import mock
from urllib.error import HTTPError
from zoneinfo import ZoneInfo

MODULE = pathlib.Path(__file__).resolve().parents[1] / "refresh_prospects.py"
FEED = (
    pathlib.Path(__file__).resolve().parents[2]
    / "assets"
    / "prospects"
    / "current.json"
)
spec = importlib.util.spec_from_file_location("refresh_prospects", MODULE)
refresh = importlib.util.module_from_spec(spec)
spec.loader.exec_module(refresh)

class ProspectParserTest(unittest.TestCase):
    def test_source_category_accepts_named_taxonomy_aliases(self):
        self.assertEqual(
            refresh._source_category({"departmentName": "Molkerei"}),
            "Molkerei",
        )
        self.assertEqual(
            refresh._source_category(
                {
                    "productCategory": {
                        "displayName": "Tiefkühlkost",
                    }
                }
            ),
            "Tiefkühlkost",
        )
        self.assertEqual(
            refresh._source_category(
                {
                    "categoryPath": [
                        {"name": "Lebensmittel"},
                        {"displayName": "Molkerei"},
                    ]
                }
            ),
            "Molkerei",
        )
        self.assertEqual(
            refresh._source_category({"departmentLabel": "Obst & Gemüse"}),
            "Obst & Gemüse",
        )
        self.assertEqual(
            refresh._source_category({"categoryLabel": "Tiefkühlkost"}),
            "Tiefkühlkost",
        )
        self.assertEqual(
            refresh._source_category({"productGroup": {"name": "Backwaren"}}),
            "Backwaren",
        )

    def test_source_category_ignores_untrusted_or_non_text_values(self):
        self.assertIsNone(
            refresh._source_category(
                {"category": {"id": "123", "url": "https://example.test/category"}}
            )
        )
        self.assertIsNone(
            refresh._source_category(
                {"categoryPath": [{"id": "123"}, {"href": "https://example.test"}]}
            )
        )

    def test_default_refresh_day_uses_berlin_calendar(self):
        expected = datetime.now(ZoneInfo("Europe/Berlin")).date()
        self.assertEqual(refresh.local_today(), expected)

    def test_previous_active_cover_survives_offer_refresh_without_pages(self):
        previous = {
            "sources": [
                {
                    "storeName": "Netto",
                    "prospects": [
                        {
                            "id": "netto-current",
                            "title": "Netto Prospekt",
                            "offerEndDate": "2026-10-19",
                            "pageSamples": [{"number": 1, "image": "https://example.test/netto-cover.jpg"}],
                        }
                    ],
                }
            ]
        }
        merged = refresh._merge_previous_prospects(
            previous,
            "Netto",
            [],
            today=refresh.date(2026, 10, 13),
        )
        self.assertEqual(merged[0]["id"], "netto-current")
        self.assertEqual(merged[0]["pageSamples"][0]["number"], 1)

    def test_previous_expired_cover_is_not_carried_forward(self):
        previous = {
            "sources": [
                {
                    "storeName": "Netto",
                    "prospects": [
                        {
                            "id": "netto-old",
                            "offerEndDate": "2026-10-12",
                            "pageSamples": [{"number": 1, "image": "https://example.test/old.jpg"}],
                        }
                    ],
                }
            ]
        }
        self.assertEqual(
            refresh._merge_previous_prospects(
                previous,
                "Netto",
                [],
                today=refresh.date(2026, 10, 13),
            ),
            [],
        )

    def test_previous_fallback_stays_with_the_exact_store_branch(self):
        previous = {
            "offers": [
                {
                    "storeName": "Lidl",
                    "branchId": "lidl-zellingen",
                    "location": "Zellingen",
                    "validUntil": "2099-10-17",
                    "productLabel": "Butter 250 g",
                },
                {
                    "storeName": "Lidl",
                    "branchId": "lidl-wuerzburg",
                    "location": "Würzburg",
                    "validUntil": "2099-10-17",
                    "productLabel": "Butter 250 g",
                },
            ]
        }
        result = refresh.active_previous(
            previous,
            "Lidl",
            {"branchId": "lidl-zellingen", "location": "Zellingen"},
        )
        self.assertEqual(len(result), 1)
        self.assertEqual(result[0]["branchId"], "lidl-zellingen")

    def test_previous_cover_does_not_cross_same_store_branches(self):
        previous = {
            "sources": [
                {
                    "storeName": "Lidl",
                    "branchId": "lidl-zellingen",
                    "location": "Zellingen",
                    "prospects": [
                        {
                            "id": "same-leaflet",
                            "title": "Lidl Prospekt",
                            "offerEndDate": "2099-10-17",
                            "pageSamples": [{"number": 1, "image": "https://example.test/zellingen.jpg"}],
                        }
                    ],
                },
                {
                    "storeName": "Lidl",
                    "branchId": "lidl-wuerzburg",
                    "location": "Würzburg",
                    "prospects": [
                        {
                            "id": "same-leaflet",
                            "title": "Lidl Prospekt",
                            "offerEndDate": "2099-10-17",
                            "pageSamples": [{"number": 1, "image": "https://example.test/wuerzburg.jpg"}],
                        }
                    ],
                },
            ]
        }
        current = [
            {
                "id": "same-leaflet",
                "title": "Lidl Prospekt",
                "offerEndDate": "2099-10-17",
                "branchId": "lidl-zellingen",
                "location": "Zellingen",
            }
        ]
        merged = refresh._merge_previous_prospects(
            previous,
            "Lidl",
            current,
            branch={"branchId": "lidl-zellingen", "location": "Zellingen"},
            today=refresh.date(2026, 10, 13),
        )
        self.assertEqual(
            merged[0]["pageSamples"][0]["image"],
            "https://example.test/zellingen.jpg",
        )

    def test_source_adapter_metadata_is_added_without_overwriting_provider_value(self):
        offers = [
            {"productLabel": "Butter", "sourceAdapter": ""},
            {"productLabel": "Prospekt", "sourceAdapter": "kaufda_next_data"},
            {"productLabel": "Milch", "sourceAdapter": None},
        ]

        enriched = refresh._attach_source_adapter(offers, "structured_api+bring_brochure")

        self.assertEqual(
            enriched[0]["sourceAdapter"],
            "structured_api+bring_brochure",
        )
        self.assertEqual(enriched[1]["sourceAdapter"], "kaufda_next_data")
        self.assertEqual(
            enriched[2]["sourceAdapter"],
            "structured_api+bring_brochure",
        )
        self.assertEqual(offers[0]["sourceAdapter"], "")
        self.assertIsNot(enriched[0], offers[0])

    def test_record_accepts_only_http_images(self):
        invalid = refresh.record(
            "Lidl",
            "Butter 250 g",
            1.99,
            refresh.date(2026, 10, 12),
            refresh.date(2026, 10, 17),
            "https://example.test/butter",
            image="javascript:alert(1)",
        )
        self.assertNotIn("imageUrl", invalid)

        valid = refresh.record(
            "Lidl",
            "Butter 250 g",
            1.99,
            refresh.date(2026, 10, 12),
            refresh.date(2026, 10, 17),
            "https://example.test/butter",
            image="https://cdn.example/butter.jpg",
        )
        self.assertEqual(valid["imageUrl"], "https://cdn.example/butter.jpg")

    def test_source_image_accepts_bounded_nested_media_aliases(self):
        image = refresh._source_image({
            "images": [
                {"thumbnail": {"url": "https://cdn.example/thumbnail.jpg"}},
            ],
        })
        self.assertEqual(image, "https://cdn.example/thumbnail.jpg")

        self.assertEqual(
            refresh._source_image({
                "pictureUrl": "https://cdn.example/picture.jpg",
            }),
            "https://cdn.example/picture.jpg",
        )

    def test_record_preserves_single_package_and_base_price(self):
        item = refresh.record(
            "Lidl",
            "Butter 250 g",
            1.99,
            refresh.date(2026, 10, 12),
            refresh.date(2026, 10, 17),
            "https://example.test/butter",
        )
        self.assertEqual(item["packageSize"], "250 g")
        self.assertEqual(item["priceByBaseUnit"], "7,96 €/kg")

    def test_record_uses_total_multipack_quantity(self):
        item = refresh.record(
            "PENNY",
            "Mineralwasser 6 x 1,5 l",
            3.99,
            refresh.date(2026, 10, 12),
            refresh.date(2026, 10, 17),
            "https://example.test/water",
        )
        self.assertEqual(item["packageSize"], "6 x 1,5 l")
        self.assertEqual(item["priceByBaseUnit"], "0,44 €/l")

    def test_record_does_not_guess_over_variable_package_range(self):
        item = refresh.record(
            "Netto",
            "Tomaten 160 g - 175 g",
            0.99,
            refresh.date(2026, 10, 12),
            refresh.date(2026, 10, 17),
            "https://example.test/tomatoes",
        )
        self.assertNotIn("packageSize", item)
        self.assertNotIn("priceByBaseUnit", item)

    def test_record_does_not_choose_one_variant_from_slash_package(self):
        item = refresh.record(
            "Lidl",
            "Pralinen je 114/110/105 g",
            1.49,
            refresh.date(2026, 10, 12),
            refresh.date(2026, 10, 17),
            "https://example.test/pralines",
        )
        self.assertNotIn("packageSize", item)
        self.assertNotIn("priceByBaseUnit", item)

    def test_http_403_is_not_retried_with_a_different_user_agent(self):
        error = HTTPError(
            "https://example.test/prospect",
            403,
            "forbidden",
            hdrs=None,
            fp=None,
        )
        with mock.patch.object(refresh, "urlopen", side_effect=error) as request:
            with self.assertRaises(HTTPError):
                refresh.fetch("https://example.test/prospect")
        self.assertEqual(request.call_count, 1)

    def test_failed_refresh_keeps_previous_dataset_timestamp(self):
        previous = {"generatedAt": "2026-10-11T04:15:00Z"}
        self.assertEqual(
            refresh.feed_generated_at(
                previous,
                0,
                now=refresh.datetime(2026, 10, 12, 4, 15, tzinfo=refresh.timezone.utc),
            ),
            "2026-10-11T04:15:00Z",
        )

    def test_successful_refresh_gets_the_actual_refresh_timestamp(self):
        previous = {"generatedAt": "2026-10-11T04:15:00Z"}
        self.assertEqual(
            refresh.feed_generated_at(
                previous,
                1,
                now=refresh.datetime(2026, 10, 12, 4, 15, tzinfo=refresh.timezone.utc),
            ),
            "2026-10-12T04:15:00Z",
        )

    def test_current_week_ends_on_the_german_retailer_saturday(self):
        self.assertEqual(
            refresh.current_week(refresh.date(2026, 10, 10)),
            (refresh.date(2026, 10, 5), refresh.date(2026, 10, 10)),
        )

    def test_every_configured_source_keeps_its_target_branch_metadata(self):
        source_ids = {source[0] for source in refresh.SOURCES}
        self.assertEqual(source_ids, set(refresh.SOURCE_BRANCH_METADATA))
        for source_id in source_ids:
            metadata = refresh.source_branch_metadata(source_id)
            self.assertTrue(metadata["branchId"])
            self.assertTrue(metadata["location"])
            self.assertTrue(metadata["address"])

    def test_versioned_feed_has_current_cover_and_branch_for_every_source(self):
        payload = refresh.json.loads(FEED.read_text(encoding="utf-8"))
        expected_store_names = {source[1] for source in refresh.SOURCES}
        self.assertEqual(
            {source["storeName"] for source in payload["sources"]},
            expected_store_names,
        )

        generated_at = str(payload.get("generatedAt", ""))
        self.assertTrue(generated_at)
        reference_day = refresh.date.fromisoformat(generated_at[:10]).isoformat()
        for source in payload["sources"]:
            with self.subTest(store=source["storeName"]):
                status = source.get("status")
                self.assertIn(status, ("ok", "metadata_only", "error"))
                if status == "error":
                    # A failed refresh may retain the last validated current
                    # cover, but it must remain visibly marked as an error.
                    self.assertTrue(source.get("prospects"))
                self.assertTrue(source.get("branchId"))
                self.assertTrue(source.get("location"))
                self.assertTrue(source.get("address"))

                current_prospects = [
                    prospect
                    for prospect in source.get("prospects", [])
                    if prospect.get("offerStartDate", "")
                    <= reference_day
                    <= prospect.get("offerEndDate", "")
                ]
                self.assertTrue(current_prospects)

                cover_pages = current_prospects[0].get("pageSamples", [])
                self.assertTrue(cover_pages)
                self.assertEqual(cover_pages[0].get("number"), 1)
                self.assertTrue(
                    str(cover_pages[0].get("image", "")).startswith("https://")
                )

    def test_versioned_feed_keeps_verified_multi_page_catalogs(self):
        payload = refresh.json.loads(FEED.read_text(encoding="utf-8"))
        minimum_pages = {
            "ALDI Süd": 2,
            "EDEKA": 2,
            "Kaufland": 2,
            "Lidl": 2,
            "PENNY": 1,
            "Netto": 2,
        }
        for store_name, minimum in minimum_pages.items():
            source = next(
                source
                for source in payload["sources"]
                if source["storeName"] == store_name
            )
            prospects = source.get("prospects", [])
            self.assertTrue(prospects, store_name)
            current = max(
                prospects,
                key=lambda item: len(item.get("pageSamples", [])),
            )
            with self.subTest(store=store_name):
                self.assertGreaterEqual(
                    len(current.get("pageSamples", [])),
                    minimum,
                )
                if store_name == "PENNY":
                    self.assertEqual(current.get("pageStatus"), "cover_only")
                    self.assertFalse(current.get("pageCountKnown"))
                else:
                    self.assertEqual(current.get("pageStatus"), "complete")
                    self.assertEqual(
                        current.get("loadedPageCount"),
                        len(current.get("pageSamples", [])),
                    )

    def test_current_prospect_offers_drop_overlapping_old_periods(self):
        offers = [
            {"storeName": "Kaufland", "validFrom": "2026-09-24", "validUntil": "2026-09-30", "productLabel": str(i), "offerPrice": 1.0}
            for i in range(3)
        ] + [{"storeName": "Kaufland", "validFrom": "2026-08-23", "validUntil": "2026-09-30", "productLabel": "old", "offerPrice": 1.0}]
        result = refresh.current_prospect_offers(offers, refresh.date(2026, 9, 29))
        self.assertEqual(len(result), 3)

    def test_current_prospect_offers_keeps_same_store_branches_separate(self):
        offers = [
            {
                "storeName": "Lidl",
                "productLabel": "Butter 250 g",
                "offerPrice": 1.29,
                "validFrom": "2026-10-12",
                "validUntil": "2026-10-17",
                "source": "retailerWebsite",
                "sourceAdapter": "lidl_api",
                "branchId": "lidl-zellingen",
                "location": "Zellingen",
            },
            {
                "storeName": "Lidl",
                "productLabel": "Butter 250 g",
                "offerPrice": 1.29,
                "validFrom": "2026-10-12",
                "validUntil": "2026-10-17",
                "source": "retailerWebsite",
                "sourceAdapter": "kaufda",
                "branchId": "lidl-zellingen",
                "location": "Zellingen",
            },
            {
                "storeName": "Lidl",
                "productLabel": "Butter 250 g",
                "offerPrice": 1.29,
                "validFrom": "2026-10-12",
                "validUntil": "2026-10-17",
                "source": "retailerWebsite",
                "sourceAdapter": "lidl_api",
                "branchId": "lidl-wuerzburg",
                "location": "Würzburg",
            },
        ]

        result = refresh.current_prospect_offers(
            offers,
            refresh.date(2026, 10, 12),
        )

        self.assertEqual(len(result), 2)
        self.assertEqual(
            {item["branchId"] for item in result},
            {"lidl-zellingen", "lidl-wuerzburg"},
        )
        zellingen = next(
            item for item in result if item["branchId"] == "lidl-zellingen"
        )
        self.assertEqual(zellingen["sourceAdapter"], "lidl_api")

    def test_current_prospect_offers_excludes_non_food_campaign_items(self):
        offers = [
            {
                "storeName": "Kaufland",
                "validFrom": "2026-10-12",
                "validUntil": "2026-10-17",
                "productLabel": "ARIEL Colorwaschmittel",
                "offerPrice": 4.99,
            },
            {
                "storeName": "Kaufland",
                "validFrom": "2026-10-12",
                "validUntil": "2026-10-17",
                "productLabel": "Pflanzenöl 1 l",
                "offerPrice": 1.99,
            },
        ]
        result = refresh.current_prospect_offers(
            offers,
            refresh.date(2026, 10, 12),
        )
        self.assertEqual([item["productLabel"] for item in result], ["Pflanzenöl 1 l"])

    def test_official_period_beats_larger_optional_kaufda_period(self):
        offers = [
            {
                "storeName": "Lidl",
                "productLabel": "Offizielles Angebot",
                "offerPrice": 1.29,
                "validFrom": "2026-10-12",
                "validUntil": "2026-10-17",
                "source": "retailerWebsite",
            },
            *[
                {
                    "storeName": "Lidl",
                    "productLabel": f"KaufDA Treffer {index}",
                    "offerPrice": 1.39,
                    "validFrom": "2026-10-11",
                    "validUntil": "2026-10-17",
                    "source": "retailerWebsite",
                    "sourceAdapter": "kaufda",
                }
                for index in range(3)
            ],
        ]

        result = refresh.current_prospect_offers(
            offers,
            refresh.date(2026, 10, 12),
        )

        self.assertEqual(
            [item["productLabel"] for item in result],
            ["Offizielles Angebot"],
        )

    def test_food_guard_keeps_food_words_that_contain_non_food_like_terms(self):
        self.assertTrue(
            refresh.is_food_offer(
                {"productLabel": "Dtsch. Halloween-Kürbis, lose je Stück"}
            )
        )
        self.assertTrue(
            refresh.is_food_offer({"productLabel": "GARDENLINE Frische Kräuter"})
        )
        self.assertFalse(
            refresh.is_food_offer({"productLabel": "HOME CREATION LED-Kerzen"})
        )
        self.assertFalse(
            refresh.is_food_offer(
                {"productLabel": "DRESDNER ESSENZ Badesalz je 60 g"}
            )
        )
        self.assertFalse(
            refresh.is_food_offer(
                {
                    "productLabel": "Gourmet Gold je 24 x 85 g",
                    "category": "09_Drogerie__Tiernahrung",
                }
            )
        )
        self.assertFalse(
            refresh.is_food_offer(
                {"productLabel": "Bepflanztes Holzgefäß je Stück"}
            )
        )

        for item in (
            {"productLabel": "LED-Lesehilfe je", "category": "181_NF_Badartikel"},
            {"productLabel": "WEINBERGER LED-Flächenlupe je", "category": "181_NF_Badartikel"},
            {"productLabel": "LED-Eimer Halloween", "category": "221_Halloween"},
            {"productLabel": "Süßigkeitenschale Halloween", "category": "221_Halloween"},
            {"productLabel": "Totenkopf Halloween", "category": "221_Halloween"},
        ):
            self.assertFalse(refresh.is_food_offer(item))

        self.assertTrue(
            refresh.is_food_offer(
                {
                    "productLabel": "BAD HEILBRUNNER Brennnesselblätter Tee* je 8 Stück",
                    "category": "drogerie-und-haushalt1",
                }
            )
        )

        for label in (
            "CROFTON Halloween Tasse, Fledermaus",
            "MELITTA Filterkaffeemaschine Easy Therm",
            "Deko-Figur Halloween",
            "JACK & JONES Herren-Hoodie",
            "KUSCHELWEICH Weichspüler 1 l",
            "K-CLASSIC Ultra-Klumpstreu 6 l",
            "ALPINA Decken- und Wandweiß 10 l je 10-l-Eimer",
        ):
            self.assertFalse(refresh.is_food_offer({"productLabel": label}))

        self.assertTrue(
            refresh.is_food_offer(
                {"productLabel": "WINTERTRAUM Tassenhänger Knuspermännchen 170 g"}
            )
        )

        self.assertTrue(
            refresh.is_food_offer(
                {"productLabel": "WINTERTRAUM Tassenhänger Knuspermännchen 170 g"}
            )
        )

        for label in (
            "CROFTON Halloween Backsortiment, Groß, Kürbis, Orange",
            "KESPER Frühstücksbrettchen* je 2er-Packung",
            "KESPER Schneid-und-Servierbrett mit Einbrand* je Stück",
            "576er-LED-Clusterlichtergirlande* je Stück",
            "LED-Glitzertannenbaum* je Stück",
            "LED-Fensterbild* je Stück",
            "AXE Bodyspray 250 ml, Temptation",
            "Fenjal Cremedusche 200 ml",
            "Dick & Durstig Küchentücher",
            "Flamingoblume je",
        ):
            self.assertFalse(refresh.is_food_offer({"productLabel": label}))

    def test_source_counts_report_filtered_food_and_keep_provider_count(self):
        sources = [{"storeName": "Kaufland", "recordCount": 3}]
        offers = [
            {"storeName": "Kaufland"},
            {"storeName": "Kaufland"},
        ]

        refresh.update_source_record_counts(sources, offers)

        self.assertEqual(sources[0]["recordCount"], 2)
        self.assertEqual(sources[0]["rawRecordCount"], 3)

    def test_source_counts_keep_same_store_branches_separate(self):
        sources = [
            {
                "storeName": "Lidl",
                "branchId": "lidl-zellingen",
                "location": "Zellingen",
                "recordCount": 2,
            },
            {
                "storeName": "Lidl",
                "branchId": "lidl-wuerzburg",
                "location": "Würzburg",
                "recordCount": 2,
            },
        ]
        offers = [
            {"storeName": "Lidl", "branchId": "lidl-zellingen", "location": "Zellingen"},
            {"storeName": "Lidl", "branchId": "lidl-zellingen", "location": "Zellingen"},
            {"storeName": "Lidl", "branchId": "lidl-wuerzburg", "location": "Würzburg"},
        ]

        refresh.update_source_record_counts(sources, offers)

        self.assertEqual(sources[0]["recordCount"], 2)
        self.assertEqual(sources[1]["recordCount"], 1)
        self.assertEqual(sources[1]["rawRecordCount"], 2)

    def test_versioned_feed_contains_only_proven_food_records(self):
        payload = refresh.json.loads(FEED.read_text(encoding="utf-8"))
        offers = payload.get("offers", [])
        self.assertTrue(offers)
        invalid = [
            item["productLabel"]
            for item in offers
            if not refresh.is_food_offer(item)
        ]
        self.assertEqual(invalid, [])
        self.assertTrue(all(float(item["offerPrice"]) > 0 for item in offers))
        self.assertTrue(all(item.get("proofRef") for item in offers))

    def test_versioned_feed_regular_prices_are_explicit_and_branch_bound(self):
        payload = refresh.json.loads(FEED.read_text(encoding="utf-8"))
        regular = [
            item for item in payload.get("offers", [])
            if "originalPrice" in item
        ]

        self.assertTrue(regular)
        for item in regular:
            with self.subTest(product=item.get("productLabel")):
                self.assertIsInstance(item["originalPrice"], (int, float))
                self.assertGreater(item["originalPrice"], item["offerPrice"])
                self.assertTrue(item.get("branchId"))
                self.assertTrue(item.get("capturedAt"))
                self.assertTrue(item.get("proofRef"))

    def test_versioned_feed_keeps_verified_netto_cover(self):
        payload = refresh.json.loads(FEED.read_text(encoding="utf-8"))
        netto = next(
            source for source in payload["sources"] if source["storeName"] == "Netto"
        )
        prospect = netto["prospects"][0]
        self.assertEqual(prospect["offerStartDate"], "2026-10-12")
        self.assertEqual(prospect["offerEndDate"], "2026-10-17")
        self.assertEqual(prospect["pageSamples"][0]["number"], 1)
        self.assertEqual(prospect["branchId"], "4371")

    def test_versioned_feed_keeps_verified_aldi_cover(self):
        payload = refresh.json.loads(FEED.read_text(encoding="utf-8"))
        aldi = next(
            source for source in payload["sources"] if source["storeName"] == "ALDI Süd"
        )
        prospect = aldi["prospects"][0]
        self.assertEqual(prospect["offerStartDate"], "2026-10-12")
        self.assertEqual(prospect["offerEndDate"], "2026-10-17")
        self.assertEqual(prospect["pageSamples"][0]["number"], 1)
        self.assertEqual(prospect["branchId"], "B384")

    def test_versioned_feed_keeps_verified_penny_cover(self):
        payload = refresh.json.loads(FEED.read_text(encoding="utf-8"))
        penny = next(
            source for source in payload["sources"] if source["storeName"] == "PENNY"
        )
        prospect = penny["prospects"][0]
        self.assertEqual(prospect["offerStartDate"], "2026-10-12")
        self.assertEqual(prospect["offerEndDate"], "2026-10-17")
        self.assertEqual(prospect["pageSamples"][0]["number"], 1)
        self.assertEqual(prospect["branchId"], "230061")

    def test_versioned_feed_keeps_verified_edeka_cover(self):
        payload = refresh.json.loads(FEED.read_text(encoding="utf-8"))
        edeka = next(
            source for source in payload["sources"] if source["storeName"] == "EDEKA"
        )
        prospect = edeka["prospects"][0]
        self.assertEqual(prospect["offerStartDate"], "2026-10-12")
        self.assertEqual(prospect["offerEndDate"], "2026-10-17")
        self.assertEqual(prospect["pageSamples"][0]["number"], 1)
        self.assertEqual(prospect["branchId"], "023738")

    def test_versioned_feed_keeps_verified_kaufland_cover(self):
        payload = refresh.json.loads(FEED.read_text(encoding="utf-8"))
        kaufland = next(
            source for source in payload["sources"] if source["storeName"] == "Kaufland"
        )
        prospect = kaufland["prospects"][0]
        self.assertEqual(prospect["offerStartDate"], "2026-10-12")
        self.assertEqual(prospect["offerEndDate"], "2026-10-17")
        self.assertEqual(prospect["pageSamples"][0]["number"], 1)
        self.assertEqual(prospect["branchId"], "DE5103")

    def test_netto_previous_fallback_drops_unactionable_labels(self):
        valid_until = (refresh.date.today() + refresh.timedelta(days=2)).isoformat()
        previous = {
            "offers": [
                {"storeName": "Netto", "productLabel": "-21%", "validUntil": valid_until},
                {"storeName": "Netto", "productLabel": "gekühlt", "validUntil": valid_until},
                {"storeName": "Netto", "productLabel": "Milka Schokolade 100 g", "validUntil": valid_until},
            ],
        }
        result = refresh.active_previous(previous, "Netto")
        self.assertEqual([item["productLabel"] for item in result], ["Milka Schokolade 100 g"])

    def test_netto_parses_official_reader_proxy_text(self):
        offers, _ = refresh.parse_netto(
            "gültig von Montag, 28.09.26 - Freitag, 02.10.26\n"
            "Minipflaumentomaten 500 g Schale\n3.98 / kg\nUVP 2.79 1.99*\n"
            "Milka Schokolade 87 g - 110 g\nstatt 1.99 0.88*\n",
            "https://www.netto-online.de/filialen/thuengersheim/am-strassacker-1/4371",
        )
        self.assertEqual(len(offers), 2)
        self.assertEqual(offers[0]["storeName"], "Netto")
        self.assertEqual(offers[0]["validUntil"], "2026-10-02")
        self.assertEqual(offers[1]["offerPrice"], 0.88)

    def test_official_record_wins_over_matching_bring_hotspot(self):
        shared = {
            "storeName": "Lidl", "productLabel": "Schmand 200 g",
            "validFrom": "2026-09-28", "validUntil": "2026-10-03",
            "offerPrice": 0.69,
        }
        bring = {**shared, "source": "leaflet", "proofRef": "bring-page"}
        official = {**shared, "source": "retailer", "proofRef": "lidl-product"}
        merged = refresh.dedupe([bring, official])
        self.assertEqual(len(merged), 1)
        self.assertEqual(merged[0]["proofRef"], "lidl-product")

    def test_official_record_wins_over_matching_kaufda_hit(self):
        shared = {
            "storeName": "Lidl",
            "productLabel": "Butter 250 g",
            "validFrom": "2026-10-12",
            "validUntil": "2026-10-17",
            "offerPrice": 1.29,
        }
        official = {
            **shared,
            "source": "retailerWebsite",
            "proofRef": "https://lidl.example/butter",
        }
        kaufda = {
            **shared,
            "source": "retailerWebsite",
            "sourceAdapter": "kaufda",
            "proofRef": "https://www.kaufda.de/butter",
            "imageUrl": "https://img.example/butter.jpg",
            "originalPrice": 1.79,
        }
        merged = refresh.dedupe([official, kaufda])
        self.assertEqual(len(merged), 1)
        self.assertEqual(merged[0]["proofRef"], "https://lidl.example/butter")
        self.assertEqual(merged[0]["imageUrl"], "https://img.example/butter.jpg")
        self.assertEqual(merged[0]["originalPrice"], 1.79)

    def test_aldi_api_resolves_image_rendition_placeholders(self):
        payload = """
        {
          "meta": {"pagination": {"totalCount": 1}},
          "data": [{
            "brandName": "KÄSE",
            "name": "Bergkäse",
            "sku": "123456",
            "urlSlugText": "bergkaese",
            "price": {"amountRelevant": 199},
            "assets": [{
              "url": "https://images.example/scaleWidth/{width}/id/{slug}"
            }]
          }]
        }
        """
        offers, _ = refresh.parse_aldi_api_page(
            payload,
            refresh.date(2026, 9, 28),
        )
        self.assertEqual(
            offers[0]["imageUrl"],
            "https://images.example/scaleWidth/600/id/image.jpg",
        )

    def test_explicit_regular_price_aliases_survive_source_adapters(self):
        aldi_payload = """
        {
          "meta": {"pagination": {"totalCount": 1}},
          "data": [{
            "brandName": "MILSANI",
            "name": "H-Milch 1 l",
            "price": {
              "amountRelevant": 99,
              "regularPrice": "1,29 €"
            }
          }]
        }
        """
        aldi_offers, _ = refresh.parse_aldi_api_page(
            aldi_payload,
            refresh.date(2026, 10, 12),
        )
        self.assertEqual(aldi_offers[0]["originalPrice"], 1.29)

        edeka_payload = """
        {
          "gueltig_von": "2026-10-12",
          "gueltig_bis": "2026-10-17",
          "docs": [{
            "angebotid": 77,
            "titel": "H-Milch 1 l",
            "preis": 0.99,
            "price": {"oldPrice": "1,29 €"}
          }]
        }
        """
        edeka_offers, _ = refresh.parse_edeka_api(
            edeka_payload,
            "https://www.edeka.de/maerkte/023738/",
        )
        self.assertEqual(edeka_offers[0]["originalPrice"], 1.29)

        alias_values = {
            "priceBefore": "1,29 €",
            "previousPrice": "1,29 €",
            "crossedOutPrice": "1,29 €",
            "strikethroughPrice": "1,29 €",
            "wasPriceNumeric": 1.29,
            "original_price": "1,29 €",
            "regular_price": "1,29 €",
            "normal_price": "1,29 €",
            "old_price": "1,29 €",
            "previous_price": "1,29 €",
            "crossed_out_price": "1,29 €",
            "strikethrough_price": "1,29 €",
        }
        for key, value in alias_values.items():
            with self.subTest(key=key):
                self.assertEqual(
                    refresh._explicit_regular_price({key: value}, 0.99),
                    1.29,
                )

    def test_explicit_regular_price_reads_bounded_nested_money_objects(self):
        self.assertEqual(
            refresh._explicit_regular_price(
                {
                    "priceReference": {
                        "previousPrice": {"amount": 1.29},
                    },
                },
                0.99,
            ),
            1.29,
        )
        self.assertEqual(
            refresh._explicit_regular_price(
                {
                    "pricing": {
                        "comparison": {
                            "regular": {"formattedValue": "1,29 €"},
                        },
                    },
                },
                0.99,
            ),
            1.29,
        )
        self.assertIsNone(
            refresh._explicit_regular_price(
                {
                    "pricing": {
                        "discount": {"amount": 1.29},
                        "uvp": {"amount": 2.99},
                    },
                },
                0.99,
            )
        )
        self.assertIsNone(
            refresh._explicit_regular_price(
                {
                    "metadata": {"previousPrice": {"amount": 1.29}},
                },
                0.99,
            )
        )

    def test_aldi_public_prospect_parser_keeps_current_cover_and_period(self):
        html = """
        <a href="https://prospekt.aldi-sued.de/kw41-26-op-mp/page/10">Vorwoche</a>
        <a href="https://prospekt.aldi-sued.de/kw42-26-op-mp/page/10">Teaser</a>
        <a href="https://prospekt.aldi-sued.de/kw42-26-op-mp">Prospekt ansehen</a>
        <a href="https://prospekt.aldi-sued.de/kw43-26-op">Nächste Woche</a>
        <img src="https://dm.emea.cms.aldi.cx/is/image/aldiprodeu/prospekte-opmp-kw42%3A2-1?wid=1400&amp;fmt=png-alpha">
        <img src="https://dm.emea.cms.aldi.cx/is/image/aldiprodeu/prospekte-op-kw43%3A2-1?wid=1400&amp;fmt=png-alpha">
        """
        prospects = refresh.parse_aldi_prospects(
            html,
            today=refresh.date(2026, 10, 12),
        )
        self.assertEqual(len(prospects), 1)
        self.assertEqual(
            prospects[0]["url"],
            "https://prospekt.aldi-sued.de/kw42-26-op-mp",
        )
        self.assertEqual(prospects[0]["offerStartDate"], "2026-10-12")
        self.assertEqual(prospects[0]["offerEndDate"], "2026-10-17")
        self.assertEqual(
            prospects[0]["pageSamples"][0]["image"],
            "https://dm.emea.cms.aldi.cx/is/image/aldiprodeu/prospekte-opmp-kw42%3A2-1?wid=1400&fmt=png-alpha",
        )
        self.assertEqual(prospects[0]["loadedPageCount"], 1)
        self.assertEqual(prospects[0]["pageStatus"], "cover_only")
        self.assertFalse(prospects[0]["pageCountKnown"])

    def test_publitas_catalog_flattens_all_pages_and_resolves_images(self):
        data = '{"numPages": 3, "cacheToken": "token"}'
        spreads = refresh.json.dumps([
            {
                "pages": [{
                    "number": 1,
                    "text": "Seite eins",
                    "images": {"at1600": "/pages/one.jpg", "at2400": "/pages/one-large.jpg"},
                }],
            },
            {
                "pages": [
                    {
                        "number": 2,
                        "text": "Seite zwei",
                        "images": {"at1600": "/pages/two.jpg", "at2400": "/pages/two-large.jpg"},
                    },
                    {
                        "number": 3,
                        "text": "Seite drei",
                        "images": {"at1600": "/pages/three.jpg"},
                    },
                ],
            },
        ])

        samples, coverage = refresh._parse_publitas_pages(
            spreads,
            "https://reader.example.test/prospect",
            expected_count=3,
        )

        self.assertEqual([page["number"] for page in samples], [1, 2, 3])
        self.assertEqual(
            samples[1]["image"],
            "https://reader.example.test/pages/two.jpg",
        )
        self.assertEqual(
            samples[0]["zoom"],
            "https://reader.example.test/pages/one-large.jpg",
        )
        self.assertEqual(coverage["pageCount"], 3)
        self.assertEqual(coverage["loadedPageCount"], 3)
        self.assertEqual(coverage["missingPageNumbers"], [])
        self.assertEqual(coverage["pageStatus"], "complete")

    def test_publitas_catalog_reports_missing_page_without_inventing_it(self):
        spreads = refresh.json.dumps([
            {"pages": [{"number": 1, "images": {"at1600": "/one.jpg"}}]},
            {"pages": [{"number": 3, "images": {"at1600": "/three.jpg"}}]},
        ])

        samples, coverage = refresh._parse_publitas_pages(
            spreads,
            "https://reader.example.test/prospect/",
            expected_count=3,
        )

        self.assertEqual([page["number"] for page in samples], [1, 3])
        self.assertEqual(coverage["missingPageNumbers"], [2])
        self.assertEqual(coverage["pageStatus"], "partial")

    def test_publitas_catalog_accepts_one_verified_page(self):
        spreads = refresh.json.dumps([
            {"number": 1, "images": {"at1600": "/only-page.jpg"}},
        ])

        samples, coverage = refresh._parse_publitas_pages(
            spreads,
            "https://reader.example.test/prospect/",
            expected_count=1,
        )

        self.assertEqual([page["number"] for page in samples], [1])
        self.assertEqual(coverage["pageCount"], 1)
        self.assertEqual(coverage["loadedPageCount"], 1)
        self.assertEqual(coverage["missingPageNumbers"], [])
        self.assertEqual(coverage["pageStatus"], "complete")

    def test_edeka_catalog_xml_expands_verified_page_mapping(self):
        html = """
        <p>Gültig vom 12.10.2026 bis zum 17.10.2026.</p>
        <a href="/maerkte/023738/prospekte/">Prospekt ansehen</a>
        <iframe src="https://blaetterkatalog.edeka.de/NORDBAYERN/8002976/index.html"></iframe>
        <img src="https://blaetterkatalog.edeka.de/NORDBAYERN/8002976/blaetterkatalog/normal/bk_1.jpg">
        """
        catalog = """
        <catalog>
          <structure>
            <detaillevel name="normal" path="../normal/" filename="bk_" extension="jpg" />
            <detaillevel name="large" path="../large/" filename="bk_" extension="jpg" />
          </structure>
          <mapping><range id_start="1" nr_start="1" pages="3" /></mapping>
        </catalog>
        """

        prospects = refresh.parse_edeka_prospects(
            html,
            "https://www.edeka.de/maerkte/023738/",
            today=refresh.date(2026, 10, 12),
            catalog_xml=catalog,
            catalog_url="https://blaetterkatalog.edeka.de/NORDBAYERN/8002976/blaetterkatalog/xml/catalog.xml",
        )

        self.assertEqual(len(prospects), 1)
        prospect = prospects[0]
        self.assertEqual(prospect["pageCount"], 3)
        self.assertEqual(prospect["loadedPageCount"], 3)
        self.assertEqual([page["number"] for page in prospect["pageSamples"]], [1, 2, 3])
        self.assertTrue(prospect["pageSamples"][2]["image"].endswith("/normal/bk_3.jpg"))
        self.assertTrue(prospect["pageSamples"][2]["zoom"].endswith("/large/bk_3.jpg"))

    def test_kaufland_leaflet_api_expands_all_verified_pages(self):
        payload = {
            "flyer": {
                "id": "flyer-1",
                "pdfUrl": "https://assets.example.test/flyer.pdf",
                "pages": [
                    {"number": 1, "image": "https://img.example.test/1.jpg", "zoom": "https://img.example.test/1-large.jpg"},
                    {"number": 2, "image": "https://img.example.test/2.jpg", "zoom": "https://img.example.test/2-large.jpg"},
                ],
            },
        }
        base = [{
            "title": "Kaufland Prospekt",
            "url": "https://leaflets.kaufland.com/de-DE/DE_de_test/ar/5103",
            "pageSamples": [{"number": 1, "image": "https://img.example.test/cover.jpg"}],
        }]

        enriched = refresh._enrich_kaufland_prospects(
            base,
            refresh.json.dumps(payload),
        )

        self.assertEqual(enriched[0]["pageCount"], 2)
        self.assertEqual(enriched[0]["loadedPageCount"], 2)
        self.assertEqual([page["number"] for page in enriched[0]["pageSamples"]], [1, 2])
        self.assertEqual(enriched[0]["flyerId"], "flyer-1")

    def test_lidl_campaign_dedup_keeps_complete_variant(self):
        duplicate_cover = {
            "title": "Aktionsprospekt 12.10.2026 – 17.10.2026",
            "offerStartDate": "2026-10-12",
            "offerEndDate": "2026-10-17",
            "pageCount": 73,
            "productCount": 163,
            "pageSamples": [1],
        }
        complete = {
            **duplicate_cover,
            "pageCount": 77,
            "productCount": 164,
            "pageSamples": list(range(1, 78)),
            "url": "https://www.lidl.de/l/prospekte/example/ar/7",
        }

        deduped = refresh._dedupe_lidl_prospects([duplicate_cover, complete])

        self.assertEqual(len(deduped), 1)
        self.assertEqual(deduped[0]["pageCount"], 77)
        self.assertEqual(deduped[0]["productCount"], 164)

    def test_lidl_leaflet_counts_dictionary_products(self):
        item = {
            "title": "Aktionsprospekt",
            "url": "https://www.lidl.de/l/prospekte/example/ar/12",
            "apiUrl": "https://api.example.test/flyer",
        }
        payload = {
            "flyer": {
                "products": {"one": {"title": "Produkt 1"}, "two": {"title": "Produkt 2"}},
                "pages": [{
                    "number": 1,
                    "image": "https://img.example.test/1.jpg",
                }],
            },
        }
        with mock.patch.object(refresh, "fetch", return_value=refresh.json.dumps(payload)):
            enriched = refresh._enrich_lidl_prospect(item)

        self.assertEqual(enriched["productCount"], 2)
        self.assertEqual(enriched["pageCount"], 1)

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
              "category": "Milchprodukte",
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
        self.assertEqual(offers[0]["category"], "Milchprodukte")
        self.assertEqual(offers[0]["originalPrice"], 0.89)
        self.assertEqual(offers[0]["validFrom"], "2026-09-21")
        self.assertEqual(offers[0]["validUntil"], "2026-09-26")
        self.assertEqual(
            offers[0]["imageUrl"],
            "https://offer-images.api.edeka/schmand.jpg",
        )
        self.assertTrue(offers[0]["proofRef"].endswith("#offer-12345"))

    def test_edeka_api_accepts_nested_image_fields(self):
        payload = """
        {
          "docs": [
            {
              "titel": "Bio Äpfel",
              "preis": "1,99 €",
              "image": {"url": "https://cdn.edeka.example/apples.jpg"}
            }
          ]
        }
        """
        offers, _ = refresh.parse_edeka_api(
            payload,
            "https://www.edeka.de/maerkte/023738/",
        )
        self.assertEqual(len(offers), 1)
        self.assertEqual(
            offers[0]["imageUrl"],
            "https://cdn.edeka.example/apples.jpg",
        )

    def test_edeka_public_prospect_parser_keeps_branch_cover_and_period(self):
        html = """
        <p>Gültig vom 12.10.2026 bis zum 17.10.2026.</p>
        <a href="/maerkte/023738/prospekte/#prospekt-abc">Prospekt ansehen</a>
        <img src="https://blaetterkatalog.edeka.de/NORDBAYERN/8002976/blaetterkatalog/normal/bk_1.jpg">
        """
        prospects = refresh.parse_edeka_prospects(
            html,
            "https://www.edeka.de/maerkte/023738/",
            today=refresh.date(2026, 10, 12),
        )
        self.assertEqual(len(prospects), 1)
        self.assertIn("/maerkte/023738/prospekte/", prospects[0]["url"])
        self.assertEqual(prospects[0]["offerStartDate"], "2026-10-12")
        self.assertEqual(prospects[0]["offerEndDate"], "2026-10-17")
        self.assertEqual(
            prospects[0]["pageSamples"][0]["image"],
            "https://blaetterkatalog.edeka.de/NORDBAYERN/8002976/blaetterkatalog/normal/bk_1.jpg",
        )

    def test_edeka_public_prospect_parser_keeps_all_explicit_pages_in_order(self):
        html = """
        <p>Gültig vom 12.10.2026 bis zum 17.10.2026.</p>
        <a href="/maerkte/023738/prospekte/#prospekt-abc">Prospekt ansehen</a>
        <img src="https://blaetterkatalog.edeka.de/NORDBAYERN/8002976/blaetterkatalog/normal/bk_3.jpg">
        <img src="https://blaetterkatalog.edeka.de/NORDBAYERN/8002976/blaetterkatalog/normal/bk_1.jpg">
        <img src="https://blaetterkatalog.edeka.de/NORDBAYERN/8002976/blaetterkatalog/normal/bk_2.jpg">
        <img src="https://blaetterkatalog.edeka.de/NORDBAYERN/8002976/blaetterkatalog/normal/bk_2.jpg">
        """
        prospects = refresh.parse_edeka_prospects(
            html,
            "https://www.edeka.de/maerkte/023738/",
            today=refresh.date(2026, 10, 12),
        )

        self.assertEqual(len(prospects), 1)
        prospect = prospects[0]
        self.assertEqual(prospect["pageCount"], 3)
        self.assertEqual(
            [page["number"] for page in prospect["pageSamples"]],
            [1, 2, 3],
        )
        self.assertEqual(
            prospect["thumbnailUrl"],
            "https://blaetterkatalog.edeka.de/NORDBAYERN/8002976/blaetterkatalog/normal/bk_1.jpg",
        )
        self.assertEqual(
            prospect["pageSamples"][2]["image"],
            "https://blaetterkatalog.edeka.de/NORDBAYERN/8002976/blaetterkatalog/normal/bk_3.jpg",
        )

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
              "category": "Getränke",
              "assets": [{"url": "https://img.example/{width}/orangensaft.jpg"}],
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
        self.assertEqual(offers[0]["category"], "Getränke")
        self.assertEqual(offers[0]["originalPrice"], 2.49)
        self.assertEqual(
            offers[0]["imageUrl"],
            "https://img.example/600/orangensaft.jpg",
        )
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

    def test_penny_public_prospect_parser_keeps_current_cover_and_period(self):
        html = """
        <section class="handout">
          <div class="handout__subline">12.10. bis 17.10.</div>
          <div class="handout__image-wrapper" id="handout-current-week">
            <picture>
              <source srcset="https://cdn.penny.de/dam/prospekt.png?imwidth=400 400w">
              <img src="https://cdn.penny.de/dam/prospekt.png?imwidth=1800" srcset="https://cdn.penny.de/dam/prospekt.png?imwidth=1800 1800w">
            </picture>
          </div>
        </section>
        """
        prospects = refresh.parse_penny_prospect(
            html,
            today=refresh.date(2026, 10, 12),
        )
        self.assertEqual(len(prospects), 1)
        self.assertEqual(prospects[0]["offerStartDate"], "2026-10-12")
        self.assertEqual(prospects[0]["offerEndDate"], "2026-10-17")
        self.assertEqual(
            prospects[0]["pageSamples"][0]["image"],
            "https://cdn.penny.de/dam/prospekt.png?imwidth=1800",
        )


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
              "image": {"url": "https://static-coupons.lidlplus.com/thunfisch.jpg"},
              "category": "Vorrat & Konserven",
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
        self.assertEqual(offers[0]["category"], "Vorrat & Konserven")
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
                "tileLg": {"url": "https://cdn.penny.de/schmand.png"}
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
            "Kühlregal",
        )
        self.assertEqual(len(offers), 1)
        self.assertEqual(offers[0]["productLabel"], "MILPRIMA Schmand je 200 g")
        self.assertEqual(offers[0]["offerPrice"], 0.69)
        self.assertEqual(offers[0]["category"], "Kühlregal")
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

    def test_netto_reads_current_store_tiles_with_images(self):
        html = """
        <div data-slider-headline="gültig von Montag, 28.09.26 - Freitag, 02.10.26">
          <li aria-label=" Zum Artikel: Rispentomaten, Niederlande, Kl. I, 1 kg, UVP 2.99, 2,29 Euro, 23 % günstiger">
            <img data-src="/media_nfs/images/tomaten.webp">
          </li>
          <li aria-label=" Zum Artikel: Kiwi gold, Neuseeland, Stück, Aktion, 0,59 Euro">
            <img data-src="/media_nfs/images/kiwi.webp">
          </li>
        </div>
        """
        offers, _ = refresh.parse_netto(
            html,
            "https://www.netto-online.de/filialen/thuengersheim/am-strassacker-1/4371",
        )
        self.assertEqual(len(offers), 2)
        self.assertEqual(offers[0]["productLabel"], "Rispentomaten, Niederlande, Kl. I, 1 kg")
        self.assertEqual(offers[0]["offerPrice"], 2.29)
        self.assertEqual(offers[0]["originalPrice"], 2.99)
        self.assertTrue(offers[0]["imageUrl"].endswith("/tomaten.webp"))
        self.assertEqual(offers[0]["validFrom"], "2026-09-28")
        self.assertEqual(offers[0]["validUntil"], "2026-10-02")
        self.assertEqual(offers[1]["productLabel"], "Kiwi gold, Neuseeland, Stück")
        self.assertEqual(offers[1]["offerPrice"], 0.59)

    def test_netto_reads_current_weekly_prospect_cover(self):
        html = """
        <p>Filial-Angebote gültig von Montag, 12.10.26 - Samstag, 17.10.26</p>
        <a href="https://wochenprospekt.netto-online.de/hz42_kisa/?storeid=4371">
          <img src="/media_nfs/images/2026-42/filial-cover.jpg" alt="Filial-Angebote">
        </a>
        """
        offers, prospects = refresh.parse_netto(
            html,
            "https://www.netto-online.de/filialen/thuengersheim/am-strassacker-1/4371",
        )
        self.assertEqual(offers, [])
        self.assertEqual(len(prospects), 1)
        self.assertEqual(prospects[0]["title"], "Netto Wochenprospekt 12.10.2026 – 17.10.2026")
        self.assertEqual(
            prospects[0]["url"],
            "https://wochenprospekt.netto-online.de/hz42_kisa/?storeid=4371",
        )
        self.assertEqual(
            prospects[0]["thumbnailUrl"],
            "https://www.netto-online.de/media_nfs/images/2026-42/filial-cover.jpg",
        )
        self.assertEqual(prospects[0]["pageSamples"][0]["number"], 1)
        self.assertEqual(prospects[0]["offerEndDate"], "2026-10-17")

    def test_netto_reads_weekly_prospect_cover_from_reader_markdown(self):
        markdown = """
        Filial-Angebote gültig von Montag, 12.10.26 - Samstag, 17.10.26
        [![Filial-Angebote](https://www.netto-online.de/media_nfs/images/2026-42/filial-cover.jpg)](https://wochenprospekt.netto-online.de/hz42_kisa/?storeid=4371)
        """
        offers, prospects = refresh.parse_netto(
            markdown,
            "https://www.netto-online.de/filialen/thuengersheim/am-strassacker-1/4371",
        )
        self.assertEqual(offers, [])
        self.assertEqual(len(prospects), 1)
        self.assertEqual(
            prospects[0]["thumbnailUrl"],
            "https://www.netto-online.de/media_nfs/images/2026-42/filial-cover.jpg",
        )

    def test_netto_drops_unactionable_placeholder_labels(self):
        html = """
        <div data-slider-headline="gültig von Montag, 28.09.26 - Freitag, 02.10.26">
          <li aria-label=" Zum Artikel: -21%, Aktion, 1,79 Euro"></li>
          <li aria-label=" Zum Artikel: gekühlt, versch. Sorten, Aktion, 2,49 Euro"></li>
          <li aria-label=" Zum Artikel: Marokko/Spanien, Kl. I, Aktion, 1,49 Euro"></li>
          <li aria-label=" Zum Artikel: Rispentomaten, 1 kg, Aktion, 2,29 Euro"></li>
        </div>
        """
        offers, _ = refresh.parse_netto(
            html,
            "https://www.netto-online.de/filialen/thuengersheim/am-strassacker-1/4371",
        )
        self.assertEqual(len(offers), 1)
        self.assertEqual(offers[0]["productLabel"], "Rispentomaten, 1 kg")

    def test_netto_reads_public_reader_markdown_tiles(self):
        markdown = """
_Minipflaumentomaten_ 500 g Schale
3.98 / kg
-28%UVP 2.79 1.99*
[](https://www.netto-online.de/INTERSHOP/web/WFS/Plus-NettoDE-Site/de_DE/-/EUR/ViewMMPWishlist-AddStoreArticle?SKU=46111&Name=Minipflaumentomaten&ValidTo=2026-10-08T22%3A40%3A00&Image=https%3A%2F%2Fwww.netto-online.de%2Fmedia_nfs%2Fimages%2Ftomaten.webp "Auf den Einkaufszettel")

_Kiwi gold_ Stück
Aktion
0.59*
[](https://www.netto-online.de/INTERSHOP/web/WFS/Plus-NettoDE-Site/de_DE/-/EUR/ViewMMPWishlist-AddStoreArticle?SKU=40141&Name=Kiwi+gold&ValidTo=2026-10-08T22%3A40%3A00&Image=https%3A%2F%2Fwww.netto-online.de%2Fmedia_nfs%2Fimages%2Fkiwi.webp "Auf den Einkaufszettel")

ab Montag, 28.09.26
"""
        offers, _ = refresh.parse_netto(
            markdown,
            "https://www.netto-online.de/filialen/thuengersheim/am-strassacker-1/4371",
        )
        self.assertEqual(len(offers), 2)
        self.assertEqual(offers[0]["productLabel"], "Minipflaumentomaten 500 g")
        self.assertEqual(offers[0]["offerPrice"], 1.99)
        self.assertEqual(offers[0]["originalPrice"], 2.79)
        self.assertEqual(offers[0]["validFrom"], "2026-09-28")
        self.assertEqual(offers[0]["validUntil"], "2026-10-08")
        self.assertTrue(offers[0]["imageUrl"].endswith("/tomaten.webp"))
        self.assertEqual(offers[1]["productLabel"], "Kiwi gold Stück")
        self.assertEqual(offers[1]["offerPrice"], 0.59)

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
                        "imageUrl": "https://cdn.rewe.example/pizza-salame.jpg",
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
        self.assertEqual(
            offers[0]["imageUrl"],
            "https://cdn.rewe.example/pizza-salame.jpg",
        )
        self.assertNotIn("originalPrice", offers[1])
        self.assertNotIn("imageUrl", offers[1])
        self.assertEqual(offers[0]["validFrom"], "2026-09-21")
        self.assertEqual(offers[0]["validUntil"], "2026-09-27")

    def test_kaufland_selector_reads_store_code(self):
        self.assertEqual(
            refresh._kaufland_selector(
                "https://filiale.kaufland.de/service/filiale.storeName%3DDE5103.html"
            ),
            "DE5103",
        )

    def test_kaufland_leaflet_date_range_handles_year_boundary(self):
        self.assertEqual(
            refresh._kaufland_leaflet_date_range(
                "Gültig vom 29.12. bis 04.01.",
                today=refresh.date(2027, 1, 2),
            ),
            (refresh.date(2026, 12, 29), refresh.date(2027, 1, 4)),
        )

    def test_kaufland_public_leaflet_parser_keeps_current_cover_and_period(self):
        branch_html = """
        <a href="https://leaflets.kaufland.com/de-DE/DE_de_KDZ2_5103_D41/ar/5103">
          Gültig vom 08.10. bis 14.10. Jetzt blättern
        </a>
        <a href="https://leaflets.kaufland.com/de-DE/DE_de_KDZ1_5103_D42/ar/5103">
          Gültig vom 12.10. bis 17.10. Jetzt blättern
        </a>
        """
        viewer_html = """
        <img src="https://imgproxy.leaflets.schwarz/example-cover.png" alt="Cover">
        <img src="https://imgproxy.leaflets.schwarz/example-page-2.png" alt="Page 2">
        """

        prospects = refresh.parse_kaufland_leaflet_prospect(
            branch_html,
            viewer_html,
            "https://filiale.kaufland.de/service/filiale.storeName%3DDE5103.html",
            today=refresh.date(2026, 10, 12),
        )

        self.assertEqual(len(prospects), 1)
        self.assertEqual(
            prospects[0]["url"],
            "https://leaflets.kaufland.com/de-DE/DE_de_KDZ1_5103_D42/ar/5103",
        )
        self.assertEqual(prospects[0]["offerStartDate"], "2026-10-12")
        self.assertEqual(prospects[0]["offerEndDate"], "2026-10-17")
        self.assertEqual(
            prospects[0]["pageSamples"][0]["image"],
            "https://imgproxy.leaflets.schwarz/example-cover.png",
        )

    def test_kaufland_public_leaflet_parser_prefers_food_campaign_over_od(self):
        branch_html = """
        <a href="https://leaflets.kaufland.com/de-DE/DE_de_KDZ1_5103_D42/ar/5103">
          Gültig vom 12.10. bis 17.10. Jetzt blättern
        </a>
        <a href="https://leaflets.kaufland.com/de-DE/DE_de_leaflet1_5103_D42-OD/ar/5103">
          Gültig vom 12.10. bis 17.10. Jetzt blättern
        </a>
        """
        viewer_html = '<img src="https://imgproxy.leaflets.schwarz/cover.png">'

        prospects = refresh.parse_kaufland_leaflet_prospect(
            branch_html,
            viewer_html,
            "https://filiale.kaufland.de/service/filiale.storeName%3DDE5103.html",
            today=refresh.date(2026, 10, 12),
        )

        self.assertEqual(
            prospects[0]["url"],
            "https://leaflets.kaufland.com/de-DE/DE_de_KDZ1_5103_D42/ar/5103",
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
                                    "name": "Milchprodukte",
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
                                            "listImage": {"image": {"url": "https://example.test/butter.jpg"}}
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
            today=refresh.date(2026, 9, 24),
        )
        self.assertEqual(len(offers), 1)
        self.assertEqual(
            offers[0]["productLabel"],
            "Kerrygold Butter je 250-g-Packung",
        )
        self.assertEqual(offers[0]["offerPrice"], 1.99)
        self.assertEqual(offers[0]["category"], "Milchprodukte")
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
        html = "<script>window.SSR[\'offers\'] = " + refresh.json.dumps(payload) + ";</script>"
        offers, _ = refresh.parse_kaufland_api(
            html,
            refresh.KAUFLAND_OVERVIEW_URL,
            {"111"},
            today=refresh.date(2026, 9, 24),
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


    def test_capture_timestamp_fills_missing_without_overwriting_existing(self):
        items = [
            {"productLabel": "Butter"},
            {
                "productLabel": "Milch",
                "capturedAt": "2026-10-14T04:00:00Z",
            },
            "ignore",
        ]

        stamped = refresh._attach_capture_timestamp(
            items,
            "2026-10-14T05:00:00Z",
        )

        self.assertEqual(
            stamped,
            [
                {
                    "productLabel": "Butter",
                    "capturedAt": "2026-10-14T05:00:00Z",
                },
                {
                    "productLabel": "Milch",
                    "capturedAt": "2026-10-14T04:00:00Z",
                },
            ],
        )
        self.assertEqual(items[0], {"productLabel": "Butter"})

    def test_record_context_fills_missing_fields_without_overwriting_provider_values(self):
        offers = [
            {"productLabel": "Milch", "storeName": "EDEKA"},
            {
                "productLabel": "Butter",
                "storeName": "EDEKA",
                "branchId": "provider-branch",
                "location": "Provider City",
            },
        ]
        prospects = [
            {"title": "EDEKA Wochenangebote"},
            {
                "title": "Provider page",
                "branchId": "page-branch",
                "location": "Page City",
            },
        ]

        enriched_offers = refresh._attach_source_branch_metadata(
            offers,
            "edeka_zellingen",
        )
        enriched_prospects = refresh._attach_source_branch_metadata(
            prospects,
            "edeka_zellingen",
        )

        self.assertEqual(enriched_offers[0]["branchId"], "023738")
        self.assertEqual(enriched_offers[0]["location"], "Zellingen")
        self.assertEqual(
            enriched_offers[0]["address"],
            "Würzburger Str. 100, 97225 Zellingen, Germany",
        )
        self.assertEqual(enriched_offers[1]["branchId"], "provider-branch")
        self.assertEqual(enriched_offers[1]["location"], "Provider City")
        self.assertEqual(enriched_prospects[0]["branchId"], "023738")
        self.assertEqual(enriched_prospects[0]["location"], "Zellingen")
        self.assertEqual(enriched_prospects[1]["branchId"], "page-branch")
        self.assertEqual(enriched_prospects[1]["location"], "Page City")
        self.assertEqual(offers[0], {"productLabel": "Milch", "storeName": "EDEKA"})

    def test_source_error_preserves_current_cover_metadata(self):
        previous = {
            "generatedAt": "2026-10-14T04:15:00Z",
            "sources": [
                {
                    "storeName": "Netto",
                    "branchId": "4371",
                    "location": "Thüngersheim",
                    "address": "Am Strassacker 1, 97291 Thüngersheim, Germany",
                    "prospects": [
                        {
                            "id": "netto-current",
                            "title": "Netto Prospekt",
                            "offerStartDate": "2026-10-12",
                            "offerEndDate": "2026-10-17",
                            "pageSamples": [
                                {
                                    "number": 1,
                                    "image": "https://example.test/netto-cover.jpg",
                                }
                            ],
                        }
                    ],
                }
            ],
            "offers": [],
        }

        with tempfile.TemporaryDirectory() as directory:
            output = pathlib.Path(directory) / "current.json"
            output.write_text(
                refresh.json.dumps(previous),
                encoding="utf-8",
            )
            source = (
                "netto_thuengersheim",
                "Netto",
                "https://example.test/netto",
                "netto",
            )
            with (
                mock.patch.object(refresh, "OUTPUT", output),
                mock.patch.object(refresh, "SOURCES", (source,)),
                mock.patch.object(
                    refresh,
                    "fetch_current_bring_prospects",
                    return_value={},
                ),
                mock.patch.object(
                    refresh,
                    "fetch",
                    side_effect=OSError("source unavailable"),
                ),
                mock.patch.object(
                    refresh,
                    "local_today",
                    return_value=refresh.date(2026, 10, 15),
                ),
            ):
                refresh.main(["netto_thuengersheim"])

            payload = refresh.json.loads(output.read_text(encoding="utf-8"))
            netto = next(
                item for item in payload["sources"] if item["storeName"] == "Netto"
            )
            self.assertEqual(netto["status"], "error")
            self.assertEqual(netto["prospects"][0]["id"], "netto-current")
            self.assertEqual(
                netto["prospects"][0]["pageSamples"][0]["image"],
                "https://example.test/netto-cover.jpg",
            )


if __name__ == "__main__":
    unittest.main()

