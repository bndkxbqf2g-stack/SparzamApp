"""Optional, read-only kaufDA search adapter for the prospect refresh.

This module deliberately implements a small SparzamApp-owned adapter instead
of importing kaufda-cli or copying its source.  It parses the public
``__NEXT_DATA__`` payload exposed by a kaufDA search page and produces the
existing prospect-feed record shape.  The adapter is disabled unless an
explicit feature flag and query list are supplied.

The public search page identifies a publisher, but not reliably an exact
branch.  Therefore records are marked as regional until a caller supplies an
explicit branch assertion.  The refresh integration does not publish those
records as current offers by default.
"""

from __future__ import annotations

import hashlib
import json
import os
import re
import tempfile
import time
from dataclasses import dataclass, field
from datetime import date, datetime, timedelta, timezone
from html.parser import HTMLParser
from pathlib import Path
from typing import Callable, Iterable, Mapping
from urllib.parse import quote, urlsplit
from urllib.request import Request, urlopen
from zoneinfo import ZoneInfo


KAUFDA_BASE_URL = "https://www.kaufda.de"
KAUFDA_SOURCE = "kaufda"
DEFAULT_CITY = "Wuerzburg"
DEFAULT_MAX_QUERIES = 8
DEFAULT_TIMEOUT_SECONDS = 15.0
DEFAULT_CACHE_MAX_AGE_HOURS = 12
MAX_RESPONSE_BYTES = 4 * 1024 * 1024
LOCAL_TIMEZONE = ZoneInfo("Europe/Berlin")

# These are canonical display names already used by SparzamApp.  Aldi Nord,
# generic E center pages and unknown publishers stay out of the feed until a
# dedicated branch mapping exists.
PUBLISHER_ALIASES = {
    "lidl": "Lidl",
    "aldi süd": "ALDI Süd",
    "aldi sued": "ALDI Süd",
    "kaufland": "Kaufland",
    "edeka": "EDEKA",
    "netto": "Netto",
    "netto marken discount": "Netto",
    "netto marken-discount": "Netto",
    "penny": "PENNY",
    "rewe": "REWE",
}

FOOD_MARKERS = (
    "milch",
    "butter",
    "käse",
    "kaese",
    "joghurt",
    "quark",
    "sahne",
    "brot",
    "bröt",
    "broet",
    "nudel",
    "reis",
    "mehl",
    "zucker",
    "öl",
    "oel",
    "kaffee",
    "tee",
    "tomat",
    "kartoff",
    "apfel",
    "banane",
    "paprika",
    "gurke",
    "salat",
    "fleisch",
    "wurst",
    "fisch",
    "pizza",
    "suppe",
    "konfit",
    "marmel",
    "schokolade",
    "chips",
    "wasser",
    "saft",
    "getränk",
    "getraenk",
)

NON_FOOD_MARKERS = (
    "werkzeug",
    "auto",
    "reifen",
    "wäsche",
    "waesche",
    "bekleidung",
    "schuh",
    "spielzeug",
    "möbel",
    "moebel",
    "garten",
    "pflanze",
    "elektronik",
    "handy",
    "fernseher",
    "batterie",
    "waschmittel",
    "reiniger",
    "shampoo",
    "kosmetik",
    "tierbedarf",
    "haustier",
    "tiernahrung",
    "hundefutter",
    "hundesnack",
    "katzenfutter",
    "purina",
    "vitakraft",
    "sheba",
    "badesalz",
    "anginetten",
    "slipeinlagen",
    "pampers",
    "gillette",
    "wc-frisch",
    "calgon",
    "cosmea",
    "viss",
    "bepflanzt",
    "holzgefäß",
    "holzgefaess",
    "drucker",
    # Composite labels that otherwise inherit a food marker (for example
    # “Kaffee” in “Kaffeemaschine”). These are high-confidence product
    # classes, not a general-purpose identity alias list.
    "kaffeemaschine",
    "kaffeevollautomat",
    "espressomaschine",
    "espresso maschine",
    "küchenmaschine",
    "kuechenmaschine",
    "milchaufschäumer",
    "milchaufschaeumer",
    "tomatenpflanze",
    "tomatenpflanzen",
    "salatschleuder",
    "brotbackautomat",
    "brotbackmaschine",
    "pizzaschneider",
    "fleischwolf",
)

_PACKAGE_RE = re.compile(
    r"\b\d+\s*[x×]\s*\d+(?:[,.]\d+)?\s*-?\s*"
    r"(?:kg|g|mg|l|cl|ml|stück|stk\.?|pack(?:ung)?|becher|dose|flasche)\b|"
    r"\b\d+\s*er\s*[- ]?(?:schale|pack(?:ung)?|becher|dose|flasche)\b|"
    r"\b\d+(?:[,.]\d+)?\s*(?:kg|g|mg|l|cl|ml|stück|stk\.?|pack(?:ung)?|becher|dose|flasche)\b",
    re.IGNORECASE,
)


