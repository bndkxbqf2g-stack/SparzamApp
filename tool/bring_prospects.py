#!/usr/bin/env python3
"""Optional Bring! brochure adapter for the Sparzam prospect refresh.

The shared Bring! URLs are useful evidence for a *specific* brochure because
they contain a stable brochure BRN and cover image. They are intentionally not
used as a permanent "current brochure" URL: a new brochure receives a new BRN.

Live discovery is therefore location based and only runs when the required
Bring credentials are supplied through environment variables. No credentials
are stored in the app or repository.
"""

from __future__ import annotations

import hashlib
import json
import os
import re
import time
from dataclasses import dataclass
from datetime import date, datetime
from typing import Any
from urllib.parse import parse_qs, quote, unquote, urlencode, urlparse
from urllib.request import Request, urlopen
from zoneinfo import ZoneInfo

BRING_BASE_URL = "https://production.bringapi.app"
BRING_PROVIDER_ID = "bring-de"
BRING_CLIENT = "iOS"
BRING_VERSION = "4.110.0"

# Existing Sparzam shopping area / branch configuration. This is not the
# device's current location and does not access user location services.
DEFAULT_ZIP_CODE = "97225"
DEFAULT_LATITUDE = 49.91009
DEFAULT_LONGITUDE = 9.81492

SUPPORTED_STORES = ("Lidl", "ALDI Süd", "EDEKA", "Kaufland", "PENNY", "Netto")
LOCAL_TIMEZONE = ZoneInfo("Europe/Berlin")


def local_today() -> date:
    """Return the business date used by the German brochure adapter."""
    return datetime.now(LOCAL_TIMEZONE).date()


def _clean(value: Any) -> str:
    return re.sub(r"\s+", " ", str(value or "")).strip()


def _decode_repeated(value: str) -> str:
    current = value
    for _ in range(3):
        decoded = unquote(current)
        if decoded == current:
            break
        current = decoded
    return current


def parse_share_url(url: str) -> dict[str, str]:
    """Extract durable evidence from a Bring! share URL.

    The returned brochureId identifies this exact brochure issue. It must not
    be treated as the identifier of future weekly brochures.
    """

    query = parse_qs(urlparse(url).query)
    deep_link = _decode_repeated(
        (query.get("af_web_dp") or query.get("deep_link_value") or [""])[0]
    )
    match = re.search(r"(brn:bring-de:offersbrochure:\d+)", deep_link)
    if match is None:
        raise ValueError("Bring share URL enthält keine Prospekt-ID")

    cover = _decode_repeated((query.get("af_og_image") or [""])[0])
    title = _decode_repeated((query.get("af_og_title") or [""])[0])
    return {
        "brochureId": match.group(1),
        "deepLink": deep_link,
        "coverImage": cover,
        "title": title,
    }


@dataclass(frozen=True)
class BringApiConfig:
    auth_token: str
    api_key: str
    user_uuid: str

    @classmethod
    def from_env(cls) -> "BringApiConfig | None":
        auth_token = _clean(os.environ.get("BRING_AUTH_TOKEN"))
        api_key = _clean(os.environ.get("BRING_API_KEY"))
        user_uuid = _clean(os.environ.get("BRING_USER_UUID"))
        if not auth_token or not api_key or not user_uuid:
            return None
        auth_token = re.sub(r"^Bearer\s+", "", auth_token, flags=re.I)
        return cls(auth_token=auth_token, api_key=api_key, user_uuid=user_uuid)


def _headers(config: BringApiConfig) -> dict[str, str]:
    return {
        "Authorization": "Bearer " + config.auth_token,
        "X-BRING-API-KEY": config.api_key,
        "X-BRING-CLIENT": BRING_CLIENT,
        "X-BRING-COUNTRY": "DE",
        "X-BRING-VERSION": BRING_VERSION,
        "X-BRING-USER-UUID": config.user_uuid,
        "Accept-Language": "de-DE",
        "Accept": "application/json",
        "User-Agent": "SparzamApp/1.0",
    }


def _fetch_json(url: str, config: BringApiConfig) -> Any:
    last_error: Exception | None = None
    for attempt in range(3):
        try:
            request = Request(url, headers=_headers(config))
            with urlopen(request, timeout=30) as response:
                return json.loads(response.read().decode("utf-8"))
        except Exception as error:  # network/API boundary
            last_error = error
            if attempt < 2:
                time.sleep(2 ** attempt)
    raise RuntimeError("Bring API nicht erreichbar") from last_error


def _canonical_store(value: Any) -> str | None:
    name = _clean(value).lower()
    if "aldi" in name:
        return "ALDI Süd"
    if "edeka" in name:
        return "EDEKA"
    if "kaufland" in name:
        return "Kaufland"
    if "lidl" in name:
        return "Lidl"
    if "penny" in name:
        return "PENNY"
    if "netto" in name:
        return "Netto"
    return None


def _record(value: Any) -> dict[str, Any]:
    return value if isinstance(value, dict) else {}


def _array(value: Any) -> list[Any]:
    return value if isinstance(value, list) else []


def _first_text(*values: Any) -> str:
    for value in values:
        text = _clean(value)
        if text:
            return text
    return ""


