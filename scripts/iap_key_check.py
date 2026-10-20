#!/usr/bin/env python3
"""Check that the In-App Purchase key RevenueCat was given actually works.

RevenueCat validates every StoreKit 2 purchase by calling Apple's App Store
Server API with this key. "Key configured" in RevenueCat says only that a key
was uploaded; a wrong key id, issuer or file still saves fine and then fails
every purchase — the store sheet completes and the app shows an error, which
is what App Review reported on build 43.

Signs the same JWT RevenueCat would and asks Apple for a transaction id that
cannot exist: 401 means the credentials are rejected, a 4040010 / 4000006
"not found / invalid id" means Apple accepted them. Prints statuses only.

Env: IAP_KEY_P8, IAP_KEY_ID, ASC_ISSUER_ID, BUNDLE_ID.
"""
import os
import time

import jwt
import requests

p8 = os.environ["IAP_KEY_P8"]
print(f"key file: {'PEM ok' if 'BEGIN PRIVATE KEY' in p8 else 'NOT a PEM private key'}"
      f" · key id {os.environ['IAP_KEY_ID']}")
now = int(time.time())
token = jwt.encode({"iss": os.environ["ASC_ISSUER_ID"], "iat": now, "exp": now + 1200,
                    "aud": "appstoreconnect-v1", "bid": os.environ.get("BUNDLE_ID", "com.awdia.dunkmax")},
                   p8, algorithm="ES256", headers={"kid": os.environ["IAP_KEY_ID"], "typ": "JWT"})
for env, host in [("sandbox", "api.storekit-sandbox.itunes.apple.com"),
                  ("production", "api.storekit.itunes.apple.com")]:
    r = requests.get(f"https://{host}/inApps/v1/transactions/2000000000000000",
                     headers={"Authorization": f"Bearer {token}"}, timeout=30)
    code = ""
    try:
        code = r.json().get("errorCode", "")
    except ValueError:
        pass
    verdict = "REJECTED (bad key / key id / issuer)" if r.status_code == 401 else "accepted"
    print(f"{env}: HTTP {r.status_code} {code} -> {verdict}")