@dataclass(frozen=True)
class KaufdaConfig:
    """Configuration for one bounded, optional refresh run."""

    city: str = DEFAULT_CITY
    queries: tuple[str, ...] = ()
    enabled: bool = False
    max_queries: int = DEFAULT_MAX_QUERIES
    timeout_seconds: float = DEFAULT_TIMEOUT_SECONDS
    request_delay_seconds: float = 1.0
    cache_path: Path | None = None
    cache_max_age_hours: int = DEFAULT_CACHE_MAX_AGE_HOURS
    # A branch assertion must come from a separately verified mapping.  A
    # publisher name alone is never treated as an exact store.
    branch_by_store: Mapping[str, Mapping[str, str]] = field(default_factory=dict)

    @property
    def bounded_queries(self) -> tuple[str, ...]:
        limit = max(0, self.max_queries)
        if limit == 0:
            return ()
        seen = set()
        result = []
        for query in self.queries:
            value = clean(query)
            key = value.casefold()
            if not value or key in seen:
                continue
            seen.add(key)
            result.append(value)
            if len(result) >= limit:
                break
        return tuple(result)

    def branch_for(self, store_name: str) -> Mapping[str, str] | None:
        canonical_store = canonical_publisher(store_name) or clean(store_name)
        branch = self.branch_by_store.get(store_name)
        if not isinstance(branch, Mapping):
            branch = self.branch_by_store.get(canonical_store)
        if not isinstance(branch, Mapping):
            for configured_name, configured_branch in self.branch_by_store.items():
                if canonical_publisher(configured_name) == canonical_store:
                    branch = configured_branch
                    break
        if not isinstance(branch, Mapping):
            return None
        branch_id = clean(str(branch.get("branchId") or ""))
        if not branch_id:
            return None
        return branch


def _truthy(value: str | None) -> bool:
    return (value or "").strip().casefold() in {"1", "true", "yes", "on"}


def config_from_env(env: Mapping[str, str] | None = None) -> KaufdaConfig:
    """Read the opt-in configuration without making any network request."""

    # An explicitly supplied mapping is also used when empty. This keeps
    # tests and controlled refresh jobs isolated from ambient process flags.
    values = os.environ if env is None else env
    raw_queries = values.get("SPARZAM_KAUFDA_QUERIES", "")
    queries = tuple(clean(item) for item in raw_queries.split(",") if clean(item))
    cache_value = clean(values.get("SPARZAM_KAUFDA_CACHE", ""))
    branch_by_store = _branch_mapping(values.get("SPARZAM_KAUFDA_BRANCHES"))
    return KaufdaConfig(
        city=clean(values.get("SPARZAM_KAUFDA_CITY", DEFAULT_CITY)) or DEFAULT_CITY,
        queries=queries,
        enabled=_truthy(values.get("SPARZAM_KAUFDA_ENABLED")),
        # Zero is an intentional hard stop for controlled refresh jobs. Do
        # not turn it back into the default query count while reading env.
        max_queries=_nonnegative_int(
            values.get("SPARZAM_KAUFDA_MAX_QUERIES"), DEFAULT_MAX_QUERIES
        ),
        timeout_seconds=_positive_float(
            values.get("SPARZAM_KAUFDA_TIMEOUT_SECONDS"), DEFAULT_TIMEOUT_SECONDS
        ),
        request_delay_seconds=max(
            0.0,
            _positive_float(values.get("SPARZAM_KAUFDA_REQUEST_DELAY_SECONDS"), 1.0),
        ),
        cache_path=Path(cache_value) if cache_value else None,
        cache_max_age_hours=_positive_int(
            values.get("SPARZAM_KAUFDA_CACHE_MAX_AGE_HOURS"),
            DEFAULT_CACHE_MAX_AGE_HOURS,
        ),
        branch_by_store=branch_by_store,
    )


def _branch_mapping(value: str | None) -> dict[str, dict[str, str]]:
    """Parse explicit branch assertions without accepting arbitrary JSON."""

    if not value or not value.strip():
        return {}
    try:
        payload = json.loads(value)
    except (TypeError, ValueError, json.JSONDecodeError):
        return {}
    if not isinstance(payload, dict):
        return {}
    result: dict[str, dict[str, str]] = {}
    for store, raw in payload.items():
        canonical = canonical_publisher(store)
        if canonical is None or not isinstance(raw, dict):
            continue
        branch_id = clean(raw.get("branchId"))
        if not branch_id:
            continue
        result[canonical] = {
            key: clean(raw[key])
            for key in ("branchId", "location", "address")
            if clean(raw.get(key))
        }
    return result


def _positive_int(value: str | None, fallback: int) -> int:
    try:
        parsed = int(value or "")
    except ValueError:
        return fallback
    return parsed if parsed > 0 else fallback


def _nonnegative_int(value: str | None, fallback: int) -> int:
    try:
        parsed = int(value or "")
    except ValueError:
        return fallback
    return parsed if parsed >= 0 else fallback


def _positive_float(value: str | None, fallback: float) -> float:
    try:
        parsed = float(value or "")
    except ValueError:
        return fallback
    return parsed if parsed > 0 else fallback


def clean(value: object) -> str:
    return re.sub(r"\s+", " ", str(value or "")).strip()


def build_search_url(city: str, query: str) -> str:
    city_part = quote(clean(city), safe="")
    query_part = quote(clean(query), safe="")
    if not query_part:
        raise ValueError("kaufDA-Suchbegriff fehlt")
    if city_part:
        return f"{KAUFDA_BASE_URL}/{city_part}/Angebote/{query_part}"
    return f"{KAUFDA_BASE_URL}/Angebote/{query_part}"


class _NextDataParser(HTMLParser):
    """Extract only the JSON script; visible HTML is deliberately ignored."""

    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self._collecting = False
        self._parts: list[str] = []
        self.found = False

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        if tag.casefold() != "script":
            return
        attributes = {key.casefold(): value or "" for key, value in attrs}
        if (
            attributes.get("id") == "__NEXT_DATA__"
            and attributes.get("type", "application/json").casefold()
            in {"", "application/json"}
        ):
            self._collecting = True
            self.found = True

    def handle_endtag(self, tag: str) -> None:
        if tag.casefold() == "script" and self._collecting:
            self._collecting = False

    def handle_data(self, data: str) -> None:
        if self._collecting:
            self._parts.append(data)

    @property
    def text(self) -> str:
        return "".join(self._parts).strip()


