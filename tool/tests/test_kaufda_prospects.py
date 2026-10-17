import pathlib
import tempfile
import unittest
from datetime import date, datetime, timedelta, timezone
from unittest import mock

from tool import kaufda_prospects as kaufda


ROOT = pathlib.Path(__file__).resolve().parents[2]
FIXTURE = ROOT / "tool" / "tests" / "fixtures" / "kaufda_search.html"


class KaufdaProspectTest(unittest.TestCase):
    def setUp(self):
        self.html = FIXTURE.read_text(encoding="utf-8")
        self.today = date(2026, 10, 12)

    def test_build_search_url_uses_city_and_query_path_segments(self):
        self.assertEqual(
            kaufda.build_search_url("Würzburg", "Tomaten & Nudeln"),
            "https://www.kaufda.de/W%C3%BCrzburg/Angebote/Tomaten%20%26%20Nudeln",
        )

    def test_supported_rewe_publisher_is_canonicalized_for_optional_source(self):
        self.assertEqual(kaufda.canonical_publisher("REWE"), "REWE")

    def test_explicit_non_food_taxonomy_overrides_food_word_in_title(self):
        self.assertFalse(
            kaufda._is_food(
                {
                    "categoryPaths": [
                        [{"name": "Haushalt"}, {"name": "Küchengeräte"}]
                    ]
                },
                "Kaffeemaschine",
            )
        )
        self.assertTrue(
            kaufda._is_food(
                {
                    "categoryPaths": [
                        [
                            {"name": "Lebensmittel und Getränke"},
                            {"name": "Kaffee"},
                        ]
                    ]
                },
                "Kaffee 500 g",
            )
        )
        self.assertFalse(
            kaufda._is_food(
                {
                    "categoryPath": [
                        {"name": "Haushalt"},
                        {"name": "Küchengeräte"},
                    ]
                },
                "Kaffee",
            )
        )
        self.assertTrue(
            kaufda._is_food(
                {"category": "02_Obst__Gemuese__Pflanzen"},
                "Orangen",
            )
        )
        self.assertFalse(
            kaufda._is_food({"category": "Pflanzen"}, "Orchidee")
        )

    def test_known_non_food_campaign_labels_stay_out_of_kaufda_results(self):
        self.assertFalse(
            kaufda._is_food({}, "PURINA Gourmet Gold 24 x 85 g")
        )
        self.assertFalse(
            kaufda._is_food({}, "DRESDNER ESSENZ Badesalz 60 g")
        )
        self.assertFalse(
            kaufda._is_food({}, "CAREFREE Slipeinlagen 40 Stück")
        )
        self.assertFalse(
            kaufda._is_food({}, "Bepflanztes Holzgefäß")
        )

    def test_food_compound_words_do_not_leak_non_food_items(self):
        for label in (
            "Kaffeemaschine 1 Stück",
            "Kaffeevollautomat",
            "Küchenmaschine",
            "Milchaufschäumer",
            "Tomatenpflanze",
            "Salatschleuder",
            "Fleischwolf",
            "Pizzaschneider",
        ):
            with self.subTest(label=label):
                self.assertFalse(kaufda._is_food({}, label))

    def test_parse_next_data_supports_multiline_json(self):
        payload = kaufda.extract_next_data(self.html)
        items = kaufda._items_from_payload(payload)
        self.assertEqual(len(items), 6)

    def test_items_from_payload_accepts_publisher_and_nested_validity_aliases(self):
        payload = {
            "results": {
                "items": [
                    {
                        "publisher": {"name": "Lidl"},
                        "validityPeriod": {
                            "startDate": "2026-10-12",
                            "endDate": "2026-10-17",
                        },
                    }
                ]
            }
        }

        self.assertEqual(len(kaufda._items_from_payload(payload)), 1)

    def test_parser_accepts_publisher_alias_and_nested_price_object(self):
        payload = kaufda.extract_next_data(self.html)
        item = payload["props"]["pageProps"]["pageInformation"]["offers"]["main"]["items"][0]
        item.pop("publisherName", None)
        item["publisher"] = {"name": "Lidl"}
        item.pop("id", None)
        item["offerId"] = "alias-offer-id"
        item["prices"]["mainPrice"] = {"amount": "1,29", "currency": "EUR"}
        item.pop("mainPrice", None)
        html = (
            '<script id="__NEXT_DATA__" type="application/json">'
            + kaufda.json.dumps(payload)
            + "</script>"
        )

        offers, _ = kaufda.parse_kaufda_html(
            html,
            city="Wuerzburg",
            query="Butter",
            today=self.today,
        )

        self.assertEqual(offers[0]["storeName"], "Lidl")
        self.assertEqual(offers[0]["offerPrice"], 1.29)

    def test_next_data_without_optional_type_attribute_is_supported(self):
        payload = kaufda.extract_next_data(self.html)
        html = (
            '<script id="__NEXT_DATA__">'
            + kaufda.json.dumps(payload)
            + "</script>"
        )
        self.assertEqual(len(kaufda._items_from_payload(kaufda.extract_next_data(html))), 6)

    def test_parser_tolerates_renamed_nested_result_container(self):
        payload = kaufda.extract_next_data(self.html)
        items = payload["props"]["pageProps"]["pageInformation"]["offers"]["main"].pop("items")
        payload["props"]["pageProps"]["searchResults"] = {"contents": items}
        html = (
            '<script id="__NEXT_DATA__" type="application/json">'
            + kaufda.json.dumps(payload)
            + "</script>"
        )
        offers, _ = kaufda.parse_kaufda_html(
            html,
            city="Wuerzburg",
            query="Butter",
            today=self.today,
        )
        self.assertEqual([offer["storeName"] for offer in offers], ["Lidl", "Netto"])

    def test_package_hint_keeps_multipack_and_count_pack_shape(self):
        self.assertEqual(kaufda._package_hint("Riegel", "3 x 50 g"), "3 x 50 g")
        self.assertEqual(
            kaufda._package_hint("Obst", "3er-Schale"),
            "3er-Schale",
        )

    def test_parser_reads_nested_validity_and_quantity_objects(self):
        payload = kaufda.extract_next_data(self.html)
        item = payload["props"]["pageProps"]["pageInformation"]["offers"]["main"]["items"][0]
        item.pop("validFrom", None)
        item.pop("validUntil", None)
        item["validityPeriod"] = {
            "startDate": "2026-10-12T00:00:00+02:00",
            "endDate": "2026-10-17",
        }
        for key in ("quantity", "packageSize", "packaging", "quantityLabel"):
            item.pop(key, None)
        item["quantity"] = {"amount": 250, "unit": "g"}
        html = (
            '<script id="__NEXT_DATA__" type="application/json">'
            + kaufda.json.dumps(payload)
            + "</script>"
        )

        offers, _ = kaufda.parse_kaufda_html(
            html,
            city="Wuerzburg",
            query="Butter",
            today=self.today,
        )

        self.assertEqual(offers[0]["validFrom"], "2026-10-12")
        self.assertEqual(offers[0]["validUntil"], "2026-10-17")
        self.assertEqual(offers[0]["packageSize"], "250 g")

    def test_parser_rejects_nested_validity_without_explicit_end(self):
        payload = kaufda.extract_next_data(self.html)
        item = payload["props"]["pageProps"]["pageInformation"]["offers"]["main"]["items"][0]
        item.pop("validFrom", None)
        item.pop("validUntil", None)
        item["validity"] = {"startDate": "2026-10-12"}
        html = (
            '<script id="__NEXT_DATA__" type="application/json">'
            + kaufda.json.dumps(payload)
            + "</script>"
        )

        offers, _ = kaufda.parse_kaufda_html(
            html,
            city="Wuerzburg",
            query="Butter",
            today=self.today,
        )

        self.assertNotIn("Lidl", [offer["storeName"] for offer in offers])

    def test_parser_accepts_singular_category_path_and_image_list_aliases(self):
        payload = kaufda.extract_next_data(self.html)
        item = payload["props"]["pageProps"]["pageInformation"]["offers"]["main"]["items"][0]
        for key in ("category", "categoryName", "productCategory", "description"):
            item.pop(key, None)
        for key in ("quantity", "packageSize", "packaging", "quantityLabel"):
            item.pop(key, None)
        item["categoryPath"] = [
            {"name": "Lebensmittel und Getränke"},
            {"name": "Milchprodukte"},
        ]
        item["quantityText"] = "250 g"
        item.pop("offerImages", None)
        item["images"] = [{"src": "https://img.example.test/alias-butter.jpg"}]
        html = (
            '<script id="__NEXT_DATA__" type="application/json">'
            + kaufda.json.dumps(payload)
            + "</script>"
        )

        offers, _ = kaufda.parse_kaufda_html(
            html,
            city="Wuerzburg",
            query="Butter",
            today=self.today,
        )

        offer = offers[0]
        self.assertEqual(
            offer["imageUrl"],
            "https://img.example.test/alias-butter.jpg",
        )
        self.assertEqual(offer["category"], "Milchprodukte")
        self.assertEqual(offer["packageSize"], "250 g")

    def test_parser_keeps_current_food_offers_and_provenance(self):
        offers, metadata = kaufda.parse_kaufda_html(
            self.html,
            city="Wuerzburg",
            query="Butter",
            today=self.today,
        )
        self.assertEqual(
            [offer["storeName"] for offer in offers],
            ["Lidl", "Netto"],
        )
        lidl = offers[0]
        self.assertEqual(lidl["offerPrice"], 1.29)
        self.assertEqual(lidl["validUntil"], "2026-10-17")
        self.assertEqual(lidl["packageSize"], "250 g")
        self.assertEqual(lidl["priceByBaseUnit"], "5,16 €/kg")
        self.assertEqual(lidl["brochureId"], "brochure-lidl-2026-10")
        self.assertEqual(lidl["brochurePage"], 3)
        self.assertTrue(lidl["regionalOnly"])
        self.assertTrue(lidl["proofRef"].startswith("https://www.kaufda.de/"))
        self.assertEqual(metadata["skipped"]["non_food"], 1)
        self.assertEqual(metadata["skipped"]["expired_or_future"], 2)
        self.assertEqual(metadata["skipped"]["unknown_publisher"], 1)
        self.assertEqual(metadata["prospects"][0]["pageSamples"], [3])
        self.assertEqual(metadata["prospects"][0]["storeName"], "Lidl")

    def test_parser_reads_live_page_object_shape(self):
        live_shape = self.html.replace(
            '"page": 3',
            '"page": {"number": 3}',
        )
        offers, metadata = kaufda.parse_kaufda_html(
            live_shape,
            city="Wuerzburg",
            query="Butter",
            today=self.today,
        )
        self.assertEqual(offers[0]["brochurePage"], 3)
        self.assertEqual(offers[0]["publisherId"], "lidl")
        self.assertEqual(metadata["prospects"][0]["pageSamples"], [3])

    def test_parser_keeps_explicit_brochure_cover_and_page_images(self):
        payload = kaufda.extract_next_data(self.html)
        item = payload["props"]["pageProps"]["pageInformation"]["offers"]["main"]["items"][0]
        item["parentContent"]["page"] = {
            "number": 3,
            "imageUrl": "https://img.example.test/lidl-page-3.jpg",
        }
        item["parentContent"]["coverUrl"] = (
            "https://img.example.test/lidl-cover.jpg"
        )
        html = (
            '<script id="__NEXT_DATA__" type="application/json">'
            + kaufda.json.dumps(payload)
            + "</script>"
        )

        _, metadata = kaufda.parse_kaufda_html(
            html,
            city="Wuerzburg",
            query="Butter",
            today=self.today,
        )

        prospect = metadata["prospects"][0]
        self.assertEqual(
            prospect["thumbnailUrl"],
            "https://img.example.test/lidl-cover.jpg",
        )
        self.assertEqual(
            prospect["pageSamples"][0],
            {
                "number": 3,
                "image": "https://img.example.test/lidl-page-3.jpg",
            },
        )

    def test_parser_keeps_stated_regular_price_but_not_uvp(self):
        regular_price_shape = self.html.replace(
            '"mainPrice": 1.29,',
            '"mainPrice": 1.29, "secondaryPrice": 1.79, '
            '"secondaryPriceIsUVP": false,',
        )
        offers, _ = kaufda.parse_kaufda_html(
            regular_price_shape,
            city="Wuerzburg",
            query="Butter",
            today=self.today,
        )
        self.assertEqual(offers[0]["originalPrice"], 1.79)

        uvp_shape = regular_price_shape.replace(
            '"secondaryPriceIsUVP": false',
            '"secondaryPriceIsUVP": true',
        )
        uvp_offers, _ = kaufda.parse_kaufda_html(
            uvp_shape,
            city="Wuerzburg",
            query="Butter",
            today=self.today,
        )
        self.assertNotIn("originalPrice", uvp_offers[0])

    def test_parser_rejects_named_uvp_label_without_boolean_flag(self):
        payload = kaufda.extract_next_data(self.html)
        item = payload["props"]["pageProps"]["pageInformation"]["offers"]["main"]["items"][0]
        item["prices"]["secondaryPrice"] = "1,79 €"
        item["prices"]["secondaryPriceLabel"] = "UVP"
        item["prices"].pop("secondaryPriceIsUVP", None)
        html = (
            '<script id="__NEXT_DATA__" type="application/json">'
            + kaufda.json.dumps(payload)
            + "</script>"
        )

        offers, _ = kaufda.parse_kaufda_html(
            html,
            city="Wuerzburg",
            query="Butter",
            today=self.today,
        )

        self.assertNotIn("originalPrice", offers[0])

    def test_parser_normalizes_named_nested_evidence_aliases(self):
        payload = kaufda.extract_next_data(self.html)
        item = payload["props"]["pageProps"]["pageInformation"]["offers"]["main"]["items"][0]
        item.pop("offerImages", None)
        item["productImage"] = {"src": "https://img.example.test/alias-butter.jpg"}
        item["productCategory"] = {"title": "Milchprodukte"}
        item["gtin"] = "04012345678905"
        item["packaging"] = "250 g"
        item["prices"].pop("priceByBaseUnit", None)
        item["prices"]["baseUnitPrice"] = "5,16 €/kg"
        item["prices"]["regularPrice"] = "1,79 €"
        html = (
            '<script id="__NEXT_DATA__" type="application/json">'
            + kaufda.json.dumps(payload)
            + "</script>"
        )

        offers, _ = kaufda.parse_kaufda_html(
            html,
            city="Wuerzburg",
            query="Butter",
            today=self.today,
        )

        offer = offers[0]
        self.assertEqual(offer["imageUrl"], "https://img.example.test/alias-butter.jpg")
        self.assertEqual(offer["category"], "Milchprodukte")
        self.assertEqual(offer["ean"], "04012345678905")
        self.assertEqual(offer["packageSize"], "250 g")
        self.assertEqual(offer["priceByBaseUnit"], "5,16 €/kg")
        self.assertEqual(offer["originalPrice"], 1.79)

    def test_parser_rejects_non_http_image_aliases(self):
        payload = kaufda.extract_next_data(self.html)
        item = payload["props"]["pageProps"]["pageInformation"]["offers"]["main"]["items"][0]
        item.pop("offerImages", None)
        item["productImage"] = {"src": "javascript:alert(1)"}
        html = (
            '<script id="__NEXT_DATA__" type="application/json">'
            + kaufda.json.dumps(payload)
            + "</script>"
        )

        offers, _ = kaufda.parse_kaufda_html(
            html,
            city="Wuerzburg",
            query="Butter",
            today=self.today,
        )

        self.assertNotIn("imageUrl", offers[0])

    def test_exact_branch_assertion_marks_records_routeable(self):
        offers, _ = kaufda.parse_kaufda_html(
            self.html,
            city="Wuerzburg",
            query="Butter",
            today=self.today,
            branch={
                "branchId": "lidl_zellingen",
                "location": "Zellingen",
                "address": "Am Güßgraben 2, 97225 Zellingen",
            },
        )
        self.assertEqual(offers[0]["branchId"], "lidl_zellingen")
        self.assertEqual(offers[0]["location"], "Zellingen")
        self.assertEqual(offers[0]["address"], "Am Güßgraben 2, 97225 Zellingen")
        self.assertFalse(offers[0]["regionalOnly"])

    def test_disabled_config_makes_no_fetch_request(self):
        called = []

        def fail(_url):
            called.append(True)
            raise AssertionError("disabled kaufDA source must not fetch")

        result = kaufda.fetch_current_kaufda_prospects(
            kaufda.KaufdaConfig(
                enabled=False,
                queries=("Butter",),
                request_delay_seconds=0,
            ),
            fetcher=fail,
            today=self.today,
        )
        self.assertEqual(result, {})
        self.assertEqual(called, [])

    def test_env_config_requires_explicit_queries_and_branch_mapping(self):
        config = kaufda.config_from_env(
            {
                "SPARZAM_KAUFDA_ENABLED": "1",
                "SPARZAM_KAUFDA_CITY": "Wuerzburg",
                "SPARZAM_KAUFDA_QUERIES": "Butter, Milch, Butter",
                "SPARZAM_KAUFDA_BRANCHES": (
                    '{"Lidl":{"branchId":"lidl_zellingen",'
                    '"location":"Zellingen"}}'
                ),
            }
        )
        self.assertEqual(config.bounded_queries, ("Butter", "Milch"))
        self.assertEqual(config.branch_for("Lidl")["branchId"], "lidl_zellingen")

    def test_direct_branch_mapping_uses_canonical_publisher_names(self):
        config = kaufda.KaufdaConfig(
            branch_by_store={
                "lidl": {"branchId": "lidl_zellingen"},
                "Netto Marken-Discount": {"branchId": "netto_thuengersheim"},
            }
        )
        self.assertEqual(config.branch_for("Lidl")["branchId"], "lidl_zellingen")
        self.assertEqual(
            config.branch_for("Netto")["branchId"],
            "netto_thuengersheim",
        )

    def test_zero_query_limit_disables_all_queries(self):
        config = kaufda.KaufdaConfig(
            enabled=True,
            queries=("Butter", "Milch"),
            max_queries=0,
        )
        self.assertEqual(config.bounded_queries, ())
        self.assertEqual(
            kaufda.fetch_current_kaufda_prospects(
                config,
                fetcher=lambda _url: (_ for _ in ()).throw(
                    AssertionError("zero query limit must not fetch")
                ),
                today=self.today,
            ),
            {},
        )

    def test_env_zero_query_limit_disables_all_queries(self):
        config = kaufda.config_from_env(
            {
                "SPARZAM_KAUFDA_ENABLED": "1",
                "SPARZAM_KAUFDA_QUERIES": "Butter,Milch",
                "SPARZAM_KAUFDA_MAX_QUERIES": "0",
            }
        )
        self.assertEqual(config.max_queries, 0)
        self.assertEqual(config.bounded_queries, ())
        self.assertEqual(
            kaufda.fetch_current_kaufda_prospects(
                config,
                fetcher=lambda _url: (_ for _ in ()).throw(
                    AssertionError("env zero query limit must not fetch")
                ),
                today=self.today,
            ),
            {},
        )

    def test_explicit_empty_env_does_not_read_process_flags(self):
        config = kaufda.config_from_env({})
        self.assertFalse(config.enabled)
        self.assertEqual(config.queries, ())

    def test_regional_results_remain_visible_but_are_not_routeable(self):
        result = kaufda.fetch_current_kaufda_prospects(
            kaufda.KaufdaConfig(
                enabled=True,
                city="Wuerzburg",
                queries=("Butter",),
                request_delay_seconds=0,
            ),
            fetcher=lambda _url: self.html,
            today=self.today,
            now=datetime(2026, 10, 12, 8, tzinfo=timezone.utc),
        )
        self.assertIn("Lidl", result)
        self.assertEqual(len(result["Lidl"]["offers"]), 1)
        self.assertTrue(result["Lidl"]["offers"][0]["regionalOnly"])
        self.assertNotIn("branchId", result["Lidl"]["offers"][0])
        self.assertEqual(result["Lidl"]["status"], "regional_only")
        self.assertGreater(result["Lidl"]["regionalOnlyCount"], 0)

    def test_exact_branch_configuration_returns_current_offers(self):
        result = kaufda.fetch_current_kaufda_prospects(
            kaufda.KaufdaConfig(
                enabled=True,
                city="Wuerzburg",
                queries=("Butter",),
                request_delay_seconds=0,
                branch_by_store={
                    "Lidl": {
                        "branchId": "lidl_zellingen",
                        "location": "Zellingen",
                        "address": "Am Güßgraben 2, 97225 Zellingen",
                    }
                },
            ),
            fetcher=lambda _url: self.html,
            today=self.today,
            now=datetime(2026, 10, 12, 8, tzinfo=timezone.utc),
        )
        self.assertEqual(len(result["Lidl"]["offers"]), 1)
        self.assertEqual(
            result["Lidl"]["offers"][0]["branchId"],
            "lidl_zellingen",
        )
        self.assertEqual(
            result["Lidl"]["offers"][0]["capturedAt"],
            "2026-10-12T08:00:00+00:00",
        )
        self.assertEqual(result["Lidl"]["regionalOnlyCount"], 0)
        self.assertEqual(len(result["Lidl"]["prospects"]), 1)
        self.assertEqual(result["Lidl"]["prospects"][0]["status"], "current")
        self.assertEqual(result["Lidl"]["prospects"][0]["branchId"], "lidl_zellingen")

    def test_grouped_capture_uses_newest_live_query_after_cache(self):
        with tempfile.TemporaryDirectory() as directory:
            cache_path = pathlib.Path(directory) / "kaufda.json"
            cached_url = kaufda.build_search_url("Wuerzburg", "Butter")
            cache_path.write_text(
                kaufda.json.dumps(
                    {
                        kaufda._cache_key(cached_url): {
                            "url": cached_url,
                            "capturedAt": "2026-10-12T07:00:00+00:00",
                            "body": self.html,
                        }
                    }
                ),
                encoding="utf-8",
            )
            config = kaufda.KaufdaConfig(
                enabled=True,
                city="Wuerzburg",
                queries=("Butter", "Milch"),
                request_delay_seconds=0,
                cache_path=cache_path,
            )

            def fetch(url):
                if url.endswith("/Butter"):
                    raise OSError("first query offline")
                return self.html

            result = kaufda.fetch_current_kaufda_prospects(
                config,
                fetcher=fetch,
                today=self.today,
                now=datetime(2026, 10, 12, 8, tzinfo=timezone.utc),
            )

            self.assertEqual(
                result["Lidl"]["capturedAt"],
                "2026-10-12T08:00:00+00:00",
            )
            self.assertTrue(result["Lidl"]["cacheUsed"])

    def test_multi_publisher_metadata_stays_with_its_publisher(self):
        result = kaufda.fetch_current_kaufda_prospects(
            kaufda.KaufdaConfig(
                enabled=True,
                city="Wuerzburg",
                queries=("Butter",),
                request_delay_seconds=0,
            ),
            fetcher=lambda _url: self.html,
            today=self.today,
            now=datetime(2026, 10, 12, 8, tzinfo=timezone.utc),
        )
        self.assertEqual(
            {item["storeName"] for item in result["Lidl"]["prospects"]},
            {"Lidl"},
        )
        self.assertEqual(
            {item["storeName"] for item in result["Netto"]["prospects"]},
            {"Netto"},
        )

    def test_cache_fallback_is_bounded_and_does_not_require_network(self):
        with tempfile.TemporaryDirectory() as directory:
            cache_path = pathlib.Path(directory) / "kaufda.json"
            config = kaufda.KaufdaConfig(
                enabled=True,
                city="Wuerzburg",
                queries=("Butter",),
                request_delay_seconds=0,
                cache_path=cache_path,
                branch_by_store={
                    "Lidl": {"branchId": "lidl_zellingen", "location": "Zellingen"}
                },
            )
            now = datetime(2026, 10, 12, 8, tzinfo=timezone.utc)
            first = kaufda.fetch_current_kaufda_prospects(
                config,
                fetcher=lambda _url: self.html,
                today=self.today,
                now=now,
            )
            self.assertEqual(len(first["Lidl"]["offers"]), 1)

            second = kaufda.fetch_current_kaufda_prospects(
                config,
                fetcher=lambda _url: (_ for _ in ()).throw(OSError("offline")),
                today=self.today,
                now=datetime(2026, 10, 12, 9, tzinfo=timezone.utc),
            )
            self.assertTrue(second["Lidl"]["cacheUsed"])
            self.assertEqual(len(second["Lidl"]["offers"]), 1)
            self.assertEqual(
                second["Lidl"]["offers"][0]["capturedAt"],
                "2026-10-12T08:00:00+00:00",
            )

    def test_parser_failure_uses_previous_cache_without_overwriting_it(self):
        with tempfile.TemporaryDirectory() as directory:
            cache_path = pathlib.Path(directory) / "kaufda.json"
            config = kaufda.KaufdaConfig(
                enabled=True,
                city="Wuerzburg",
                queries=("Butter",),
                request_delay_seconds=0,
                cache_path=cache_path,
                branch_by_store={
                    "Lidl": {"branchId": "lidl_zellingen", "location": "Zellingen"}
                },
            )
            first = kaufda.fetch_current_kaufda_prospects(
                config,
                fetcher=lambda _url: self.html,
                today=self.today,
                now=datetime(2026, 10, 12, 8, tzinfo=timezone.utc),
            )
            self.assertEqual(len(first["Lidl"]["offers"]), 1)

            second = kaufda.fetch_current_kaufda_prospects(
                config,
                fetcher=lambda _url: '<script id="__NEXT_DATA__">{</script>',
                today=self.today,
                now=datetime(2026, 10, 12, 9, tzinfo=timezone.utc),
            )

            self.assertTrue(second["Lidl"]["cacheUsed"])
            self.assertEqual(len(second["Lidl"]["offers"]), 1)
            self.assertEqual(
                second["Lidl"]["offers"][0]["capturedAt"],
                "2026-10-12T08:00:00+00:00",
            )
            self.assertTrue(second["Lidl"]["errors"])
            cached_body, _ = kaufda._load_cached_body(
                cache_path,
                kaufda.build_search_url("Wuerzburg", "Butter"),
                now=datetime(2026, 10, 12, 9, tzinfo=timezone.utc),
                max_age_hours=12,
            )
            self.assertEqual(cached_body, self.html)

    def test_cache_document_keeps_newest_entries_with_entry_limit(self):
        with tempfile.TemporaryDirectory() as directory:
            cache_path = pathlib.Path(directory) / "kaufda.json"
            for index in range(kaufda.MAX_CACHE_ENTRIES + 2):
                url = kaufda.build_search_url("Wuerzburg", f"Query {index}")
                kaufda._save_cached_body(
                    cache_path,
                    url,
                    self.html,
                    datetime(2026, 10, 12, 8, tzinfo=timezone.utc) + timedelta(hours=index),
                )

            payload = kaufda.json.loads(cache_path.read_text(encoding="utf-8"))
            self.assertLessEqual(len(payload), kaufda.MAX_CACHE_ENTRIES)
            oldest = kaufda.build_search_url("Wuerzburg", "Query 0")
            newest = kaufda.build_search_url(
                "Wuerzburg", f"Query {kaufda.MAX_CACHE_ENTRIES + 1}"
            )
            self.assertIsNone(
                kaufda._load_cached_body(
                    cache_path,
                    oldest,
                    now=datetime(2026, 10, 14, 8, tzinfo=timezone.utc),
                    max_age_hours=48,
                )
            )
            self.assertIsNotNone(
                kaufda._load_cached_body(
                    cache_path,
                    newest,
                    now=datetime(2026, 10, 14, 8, tzinfo=timezone.utc),
                    max_age_hours=48,
                )
            )

    def test_cache_document_keeps_newest_body_with_byte_limit(self):
        with tempfile.TemporaryDirectory() as directory:
            cache_path = pathlib.Path(directory) / "kaufda.json"
            with mock.patch.object(kaufda, "MAX_CACHE_BYTES", 512):
                first_url = kaufda.build_search_url("Wuerzburg", "first")
                second_url = kaufda.build_search_url("Wuerzburg", "second")
                body = "x" * 300
                kaufda._save_cached_body(
                    cache_path,
                    first_url,
                    body,
                    datetime(2026, 10, 12, 8, tzinfo=timezone.utc),
                )
                kaufda._save_cached_body(
                    cache_path,
                    second_url,
                    body,
                    datetime(2026, 10, 12, 9, tzinfo=timezone.utc),
                )

            self.assertLessEqual(
                cache_path.stat().st_size,
                kaufda.MAX_CACHE_BYTES,
            )

            self.assertIsNone(
                kaufda._load_cached_body(
                    cache_path,
                    first_url,
                    now=datetime(2026, 10, 12, 10, tzinfo=timezone.utc),
                    max_age_hours=12,
                )
            )
            cached = kaufda._load_cached_body(
                cache_path,
                second_url,
                now=datetime(2026, 10, 12, 10, tzinfo=timezone.utc),
                max_age_hours=12,
            )
            self.assertIsNotNone(cached)
            self.assertEqual(cached[0], body)

    def test_cache_write_failure_keeps_previous_document_readable(self):
        with tempfile.TemporaryDirectory() as directory:
            cache_path = pathlib.Path(directory) / "kaufda.json"
            url = kaufda.build_search_url("Wuerzburg", "Butter")
            previous = {
                kaufda._cache_key(url): {
                    "url": url,
                    "capturedAt": "2026-10-12T08:00:00+00:00",
                    "body": self.html,
                }
            }
            cache_path.write_text(kaufda.json.dumps(previous), encoding="utf-8")

            with mock.patch.object(
                kaufda.os,
                "replace",
                side_effect=OSError("simulated replace failure"),
            ):
                kaufda._save_cached_body(
                    cache_path,
                    url,
                    self.html.replace("Butter", "Butter neu"),
                    datetime(2026, 10, 12, 9, tzinfo=timezone.utc),
                )

            self.assertEqual(kaufda._load_cached_body(
                cache_path,
                url,
                now=datetime(2026, 10, 12, 10, tzinfo=timezone.utc),
                max_age_hours=12,
            ), (self.html, datetime(2026, 10, 12, 8, tzinfo=timezone.utc)))
            self.assertEqual(list(cache_path.parent.glob(".kaufda.json.*.tmp")), [])

    def test_malformed_payload_is_explicit_error(self):
        with self.assertRaises(ValueError):
            kaufda.extract_next_data('<script id="__NEXT_DATA__">{</script>')

    def test_dedupe_collapses_transient_ids_but_keeps_distinct_pages(self):
        base = {
            "storeName": "Lidl",
            "productLabel": "Butter 250 g",
            "offerPrice": 1.29,
            "validFrom": "2026-10-12",
            "validUntil": "2026-10-17",
            "brochureId": "leaflet-1",
            "brochurePage": 3,
            "sourceId": "transient-a",
        }
        duplicate = {**base, "sourceId": "transient-b", "imageUrl": "https://img.test/butter.jpg"}
        other_page = {**base, "sourceId": "transient-c", "brochurePage": 4}

        result = kaufda.dedupe_kaufda([base, duplicate, other_page])

        self.assertEqual(len(result), 2)
        self.assertEqual(result[0].get("imageUrl"), "https://img.test/butter.jpg")

    def test_dedupe_keeps_distinct_exact_branches_and_prefers_verified_context(self):
        base = {
            "storeName": "Lidl",
            "productLabel": "Butter 250 g",
            "offerPrice": 1.29,
            "validFrom": "2026-10-12",
            "validUntil": "2026-10-17",
            "brochureId": "leaflet-1",
            "brochurePage": 3,
            "sourceId": "branch-a",
            "branchId": "lidl-a",
            "location": "Zellingen",
            "regionalOnly": True,
        }
        branch_b = {
            **base,
            "sourceId": "branch-b",
            "branchId": "lidl-b",
            "location": "Würzburg",
        }
        verified = {
            **base,
            "sourceId": "verified-a",
            "regionalOnly": False,
            "address": "Am Güßgraben 2",
        }

        result = kaufda.dedupe_kaufda([base, branch_b, verified])

        self.assertEqual(len(result), 2)
        self.assertEqual(
            {offer["branchId"] for offer in result},
            {"lidl-a", "lidl-b"},
        )
        zellingen = next(
            offer for offer in result if offer["branchId"] == "lidl-a"
        )
        self.assertFalse(zellingen["regionalOnly"])
        self.assertEqual(zellingen["address"], "Am Güßgraben 2")

    def test_future_cache_timestamp_is_not_used_as_current_evidence(self):
        with tempfile.TemporaryDirectory() as directory:
            cache_path = pathlib.Path(directory) / "kaufda.json"
            url = kaufda.build_search_url("Wuerzburg", "Butter")
            cache_path.write_text(
                kaufda.json.dumps(
                    {
                        kaufda._cache_key(url): {
                            "capturedAt": "2026-10-12T09:00:00+00:00",
                            "body": self.html,
                        }
                    }
                ),
                encoding="utf-8",
            )

            self.assertIsNone(
                kaufda._load_cached_body(
                    cache_path,
                    url,
                    now=datetime(2026, 10, 12, 8, tzinfo=timezone.utc),
                    max_age_hours=12,
                )
            )

    def test_malformed_cache_root_is_treated_as_cache_miss(self):
        with tempfile.TemporaryDirectory() as directory:
            cache_path = pathlib.Path(directory) / "kaufda.json"
            cache_path.write_text("[]", encoding="utf-8")

            self.assertIsNone(
                kaufda._load_cached_body(
                    cache_path,
                    kaufda.build_search_url("Wuerzburg", "Butter"),
                    now=datetime(2026, 10, 12, 8, tzinfo=timezone.utc),
                    max_age_hours=12,
                )
            )


    def test_env_parallel_query_limit_is_bounded(self):
        configured = kaufda.config_from_env(
            {"SPARZAM_KAUFDA_MAX_PARALLEL_QUERIES": "99"}
        )
        self.assertEqual(configured.max_parallel_queries, kaufda.MAX_PARALLEL_QUERIES)

        zero = kaufda.config_from_env(
            {"SPARZAM_KAUFDA_MAX_PARALLEL_QUERIES": "0"}
        )
        self.assertEqual(zero.max_parallel_queries, 1)

    def test_live_prefetch_keeps_query_order_and_batch_delay(self):
        urls = [
            kaufda.build_search_url("Wuerzburg", f"Query {index}")
            for index in range(5)
        ]
        with mock.patch.object(
            kaufda,
            "fetch_kaufda_html",
            side_effect=lambda _url, timeout_seconds: self.html,
        ) as fetch:
            with mock.patch.object(kaufda.time, "sleep") as sleep:
                result = kaufda._prefetch_kaufda_html(
                    urls,
                    timeout_seconds=3,
                    max_parallel_queries=2,
                    request_delay_seconds=0.25,
                )

        self.assertEqual(list(result), urls)
        self.assertEqual([body for body, error in result.values()], [self.html] * 5)
        self.assertTrue(all(error is None for _, error in result.values()))
        self.assertEqual(fetch.call_count, 5)
        self.assertEqual(sleep.call_count, 2)
        sleep.assert_has_calls([mock.call(0.25), mock.call(0.25)])

    def test_nonfinite_env_timing_values_fall_back(self):
        config = kaufda.config_from_env(
            {
                "SPARZAM_KAUFDA_TIMEOUT_SECONDS": "inf",
                "SPARZAM_KAUFDA_REQUEST_DELAY_SECONDS": "Infinity",
            }
        )

        self.assertEqual(config.timeout_seconds, kaufda.DEFAULT_TIMEOUT_SECONDS)
        self.assertEqual(
            config.request_delay_seconds,
            kaufda.DEFAULT_REQUEST_DELAY_SECONDS,
        )
        self.assertEqual(
            kaufda._positive_float(float("inf"), kaufda.DEFAULT_TIMEOUT_SECONDS),
            kaufda.DEFAULT_TIMEOUT_SECONDS,
        )
        self.assertEqual(
            kaufda._finite_nonnegative_float(float("nan"), 0.0),
            0.0,
        )

    def test_nonfinite_direct_timing_values_are_normalized_before_fetch(self):
        config = kaufda.KaufdaConfig(
            enabled=True,
            city="Wuerzburg",
            queries=("Butter", "Milch"),
            timeout_seconds=float("inf"),
            request_delay_seconds=float("inf"),
            cache_max_age_hours=float("inf"),
        )

        with mock.patch.object(kaufda.time, "sleep") as sleep:
            result = kaufda.fetch_current_kaufda_prospects(
                config,
                fetcher=lambda _url: self.html,
                today=self.today,
                now=datetime(2026, 10, 12, 8, tzinfo=timezone.utc),
            )

        self.assertIn("Lidl", result)
        sleep.assert_called_once_with(kaufda.DEFAULT_REQUEST_DELAY_SECONDS)

    def test_nonfinite_http_timeout_is_replaced_before_urlopen(self):
        response = mock.MagicMock()
        response.__enter__.return_value.read.return_value = b""
        with mock.patch.object(kaufda, "urlopen", return_value=response) as opener:
            self.assertEqual(
                kaufda.fetch_kaufda_html(
                    "https://example.test",
                    timeout_seconds=float("inf"),
                ),
                "",
            )

        self.assertEqual(
            opener.call_args.kwargs["timeout"],
            kaufda.DEFAULT_TIMEOUT_SECONDS,
        )


if __name__ == "__main__":
    unittest.main()
