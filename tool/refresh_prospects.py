#!/usr/bin/env python3
import hashlib
import html
import json
import re
import sys
import time
from datetime import date, datetime, timedelta, timezone
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import quote, urljoin
from urllib.error import HTTPError
from urllib.request import Request, urlopen
from zoneinfo import ZoneInfo

OUTPUT = Path("assets/prospects/current.json")
UA = "SparzamApp/1.0 (+https://github.com/bndkxbqf2g-stack/SparzamApp)"
SOURCES = (
    ("aldi_sued", "ALDI Süd", "https://www.aldi-sued.de/", "aldi_api"),
    ("edeka_zellingen", "EDEKA", "https://www.edeka.de/maerkte/023738/", "edeka_api"),
    ("kaufland_grombuehl", "Kaufland", "https://filiale.kaufland.de/service/filiale.storeName%3DDE5103.html", "kaufland"),
    ("lidl_zellingen", "Lidl", "https://www.lidl.de/c/online-prospekte/s10005610/", "lidl"),
    ("penny_retzbach", "PENNY", "https://www.penny.de/markt/zellingen/230061/penny-retzbach-am-guessgraben-1", "penny"),
    ("netto_thuengersheim", "Netto", "https://www.netto-online.de/filialen/thuengersheim/am-strassacker-1/4371", "netto"),
    ("rewe_veitshoechheim", "REWE", "https://www.rewe.de/api/stationary-offers/461683", "rewe_api"),
)