def extract_next_data(html_text: str) -> dict:
    parser = _NextDataParser()
    parser.feed(html_text)
    if not parser.found or not parser.text:
        raise ValueError("kaufDA: __NEXT_DATA__ fehlt")
    try:
        payload = json.loads(parser.text)
    except json.JSONDecodeError as error:
        raise ValueError("kaufDA: __NEXT_DATA__ ist kein JSON") from error
    if not isinstance(payload, dict):
        raise ValueError("kaufDA: __NEXT_DATA__ ist kein Objekt")
    return payload


def _items_from_payload(payload: Mapping[str, object]) -> list[dict]:
    current: object = payload
    for key in (
        "props",
        "pageProps",
        "pageInformation",
        "offers",
        "main",
        "items",
    ):
        if not isinstance(current, Mapping):
            return []
        current = current.get(key)
    if isinstance(current, list):
        parsed = [item for item in current if isinstance(item, dict)]
        if parsed:
            return parsed

    # kaufDA has changed the names of intermediate result containers in the
    # past.  Tolerate a bounded nesting change, but only accept lists that
    # still carry the fields of an offer; arbitrary JSON arrays are ignored.
    def find_offer_list(value: object, depth: int = 0) -> list[dict] | None:
        if depth > 10:
            return None
        if isinstance(value, Mapping):
            for key, child in value.items():
                if (
                    clean(key).casefold()
                    in {"items", "offers", "results", "offeritems", "contents"}
                    and isinstance(child, list)
                    and any(
                        isinstance(item, Mapping)
                        and (
                            item.get("publisherName") is not None
                            or item.get("validFrom") is not None
                        )
                        for item in child
                    )
                ):
                    return [dict(item) for item in child if isinstance(item, Mapping)]
                nested = find_offer_list(child, depth + 1)
                if nested is not None:
                    return nested
        elif isinstance(value, list):
            for child in value:
                nested = find_offer_list(child, depth + 1)
                if nested is not None:
                    return nested
        return None

    return find_offer_list(payload) or []


def parse_date(value: object) -> date | None:
    if isinstance(value, date) and not isinstance(value, datetime):
        return value
    if not isinstance(value, str):
        return None
    raw = value.strip()
    if not raw:
        return None
    candidates = (raw, raw.replace("Z", "+00:00"))
    for candidate in candidates:
        try:
            parsed = datetime.fromisoformat(candidate)
            return parsed.date()
        except ValueError:
            pass
    for pattern in ("%d.%m.%Y", "%Y-%m-%d"):
        try:
            return datetime.strptime(raw, pattern).date()
        except ValueError:
            pass
    return None


def _parse_price(value: object) -> float | None:
    if isinstance(value, (int, float)) and not isinstance(value, bool):
        number = float(value)
        return number if number > 0 else None
    if not isinstance(value, str):
        return None
    raw = value.replace("€", "").strip()
    match = re.search(r"\d[\d.]*[,.]\d{1,2}|\d+", raw)
    if match is None:
        return None
    token = match.group(0)
    if "," in token:
        token = token.replace(".", "").replace(",", ".")
    try:
        number = float(token)
    except ValueError:
        return None
    return number if number > 0 else None


def _barcode_value(*values: object) -> str | None:
    """Normalize only explicitly named source barcode fields."""

    for value in values:
        candidate = value
        if isinstance(candidate, Mapping):
            for key in ("ean", "gtin", "barcode", "productCode", "product_code", "code", "value"):
                nested = candidate.get(key)
                if nested is not None:
                    candidate = nested
                    break
        if isinstance(candidate, bool) or candidate is None:
            continue
        text = clean(candidate)
        compact = re.sub(r"[\s-]+", "", text)
        if not re.fullmatch(r"\d+", compact):
            continue
        if len(compact) == 12:
            compact = "0" + compact
        if len(compact) in {8, 13, 14}:
            return compact
    return None


def _regular_price_value(value: object) -> float | None:
    if isinstance(value, Mapping):
        for key in ("amount", "value", "price", "formatted", "text"):
            parsed = _parse_price(value.get(key))
            if parsed is not None:
                return parsed
        return None
    return _parse_price(value)


def _explicit_regular_price(
    raw: Mapping[str, object] | None,
    sale: float,
) -> float | None:
    """Read only explicitly named previous/regular price fields.

    Discount rates, UVP/list prices and arbitrary numeric fields remain
    outside this helper.  A source format change therefore cannot invent a
    comparable regular price.
    """
    if not isinstance(raw, Mapping):
        return None
    for key in (
        "streichpreis",
        "wasPriceDisplay",
        "wasPrice",
        "originalPrice",
        "regularPrice",
        "normalPrice",
        "alterPreis",
        "oldPrice",
    ):
        candidate = _regular_price_value(raw.get(key))
        if candidate is not None and candidate >= sale:
            return candidate
    return None


def canonical_publisher(value: object) -> str | None:
    normalized = re.sub(r"[^\wäöüß-]+", " ", clean(value).casefold())
    normalized = re.sub(r"\s+", " ", normalized).strip()
    return PUBLISHER_ALIASES.get(normalized)


def _nested(raw: Mapping[str, object], *keys: str) -> object:
    current: object = raw
    for key in keys:
        if not isinstance(current, Mapping):
            return None
        current = current.get(key)
    return current


def _source_text(value: object, *, depth: int = 0) -> str:
    """Read bounded, named presentation labels from public source objects."""
    if depth > 2:
        return ""
    if isinstance(value, str):
        return clean(value)
    if isinstance(value, Mapping):
        for key in ("name", "title", "label", "value", "text", "formatted"):
            nested = _source_text(value.get(key), depth=depth + 1)
            if nested:
                return nested
    return ""


