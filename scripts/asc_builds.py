#!/usr/bin/env python3
"""Print the app's latest builds and their processing / TestFlight state.

Read-only. Runs in CI (.github/workflows/asc-builds.yml).
Env: ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_P8 (PEM), BUNDLE_ID.
"""
import os
import time

import jwt
import requests

BASE = "https://api.appstoreconnect.apple.com"


def token():
    now = int(time.time())
    return jwt.encode({"iss": os.environ["ASC_ISSUER_ID"], "iat": now, "exp": now + 1100,
                       "aud": "appstoreconnect-v1"}, os.environ["ASC_KEY_P8"],
                      algorithm="ES256", headers={"kid": os.environ["ASC_KEY_ID"]})


def get(path, params=None):
    r = requests.get(BASE + path, params=params, timeout=60,
                     headers={"Authorization": f"Bearer {token()}"})
    r.raise_for_status()
    return r.json()


app = get("/v1/apps", {"filter[bundleId]": os.environ.get("BUNDLE_ID", "com.awdia.dunkmax")})["data"][0]
# Every state, explicitly: a build that failed processing is otherwise easy
# to miss, and that is exactly the one worth seeing.
builds = get("/v1/builds", {"filter[app]": app["id"], "sort": "-uploadedDate", "limit": 5,
                            "filter[processingState]": "PROCESSING,FAILED,INVALID,VALID",
                            "include": "buildBetaDetail,preReleaseVersion"})
details = {i["id"]: i["attributes"] for i in builds.get("included", []) if i["type"] == "buildBetaDetails"}
versions = {i["id"]: i["attributes"]["version"] for i in builds.get("included", [])
            if i["type"] == "preReleaseVersions"}
for b in builds["data"]:
    a = b["attributes"]
    rel = b["relationships"]
    d = details.get((rel.get("buildBetaDetail", {}).get("data") or {}).get("id"), {})
    v = versions.get((rel.get("preReleaseVersion", {}).get("data") or {}).get("id"), "?")
    print(f"{v} ({a['version']})  uploaded {a['uploadedDate']}  processing={a['processingState']}  "
          f"expired={a.get('expired')}  internal={d.get('internalBuildState')}  "
          f"external={d.get('externalBuildState')}")
