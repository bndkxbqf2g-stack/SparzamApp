import pathlib
import tempfile
import unittest
from datetime import date, datetime, timezone
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


if __name__ == "__main__":
    unittest.main()