def _first_source_text(
    raw: Mapping[str, object] | None,
    keys: Iterable[str],
) -> str:
    if not isinstance(raw, Mapping):
        return ""
    for key in keys:
        value = _source_text(raw.get(key))
        if value:
            return value
    return ""


def _http_url(value: object) -> str:
    if not isinstance(value, str):
        return ""
    candidate = clean(value)
    parsed = urlsplit(candidate)
    if parsed.scheme.casefold() not in {"http", "https"} or not parsed.netloc:
        return ""
    return candidate


def _first_http_url(
    values: Iterable[object],
    *,
    depth: int = 0,
) -> str:
    """Accept only bounded, named URL fields from public source objects."""
    if depth > 2:
        return ""
    for value in values:
        direct = _http_url(value)
        if direct:
            return direct
        if isinstance(value, Mapping):
            for key in (
                "url",
                "src",
                "href",
                "imageUrl",
                "imageURL",
                "image_url",
                "image",
                "normal",
                "original",
                "large",
            ):
                nested = _first_http_url(
                    (value.get(key),),
                    depth=depth + 1,
                )
                if nested:
                    return nested
    return ""


def _package_hint(*values: object) -> str | None:
    parts: list[str] = []
    for value in values:
        if isinstance(value, (list, tuple)):
            parts.extend(
                rendered
                for item in value
                if (rendered := _source_text(item))
            )
            continue
        rendered = _source_text(value)
        if not rendered and not isinstance(value, Mapping):
            rendered = clean(value)
        if rendered:
            parts.append(rendered)
    match = _PACKAGE_RE.search(clean(" ".join(parts)))
    return match.group(0) if match else None


def _page_number(value: object) -> int | None:
    """Read both legacy numeric and current kaufDA page representations."""

    candidate = value
    if isinstance(candidate, Mapping):
        for key in ("number", "page", "value"):
            nested = candidate.get(key)
            if nested is not None:
                candidate = nested
                break
    if isinstance(candidate, bool):
        return None
    try:
        page = int(str(candidate).strip())
    except (TypeError, ValueError):
        return None
    return page if page > 0 else None


_PAGE_IMAGE_KEYS = (
    "image",
    "imageUrl",
    "imageURL",
    "image_url",
    "pageImage",
    "pageImageUrl",
    "page_image",
    "page_image_url",
    "thumbnail",
    "thumbnailUrl",
    "cover",
    "coverUrl",
    "coverImage",
    "coverImageUrl",
    "normal",
    "original",
    "large",
)


def _page_image_url(value: object) -> str:
    """Read a page/cover image only from explicit brochure fields."""

    if isinstance(value, Mapping):
        for key in _PAGE_IMAGE_KEYS:
            image = _first_http_url((value.get(key),))
            if image:
                return image
        return ""
    return _http_url(value)


def _prospect_page_image(
    raw: Mapping[str, object],
    parent: Mapping[str, object],
) -> str:
    """Resolve a brochure page image without reusing a product image."""

    page = parent.get("page")
    image = _page_image_url(page)
    if image:
        return image
    image = _page_image_url(parent)
    if image:
        return image
    for key in (
        "brochurePageImage",
        "brochurePageImageUrl",
        "pageImage",
        "pageImageUrl",
        "page_image",
        "page_image_url",
        "pagePreview",
        "pagePreviewUrl",
    ):
        image = _first_http_url((raw.get(key),))
        if image:
            return image
    return ""


def _prospect_cover_image(
    raw: Mapping[str, object],
    parent: Mapping[str, object],
) -> str:
    """Resolve an explicit brochure cover/thumbnail field only."""

    for container, keys in (
        (
            parent,
            (
                "cover",
                "coverUrl",
                "coverImage",
                "coverImageUrl",
                "thumbnail",
                "thumbnailUrl",
            ),
        ),
        (
            raw,
            (
                "brochureCover",
                "brochureCoverUrl",
                "brochureCoverImage",
                "brochureCoverImageUrl",
                "cover",
                "coverUrl",
                "coverImage",
                "coverImageUrl",
            ),
        ),
    ):
        for key in keys:
            image = _first_http_url((container.get(key),))
            if image:
                return image
    return ""


def _add_page_sample(
    samples: list[object],
    page: int,
    image: str,
) -> None:
    """Keep legacy page numbers while enriching them with verified images."""

    for index, existing in enumerate(samples):
        if _page_number(existing) != page:
            continue
        if image and not _page_image_url(existing):
            samples[index] = {"number": page, "image": image}
        return
    samples.append({"number": page, "image": image} if image else page)


def _category_text(raw: Mapping[str, object]) -> str:
    values: list[str] = []
    for key in (
        "category",
        "categoryName",
        "productCategory",
        "subcategory",
        "subCategory",
        "sub_category",
        "department",
        "departmentName",
        "warengruppe",
        "sortiment",
    ):
        value = _source_text(raw.get(key))
        if value:
            values.append(value)
    categories = raw.get("categories")
    if isinstance(categories, (list, tuple)):
        for entry in categories:
            value = _source_text(entry) or clean(entry)
            if value:
                values.append(value)
    paths = raw.get("categoryPaths")
    if isinstance(paths, (list, tuple)):
        for path in paths:
            if not isinstance(path, (list, tuple)):
                continue
            for entry in path:
                value = _source_text(entry) or clean(entry)
                if value:
                    values.append(value)
    return clean(" ".join(values))


