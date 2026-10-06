#!/usr/bin/env python3
"""Push the product page to App Store Connect: metadata and screenshots.

Runs in CI (.github/workflows/asc-listing.yml); adapted from RepLock's.

Metadata comes from scripts/listing/<file>.json (built and validated by
scripts/listing/build_listing.py):

  {"localizations": {"en-US": {"description", "keywords", "whatsNew",
                               "promotionalText", "supportUrl"}, ...},
   "appInfo":       {"en-US": {"name", "subtitle"}, ...}}

Screenshots (optional, SCREENSHOTS_DIR) come from
tool/store_screenshots/compose.py: <dir>/<caption set>/<device>/NN_*.png, and
each store locale uses the caption set named in compose.STORE_LOCALES.
A locale's existing screenshots for that display size are replaced.

Targets the app's editable App Store version (the one not yet live), so the
listing file carries no version number of its own. Localizations that don't
exist yet are created. Only the keys present are changed.

Env: ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_P8 (PEM text), LISTING_FILE,
SCREENSHOTS_DIR (optional), BUNDLE_ID (default com.awdia.dunkmax),
DRY_RUN ("1" = print only).
"""
import hashlib
import json
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

LIMITS = {"name": 30, "subtitle": 30, "keywords": 100, "promotionalText": 170,
          "description": 4000, "whatsNew": 4000}

# compose.py device folder -> ASC display type. The 6.7" slot is the one
# that takes the 6.9" sizes (1320x2868) in the API; iPad 13" is 3rd-gen 12.9.
DISPLAY_TYPES = {"iphone69": "APP_IPHONE_67", "ipad13": "APP_IPAD_PRO_3GEN_129"}

EDITABLE = {"PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED",
            "METADATA_REJECTED", "INVALID_BINARY", "WAITING_FOR_REVIEW"}


def token():
    now = int(time.time())
    return jwt.encode({"iss": ISSUER, "iat": now, "exp": now + 1100, "aud": "appstoreconnect-v1"},
                      P8, algorithm="ES256", headers={"kid": KEY_ID})


def call(method, path, body=None, params=None):
    r = requests.request(method, BASE + path, json=body, params=params,
                         headers={"Authorization": f"Bearer {token()}"}, timeout=120)
    if r.status_code >= 400:
        raise RuntimeError(f"{method} {path} -> {r.status_code}: {r.text[:800]}")
    return r.json() if r.text else {}


def check_limits(locale, attrs):
    for k, v in attrs.items():
        if k in LIMITS and v is not None and len(v) > LIMITS[k]:
            sys.exit(f"{locale}.{k} is {len(v)} chars, limit {LIMITS[k]}")
        if isinstance(v, str) and "{{" in v:
            msg = (f"{locale}.{k} still holds a placeholder ({v[v.index('{{'):][:30]}...) — "
                   "publish the page and fill it in scripts/listing/build_listing.py")
            if not DRY:
                sys.exit(msg)
            print(f"  WARNING {msg}")


def upsert(kind, parent_rel, parent_id, existing, locale, attrs):
    """Create or patch one localization of type `kind`."""
    check_limits(locale, attrs)
    if locale in existing:
        loc = existing[locale]
        changed = {k: v for k, v in attrs.items() if loc["attributes"].get(k) != v}
        if not changed:
            print(f"  {locale}: unchanged")
            return loc["id"]
        print(f"  {locale}: update {sorted(changed)}")
        if not DRY:
            call("PATCH", f"/v1/{kind}/{loc['id']}",
                 {"data": {"type": kind, "id": loc["id"], "attributes": changed}})
        return loc["id"]
    print(f"  {locale}: CREATE with {sorted(attrs)}")
    if DRY:
        return None
    parent_type = "appStoreVersions" if parent_rel == "appStoreVersion" else "appInfos"
    made = call("POST", f"/v1/{kind}",
                {"data": {"type": kind, "attributes": dict(attrs, locale=locale),
                          "relationships": {parent_rel: {"data": {"type": parent_type, "id": parent_id}}}}})
    return made["data"]["id"]


