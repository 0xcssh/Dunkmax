#!/usr/bin/env python3
"""Create the Dunk It Pro subscriptions in App Store Connect.

Runs in CI (.github/workflows/asc-subscriptions.yml). Idempotent: anything
that already exists (group, product, localization, availability, price,
trial) is left alone, so re-running only fills gaps.

What it builds: one group "Dunk It Pro", two auto-renewable products,

  com.awdia.dunkmax.pro.yearly   1 year   3-day free trial
  com.awdia.dunkmax.pro.weekly   1 week   3-day free trial

Apple grants an intro offer once per group per customer; the paywall asks
StoreKit for eligibility and only promises the trial to the eligible, so no
separate no-trial products are needed (a .notrial pair existed briefly and
was deleted, owner's decision 2026-10-06 — those ids can never be reused).

Prices (owner's call, 2026-10-06: "like the competitor"): the US price is
set and every other territory takes Apple's equalized equivalent, except the
euro countries, which get the round euro price below.

Env: ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_P8 (PEM), BUNDLE_ID, DRY_RUN.
"""
import hashlib
import os
import pathlib
import sys
import time

import jwt
import requests

KEY_ID = os.environ["ASC_KEY_ID"]
ISSUER = os.environ["ASC_ISSUER_ID"]
P8 = os.environ["ASC_KEY_P8"]
BUNDLE_ID = os.environ.get("BUNDLE_ID", "com.awdia.dunkmax")
DRY = os.environ.get("DRY_RUN", "0") == "1"
BASE = "https://api.appstoreconnect.apple.com"

GROUP = "Dunk It Pro"
# The App Review screenshot every subscription needs before it leaves
# MISSING_METADATA: the real paywall, rendered by
# tool/store_screenshots/capture_test.dart at the 6.9" size.
REVIEW_SHOT = pathlib.Path(__file__).resolve().parent.parent / "tool/store_screenshots/assets/review_paywall.png"
EURO = ["AUT", "BEL", "CYP", "DEU", "ESP", "EST", "FIN", "FRA", "GRC", "HRV",
        "IRL", "ITA", "LTU", "LUX", "LVA", "MLT", "NLD", "PRT", "SVK", "SVN"]

# product id, reference name, period, group level, trial, USD, EUR
PRODUCTS = [
    ("com.awdia.dunkmax.pro.yearly", "Pro Yearly (trial)", "ONE_YEAR", 1, True, "59.99", "69.99"),
    ("com.awdia.dunkmax.pro.weekly", "Pro Weekly (trial)", "ONE_WEEK", 2, True, "7.99", "8.99"),
]

# What the App Store shows in the subscription sheet and in Settings.
# Display name ≤ 30, description ≤ 45.
GROUP_NAMES = {"en-US": "Dunk It Pro", "fr-FR": "Dunk It Pro", "es-MX": "Dunk It Pro",
               "es-ES": "Dunk It Pro", "pt-BR": "Dunk It Pro", "de-DE": "Dunk It Pro", "it": "Dunk It Pro"}
SUB_TEXT = {
    "ONE_YEAR": {
        "en-US": ("Dunk It Pro – Yearly", "Full plan, unlimited jump analysis"),
        "fr-FR": ("Dunk It Pro – Annuel", "Plan complet, analyses illimitées"),
        "es-MX": ("Dunk It Pro – Anual", "Plan completo y análisis ilimitados"),
        "es-ES": ("Dunk It Pro – Anual", "Plan completo y análisis ilimitados"),
        "pt-BR": ("Dunk It Pro – Anual", "Plano completo e análises ilimitadas"),
        "de-DE": ("Dunk It Pro – Jährlich", "Voller Plan, unbegrenzte Analysen"),
        "it": ("Dunk It Pro – Annuale", "Piano completo, analisi illimitate"),
    },
    "ONE_WEEK": {
        "en-US": ("Dunk It Pro – Weekly", "Full plan, unlimited jump analysis"),
        "fr-FR": ("Dunk It Pro – Hebdo", "Plan complet, analyses illimitées"),
        "es-MX": ("Dunk It Pro – Semanal", "Plan completo y análisis ilimitados"),
        "es-ES": ("Dunk It Pro – Semanal", "Plan completo y análisis ilimitados"),
        "pt-BR": ("Dunk It Pro – Semanal", "Plano completo e análises ilimitadas"),
        "de-DE": ("Dunk It Pro – Wöchentlich", "Voller Plan, unbegrenzte Analysen"),
        "it": ("Dunk It Pro – Settimanale", "Piano completo, analisi illimitate"),
    },
}