class VisibleTextParser(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.lines, self.anchors = [], []
        self._skip, self._href, self._anchor_parts = 0, None, []

    def handle_starttag(self, tag, attrs):
        if tag in ("script", "style", "noscript"):
            self._skip += 1
            return
        if self._skip:
            return
        if tag == "a":
            self._href = dict(attrs).get("href")
            self._anchor_parts = []

    def handle_endtag(self, tag):
        if tag in ("script", "style", "noscript") and self._skip:
            self._skip -= 1
            return
        if self._skip:
            return
        if tag == "a" and self._href is not None:
            text = clean(" ".join(self._anchor_parts))
            if text:
                self.anchors.append((self._href, text))
            self._href, self._anchor_parts = None, []

    def handle_data(self, data):
        if self._skip:
            return
        value = clean(data)
        if not value:
            return
        self.lines.append(value)
        if self._href is not None:
            self._anchor_parts.append(value)

def clean(value):
    return re.sub(r"\s+", " ", html.unescape(value or "")).strip()

def fetch(url):
    headers = {
        "User-Agent": UA,
        "Accept-Language": "de-DE,de;q=0.9",
        "Accept": "text/html,application/xhtml+xml,application/json;q=0.9,*/*;q=0.8",
    }
    request = Request(url, headers=headers)
    try:
        with urlopen(request, timeout=30) as response:
            return response.read().decode("utf-8", errors="replace")
    except HTTPError as error:
        if error.code != 403:
            raise
        # Some public retailer pages reject non-browser user agents although
        # the same page is intended for normal browser access. Retry once with
        # a standard browser UA; no login, challenge or protected endpoint is bypassed.
        browser_headers = {
            **headers,
            "User-Agent": (
                "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
                "(KHTML, like Gecko) Chrome/140.0 Safari/537.36"
            ),
        }
        with urlopen(Request(url, headers=browser_headers), timeout=30) as response:
            return response.read().decode("utf-8", errors="replace")

def parsed(html_text):
    parser = VisibleTextParser()
    parser.feed(html_text)
    return parser

def money(value):
    return float(value.replace(",", "."))

def parse_date(value):
    try:
        return datetime.strptime(value, "%d.%m.%Y").date()
    except ValueError:
        return None

def current_week():
    today = date.today()
    monday = today - timedelta(days=today.weekday())
    return monday, monday + timedelta(days=5)

def stable_id(store, proof, text):
    raw = (store + "|" + proof + "|" + text).encode("utf-8")
    return hashlib.sha256(raw).hexdigest()[:20]

def record(store, label, offer_price, valid_from, valid_until, proof, original=None, image=None):
    result = {
        "sourceId": stable_id(store, proof, label + str(offer_price)),
        "productLabel": clean(label),
        "storeName": store,
        "offerPrice": round(float(offer_price), 2),
        "validFrom": valid_from.isoformat(),
        "validUntil": valid_until.isoformat(),
        "source": "retailerWebsite",
        "proofRef": proof,
    }
    if original is not None and original >= offer_price:
        result["originalPrice"] = round(float(original), 2)
    if image:
        result["imageUrl"] = image
    return result

ALDI_API_URL = "https://api.aldi-sued.de/v3/product-search"


def _aldi_api_url(promotion_day, offset=0):
    return (
        ALDI_API_URL
        + "?serviceType=walk-in"
        + "&servicePoint=B384"
        + "&currency=EUR"
        + "&limit=60"
        + "&offset=" + str(offset)
        + "&sort=relevance"
        + "&promotionKey=" + promotion_day.isoformat()
    )


def parse_aldi_api_page(json_text, promotion_day):
    payload = json.loads(json_text)
    if not isinstance(payload, dict):
        raise ValueError("ALDI API: ungültige Antwort")
    errors = payload.get("errors")
    if isinstance(errors, list) and errors:
        message = "; ".join(
            clean(str(item.get("message") or item.get("code") or "API-Fehler"))
            for item in errors
            if isinstance(item, dict)
        )
        raise ValueError("ALDI API: " + (message or "unbekannter Fehler"))

    data = payload.get("data", [])
    meta = payload.get("meta", {})
    pagination = meta.get("pagination", {}) if isinstance(meta, dict) else {}
    total_count = pagination.get("totalCount", 0) if isinstance(pagination, dict) else 0
    if not isinstance(data, list):
        raise ValueError("ALDI API: data ist keine Liste")

    valid_until = promotion_day + timedelta(
        days=(5 - promotion_day.weekday()) % 7,
    )
    offers = []
    for item in data:
        if not isinstance(item, dict):
            continue
        price = item.get("price", {})
        if not isinstance(price, dict):
            continue
        cents = price.get("amountRelevant")
        if not isinstance(cents, (int, float)) or cents <= 0:
            cents = price.get("amount")
        if not isinstance(cents, (int, float)) or cents <= 0:
            continue

        brand = clean(str(item.get("brandName") or ""))
        name = clean(str(item.get("name") or ""))
        label = clean(" ".join(value for value in (brand, name) if value))
        if len(label) < 2:
            continue

        regular = None
        was_price = price.get("wasPriceDisplay")
        if isinstance(was_price, str):
            match = re.search(r"(\d+[,.]\d{2})", was_price)
            if match:
                regular = money(match.group(1))

        sku = clean(str(item.get("sku") or ""))
        slug = clean(str(item.get("urlSlugText") or "")).strip("/")
        if slug and sku:
            proof = "https://www.aldi-sued.de/produkt/" + slug + "-" + sku
        else:
            proof = "https://www.aldi-sued.de/angebote/" + promotion_day.isoformat()

        offers.append(record(
            "ALDI Süd",
            label,
            float(cents) / 100,
            promotion_day,
            valid_until,
            proof,
            regular,
        ))

    return dedupe(offers), int(total_count or len(data))


def fetch_aldi_api_offers():
    today = date.today()
    start = today - timedelta(days=today.weekday())
    end = start + timedelta(days=12)
    all_offers = []
    successful_days = 0

    day = start
    while day <= end:
        offset = 0
        day_found = False
        while True:
            try:
                body = fetch(_aldi_api_url(day, offset))
                page_offers, total_count = parse_aldi_api_page(body, day)
            except Exception:
                break
            day_found = True
            all_offers.extend(page_offers)
            offset += 60
            if total_count <= offset:
                break
            time.sleep(0.4)
        if day_found:
            successful_days += 1
        day += timedelta(days=1)
        time.sleep(0.4)

    if successful_days == 0 or not all_offers:
        raise ValueError("ALDI API lieferte keine verwertbaren Aktionstage")
    return dedupe(all_offers), []


def parse_aldi(html_text, base_url):
    page = parsed(html_text)
    default_from, _ = current_week()
    offers = []
    price_re = re.compile(r"(\d{1,3}[,.]\d{2})\s*€")
    for href, text in page.anchors:
        lower = text.lower()
        if "€" not in text or ("aktion" not in lower and "spare" not in lower):
            continue
        prices = [money(value) for value in price_re.findall(text)]
        if not prices:
            continue
        original = None
        if "spare" in lower and len(prices) >= 2:
            offer_price, original = prices[-2], prices[-1]
        else:
            offer_price = prices[-1]
        explicit = re.search(r"Verfügbar (?:ab|seit)\s+(\d{2}\.\d{2}\.\d{4})", text)
        valid_from = parse_date(explicit.group(1)) if explicit else default_from
        valid_from = valid_from or default_from
        valid_until = valid_from + timedelta(days=max(0, 5 - valid_from.weekday()))
        proof = urljoin(base_url, href)
        label = re.sub(r"Verfügbar (?:ab|seit)\s+\d{2}\.\d{2}\.\d{4}", "", text)
        label = re.sub(r"\bKühlung\b|\bAktion\b", " ", label, flags=re.I)
        label = re.sub(r"\s+Spare\s+\d+\s*%.*$", "", label, flags=re.I)
        if "spare" not in lower:
            label = price_re.sub("", label)
        label = clean(label)
        if len(label) >= 3:
            offers.append(record("ALDI Süd", label, offer_price, valid_from, valid_until, proof, original))
    return dedupe(offers), []

EDEKA_API_URL = "https://www.edeka.de/eh/service/eh/offers"


def _edeka_api_url(base_url):
    match = re.search(r"/maerkte/(\\d+)/", base_url)
    if match is None:
        raise ValueError("EDEKA Markt-ID fehlt in der Markt-URL")
    return EDEKA_API_URL + "?marketId=" + quote(match.group(1)) + "&limit=99999"


def _json_money(value):
    if isinstance(value, (int, float)):
        return float(value)
    if not isinstance(value, str):
        return None
    match = re.search(r"(\\d+[,.]\\d{1,2})", value)
    return money(match.group(1)) if match else None


def _edeka_date(value):
    if isinstance(value, (int, float)):
        timestamp = float(value)
        if timestamp > 10_000_000_000:
            timestamp /= 1000.0
        try:
            return datetime.fromtimestamp(
                timestamp,
                tz=ZoneInfo("Europe/Berlin"),
            ).date()
        except (OverflowError, OSError, ValueError):
            return None
    if not isinstance(value, str):
        return None
    raw = value.strip()
    if not raw:
        return None
    for parser in (
        lambda text: date.fromisoformat(text[:10]),
        lambda text: datetime.strptime(text, "%d.%m.%Y").date(),
    ):
        try:
            return parser(raw)
        except ValueError:
            pass
    return None


def parse_edeka_api(json_text, base_url):
    payload = json.loads(json_text)
    if isinstance(payload, dict):
        docs = payload.get("docs", [])
        root = payload
    elif isinstance(payload, list):
        docs = payload
        root = {}
    else:
        raise ValueError("EDEKA API: ungültige Antwort")
    if not isinstance(docs, list):
        raise ValueError("EDEKA API: docs ist keine Liste")

    offers = []
    for index, doc in enumerate(docs):
        if not isinstance(doc, dict):
            continue
        label = clean(str(doc.get("titel") or ""))
        sale = _json_money(doc.get("preis"))
        if len(label) < 2 or sale is None or sale <= 0:
            continue

        valid_from = _edeka_date(
            doc.get("gueltig_von")
            or doc.get("validFrom")
            or root.get("gueltig_von")
            or root.get("validFrom")
        )
        valid_until = _edeka_date(
            doc.get("gueltig_bis")
            or doc.get("validUntil")
            or root.get("gueltig_bis")
            or root.get("validUntil")
        )
        if valid_from is None and valid_until is not None:
            valid_from = valid_until - timedelta(days=valid_until.weekday())
        if valid_until is None and valid_from is not None:
            valid_until = valid_from + timedelta(days=max(0, 5 - valid_from.weekday()))
        if valid_from is None or valid_until is None:
            valid_from, valid_until = current_week()

        regular = None
        for key in (
            "streichpreis",
            "originalPrice",
            "regularPrice",
            "alterPreis",
            "oldPrice",
        ):
            candidate = _json_money(doc.get(key))
            if candidate is not None and candidate >= sale:
                regular = candidate
                break

        raw_id = clean(str(doc.get("angebotid") or doc.get("externeid") or index))
        proof = base_url + "#offer-" + raw_id
        image = clean(str(
            doc.get("bild_app")
            or doc.get("bild_web130")
            or doc.get("bild_web90")
            or ""
        ))
        offers.append(record(
            "EDEKA",
            label,
            sale,
            valid_from,
            valid_until,
            proof,
            regular,
            image,
        ))
    return dedupe(offers), []


def parse_edeka(html_text, base_url):
    # EDEKA currently embeds part of the offer markup inside script/template
    # payloads. HTMLParser intentionally skips scripts, so scan a tag-stripped
    # copy of the raw response as the canonical fallback.
    raw_text = clean(re.sub(r"<[^>]+>", " ", html_text))
    valid_from, valid_until = current_week()

    validity = re.search(
        r"Gültig vom\s+(\d{2}\.\d{2}\.\d{4})\s+bis zum\s+(\d{2}\.\d{2}\.\d{4})",
        raw_text,
    )
    if validity:
        valid_from = parse_date(validity.group(1)) or valid_from
        valid_until = parse_date(validity.group(2)) or valid_until
    else:
        legal_end = re.search(
            r"Alle Angebote gültig bis Samstag,\s*den\s+(\d{2}\.\d{2}\.\d{4})",
            raw_text,
        )
        if legal_end:
            parsed_end = parse_date(legal_end.group(1))
            if parsed_end is not None:
                valid_until = parsed_end
                valid_from = parsed_end - timedelta(days=parsed_end.weekday())

    markers = list(re.finditer(r"Angebot:\s*", raw_text))
    candidates = {}
    for index, marker in enumerate(markers):
        end = markers[index + 1].start() if index + 1 < len(markers) else len(raw_text)
        segment = raw_text[marker.end():end]
        fixed = re.search(r"Festpreis von\s+(\d+[,.]\d{2})\s*€", segment)
        if fixed is None:
            continue

        price = money(fixed.group(1))
        before_price = segment[:fixed.start()].strip()
        before_price = re.sub(r"\s+\d+[,.]\d{2}\s*$", "", before_price)
        before_price = re.sub(
            r"\s+\d+[,.]\d{2}\s+App\s+App Preis von\s+"
            r"\d+[,.]\d{2}\s*€\s*$",
            "",
            before_price,
            flags=re.I,
        )

        explicit_start = re.search(
            r"\bGültig ab\s+(\d{2}\.\d{2}\.\d{4})",
            before_price,
        )
        start = valid_from
        label_text = before_price
        has_specific_start = False
        if explicit_start:
            start = parse_date(explicit_start.group(1)) or start
            label_text = before_price[:explicit_start.start()]
            has_specific_start = True

        # Some card variants expose the start date inside the accessible label
        # as "... ab 24.09." instead of a separate "Gültig ab" node.
        short_start = re.search(
            r"\s+ab\s+(\d{2})\.(\d{2})\.\s*$",
            label_text,
            flags=re.I,
        )
        if short_start:
            day = int(short_start.group(1))
            month = int(short_start.group(2))
            try:
                start = date(valid_until.year, month, day)
                has_specific_start = True
            except ValueError:
                pass
            label_text = label_text[:short_start.start()]

        # PAYBACK / points text is a condition, not part of the product name.
        label_text = re.split(
            r"\s+\d+\s+Extra\s+°?P\b|\s+Mit PAYBACK\b",
            label_text,
            maxsplit=1,
            flags=re.I,
        )[0]
        label = clean(label_text)
        if len(label) < 2:
            continue

        proof = base_url + "#offer-" + stable_id("EDEKA", base_url, label)
        item = record("EDEKA", label, price, start, valid_until, proof)
        key = (label.lower(), price, valid_until.isoformat())
        previous = candidates.get(key)
        if previous is None or has_specific_start:
            candidates[key] = item

    return list(candidates.values()), []

def parse_kaufland(html_text, base_url):
    page = parsed(html_text)
    whole = "\n".join(page.lines)
    validity = re.search(r"Gültig vom\s+(\d{2}\.\d{2}\.\d{4})\s+bis\s+(?:zum\s+)?(\d{2}\.\d{2}\.\d{4})", whole)
    valid_from, valid_until = current_week()
    if validity:
        valid_from = parse_date(validity.group(1)) or valid_from
        valid_until = parse_date(validity.group(2)) or valid_until
    offers = []
    percent = re.compile(r"^(.*?)-\d{1,2}%\s*(\d+[,.]\d{2})\s+(\d+[,.]\d{2})$")
    only = re.compile(r"^(.*?)\bnur\s+(\d+[,.]\d{2})$", re.I)
    for href, text in page.anchors:
        # XTRA/App prices are conditional and must not become universally
        # routable until loyalty-card conditions are modelled explicitly.
        if "kaufland card xtra" in text.lower():
            continue
        match = percent.match(text)
        if match:
            label, sale, regular = clean(match.group(1)), money(match.group(2)), money(match.group(3))
            if label:
                offers.append(record("Kaufland", label, sale, valid_from, valid_until, urljoin(base_url, href), regular))
            continue
        match = only.match(text)
        if match:
            label, sale = clean(match.group(1)), money(match.group(2))
            if label:
                offers.append(record("Kaufland", label, sale, valid_from, valid_until, urljoin(base_url, href)))
    return dedupe(offers), []

def parse_lidl(html_text, base_url):
    page = parsed(html_text)
    prospects = []
    seen = set()
    for href, text in page.anchors:
        absolute = urljoin(base_url, href)
        if "/prospekte/" not in absolute and "/l/prospekte/" not in absolute:
            continue
        if absolute in seen:
            continue
        seen.add(absolute)

        item = {"title": text[:160], "url": absolute}
        match = re.search(r"/l/prospekte/([^/]+)/ar/(\d+)", absolute)
        if match and "aktionsprospekt" in text.lower():
            slug, region = match.group(1), match.group(2)
            api_url = (
                "https://endpoints.leaflets.schwarz/v4/flyer"
                "?version=4"
                "&client=lidl"
                "&flyer_identifier=" + quote(slug) +
                "&region_id=" + region +
                "&region_code=" + region
            )
            try:
                payload = json.loads(fetch(api_url))
                flyer = payload.get("flyer", payload)
                products = flyer.get("products", []) if isinstance(flyer, dict) else []
                pages = flyer.get("pages", []) if isinstance(flyer, dict) else []
                item["apiUrl"] = api_url
                item["apiTopKeys"] = sorted(payload.keys()) if isinstance(payload, dict) else []
                item["flyerKeys"] = sorted(flyer.keys()) if isinstance(flyer, dict) else []
                item["productCount"] = len(products) if isinstance(products, list) else 0
                item["pageCount"] = len(pages) if isinstance(pages, list) else 0
                item["offerStartDate"] = flyer.get("offerStartDate") if isinstance(flyer, dict) else None
                item["offerEndDate"] = flyer.get("offerEndDate") if isinstance(flyer, dict) else None
                item["pdfUrl"] = flyer.get("pdfUrl") if isinstance(flyer, dict) else None
                if isinstance(products, list) and products and isinstance(products[0], dict):
                    sample = products[0]
                    item["productKeys"] = sorted(sample.keys())
                    item["productSample"] = {
                        key: sample.get(key)
                        for key in sorted(sample.keys())
                        if key in {
                            "id", "name", "title", "price", "oldPrice",
                            "priceOld", "offerPrice", "regularPrice",
                            "validFrom", "validTo", "image", "imageUrl",
                            "description", "brand"
                        }
                    }
                if isinstance(pages, list) and pages and isinstance(pages[0], dict):
                    item["pageKeys"] = sorted(pages[0].keys())
                    if not prospects:
                        samples = []
                        for page_data in pages[:5]:
                            if not isinstance(page_data, dict):
                                continue
                            samples.append({
                                "number": page_data.get("number"),
                                "altText": clean(str(page_data.get("altText") or ""))[:320],
                                "keyWords": clean(str(page_data.get("keyWords") or ""))[:900],
                                "image": page_data.get("image"),
                                "zoom": page_data.get("zoom"),
                            })
                        item["pageSamples"] = samples
            except Exception as error:
                item["apiError"] = clean(str(error))[:240]
        prospects.append(item)

    return [], prospects[:8]


def parse_penny(html_text, base_url):
    page = parsed(html_text)
    valid_from, valid_until = current_week()
    offers = []
    price_re = re.compile(r"(?:Streichpreis|UVP)\s+(\d+[,.]\d{2})\s*€.*?Angebotspreis\s+(\d+[,.]\d{2})\s*€", re.I)
    sale_re = re.compile(r"Angebotspreis\s+(\d+[,.]\d{2})\s*€", re.I)
    for href, text in page.anchors:
        if "angebotspreis" not in text.lower():
            continue
        sale_match = sale_re.search(text)
        if sale_match is None:
            continue
        sale = money(sale_match.group(1))
        original = None
        regular_match = price_re.search(text)
        if regular_match:
            original = money(regular_match.group(1))
        tail = text[sale_match.end():]
        tail = re.sub(r"^\s*\d+[,.]\d{2}\s*", "", tail)
        tail = re.sub(r"^\s*(?:Aktion|-\d{1,2}%[^\w]*)\s*", "", tail, flags=re.I)
        label = re.split(r"\*?\s+je\s+", tail, maxsplit=1, flags=re.I)[0]
        label = clean(label.replace("*", " "))
        if len(label) < 2:
            continue
        offers.append(record(
            "PENNY", label, sale, valid_from, valid_until,
            urljoin(base_url, href), original,
        ))
    return dedupe(offers), []


def _netto_money(value):
    normalized = value.replace("–", "00").replace("-", "00")
    if normalized.endswith("."):
        normalized += "00"
    return money(normalized)


def parse_netto(html_text, base_url):
    page = parsed(html_text)
    whole = "\n".join(page.lines)
    validity = re.search(
        r"gültig von Montag,\s*(\d{2}\.\d{2}\.\d{2,4})\s*-\s*Samstag,\s*(\d{2}\.\d{2}\.\d{2,4})",
        whole,
        flags=re.I,
    )
    valid_from, valid_until = current_week()
    if validity:
        for index, value in enumerate(validity.groups()):
            fmt = "%d.%m.%y" if len(value.rsplit(".", 1)[-1]) == 2 else "%d.%m.%Y"
            parsed_value = datetime.strptime(value, fmt).date()
            if index == 0:
                valid_from = parsed_value
            else:
                valid_until = parsed_value

    offers = []
    trailing = re.compile(
        r"^(.*?)(?:-\d{1,2}\s*%\s*)?(?:statt|UVP)\s+"
        r"(\d+[,.]\d{2})\s+(\d+(?:[,.]\d{2}|[.–-]))\*?$",
        re.I,
    )
    for href, text in page.anchors:
        match = trailing.match(clean(text))
        if match is None:
            continue
        label = clean(match.group(1))
        regular = money(match.group(2))
        sale = _netto_money(match.group(3))
        if len(label) < 2:
            continue
        offers.append(record(
            "Netto", label, sale, valid_from, valid_until,
            urljoin(base_url, href), regular,
        ))
    return dedupe(offers), []


def parse_rewe(html_text, base_url):
    raw_text = clean(re.sub(r"<[^>]+>", " ", html_text))
    valid_from, valid_until = current_week()
    validity = re.search(
        r"(\d{1,2}\.\d{1,2}\.)\s*bis\s*(\d{1,2}\.\d{1,2}\.)",
        raw_text,
        flags=re.I,
    )
    if validity:
        year = date.today().year
        start = datetime.strptime(validity.group(1) + str(year), "%d.%m.%Y").date()
        end = datetime.strptime(validity.group(2) + str(year), "%d.%m.%Y").date()
        valid_from, valid_until = start, end

    offers = []
    headings = list(re.finditer(
        r"<h3\b[^>]*>(.*?)</h3>",
        html_text,
        flags=re.I | re.S,
    ))
    for index, heading in enumerate(headings):
        label = clean(re.sub(r"<[^>]+>", " ", heading.group(1)))
        if not label or label.lower().startswith(("gültig", "der angebots", "top-")):
            continue
        end = headings[index + 1].start() if index + 1 < len(headings) else min(
            len(html_text), heading.end() + 2400,
        )
        block = clean(re.sub(r"<[^>]+>", " ", html_text[heading.end():end]))
        if "aktion" not in block.lower() and "knaller" not in block.lower():
            continue
        price = re.search(r"\b(\d+[,.]\d{2})\s*€", block)
        if price is None:
            continue
        proof = base_url + "#offer-" + stable_id("REWE", base_url, label)
        offers.append(record(
            "REWE", label, money(price.group(1)), valid_from, valid_until, proof,
        ))
    return dedupe(offers), []



def _rewe_price(value):
    if not isinstance(value, str):
        return None
    match = re.search(r"(\d+[,.]\d{2})", value)
    return money(match.group(1)) if match else None


def parse_rewe_api(json_text, base_url):
    payload = json.loads(json_text)
    data = payload.get("data", {}) if isinstance(payload, dict) else {}
    weeks = data.get("offers", {}) if isinstance(data, dict) else {}
    current = weeks.get("current", {}) if isinstance(weeks, dict) else {}
    if not isinstance(current, dict) or not current.get("available", False):
        return [], []

    valid_from = date.fromisoformat(current["fromDate"])
    valid_until = date.fromisoformat(current["untilDate"])
    offers = []
    for category in current.get("categories", []):
        if not isinstance(category, dict):
            continue
        for item in category.get("offers", []):
            if not isinstance(item, dict):
                continue
            label = clean(str(item.get("title") or ""))
            price_data = item.get("priceData", {})
            if not isinstance(price_data, dict):
                continue
            sale = _rewe_price(price_data.get("price"))
            if not label or sale is None:
                continue
            regular = _rewe_price(price_data.get("regularPrice"))
            if regular is not None and regular < sale:
                regular = None
            raw_values = item.get("rawValues", {})
            article = raw_values.get("nan") if isinstance(raw_values, dict) else None
            proof = (
                "https://www.rewe.de/angebote/veitshoechheim/461683/"
                "rewe-markt-pont-leveque-allee-1/"
            )
            if article:
                proof += "#article-" + str(article)
            offers.append(record(
                "REWE", label, sale, valid_from, valid_until, proof, regular,
            ))
    return dedupe(offers), []


def dedupe(offers):
    unique = {}
    for item in offers:
        key = (item["storeName"], clean(item["productLabel"]).lower(), item["validFrom"], item["validUntil"], item["offerPrice"])
        unique[key] = item
    return list(unique.values())

PARSERS = {
    "aldi": parse_aldi,
    "aldi_api": parse_aldi_api_page,
    "edeka": parse_edeka,
    "edeka_api": parse_edeka_api,
    "kaufland": parse_kaufland,
    "lidl": parse_lidl,
    "penny": parse_penny,
    "netto": parse_netto,
    "rewe": parse_rewe,
    "rewe_api": parse_rewe_api,
}

def load_previous():
    if not OUTPUT.exists():
        return {"sources": [], "offers": []}
    try:
        return json.loads(OUTPUT.read_text(encoding="utf-8"))
    except Exception:
        return {"sources": [], "offers": []}

def active_previous(previous, store):
    today = date.today().isoformat()
    return [item for item in previous.get("offers", []) if item.get("storeName") == store and item.get("validUntil", "") >= today]

def main():
    previous = load_previous()
    all_offers, sources = [], []
    for source_id, store, url, parser_name in SOURCES:
        try:
            source_mode = parser_name
            if parser_name == "aldi_api":
                try:
                    offers, prospects = fetch_aldi_api_offers()
                    source_mode = "structured_api"
                    body = ""
                except Exception:
                    body = fetch(url)
                    offers, prospects = parse_aldi(body, url)
                    source_mode = "website_fallback"
            elif parser_name == "edeka_api":
                try:
                    body = fetch(_edeka_api_url(url))
                    offers, prospects = parse_edeka_api(body, url)
                    source_mode = "structured_api"
                    if not offers:
                        raise ValueError("EDEKA API lieferte keine Angebote")
                except Exception:
                    body = fetch(url)
                    offers, prospects = parse_edeka(body, url)
                    source_mode = "website_fallback"
            else:
                body = fetch(url)
                offers, prospects = PARSERS[parser_name](body, url)
            metadata_only = parser_name == "lidl"
            if not offers and not metadata_only:
                lower_body = body.lower()
                marker = lower_body.find("festpreis")
                snippet = ""
                if marker >= 0:
                    before = clean(re.sub(r"<[^>]+>", " ", body[max(0, marker - 1800):marker]))
                    after = clean(re.sub(r"<[^>]+>", " ", body[marker:marker + 220]))
                    snippet = before[-150:] + " || " + after[:70]
                diagnostics = "edeka-sample=" + snippet[:220]
                raise ValueError("keine sicher extrahierbaren Angebote gefunden; " + diagnostics)
            all_offers.extend(offers)
            sources.append({"id": source_id, "storeName": store, "url": url, "status": "metadata_only" if metadata_only else "ok", "recordCount": len(offers), "mode": source_mode, "prospects": prospects})
        except Exception as error:
            kept = active_previous(previous, store)
            all_offers.extend(kept)
            sources.append({"id": source_id, "storeName": store, "url": url, "status": "error", "recordCount": len(kept), "error": clean(str(error))[:240]})
    payload = {"schemaVersion": 1, "generatedAt": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"), "sources": sources, "offers": dedupe(all_offers)}
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("Prospektfeed:", len(payload["offers"]), "Angebote")

if __name__ == "__main__":
    sys.exit(main())