def upload_screenshots(loc_id, locale, files, display_type):
    sets = call("GET", f"/v1/appStoreVersionLocalizations/{loc_id}/appScreenshotSets",
                params={"limit": 50})["data"]
    shot_set = next((s for s in sets if s["attributes"]["screenshotDisplayType"] == display_type), None)
    print(f"    {display_type}: {len(files)} file(s)" + ("" if shot_set else " (new set)"))
    if DRY:
        return
    if shot_set is None:
        shot_set = call("POST", "/v1/appScreenshotSets",
                        {"data": {"type": "appScreenshotSets",
                                  "attributes": {"screenshotDisplayType": display_type},
                                  "relationships": {"appStoreVersionLocalization": {
                                      "data": {"type": "appStoreVersionLocalizations", "id": loc_id}}}}})["data"]
    for old in call("GET", f"/v1/appScreenshotSets/{shot_set['id']}/appScreenshots",
                    params={"limit": 50})["data"]:
        call("DELETE", f"/v1/appScreenshots/{old['id']}")
    ids = []
    for f in files:
        data = f.read_bytes()
        shot = call("POST", "/v1/appScreenshots",
                    {"data": {"type": "appScreenshots",
                              "attributes": {"fileName": f.name, "fileSize": len(data)},
                              "relationships": {"appScreenshotSet": {
                                  "data": {"type": "appScreenshotSets", "id": shot_set["id"]}}}}})["data"]
        for op in shot["attributes"]["uploadOperations"]:
            chunk = data[op["offset"]:op["offset"] + op["length"]]
            headers = {h["name"]: h["value"] for h in op.get("requestHeaders", [])}
            r = requests.request(op["method"], op["url"], data=chunk, headers=headers, timeout=300)
            r.raise_for_status()
        call("PATCH", f"/v1/appScreenshots/{shot['id']}",
             {"data": {"type": "appScreenshots", "id": shot["id"],
                       "attributes": {"uploaded": True,
                                      "sourceFileChecksum": hashlib.md5(data).hexdigest()}}})
        ids.append(shot["id"])
    # Creation order is not guaranteed to be display order: set it.
    call("PATCH", f"/v1/appScreenshotSets/{shot_set['id']}/relationships/appScreenshots",
         {"data": [{"type": "appScreenshots", "id": i} for i in ids]})


def main():
    spec = json.loads(pathlib.Path(os.environ["LISTING_FILE"]).read_text(encoding="utf-8"))
    apps = call("GET", "/v1/apps", params={"filter[bundleId]": BUNDLE_ID})["data"]
    if not apps:
        sys.exit(f"no app with bundle id {BUNDLE_ID}")
    app_id = apps[0]["id"]
    versions = call("GET", f"/v1/apps/{app_id}/appStoreVersions",
                    params={"filter[platform]": "IOS", "limit": 10})["data"]
    editable = [v for v in versions if v["attributes"]["appStoreState"] in EDITABLE]
    if not editable:
        sys.exit("no editable App Store version — create the next version in App Store Connect first")
    version = editable[0]
    print(f"app {app_id} · version {version['attributes']['versionString']} "
          f"({version['attributes']['appStoreState']})")

    existing = {l["attributes"]["locale"]: l for l in
                call("GET", f"/v1/appStoreVersions/{version['id']}/appStoreVersionLocalizations",
                     params={"limit": 50})["data"]}
    loc_ids = {}
    for locale, attrs in spec.get("localizations", {}).items():
        loc_ids[locale] = upsert("appStoreVersionLocalizations", "appStoreVersion",
                                 version["id"], existing, locale, attrs)

    if spec.get("appInfo"):
        infos = call("GET", f"/v1/apps/{app_id}/appInfos")["data"]
        info = next((i for i in infos if i["attributes"].get("appStoreState") != "READY_FOR_SALE"
                     and i["attributes"].get("state") != "READY_FOR_DISTRIBUTION"), infos[0])
        print(f"appInfo {info['id']}")
        existing = {l["attributes"]["locale"]: l for l in
                    call("GET", f"/v1/appInfos/{info['id']}/appInfoLocalizations",
                         params={"limit": 50})["data"]}
        for locale, attrs in spec["appInfo"].items():
            upsert("appInfoLocalizations", "appInfo", info["id"], existing, locale, attrs)

    shots_dir = os.environ.get("SCREENSHOTS_DIR")
    if shots_dir:
        sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent.parent / "tool" / "store_screenshots"))
        from compose import STORE_LOCALES  # the locale -> caption-set map lives with the art
        root = pathlib.Path(shots_dir)
        print("screenshots")
        for locale, set_name in STORE_LOCALES.items():
            if locale not in loc_ids:
                print(f"  {locale}: no localization in the listing file, skipped")
                continue
            print(f"  {locale} <- {set_name}")
            for device, display_type in DISPLAY_TYPES.items():
                files = sorted((root / set_name / device).glob("*.png"))
                if not files:
                    sys.exit(f"no screenshots in {root / set_name / device}")
                if loc_ids[locale] is None:
                    print(f"    {display_type}: {len(files)} file(s) after the localization is created")
                    continue
                upload_screenshots(loc_ids[locale], locale, files, display_type)
    print("dry run, nothing written" if DRY else "done")


if __name__ == "__main__":
    main()