def token():
    now = int(time.time())
    return jwt.encode({"iss": ISSUER, "iat": now, "exp": now + 1100, "aud": "appstoreconnect-v1"},
                      P8, algorithm="ES256", headers={"kid": KEY_ID})


def call(method, path, body=None, params=None):
    url = path if path.startswith("http") else BASE + path
    for attempt in range(5):
        r = requests.request(method, url, json=body, params=params,
                             headers={"Authorization": f"Bearer {token()}"}, timeout=120)
        if r.status_code == 429:
            time.sleep(10 * (attempt + 1))
            continue
        if r.status_code >= 400:
            raise RuntimeError(f"{method} {path} -> {r.status_code}: {r.text[:900]}")
        return r.json() if r.text else {}
    raise RuntimeError(f"{method} {path}: rate limited")


def get_all(path, params=None):
    out, included = [], []
    page = call("GET", path, params=dict(params or {}, limit=200))
    while True:
        out += page.get("data", [])
        included += page.get("included", [])
        nxt = page.get("links", {}).get("next")
        if not nxt:
            return out, included
        page = call("GET", nxt)


def post(kind, attributes, relationships, label):
    print(f"    + {label}")
    if DRY:
        return {"id": f"dry-{kind}"}
    rels = {k: {"data": v} for k, v in relationships.items()}
    return call("POST", f"/v1/{kind}", {"data": {"type": kind, "attributes": attributes,
                                                 "relationships": rels}})["data"]


def ref(kind, id_):
    return {"type": kind, "id": id_}


def price_point(sub_id, territory, price):
    points, _ = get_all(f"/v1/subscriptions/{sub_id}/pricePoints",
                        {"filter[territory]": territory})
    for p in points:
        if p["attributes"]["customerPrice"] == price:
            return p
    sys.exit(f"no {territory} price point at {price}")


