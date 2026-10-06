#!/usr/bin/env python3
"""Delete never-submitted subscriptions from App Store Connect by product id.

Irreversible, and Apple keeps the product id reserved forever. Only a
subscription that was never submitted can be deleted. Runs in CI
(.github/workflows/asc-delete-subscriptions.yml), dry run by default.
Env: ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_P8, PRODUCT_IDS (comma-separated),
BUNDLE_ID, DRY_RUN.
"""
import os
import sys
import time

import jwt
import requests

BASE = "https://api.appstoreconnect.apple.com"
DRY = os.environ.get("DRY_RUN", "0") == "1"


def call(method, path, params=None):
    now = int(time.time())
    tok = jwt.encode({"iss": os.environ["ASC_ISSUER_ID"], "iat": now, "exp": now + 1100,
                      "aud": "appstoreconnect-v1"}, os.environ["ASC_KEY_P8"],
                     algorithm="ES256", headers={"kid": os.environ["ASC_KEY_ID"]})
    r = requests.request(method, BASE + path, params=params, timeout=60,
                         headers={"Authorization": f"Bearer {tok}"})
    if r.status_code >= 400:
        raise RuntimeError(f"{method} {path} -> {r.status_code}: {r.text[:600]}")
    return r.json() if r.text else {}


wanted = {p.strip() for p in os.environ["PRODUCT_IDS"].split(",") if p.strip()}
app = call("GET", "/v1/apps", {"filter[bundleId]": os.environ.get("BUNDLE_ID", "com.awdia.dunkmax")})["data"][0]
found = {}
for g in call("GET", f"/v1/apps/{app['id']}/subscriptionGroups", {"limit": 50})["data"]:
    for s in call("GET", f"/v1/subscriptionGroups/{g['id']}/subscriptions", {"limit": 50})["data"]:
        if s["attributes"]["productId"] in wanted:
            found[s["attributes"]["productId"]] = s
missing = wanted - set(found)
if missing:
    print(f"not found (already gone?): {sorted(missing)}")
for pid, s in sorted(found.items()):
    print(f"DELETE {pid} ({s['attributes'].get('state')})")
    if not DRY:
        call("DELETE", f"/v1/subscriptions/{s['id']}")
print("dry run, nothing deleted" if DRY else "done")