def _image_url(value: Any) -> str:
    if isinstance(value, str):
        return _clean(value)
    image = _record(value)
    return _first_text(
        image.get("imageUrl"),
        image.get("url"),
        image.get("originalImageUrl"),
    )


def _money_eur(value: Any) -> float | None:
    if value is None or isinstance(value, bool):
        return None
    if isinstance(value, dict):
        for key in ("cents", "amountCents", "valueCents"):
            candidate = value.get(key)
            if isinstance(candidate, (int, float)):
                return round(float(candidate) / 100.0, 2)
        for key in ("amount", "value", "price"):
            candidate = _money_eur(value.get(key))
            if candidate is not None:
                return candidate
        return None
    if isinstance(value, int):
        return round(value / 100.0, 2)
    if isinstance(value, float):
        if value.is_integer() and abs(value) >= 100:
            return round(value / 100.0, 2)
        return round(value, 2)
    if isinstance(value, str):
        raw = value.strip()
        if not raw:
            return None
        has_currency_format = "€" in raw or "," in raw or "." in raw
        normalized = re.sub(r"[^\d,.-]", "", raw).replace(",", ".")
        try:
            numeric = float(normalized)
        except ValueError:
            return None
        if not has_currency_format and numeric.is_integer():
            return round(numeric / 100.0, 2)
        return round(numeric, 2)
    return None


def _iso_date(value: Any) -> date | None:
    text = _clean(value)
    if len(text) < 10:
        return None
    try:
        return date.fromisoformat(text[:10])
    except ValueError:
        return None


def _company_name(offer: dict[str, Any], detail: dict[str, Any]) -> str:
    for container in (
        _record(offer.get("company")),
        _record(detail.get("company")),
        _record(offer.get("retailer")),
        _record(detail.get("retailer")),
    ):
        name = _first_text(container.get("title"), container.get("name"))
        if name:
            return name
    return ""


def _deep_link(brochure_id: str, page_number: int = 1) -> str:
    page_index = max(0, page_number - 1)
    return (
        "https://deeplink.getbring.com/view/offers/bring-de/"
        + brochure_id
        + "/"
        + str(page_index)
    )


def _source_id(store: str, brochure_id: str, page_number: int, label: str, price: float) -> str:
    raw = f"{store}|{brochure_id}|{page_number}|{label}|{price:.2f}".encode("utf-8")
    return hashlib.sha256(raw).hexdigest()[:20]


def _discount_label(discount: dict[str, Any]) -> str:
    title = _first_text(discount.get("name"), discount.get("title"))
    description = _clean(discount.get("description"))
    if not title:
        return description
    if description and description.lower() not in title.lower():
        return _clean(title + " " + description)
    return title


def _discount_record(
    store: str,
    brochure_id: str,
    page_number: int,
    valid_from: date,
    valid_until: date,
    discount: dict[str, Any],
) -> dict[str, Any] | None:
    label = _discount_label(discount)
    if len(label) < 2:
        return None

    sale = None
    for key in ("price", "currentPrice", "salePrice", "offerPrice"):
        sale = _money_eur(discount.get(key))
        if sale is not None:
            break
    if sale is None:
        price_label = _first_text(
            discount.get("priceLabel"),
            discount.get("priceText"),
            discount.get("formattedPrice"),
        )
        match = re.search(r"(\d+[,.]\d{1,2})", price_label)
        sale = _money_eur(match.group(1)) if match else None
    if sale is None or sale <= 0:
        return None

    original = None
    for key in ("oldPrice", "regularPrice", "originalPrice"):
        candidate = _money_eur(discount.get(key))
        if candidate is not None and candidate >= sale:
            original = candidate
            break

    image = _image_url(discount.get("imageUrl") or discount.get("image"))
    record = {
        "sourceId": _source_id(store, brochure_id, page_number, label, sale),
        "productLabel": label,
        "storeName": store,
        "offerPrice": sale,
        "validFrom": valid_from.isoformat(),
        "validUntil": valid_until.isoformat(),
        "source": "leaflet",
        "proofRef": _deep_link(brochure_id, page_number),
    }
    if original is not None:
        record["originalPrice"] = original
    if image:
        record["imageUrl"] = image
    return record