def _category_label(raw: Mapping[str, object]) -> str:
    keys = (
        "category",
        "categoryName",
        "productCategory",
        "subcategory",
        "subCategory",
        "sub_category",
        "department",
        "departmentName",
        "warengruppe",
        "sortiment",
    )
    for key in keys:
        value = _source_text(raw.get(key))
        if value:
            return value
    categories = raw.get("categories")
    if isinstance(categories, (list, tuple)):
        values = [_source_text(value) or clean(value) for value in categories]
        values = [value for value in values if value]
        if values:
            return values[-1]
    paths = raw.get("categoryPaths")
    if isinstance(paths, (list, tuple)):
        for path in reversed(paths):
            if not isinstance(path, (list, tuple)):
                continue
            for entry in reversed(path):
                value = _source_text(entry) or clean(entry)
                if value:
                    return value
    return ""


def _is_food(raw: Mapping[str, object], label: str) -> bool:
    category = _category_text(raw).casefold()
    searchable = clean(
        " ".join(
            str(value or "")
            for value in (
                label,
                raw.get("description"),
                raw.get("brand"),
                category,
            )
        )
    ).casefold()
    if any(marker in searchable for marker in NON_FOOD_MARKERS):
        return False
    if any(marker in category for marker in NON_FOOD_MARKERS):
        return False
    if any(marker in category for marker in FOOD_MARKERS):
        return True
    paths = raw.get("categoryPaths")
    if isinstance(paths, (list, tuple)) and paths:
        has_food_root = any(
            isinstance(path, (list, tuple))
            and any(
                isinstance(entry, Mapping)
                and "lebensmittel" in clean(
                    entry.get("name") or entry.get("label")
                ).casefold()
                for entry in path[:1]
            )
            for path in paths
        )
        if has_food_root:
            return True
        # An explicit non-food taxonomy is stronger evidence than a title
        # substring such as “Kaffee” in “Kaffeemaschine”.
        return False
    return any(marker in searchable for marker in FOOD_MARKERS)


def _label(raw: Mapping[str, object]) -> str:
    title = clean(raw.get("title"))
    brand = clean(raw.get("brand"))
    description = clean(raw.get("description"))
    parts: list[str] = []
    if brand and brand.casefold() not in title.casefold():
        parts.append(brand)
    if title:
        parts.append(title)
    if description and description.casefold() not in title.casefold():
        parts.append(description)
    return clean(" ".join(parts))


def _source_id(
    *,
    publisher: str,
    item_id: str,
    label: str,
    valid_from: date,
    valid_until: date,
    page: int | None,
) -> str:
    identity = "|".join(
        (
            KAUFDA_SOURCE,
            publisher,
            item_id,
            label.casefold(),
            valid_from.isoformat(),
            valid_until.isoformat(),
            str(page or ""),
        )
    )
    return hashlib.sha256(identity.encode("utf-8")).hexdigest()[:20]