def main():
    apps = call("GET", "/v1/apps", params={"filter[bundleId]": BUNDLE_ID})["data"]
    if not apps:
        sys.exit(f"no app with bundle id {BUNDLE_ID}")
    app_id = apps[0]["id"]
    print(f"app {app_id}")

    groups, _ = get_all(f"/v1/apps/{app_id}/subscriptionGroups")
    group = next((g for g in groups if g["attributes"]["referenceName"] == GROUP), None)
    if group is None:
        print(f"group {GROUP}: CREATE")
        group = post("subscriptionGroups", {"referenceName": GROUP}, {"app": ref("apps", app_id)}, GROUP)
    else:
        print(f"group {GROUP}: exists ({group['id']})")
    have_g = set()
    if not DRY or not group["id"].startswith("dry"):
        locs, _ = get_all(f"/v1/subscriptionGroups/{group['id']}/subscriptionGroupLocalizations")
        have_g = {l["attributes"]["locale"] for l in locs}
    for locale, name in GROUP_NAMES.items():
        if locale not in have_g:
            post("subscriptionGroupLocalizations", {"locale": locale, "name": name},
                 {"subscriptionGroup": ref("subscriptionGroups", group["id"])}, f"group name {locale}")

    territories = [t["id"] for t in get_all("/v1/territories")[0]]
    print(f"{len(territories)} territories")

    existing = {}
    if not group["id"].startswith("dry"):
        subs, _ = get_all(f"/v1/subscriptionGroups/{group['id']}/subscriptions")
        existing = {s["attributes"]["productId"]: s for s in subs}

    for product_id, ref_name, period, level, trial, usd, eur in PRODUCTS:
        print(f"{product_id}")
        sub = existing.get(product_id)
        if sub is None:
            sub = post("subscriptions", {"name": ref_name, "productId": product_id,
                                         "subscriptionPeriod": period, "groupLevel": level,
                                         "familySharable": False},
                       {"group": ref("subscriptionGroups", group["id"])}, "subscription")
        if DRY and sub["id"].startswith("dry"):
            print(f"    + localizations {sorted(SUB_TEXT[period])}, availability, "
                  f"prices {usd} USD / {eur} EUR" + (", 3-day free trial" if trial else ""))
            continue
        sid = sub["id"]

        locs, _ = get_all(f"/v1/subscriptions/{sid}/subscriptionLocalizations")
        have = {l["attributes"]["locale"] for l in locs}
        for locale, (name, desc) in SUB_TEXT[period].items():
            if locale not in have:
                post("subscriptionLocalizations", {"locale": locale, "name": name, "description": desc},
                     {"subscription": ref("subscriptions", sid)}, f"localization {locale}")

        try:
            avail = call("GET", f"/v1/subscriptions/{sid}/subscriptionAvailability")["data"]
        except RuntimeError:
            avail = None
        if not avail:
            post("subscriptionAvailabilities", {"availableInNewTerritories": True},
                 {"subscription": ref("subscriptions", sid),
                  "availableTerritories": [ref("territories", t) for t in territories]},
                 f"available in {len(territories)} territories")

        prices, inc = get_all(f"/v1/subscriptions/{sid}/prices", {"include": "territory"})
        priced = {p["relationships"]["territory"]["data"]["id"] for p in prices
                  if p.get("relationships", {}).get("territory", {}).get("data")}
        if len(priced) < len(territories):
            base = price_point(sid, "USA", usd)
            eq, _ = get_all(f"/v1/subscriptionPricePoints/{base['id']}/equalizations",
                            {"include": "territory"})
            target = {"USA": base["id"]}
            for p in eq:
                t = p["relationships"]["territory"]["data"]["id"]
                target[t] = p["id"]
            for t in EURO:
                if t in target:
                    target[t] = price_point(sid, t, eur)["id"]
            todo = [t for t in target if t not in priced]
            print(f"    + prices for {len(todo)} territories ({usd} USD, {eur} EUR)")
            for t in todo:
                if not DRY:
                    call("POST", "/v1/subscriptionPrices", {"data": {
                        "type": "subscriptionPrices",
                        "attributes": {"preserveCurrentPrice": False},
                        "relationships": {
                            "subscription": {"data": ref("subscriptions", sid)},
                            "subscriptionPricePoint": {"data": ref("subscriptionPricePoints", target[t])},
                        }}})

        try:
            shot = call("GET", f"/v1/subscriptions/{sid}/appStoreReviewScreenshot").get("data")
        except RuntimeError:
            shot = None
        if not shot:
            data = REVIEW_SHOT.read_bytes()
            print(f"    + review screenshot ({len(data)} bytes)")
            if not DRY:
                made = call("POST", "/v1/subscriptionAppStoreReviewScreenshots", {"data": {
                    "type": "subscriptionAppStoreReviewScreenshots",
                    "attributes": {"fileName": REVIEW_SHOT.name, "fileSize": len(data)},
                    "relationships": {"subscription": {"data": ref("subscriptions", sid)}}}})["data"]
                for op in made["attributes"]["uploadOperations"]:
                    chunk = data[op["offset"]:op["offset"] + op["length"]]
                    headers = {h["name"]: h["value"] for h in op.get("requestHeaders", [])}
                    requests.request(op["method"], op["url"], data=chunk, headers=headers,
                                     timeout=300).raise_for_status()
                call("PATCH", f"/v1/subscriptionAppStoreReviewScreenshots/{made['id']}", {"data": {
                    "type": "subscriptionAppStoreReviewScreenshots", "id": made["id"],
                    "attributes": {"uploaded": True,
                                   "sourceFileChecksum": hashlib.md5(data).hexdigest()}}})

        if trial:
            offers, _ = get_all(f"/v1/subscriptions/{sid}/introductoryOffers")
            if not offers:
                # One offer per territory: the API ties each to a territory.
                for t in territories:
                    if not DRY:
                        call("POST", "/v1/subscriptionIntroductoryOffers", {"data": {
                            "type": "subscriptionIntroductoryOffers",
                            "attributes": {"duration": "THREE_DAYS", "offerMode": "FREE_TRIAL",
                                           "numberOfPeriods": 1},
                            "relationships": {
                                "subscription": {"data": ref("subscriptions", sid)},
                                "territory": {"data": ref("territories", t)},
                            }}})
                print(f"    + 3-day free trial in {len(territories)} territories")
    if not group["id"].startswith("dry"):
        for s_ in get_all(f"/v1/subscriptionGroups/{group['id']}/subscriptions")[0]:
            a = s_["attributes"]
            n_price = len(get_all(f"/v1/subscriptions/{s_['id']}/prices")[0])
            n_intro = len(get_all(f"/v1/subscriptions/{s_['id']}/introductoryOffers")[0])
            n_loc = len(get_all(f"/v1/subscriptions/{s_['id']}/subscriptionLocalizations")[0])
            try:
                rs = call("GET", f"/v1/subscriptions/{s_['id']}/appStoreReviewScreenshot").get("data") or {}
                shot_state = ((rs.get("attributes") or {}).get("assetDeliveryState") or {}).get("state")
            except RuntimeError:
                shot_state = None
            print(f"state {a['productId']}: {a.get('state')} · review shot {shot_state} · "
                  f"{a.get('subscriptionPeriod')} · "
                  f"level {a.get('groupLevel')} · {n_price} prices · {n_intro} intro offers · "
                  f"{n_loc} localizations")
    print("dry run, nothing written" if DRY else "done")


if __name__ == "__main__":
    main()