def transform_bring_brochure(
    offer_value: Any,
    detail_value: Any,
    *,
    today: date | None = None,
) -> dict[str, Any] | None:
    offer = _record(offer_value)
    detail = _record(detail_value)
    brochure_id = _first_text(offer.get("brn"), offer.get("id"), detail.get("brn"), detail.get("id"))
    if not brochure_id.startswith("brn:bring-de:offersbrochure:"):
        return None

    store = _canonical_store(_company_name(offer, detail))
    if store not in SUPPORTED_STORES:
        return None

    valid_from = _iso_date(
        offer.get("activeFrom") or offer.get("validFrom")
        or detail.get("activeFrom") or detail.get("validFrom")
    )
    valid_until = _iso_date(
        offer.get("activeTo") or offer.get("validUntil")
        or detail.get("activeTo") or detail.get("validUntil")
    )
    if valid_from is None or valid_until is None:
        return None
    reference_day = today or local_today()
    if reference_day < valid_from or reference_day > valid_until:
        return None

    page_samples: list[dict[str, Any]] = []
    records: list[dict[str, Any]] = []
    for index, page_value in enumerate(_array(detail.get("pages"))):
        page = _record(page_value)
        number_raw = page.get("page") if page.get("page") is not None else page.get("number")
        try:
            page_number = int(number_raw) if number_raw is not None else index + 1
        except (TypeError, ValueError):
            page_number = index + 1

        image = _image_url(page.get("image") or page.get("originalImage") or page.get("original_image"))
        discounts = [_record(value) for value in _array(page.get("discounts"))]
        labels = [_discount_label(value) for value in discounts]
        keywords = _clean(" · ".join(value for value in labels if value))[:700]
        if image:
            page_samples.append({
                "number": page_number,
                "image": image,
                "zoom": image,
                "keyWords": keywords,
            })

        for discount in discounts:
            item = _discount_record(
                store,
                brochure_id,
                page_number,
                valid_from,
                valid_until,
                discount,
            )
            if item is not None:
                records.append(item)

    if not page_samples:
        return None

    summary_pages = _array(offer.get("pages"))
    cover = ""
    if summary_pages:
        first_page = _record(summary_pages[0])
        cover = _image_url(first_page.get("image") or first_page.get("originalImage"))
    if not cover:
        cover = _clean(page_samples[0].get("image"))

    title = _first_text(offer.get("title"), detail.get("title"), store + " Angebote")
    prospect = {
        "id": brochure_id,
        "title": title,
        "url": _deep_link(brochure_id),
        "offerStartDate": valid_from.isoformat(),
        "offerEndDate": valid_until.isoformat(),
        "thumbnailUrl": cover,
        "pageCount": len(page_samples),
        "productCount": len(records),
        "pageSamples": page_samples,
    }
    return {
        "storeName": store,
        "prospect": prospect,
        "offers": records,
        "pageCount": len(page_samples),
        "validFrom": valid_from.isoformat(),
    }


def _list_url(zip_code: str, latitude: float, longitude: float) -> str:
    params = urlencode({
        "type": "brochure",
        "providerId": BRING_PROVIDER_ID,
        "lat": str(latitude),
        "long": str(longitude),
        "zipCode": zip_code,
    })
    return BRING_BASE_URL + "/offers/rest/v1/offers?" + params


def _detail_url(brochure_id: str, zip_code: str, latitude: float, longitude: float) -> str:
    params = urlencode({
        "brochureId": brochure_id,
        "lat": str(latitude),
        "long": str(longitude),
        "providerId": BRING_PROVIDER_ID,
        "zipCode": zip_code,
    })
    return (
        BRING_BASE_URL
        + "/offers/rest/v1/offers/brochures/"
        + quote(brochure_id, safe="")
        + "?"
        + params
    )


def fetch_current_bring_prospects(
    *,
    zip_code: str = DEFAULT_ZIP_CODE,
    latitude: float = DEFAULT_LATITUDE,
    longitude: float = DEFAULT_LONGITUDE,
    today: date | None = None,
) -> dict[str, dict[str, Any]]:
    """Return at most one current main brochure for each supported retailer.

    If credentials are absent the adapter is disabled and returns an empty map.
    When multiple current brochures exist, the one with the most readable
    pages wins; ties prefer the more recently started brochure.
    """

    config = BringApiConfig.from_env()
    if config is None:
        return {}

    payload = _record(_fetch_json(_list_url(zip_code, latitude, longitude), config))
    raw_offers = _array(payload.get("offers"))
    reference_day = today or local_today()
    candidates: dict[str, list[dict[str, Any]]] = {}

    for offer_value in raw_offers:
        offer = _record(offer_value)
        brochure_id = _first_text(offer.get("brn"), offer.get("id"))
        store = _canonical_store(_company_name(offer, {}))
        valid_from = _iso_date(offer.get("activeFrom") or offer.get("validFrom"))
        valid_until = _iso_date(offer.get("activeTo") or offer.get("validUntil"))
        if (
            store not in SUPPORTED_STORES
            or not brochure_id.startswith("brn:bring-de:offersbrochure:")
            or valid_from is None
            or valid_until is None
            or reference_day < valid_from
            or reference_day > valid_until
        ):
            continue
        candidates.setdefault(store, []).append(offer)

    result: dict[str, dict[str, Any]] = {}
    for store, store_offers in candidates.items():
        transformed: list[dict[str, Any]] = []
        for offer in store_offers:
            brochure_id = _first_text(offer.get("brn"), offer.get("id"))
            try:
                detail = _fetch_json(
                    _detail_url(brochure_id, zip_code, latitude, longitude),
                    config,
                )
                current = transform_bring_brochure(
                    offer,
                    detail,
                    today=reference_day,
                )
                if current is not None:
                    transformed.append(current)
            except Exception:
                continue

        if not transformed:
            continue
        transformed.sort(
            key=lambda item: (int(item.get("pageCount") or 0), item.get("validFrom") or ""),
            reverse=True,
        )
        result[store] = transformed[0]

    return result
