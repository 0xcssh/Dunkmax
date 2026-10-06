#!/usr/bin/env python3
"""Configure the RevenueCat project for Dunk It through the REST API v2.

Runs in CI (.github/workflows/revenuecat-setup.yml). Idempotent: anything
that already exists is reused, so a re-run only fills gaps.

Builds:
  app          App Store app for com.awdia.dunkmax, with the account's
               In-App Purchase key (QL2P7M4WRG, shared with RepLock — IAP keys
               are account-level) and the App Store Connect API key, so
               RevenueCat can validate StoreKit 2 transactions and import
               product metadata;
  products     the four App Store subscriptions (scripts/asc_subscriptions.py);
  entitlement  `pro` — must equal SubscriptionService.entitlementId — with all
               four products attached;
  offering     `default`, current, with `$rc_annual` and `$rc_weekly` on the
               trial products. Who actually gets the trial is decided by
               StoreKit's eligibility, which the paywall checks before it
               promises one; the `.notrial` products are attached to `pro`
               only so a purchase of either can never fail to unlock.

Prints the app's public SDK key (appl_…) at the end: that is the value of
the REVENUECAT_API_KEY repo secret the release build passes to the app.

Env: RC_SECRET_KEY, RC_PROJECT (optional, else the only project),
IAP_KEY_P8, IAP_KEY_ID, ASC_KEY_P8, ASC_KEY_ID, ASC_ISSUER_ID, DRY_RUN.
"""
import os
import sys
import time

import requests

BASE = "https://api.revenuecat.com/v2"
KEY = os.environ["RC_SECRET_KEY"]
DRY = os.environ.get("DRY_RUN", "0") == "1"
BUNDLE_ID = "com.awdia.dunkmax"
ENTITLEMENT = "pro"

PRODUCTS = [
    ("com.awdia.dunkmax.pro.yearly", "Pro Yearly (3-day trial)"),
    ("com.awdia.dunkmax.pro.yearly.notrial", "Pro Yearly (no trial)"),
    ("com.awdia.dunkmax.pro.weekly", "Pro Weekly (3-day trial)"),
    ("com.awdia.dunkmax.pro.weekly.notrial", "Pro Weekly (no trial)"),
]
PACKAGES = [  # lookup key, display name, position, product
    ("$rc_annual", "Yearly", 1, "com.awdia.dunkmax.pro.yearly"),
    ("$rc_weekly", "Weekly", 2, "com.awdia.dunkmax.pro.weekly"),
]


def call(method, path, body=None):
    for attempt in range(5):
        r = requests.request(method, BASE + path, json=body, timeout=60,
                             headers={"Authorization": f"Bearer {KEY}"})
        if r.status_code == 429:
            time.sleep(5 * (attempt + 1))
            continue
        if r.status_code >= 400:
            raise RuntimeError(f"{method} {path} -> {r.status_code}: {r.text[:900]}")
        return r.json() if r.text else {}
    raise RuntimeError(f"{method} {path}: rate limited")


def items(path):
    out, url = [], path
    while url:
        page = call("GET", url)
        out += page.get("items", [])
        nxt = page.get("next_page")
        url = nxt.replace(BASE, "") if nxt else None
    return out


def create(path, body, label):
    print(f"  + {label}")
    if DRY:
        return {"id": f"dry-{label}"}
    return call("POST", path, body)