def parse_kaufda_html(
    html_text: str,
    *,
    city: str,
    query: str,
    today: date | None = None,
    branch: Mapping[str, str] | None = None,
) -> tuple[list[dict], dict]:
    """Parse one public search page into current, food-only feed records.

    A missing branch assertion keeps ``regionalOnly`` true.  This is useful
    for discovery and diagnostics but is deliberately not promoted by the
    refresh integration to routeable offers.
    """

    payload = extract_next_data(html_text)
    raw_items = _items_from_payload(payload)
    reference = today or date.today()
    search_url = build_search_url(city, query)
    offers: list[dict] = []
    skipped = {
        "invalid": 0,
        "expired_or_future": 0,
        "unknown_publisher": 0,
        "non_food": 0,
    }
    prospects: dict[tuple[str, str, str, str], dict] = {}
    exact_branch = branch is not None and clean(branch.get("branchId"))
    publisher_counts: dict[str, int] = {}
    regional_only_counts: dict[str, int] = {}

    for raw in raw_items:
        publisher = canonical_publisher(raw.get("publisherName"))
        if publisher is None:
            skipped["unknown_publisher"] += 1
            continue
        publisher_counts[publisher] = publisher_counts.get(publisher, 0) + 1
        label = _label(raw)
        prices = raw.get("prices")
        prices = prices if isinstance(prices, Mapping) else {}
        offer_price = _parse_price(prices.get("mainPrice") or raw.get("mainPrice"))
        valid_from = parse_date(raw.get("validFrom"))
        valid_until = parse_date(raw.get("validUntil"))
        if not label or offer_price is None or valid_from is None or valid_until is None:
            skipped["invalid"] += 1
            continue
        if valid_until < valid_from or not (valid_from <= reference <= valid_until):
            skipped["expired_or_future"] += 1
            continue
        if not _is_food(raw, label):
            skipped["non_food"] += 1
            continue

        item_id = clean(raw.get("id"))
        if not item_id:
            item_id = hashlib.sha256(
                f"{publisher}|{label}|{offer_price}|{valid_from}|{valid_until}".encode(
                    "utf-8"
                )
            ).hexdigest()[:16]
        parent = raw.get("parentContent")
        parent = parent if isinstance(parent, Mapping) else {}
        brochure_id = clean(parent.get("id") or raw.get("brochureId"))
        parent_page = parent.get("page")
        page = _page_number(parent_page or raw.get("brochurePage"))
        page_image = _prospect_page_image(raw, parent)
        cover_image = _prospect_cover_image(raw, parent)
        source_id = _source_id(
            publisher=publisher,
            item_id=item_id,
            label=label,
            valid_from=valid_from,
            valid_until=valid_until,
            page=page,
        )
        proof = f"{search_url}#offer-{quote(item_id, safe='')}"
        image = _first_http_url(
            (
                _nested(raw, "offerImages", "url", "normal"),
                _nested(raw, "offerImages", "url"),
                raw.get("imageUrl"),
                raw.get("imageURL"),
                raw.get("image_url"),
                raw.get("image"),
                raw.get("productImage"),
                raw.get("product_image"),
                raw.get("bild"),
                raw.get("bild_app"),
                raw.get("bild_web130"),
                raw.get("bild_web90"),
            )
        )
        category = _category_label(raw)
        ean = _barcode_value(
            raw.get("ean"),
            raw.get("gtin"),
            raw.get("barcode"),
            raw.get("productCode"),
            raw.get("product_code"),
        )
        record = {
            "sourceId": source_id,
            "productLabel": label,
            "storeName": publisher,
            "offerPrice": round(offer_price, 2),
            "validFrom": valid_from.isoformat(),
            "validUntil": valid_until.isoformat(),
            "source": "retailerWebsite",
            "sourceAdapter": KAUFDA_SOURCE,
            "proofRef": proof,
            "regionalOnly": not exact_branch,
        }
        regular_price = None
        for price_source in (
            raw,
            prices,
            raw.get("price"),
            raw.get("pricing"),
        ):
            regular_price = _explicit_regular_price(price_source, offer_price)
            if regular_price is not None:
                break
        secondary_price = _parse_price(prices.get("secondaryPrice"))
        secondary_is_uvp = bool(prices.get("secondaryPriceIsUVP"))
        if (
            regular_price is None
            and secondary_price is not None
            and secondary_price > offer_price
            and not secondary_is_uvp
        ):
            regular_price = secondary_price
        if regular_price is not None:
            record["originalPrice"] = round(regular_price, 2)
        publisher_id = clean(raw.get("publisherId"))
        if publisher_id:
            record["publisherId"] = publisher_id
        if image:
            record["imageUrl"] = image
        if category:
            record["category"] = category
        if ean:
            record["ean"] = ean
        package = _package_hint(
            raw.get("title"),
            raw.get("description"),
            raw.get("quantity"),
            raw.get("packageSize"),
            raw.get("package"),
            raw.get("packaging"),
            raw.get("quantityLabel"),
        )
        if package:
            record["packageSize"] = package
        base_unit = (
            _first_source_text(
                prices,
                ("priceByBaseUnit", "unitPrice", "baseUnitPrice"),
            )
            or _first_source_text(
                raw,
                ("priceByBaseUnit", "unitPrice", "baseUnitPrice"),
            )
            or _first_source_text(
                raw.get("pricing"),
                ("priceByBaseUnit", "unitPrice", "baseUnitPrice"),
            )
        )
        if base_unit:
            record["priceByBaseUnit"] = base_unit
        if brochure_id:
            record["brochureId"] = brochure_id
        if page is not None:
            record["brochurePage"] = page
        if exact_branch:
            record["branchId"] = clean(branch.get("branchId"))
            location = clean(branch.get("location"))
            if location:
                record["location"] = location
            address = clean(branch.get("address"))
            if address:
                record["address"] = address

        offers.append(record)
        if record["regionalOnly"]:
            regional_only_counts[publisher] = regional_only_counts.get(publisher, 0) + 1
        if brochure_id:
            prospect_key = (
                publisher,
                brochure_id,
                valid_from.isoformat(),
                valid_until.isoformat(),
            )
            prospect = prospects.setdefault(
                prospect_key,
                {
                    "id": brochure_id,
                    "storeName": publisher,
                    "title": f"kaufDA {publisher} {valid_from:%d.%m.%Y} – {valid_until:%d.%m.%Y}",
                    "url": search_url,
                    "offerStartDate": valid_from.isoformat(),
                    "offerEndDate": valid_until.isoformat(),
                    "status": "regional_only" if not exact_branch else "current",
                    "productCount": 0,
                    "pageSamples": [],
                },
            )
            prospect["productCount"] += 1
            if cover_image and not prospect.get("thumbnailUrl"):
                prospect["thumbnailUrl"] = cover_image
            if page is not None:
                _add_page_sample(prospect["pageSamples"], page, page_image)

    offers = dedupe_kaufda(offers)
    return offers, {
        "url": search_url,
        "query": clean(query),
        "rawItemCount": len(raw_items),
        "recordCount": len(offers),
        "skipped": skipped,
        "prospects": list(prospects.values()),
        "regionalOnlyCount": sum(1 for offer in offers if offer.get("regionalOnly")),
        "publisherCounts": publisher_counts,
        "regionalOnlyCounts": regional_only_counts,
        "publishers": sorted(
            {
                publisher
                for publisher in (
                    canonical_publisher(item.get("publisherName"))
                    for item in raw_items
                )
                if publisher
            }
        ),
    }


