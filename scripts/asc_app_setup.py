#!/usr/bin/env python3
"""Fill the App Store Connect fields that block "Add for Review".

Runs in CI (.github/workflows/asc-app-setup.yml). Idempotent; only fields
with a value are touched, so it can run before the owner has supplied the
contact details. Handles:

  privacy policy URL   every appInfo localization (the store's per-locale
                       "Privacy Policy URL")
  price                free download (the subscriptions are the business)
  copyright            on the editable App Store version
  review contact       App Review's first/last name, phone, email, plus the
                       review notes (no account needed; how to test)

NOT covered, because Apple has no public API for it: the App Privacy
questionnaire ("nutrition label") — see docs/app-store-listing.md.

Env: ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_P8, BUNDLE_ID, DRY_RUN, and the
optional COPYRIGHT, CONTACT_FIRST_NAME, CONTACT_LAST_NAME, CONTACT_PHONE,
CONTACT_EMAIL.
"""
import os
import sys
import time

import jwt
import requests

BASE = "https://api.appstoreconnect.apple.com"
DRY = os.environ.get("DRY_RUN", "0") == "1"
PRIVACY_URL = "https://0xcssh.github.io/dunkit-legal/privacy.html"
EDITABLE = {"PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED",
            "METADATA_REJECTED", "INVALID_BINARY"}

REVIEW_NOTES = """Dunk It measures a vertical jump from a video: the athlete films one jump (or picks a clip from the photo library), and on-device body tracking (Google ML Kit pose detection) times the flight to estimate jump height. No account or login exists.

How to test:
1. Complete the short onboarding quiz (any answers).
2. You are offered one free jump analysis before the paywall. Use "Choose from library" with any video of a person jumping, filmed straight on with the whole body in frame — or skip it with "I'll do this later".
3. The paywall sells Dunk It Pro (yearly or weekly, 3-day free trial where eligible). Subscribing in the sandbox unlocks the app: Home, Analyze, Train, Feed and Progress tabs.

The camera is used only to film the jump; frames are processed on the device and never uploaded. The microphone permission is requested because iOS video capture requires it; audio is not used."""


def token():
    now = int(time.time())
    return jwt.encode({"iss": os.environ["ASC_ISSUER_ID"], "iat": now, "exp": now + 1100,
                       "aud": "appstoreconnect-v1"}, os.environ["ASC_KEY_P8"],
                      algorithm="ES256", headers={"kid": os.environ["ASC_KEY_ID"]})


def call(method, path, body=None, params=None):
    r = requests.request(method, BASE + path, json=body, params=params, timeout=60,
                         headers={"Authorization": f"Bearer {token()}"})
    if r.status_code >= 400:
        raise RuntimeError(f"{method} {path} -> {r.status_code}: {r.text[:800]}")
    return r.json() if r.text else {}


def write(method, path, body, label):
    print(f"  {label}")
    if not DRY:
        return call(method, path, body)
    return {}


def main():
    app = call("GET", "/v1/apps", {"filter[bundleId]": os.environ.get("BUNDLE_ID", "com.awdia.dunkmax")})["data"][0]
    app_id = app["id"]
    print(f"app {app_id}")

    # ---- Privacy policy URL, every locale
    infos = call("GET", f"/v1/apps/{app_id}/appInfos")["data"]
    info = next((i for i in infos if i["attributes"].get("state") != "READY_FOR_DISTRIBUTION"), infos[0])
    for loc in call("GET", f"/v1/appInfos/{info['id']}/appInfoLocalizations", {"limit": 50})["data"]:
        if loc["attributes"].get("privacyPolicyUrl") != PRIVACY_URL:
            write("PATCH", f"/v1/appInfoLocalizations/{loc['id']}",
                  {"data": {"type": "appInfoLocalizations", "id": loc["id"],
                            "attributes": {"privacyPolicyUrl": PRIVACY_URL}}},
                  f"privacy URL {loc['attributes']['locale']}")

    # ---- Price: free
    try:
        schedule = call("GET", f"/v1/apps/{app_id}/appPriceSchedule").get("data")
    except RuntimeError:
        schedule = None
    has_price = False
    if schedule:
        try:
            has_price = bool(call("GET", f"/v1/appPriceSchedules/{schedule['id']}/manualPrices")["data"])
        except RuntimeError:
            has_price = False
    if not has_price:
        points = call("GET", f"/v1/apps/{app_id}/appPricePoints",
                      {"filter[territory]": "USA", "limit": 200})["data"]
        free = next(p for p in points if float(p["attributes"]["customerPrice"]) == 0)
        try:
            write("POST", "/v1/appPriceSchedules", {
                "data": {"type": "appPriceSchedules",
                         "relationships": {
                             "app": {"data": {"type": "apps", "id": app_id}},
                             "baseTerritory": {"data": {"type": "territories", "id": "USA"}},
                             "manualPrices": {"data": [{"type": "appPrices", "id": "${free}"}]}}},
                "included": [{"type": "appPrices", "id": "${free}",
                              "attributes": {"startDate": None},
                              "relationships": {"appPricePoint": {
                                  "data": {"type": "appPricePoints", "id": free["id"]}}}}],
            }, "price: free")
        except RuntimeError as e:
            # The price-schedule payload is picky; a free price is two clicks
            # in App Store Connect (Pricing → Free), so this must not block the
            # rest of the run.
            print(f"  price: NOT SET ({e}) — set it to Free by hand")
    else:
        print("  price: already set")

    # ---- Version: copyright, review details
    versions = call("GET", f"/v1/apps/{app_id}/appStoreVersions",
                    {"filter[platform]": "IOS", "limit": 10})["data"]
    version = next((v for v in versions if v["attributes"]["appStoreState"] in EDITABLE), None)
    if version is None:
        sys.exit("no editable version")
    copyright_ = os.environ.get("COPYRIGHT", "").strip()
    if copyright_ and version["attributes"].get("copyright") != copyright_:
        write("PATCH", f"/v1/appStoreVersions/{version['id']}",
              {"data": {"type": "appStoreVersions", "id": version["id"],
                        "attributes": {"copyright": copyright_}}}, f"copyright: {copyright_}")

    contact = {k: os.environ.get(e, "").strip() for k, e in [
        ("contactFirstName", "CONTACT_FIRST_NAME"), ("contactLastName", "CONTACT_LAST_NAME"),
        ("contactPhone", "CONTACT_PHONE"), ("contactEmail", "CONTACT_EMAIL")]}
    attrs = {k: v for k, v in contact.items() if v}
    attrs.update({"demoAccountRequired": False, "notes": REVIEW_NOTES})
    try:
        detail = call("GET", f"/v1/appStoreVersions/{version['id']}/appStoreReviewDetail").get("data")
    except RuntimeError:
        detail = None
    if detail:
        changed = {k: v for k, v in attrs.items() if detail["attributes"].get(k) != v}
        if changed:
            write("PATCH", f"/v1/appStoreReviewDetails/{detail['id']}",
                  {"data": {"type": "appStoreReviewDetails", "id": detail["id"],
                            "attributes": changed}}, f"review details: {sorted(changed)}")
    else:
        write("POST", "/v1/appStoreReviewDetails",
              {"data": {"type": "appStoreReviewDetails", "attributes": attrs,
                        "relationships": {"appStoreVersion": {
                            "data": {"type": "appStoreVersions", "id": version["id"]}}}}},
              f"review details: create {sorted(attrs)}")
    print("dry run, nothing written" if DRY else "done")


if __name__ == "__main__":
    main()