def main():
    projects = items("/projects")
    wanted = os.environ.get("RC_PROJECT")
    project = next((p for p in projects if p["id"] == wanted or p["name"] == wanted), None) \
        if wanted else (projects[0] if len(projects) == 1 else None)
    if project is None:
        sys.exit(f"pick a project with RC_PROJECT: {[p['name'] for p in projects]}")
    pid = project["id"]
    print(f"project {project['name']} ({pid})")

    # ---- App Store app
    apps = items(f"/projects/{pid}/apps")
    app = next((a for a in apps if a.get("type") == "app_store"
                and (a.get("app_store") or {}).get("bundle_id") == BUNDLE_ID), None)
    if app is None:
        app = create(f"/projects/{pid}/apps", {
            "name": "Dunk It (App Store)",
            "type": "app_store",
            "app_store": {
                "bundle_id": BUNDLE_ID,
                "subscription_private_key": os.environ["IAP_KEY_P8"],
                "subscription_key_id": os.environ["IAP_KEY_ID"],
                "subscription_key_issuer": os.environ["ASC_ISSUER_ID"],
                "app_store_connect_api_key": os.environ["ASC_KEY_P8"],
                "app_store_connect_api_key_id": os.environ["ASC_KEY_ID"],
                "app_store_connect_api_key_issuer": os.environ["ASC_ISSUER_ID"],
            },
        }, f"app {BUNDLE_ID}")
    else:
        print(f"  app {BUNDLE_ID}: exists ({app['id']})")
    app_id = app["id"]

    # ---- Products
    existing = {} if DRY and app_id.startswith("dry") else {
        p["store_identifier"]: p for p in items(f"/projects/{pid}/products")
        if p.get("app_id") == app_id}
    product_ids = {}
    for store_id, name in PRODUCTS:
        p = existing.get(store_id) or create(f"/projects/{pid}/products", {
            "store_identifier": store_id, "app_id": app_id,
            "type": "subscription", "display_name": name}, f"product {store_id}")
        product_ids[store_id] = p["id"]

    # ---- Entitlement
    ents = items(f"/projects/{pid}/entitlements")
    ent = next((e for e in ents if e["lookup_key"] == ENTITLEMENT), None) or create(
        f"/projects/{pid}/entitlements",
        {"lookup_key": ENTITLEMENT, "display_name": "Dunk It Pro"}, f"entitlement {ENTITLEMENT}")
    attached = set()
    if not ent["id"].startswith("dry"):
        attached = {p["id"] for p in items(f"/projects/{pid}/entitlements/{ent['id']}/products")}
    todo = [i for i in product_ids.values() if i not in attached]
    if todo:
        print(f"  + attach {len(todo)} product(s) to {ENTITLEMENT}")
        if not DRY:
            call("POST", f"/projects/{pid}/entitlements/{ent['id']}/actions/attach_products",
                 {"product_ids": todo})

    # ---- Offering + packages
    offs = items(f"/projects/{pid}/offerings")
    off = next((o for o in offs if o["lookup_key"] == "default"), None) or create(
        f"/projects/{pid}/offerings",
        {"lookup_key": "default", "display_name": "Dunk It Pro — yearly + weekly"}, "offering default")
    if not off.get("is_current"):
        print("  + make offering default current")
        if not DRY:
            call("POST", f"/projects/{pid}/offerings/{off['id']}", {"is_current": True})
    pkgs = {} if off["id"].startswith("dry") else {
        p["lookup_key"]: p for p in items(f"/projects/{pid}/offerings/{off['id']}/packages")}
    for key, name, pos, store_id in PACKAGES:
        pkg = pkgs.get(key) or create(f"/projects/{pid}/offerings/{off['id']}/packages",
                                      {"lookup_key": key, "display_name": name, "position": pos},
                                      f"package {key}")
        have = set()
        if not pkg["id"].startswith("dry"):
            have = {p["product"]["id"] if "product" in p else p.get("id")
                    for p in items(f"/projects/{pid}/packages/{pkg['id']}/products")}
        if product_ids[store_id] not in have:
            print(f"  + attach {store_id} to {key}")
            if not DRY:
                call("POST", f"/projects/{pid}/packages/{pkg['id']}/actions/attach_products",
                     {"products": [{"product_id": product_ids[store_id], "eligibility_criteria": "all"}]})

    # ---- The public SDK key the app needs
    if not app_id.startswith("dry"):
        keys = items(f"/projects/{pid}/apps/{app_id}/public_api_keys")
        for k in keys:
            print(f"public SDK key: {k.get('key')}  ({k.get('environment', '')})")
    print("dry run, nothing written" if DRY else "done")


if __name__ == "__main__":
    main()