def dedupe_kaufda(offers: Iterable[dict]) -> list[dict]:
    """Dedupe repeated search hits without merging distinct leaflet pages.

    The same kaufDA item can receive a different transient ID when it is
    reached through another query. The semantic key therefore includes the
    exact retailer label, price, validity window and leaflet context. Page and
    validity remain part of the key, so two real placements are preserved.
    """

    unique: dict[tuple[object, ...], dict] = {}
    for offer in offers:
        if not isinstance(offer, dict):
            continue
        source_id = clean(offer.get("sourceId"))
        key = (
            clean(offer.get("storeName")).casefold(),
            clean(offer.get("productLabel")).casefold(),
            clean(offer.get("validFrom")),
            clean(offer.get("validUntil")),
            clean(offer.get("offerPrice")),
            clean(offer.get("ean")),
            clean(offer.get("brochureId")),
            clean(offer.get("brochurePage")),
            # Exact branch context is part of identity. Two same-name stores
            # may publish the same item, price, and page in one campaign.
            clean(offer.get("branchId")),
            (
                ""
                if clean(offer.get("branchId"))
                else clean(offer.get("location")).casefold()
            ),
            (
                ""
                if clean(offer.get("branchId"))
                else clean(offer.get("address")).casefold()
            ),
            # Without leaflet context, retain a source identity because two
            # otherwise identical records may belong to separate campaigns.
            "" if clean(offer.get("brochureId")) or clean(offer.get("brochurePage")) else source_id,
        )
        previous = unique.get(key)
        if previous is None:
            unique[key] = offer
            continue
        # Keep the richest record while preserving the original deterministic
        # order. A query with an image/category must not erase that evidence
        # from an earlier duplicate.
        merged = dict(previous)
        if (
            merged.get("regionalOnly") is True
            and offer.get("regionalOnly") is False
        ):
            # A verified branch assertion wins when all identity fields above
            # match; a regional hit must not downgrade an exact one.
            merged["regionalOnly"] = False
        for field in (
            "originalPrice",
            "imageUrl",
            "category",
            "packageSize",
            "priceByBaseUnit",
            "publisherId",
            "brochureId",
            "brochurePage",
            "capturedAt",
            "branchId",
            "location",
            "address",
        ):
            if not clean(merged.get(field)) and clean(offer.get(field)):
                merged[field] = offer[field]
        unique[key] = merged
    return list(unique.values())


def fetch_kaufda_html(url: str, *, timeout_seconds: float = DEFAULT_TIMEOUT_SECONDS) -> str:
    request = Request(
        url,
        headers={
            "User-Agent": "SparzamApp-kaufda-adapter/1.0 (+https://github.com/bndkxbqf2g-stack/SparzamApp)",
            "Accept-Language": "de-DE,de;q=0.9",
            "Accept": "text/html,application/xhtml+xml;q=0.9,*/*;q=0.8",
        },
    )
    with urlopen(request, timeout=timeout_seconds) as response:
        body = response.read(MAX_RESPONSE_BYTES + 1)
        if len(body) > MAX_RESPONSE_BYTES:
            raise ValueError("kaufDA: Antwort ist zu groß")
        return body.decode("utf-8", errors="replace")


def _cache_key(url: str) -> str:
    return hashlib.sha256(url.encode("utf-8")).hexdigest()


def _load_cached_body(
    path: Path | None,
    url: str,
    *,
    now: datetime,
    max_age_hours: int,
) -> tuple[str, datetime] | None:
    if path is None or not path.exists():
        return None
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
        if not isinstance(payload, Mapping):
            return None
        entry = payload.get(_cache_key(url))
        if not isinstance(entry, Mapping):
            return None
        captured_at = datetime.fromisoformat(str(entry["capturedAt"]))
        body = entry["body"]
        if (
            not isinstance(body, str)
            or len(body.encode("utf-8")) > MAX_RESPONSE_BYTES
            or captured_at > now
            or now - captured_at > timedelta(hours=max_age_hours)
        ):
            return None
        return body, captured_at
    except (
        OSError,
        AttributeError,
        KeyError,
        TypeError,
        ValueError,
        json.JSONDecodeError,
    ):
        return None


def _save_cached_body(path: Path | None, url: str, body: str, captured_at: datetime) -> None:
    if path is None:
        return
    temporary_path: Path | None = None
    try:
        path.parent.mkdir(parents=True, exist_ok=True)
        payload = {}
        if path.exists():
            try:
                payload = json.loads(path.read_text(encoding="utf-8"))
            except (OSError, TypeError, ValueError, json.JSONDecodeError):
                payload = {}
        if not isinstance(payload, dict):
            payload = {}
        payload[_cache_key(url)] = {
            "url": url,
            "capturedAt": captured_at.isoformat(),
            "body": body,
        }
        # Write beside the target and replace it only after the complete JSON
        # document is on disk. A killed refresh must leave the previous cache
        # readable for the offline fallback.
        with tempfile.NamedTemporaryFile(
            mode="w",
            encoding="utf-8",
            dir=path.parent,
            prefix=f".{path.name}.",
            suffix=".tmp",
            delete=False,
        ) as temporary:
            temporary_path = Path(temporary.name)
            temporary.write(json.dumps(payload, ensure_ascii=False))
            temporary.flush()
            os.fsync(temporary.fileno())
        os.replace(temporary_path, path)
        temporary_path = None
    except OSError:
        # Cache repair must never turn a valid source response into a refresh
        # failure.
        pass
    finally:
        if temporary_path is not None:
            try:
                temporary_path.unlink(missing_ok=True)
            except OSError:
                pass


