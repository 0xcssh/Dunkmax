#!/usr/bin/env python3
"""Read-only check that in-app purchases can work for App Review.

Runs in CI (.github/workflows/iap-readiness.yml). Writes nothing. Written
after build 43 was rejected under 2.1(b) ("an error message was displayed
when we tried to proceed with IAP"): it prints every link in the chain a
reviewer's purchase depends on, so the next submission is not a guess.

App Store Connect
  version        state, attached build
  submissions    review submissions and what each one carried
  subscriptions  state of each product — a FIRST subscription must ride
                 with an app version, and one still READY_TO_SUBMIT was
                 never sent to review with it
RevenueCat
  app            bundle id, In-App Purchase key configured (without it a
                 StoreKit 2 purchase cannot be validated and fails)
  sdk key        whether the REVENUECAT_API_KEY secret the release build
                 passes is this app's key at all
  products       store ids and the current offering's packages
  customers      how many, and how many hold an entitlement (counts only:
                 the CI logs are public)

The Paid Apps Agreement has no public API: check it by hand in App Store
Connect → Business.

Env: ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_P8, RC_SECRET_KEY, RC_SDK_KEY.
"""
import os
import time

import jwt
import requests

BUNDLE_ID = "com.awdia.dunkmax"
ASC = "https://api.appstoreconnect.apple.com"
RC = "https://api.revenuecat.com/v2"


def asc_token():
    now = int(time.time())
    return jwt.encode({"iss": os.environ["ASC_ISSUER_ID"], "iat": now, "exp": now + 1100,
                       "aud": "appstoreconnect-v1"}, os.environ["ASC_KEY_P8"],
                      algorithm="ES256", headers={"kid": os.environ["ASC_KEY_ID"]})


def asc(path, params=None):
    r = requests.get(ASC + path, params=params, timeout=60,
                     headers={"Authorization": f"Bearer {asc_token()}"})
    if r.status_code >= 400:
        return {"error": f"{r.status_code}: {r.text[:300]}"}
    return r.json()


def rc(path, params=None):
    r = requests.get(RC + path, params=params, timeout=60,
                     headers={"Authorization": f"Bearer {os.environ['RC_SECRET_KEY']}"})
    if r.status_code >= 400:
        return {"error": f"{r.status_code}: {r.text[:300]}"}
    return r.json()


def app_store_connect():
    print("== App Store Connect")
    app = asc("/v1/apps", {"filter[bundleId]": BUNDLE_ID})["data"][0]
    app_id = app["id"]
    print(f"app {app_id}")

    for v in asc(f"/v1/apps/{app_id}/appStoreVersions",
                 {"filter[platform]": "IOS", "limit": 5})["data"]:
        build = asc(f"/v1/appStoreVersions/{v['id']}/build").get("data") or {}
        print(f"version {v['attributes']['versionString']}: {v['attributes']['appStoreState']}"
              f" · build {(build.get('attributes') or {}).get('version', '-')}")

    subs = asc(f"/v1/reviewSubmissions", {"filter[app]": app_id, "limit": 10})
    for s in subs.get("data", []):
        a = s["attributes"]
        print(f"review submission {s['id']}: {a.get('state')} · submitted {a.get('submittedDate')}")
        items = asc(f"/v1/reviewSubmissions/{s['id']}/items", {"limit": 50})
        for it in items.get("data", []):
            kinds = [k for k, rel in (it.get("relationships") or {}).items()
                     if (rel.get("data") if isinstance(rel, dict) else None)]
            print(f"  item {it['attributes'].get('state')} {kinds}")
    if "error" in subs:
        print(f"review submissions: {subs['error']}")

    for g in asc(f"/v1/apps/{app_id}/subscriptionGroups")["data"]:
        print(f"group {g['attributes']['referenceName']}")
        for loc in asc(f"/v1/subscriptionGroups/{g['id']}/subscriptionGroupLocalizations",
                       {"limit": 50}).get("data", []):
            print(f"  group localization {loc['attributes']['locale']}: {loc['attributes'].get('state')}")
        for sub in asc(f"/v1/subscriptionGroups/{g['id']}/subscriptions", {"limit": 50})["data"]:
            a = sub["attributes"]
            print(f"  {a['productId']}: {a['state']}")


def revenuecat():
    print("== RevenueCat")
    projects = rc("/projects").get("items", [])
    sdk_key = os.environ.get("RC_SDK_KEY", "")
    print(f"release build's SDK key: {sdk_key[:5]}… ({len(sdk_key)} chars)")
    for p in projects:
        pid = p["id"]
        print(f"project {p['name']} ({pid})")
        for a in rc(f"/projects/{pid}/apps").get("items", []):
            store = a.get("app_store") or {}
            print(f"  app {a['name']} [{a['type']}] bundle={store.get('bundle_id')}"
                  f" iap_key={store.get('subscription_key_configured')}"
                  f" asc_key={store.get('app_store_connect_api_key_configured')}")
            for k in rc(f"/projects/{pid}/apps/{a['id']}/public_api_keys").get("items", []):
                same = "  <- the release build's key" if k.get("key") == sdk_key else ""
                print(f"    sdk key {k.get('key', '')[:5]}… ({k.get('environment')}){same}")
        for pr in rc(f"/projects/{pid}/products").get("items", []):
            print(f"  product {pr.get('store_identifier')} {pr.get('state')} app={pr.get('app_id')}")
        for e in rc(f"/projects/{pid}/entitlements").get("items", []):
            attached = rc(f"/projects/{pid}/entitlements/{e['id']}/products").get("items", [])
            print(f"  entitlement {e['lookup_key']}: {[x.get('store_identifier') for x in attached]}")
        for o in rc(f"/projects/{pid}/offerings").get("items", []):
            print(f"  offering {o['lookup_key']} current={o.get('is_current')}")
            for pk in rc(f"/projects/{pid}/offerings/{o['id']}/packages").get("items", []):
                prods = rc(f"/projects/{pid}/packages/{pk['id']}/products").get("items", [])
                ids = [(x.get("product") or x).get("store_identifier") for x in prods]
                print(f"    package {pk['lookup_key']}: {ids}")
        # Counts only: this repo and its CI logs are public, so nothing that
        # describes an individual customer may be printed here.
        customers = rc(f"/projects/{pid}/customers", {"limit": 50})
        if "error" in customers:
            print(f"  customers: {customers['error']}")
        rows = customers.get("items", [])
        entitled = sum(1 for c in rows if rc(
            f"/projects/{pid}/customers/{c['id']}/active_entitlements").get("items"))
        print(f"  customers: {len(rows)} seen, {entitled} with an active entitlement")

if __name__ == "__main__":
    app_store_connect()
    revenuecat()
