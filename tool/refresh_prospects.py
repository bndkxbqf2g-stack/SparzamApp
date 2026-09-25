#!/usr/bin/env python3
import hashlib
import html
import json
import re
import sys
from datetime import date, datetime, timedelta, timezone
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import urljoin
from urllib.request import Request, urlopen

OUTPUT = Path("assets/prospects/current.json")
UA = "SparzamApp/1.0 (+https://github.com/bndkxbqf2g-stack/SparzamApp)"
SOURCES = (
    ("aldi_sued", "ALDI Süd", "https://www.aldi-sued.de/", "aldi"),
    ("edeka_zellingen", "EDEKA", "https://www.edeka.de/maerkte/023738/", "edeka"),
    ("kaufland_grombuehl", "Kaufland", "https://filiale.kaufland.de/service/filiale.storeName%3DDE5103.html", "kaufland"),
    ("lidl_zellingen", "Lidl", "https://www.lidl.de/s/de-DE/filialen/zellingen/am-guessgraben-2/", "lidl"),
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
    request = Request(url, headers={"User-Agent": UA, "Accept-Language": "de-DE,de;q=0.9"})
    with urlopen(request, timeout=30) as response:
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

def record(store, label, offer_price, valid_from, valid_until, proof, original=None):
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
    return result

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
        if explicit_start:
            start = parse_date(explicit_start.group(1)) or start
            label_text = before_price[:explicit_start.start()]

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
        if previous is None or explicit_start is not None:
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
    for href, text in page.anchors:
        absolute = urljoin(base_url, href)
        if "/prospekte/" in absolute or "/l/prospekte/" in absolute:
            prospects.append({"title": text[:160], "url": absolute})
    unique = {item["url"]: item for item in prospects}
    return [], list(unique.values())[:8]

def dedupe(offers):
    unique = {}
    for item in offers:
        key = (item["storeName"], clean(item["productLabel"]).lower(), item["validFrom"], item["validUntil"], item["offerPrice"])
        unique[key] = item
    return list(unique.values())

PARSERS = {"aldi": parse_aldi, "edeka": parse_edeka, "kaufland": parse_kaufland, "lidl": parse_lidl}

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
            sources.append({"id": source_id, "storeName": store, "url": url, "status": "metadata_only" if metadata_only else "ok", "recordCount": len(offers), "prospects": prospects})
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