def fetch_current_kaufda_prospects(
    config: KaufdaConfig | None = None,
    *,
    fetcher: Callable[[str], str] | None = None,
    today: date | None = None,
    now: datetime | None = None,
) -> dict[str, dict]:
    """Fetch bounded search pages and group safe results by canonical store.

    The empty result is intentional when the feature flag or query list is
    absent.  Network calls are therefore impossible during normal refreshes.
    """

    settings = config or config_from_env()
    queries = settings.bounded_queries
    if not settings.enabled or not queries:
        return {}

    reference_now = now or datetime.now(timezone.utc)
    reference_day = today or reference_now.astimezone(LOCAL_TIMEZONE).date()
    grouped: dict[str, dict] = {}
    for index, query in enumerate(queries):
        url = build_search_url(settings.city, query)
        body = None
        captured_at = reference_now
        cache_used = False
        error = None
        try:
            candidate = (fetcher or (lambda target: fetch_kaufda_html(
                target, timeout_seconds=settings.timeout_seconds
            )))(url)
            if not isinstance(candidate, str) or not candidate.strip():
                raise ValueError("kaufDA: leere Antwort")
            if len(candidate.encode("utf-8")) > MAX_RESPONSE_BYTES:
                raise ValueError("kaufDA: Antwort ist zu groß")
            body = candidate
        except Exception as exc:  # noqa: BLE001 - source failure is isolated
            error = clean(exc)[:240]
            cached = _load_cached_body(
                settings.cache_path,
                url,
                now=reference_now,
                max_age_hours=settings.cache_max_age_hours,
            )
            if cached is None:
                if index + 1 < len(queries) and settings.request_delay_seconds:
                    time.sleep(settings.request_delay_seconds)
                continue
            body, captured_at = cached
            cache_used = True

        parsed_from_live = not cache_used
        try:
            offers, metadata = parse_kaufda_html(
                body,
                city=settings.city,
                query=query,
                today=reference_day,
            )
        except Exception as exc:  # noqa: BLE001 - malformed source is isolated
            parse_error = clean(exc)[:240]
            # A page can return HTTP 200 while its embedded JSON has changed.
            # Keep the last successfully parsed body available in that case;
            # the malformed live response must never replace it.
            cached = None
            if parsed_from_live:
                cached = _load_cached_body(
                    settings.cache_path,
                    url,
                    now=reference_now,
                    max_age_hours=settings.cache_max_age_hours,
                )
            if cached is not None:
                try:
                    cached_offers, cached_metadata = parse_kaufda_html(
                        cached[0],
                        city=settings.city,
                        query=query,
                        today=reference_day,
                    )
                except Exception:
                    cached = None
                else:
                    body, captured_at = cached
                    cache_used = True
                    error = parse_error
                    offers, metadata = cached_offers, cached_metadata

            if cached is None:
                error = parse_error
                offers, metadata = [], {
                    "url": url,
                    "query": query,
                    "rawItemCount": 0,
                    "recordCount": 0,
                    "regionalOnlyCount": 0,
                    "skipped": {"invalid": 1},
                    "prospects": [],
                }

        if not cache_used and body is not None:
            # Only a successfully parsed live response is eligible to replace
            # the previous cache entry.
            _save_cached_body(settings.cache_path, url, body, reference_now)

        for offer in offers:
            store = clean(offer.get("storeName"))
            if not store:
                continue
            branch = settings.branch_for(store)
            # Keep current regional food hits in the feed so users can find
            # them and inspect the KaufDA evidence.  The Flutter import and
            # route layers reject regionalOnly records, so visibility never
            # turns an unverified publisher into an exact branch price.
            offer["regionalOnly"] = branch is None
            # Keep the actual fetch/cache time on the individual record. The
            # combined feed may contain newer retailer data alongside a
            # cached kaufDA response, so a single feed timestamp would make
            # this offer look fresher than its evidence.
            offer["capturedAt"] = captured_at.isoformat()
            if branch is not None:
                offer["branchId"] = clean(branch.get("branchId"))
                location = clean(branch.get("location"))
                if location:
                    offer["location"] = location
                address = clean(branch.get("address"))
                if address:
                    offer["address"] = address
            grouped.setdefault(
                store,
                {
                    "offers": [],
                    "prospects": [],
                    "urls": [],
                    "queries": [],
                    "rawItemCount": 0,
                    "regionalOnlyCount": 0,
                    "capturedAt": captured_at.isoformat(),
                    "cacheUsed": cache_used,
                    "errors": [],
                    "branch": dict(branch or {}),
                },
            )["offers"].append(offer)

        # Retain source diagnostics even when every result was regional.
        for store in metadata.get("publishers", []):
            entry = grouped.setdefault(
                store,
                {
                    "offers": [],
                    "prospects": [],
                    "urls": [],
                    "queries": [],
                    "rawItemCount": 0,
                    "regionalOnlyCount": 0,
                    "capturedAt": captured_at.isoformat(),
                    "cacheUsed": cache_used,
                    "errors": [],
                    "branch": dict(settings.branch_for(store) or {}),
                },
            )
            publisher_counts = metadata.get("publisherCounts", {})
            regional_only_counts = metadata.get("regionalOnlyCounts", {})
            entry["rawItemCount"] += int(publisher_counts.get(store, 0))
            if settings.branch_for(store) is None:
                entry["regionalOnlyCount"] += int(regional_only_counts.get(store, 0))
            entry["urls"].append(url)
            entry["queries"].append(query)
            branch = settings.branch_for(store)
            for item in metadata.get("prospects", []):
                if not isinstance(item, dict):
                    continue
                if clean(item.get("storeName")) != store:
                    continue
                prospect = dict(item)
                if branch is not None:
                    prospect["status"] = "current"
                    prospect["branchId"] = clean(branch.get("branchId"))
                    location = clean(branch.get("location"))
                    if location:
                        prospect["location"] = location
                    address = clean(branch.get("address"))
                    if address:
                        prospect["address"] = address
                if prospect not in entry["prospects"]:
                    entry["prospects"].append(prospect)
            if cache_used:
                entry["cacheUsed"] = True
            if error:
                entry["errors"].append(error)

        if index + 1 < len(queries) and settings.request_delay_seconds:
            time.sleep(settings.request_delay_seconds)

    for store, entry in grouped.items():
        entry["offers"] = dedupe_kaufda(entry.get("offers", []))
        entry["url"] = entry.get("urls", [build_search_url(settings.city, store)])[0]
        has_exact_branch_offer = any(
            not bool(offer.get("regionalOnly")) for offer in entry["offers"]
        )
        if has_exact_branch_offer:
            entry["status"] = "cached" if entry.get("cacheUsed") else "ok"
        elif entry["offers"] or entry.get("regionalOnlyCount"):
            entry["status"] = "regional_only"
        elif entry.get("errors"):
            entry["status"] = "error"
        else:
            entry["status"] = "no_current_offers"
    return grouped

