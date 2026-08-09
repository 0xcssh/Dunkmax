# RevenueCat + App Store subscriptions — owner setup

The app code is done. Everything below is account/portal work that only the
account owner can do — none of it can be automated from this repo, and none of
it belongs in git.

Until the API key exists, the app still runs: `SubscriptionService.isConfigured`
is false, `Purchases.configure` is never called, StoreKit is never touched, and
the paywall shows an honest "purchases unavailable" state. See
[Why a build with no key still works](#why-a-build-with-no-key-still-works).

**Never commit an API key, a `.p8`, or a `.p12`.** The only thing that goes in
this repo is the *name* of a secret.

---

## 0. Prerequisites (Apple side, do these first)

RevenueCat can't see products that don't exist yet in App Store Connect, and
App Store Connect won't let you create paid products until the legal/banking
paperwork is done.

1. **Register the bundle id** `com.awdia.dunkmax` in the Apple Developer
   portal (Certificates, Identifiers & Profiles → Identifiers), with the
   **In-App Purchase** capability enabled.
2. **Create the app record** in App Store Connect for that bundle id.
3. **Paid Applications Agreement.** App Store Connect → Business →
   Agreements, Tax, and Banking. Accept the *Paid Applications* agreement and
   fill in **banking** and **tax** details. Until its status is `Active`:
   - you cannot create in-app purchase products;
   - StoreKit returns *no products* to the app, so the paywall will show its
     "Plans unavailable" state even with a correct API key.
   This is the single most common cause of an empty paywall. It can take a
   day or more after submission.

---

## 1. App Store Connect — the subscription group and the two products

CLAUDE.md calls for a **trial / no-trial cascade**: two products that are
priced identically, one carrying the free-trial introductory offer and one
carrying none. RevenueCat serves the trial product to athletes who are
eligible for a trial and the plain one to athletes who have already used their
trial, so nobody is ever shown a "3-day free trial" they cannot have.

In App Store Connect → your app → **Subscriptions**:

1. Create **one subscription group**, e.g. `DunkIt Pro`. Reference name is
   internal; the **Group Display Name** is shown by Apple in the App Store
   subscription management UI, so make it presentable.

   > Both products must be in the **same** group. That is what makes them
   > mutually exclusive and what makes upgrading/downgrading between them
   > work.

2. Create the products. Suggested identifiers (they are permanent — you cannot
   rename or reuse a product id, ever):

   | Product ID | Duration | Free trial |
   |---|---|---|
   | `com.awdia.dunkmax.pro.yearly` | 1 year | 3 days |
   | `com.awdia.dunkmax.pro.yearly.notrial` | 1 year | none |
   | `com.awdia.dunkmax.pro.weekly` | 1 week | 3 days |
   | `com.awdia.dunkmax.pro.weekly.notrial` | 1 week | none |

   If you only want to ship one plan at first, ship the yearly pair; the
   paywall renders whatever the offering contains, and hides "View other
   plans" when there is only one.

3. For each product set the **price** (Apple's price tier, all storefronts),
   a **Subscription Display Name** and a **Description**. Add at least one
   **localization** (English) or the product stays in "Missing Metadata" and
   will not be returned to the app.

4. On the two `…trial` products only, add the **Introductory Offer**:
   *Free trial*, duration **3 days**, for **New subscribers**. Set no
   introductory offer at all on the `.notrial` products.

   > The app reads the trial length off the product
   > (`StoreProduct.introductoryPrice`) and only calls it a trial when its
   > price is zero. If you configure a *paid* introductory offer instead, the
   > paywall will correctly stop claiming a free trial and the CTA becomes
   > "SUBSCRIBE".

5. Upload a **subscription review screenshot** for each product and fill in
   Review Notes. Products are reviewed with the first app submission.

---

## 2. App Store Connect — the API key RevenueCat needs

RevenueCat needs to read your subscription status server-side.

1. App Store Connect → Users and Access → **Integrations** → **App Store
   Connect API** → generate an **In-App Purchase key**, role *Admin* is not
   required; the dedicated In-App Purchase key type is the right one.
   Download the `.p8` **once** (it cannot be downloaded again).
2. App Store Connect → your app → **App Information** → copy the
   **App-Specific Shared Secret** (generate one if absent). Older RevenueCat
   setups use this; newer ones prefer the In-App Purchase key. Have both.

---

## 3. RevenueCat dashboard

1. Create a **Project** (e.g. `DunkIt`) at <https://app.revenuecat.com>.
2. Add an **App** to it: platform *App Store*, bundle id
   **`com.awdia.dunkmax`**. Upload the **In-App Purchase `.p8`** (with its Key
   ID and Issuer ID) and paste the **App-Specific Shared Secret**.
3. **Products** → import / add each product id from step 1.
4. **Entitlements** → create exactly one entitlement with the identifier:

   ```
   pro
   ```

   > ⚠️ This string must match `SubscriptionService.entitlementId` in
   > `lib/services/subscription_service.dart`. If it doesn't, a real purchase
   > will succeed and still leave the athlete locked out — the app detects
   > that case and shows "That purchase went through but did not unlock
   > DunkIt", which is a *configuration* bug, not a payment one.

   Attach **all four** products to `pro`.

5. **Offerings** → create an offering, mark it **Current**. Add packages:
   - `$rc_annual` → `com.awdia.dunkmax.pro.yearly`
   - `$rc_weekly` → `com.awdia.dunkmax.pro.weekly`

   Then create a **second** offering for the no-trial cascade with the same
   package identifiers pointing at the `.notrial` products, and set up
   RevenueCat's **Targeting / Offering placements** (or a `trial eligibility`
   rule) so trial-ineligible customers receive it. The app does not choose
   between them — it renders `offerings.current`, which is what RevenueCat
   decides per customer.

   > Package ordering in the app is not taken from the dashboard: the paywall
   > sorts by billing period (longest commitment first) and computes
   > "BEST VALUE" and "Save N%" from the real prices. There is nothing to
   > configure for that, and nothing to hardcode.

6. **API keys** → copy the **public SDK key for App Store**. It starts with
   `appl_`. This is the only credential the app ever sees, and it is a
   *public* key — but still keep it in a repo secret rather than in git, so it
   isn't tied to the repo's visibility.

---

## 4. The repo secret and the workflow change

Add one repository secret (Settings → Secrets and variables → Actions → New
repository secret):

| Secret name | Value |
|---|---|
| `REVENUECAT_API_KEY` | the `appl_…` public SDK key from step 3.6 |

Then make **one** change to `.github/workflows/ios-release.yml` — the *Build
(CocoaPods install + asset compile, unsigned)* step, currently around line 80.
Change:

```yaml
        run: flutter build ios --release --no-codesign
```

to:

```yaml
        run: |
          flutter build ios --release --no-codesign \
            --dart-define=REVENUECAT_API_KEY=${{ secrets.REVENUECAT_API_KEY }}
```

That is the whole change. Notes:

- **Only that workflow.** `ci.yml` (analyze + test) and `web-preview.yml` must
  stay secret-free — they are the reason the no-key path has to work, and the
  web preview cannot use StoreKit anyway.
- The archive step later in the same workflow re-uses the already-compiled
  Dart from this step, so the define only needs to be here. If you ever switch
  to `flutter build ipa`, the define moves to that command instead.
- If the secret is missing, the define expands to an empty string, the app
  builds fine, and the **release** paywall shows "purchases unavailable" with
  no way into the app. That failure is loud on purpose — see below.

---

## 5. Why a build with no key still works

`SubscriptionService` mirrors `LeaderboardService`:

- `isConfigured` is `String.fromEnvironment('REVENUECAT_API_KEY').isNotEmpty`.
- `initialize()` returns immediately when unconfigured; when configured it is
  wrapped in try/catch and timed out, so a dead network cannot hang startup.
- Every other call returns "unavailable"/"not entitled" instead of throwing.

Because nobody can be entitled without a key, strict entitlement gating would
lock developers, CI and the web preview out of the app entirely. The escape
hatch is deliberate and narrow:

```dart
bool get allowsUnconfiguredAccess => !isConfigured && !kReleaseMode;
```

- **Debug / profile with no key** (local runs, `flutter test`, web preview):
  the paywall shows an "unavailable" card and a `CONTINUE WITHOUT PURCHASE`
  button labelled as a debug build. Developers get in.
- **Release with a key**: normal behaviour — the entitlement decides.
- **Release with no key**: **fails closed.** No purchase is possible and there
  is no way past the paywall. This is intentional: a signed build that lost
  its secret should be obviously broken rather than silently free.

---

## 6. Sandbox testing (on device, after signing is wired)

1. App Store Connect → Users and Access → **Sandbox** → **Test Accounts** →
   create one. Use an email address you control that has **never** been an
   Apple ID.
2. On the iPhone: Settings → App Store → **Sandbox Account** → sign in with
   it. Do *not* sign out of your real Apple ID.
3. Install the IPA over USB (see CLAUDE.md) and open the paywall. You should
   see real localized prices and the "3-day free trial" line.
4. Buy. Sandbox subscription durations are compressed (a 1-year sub renews in
   about an hour; a 3-day trial lasts minutes), so renewals and expiry are
   testable in one sitting.
5. Verify in the RevenueCat dashboard → Customers that the purchase appears
   and that the `pro` entitlement is **active**.
6. Test **Restore Purchases**: delete the app, reinstall, tap Restore. You
   should land in the app without paying again.
7. Test **cancel**: tap the CTA and dismiss the sheet. The paywall must stay
   exactly as it was, with no error message.
8. Reset trial eligibility for a sandbox account by creating a new one —
   eligibility is per Apple ID and cannot be reset.

---

## 7. Still outstanding (not RevenueCat's problem, but blocks review)

- **Privacy Policy URL.** `lib/core/legal_urls.dart` holds a deliberately
  unusable `https://dunkit.invalid/privacy` placeholder. Publish a real page,
  put its URL there, flip `privacyPolicyPublished` to `true`, and enter the
  same URL in App Store Connect's *Privacy Policy URL* field. App Review
  taps this link.
- **Terms of Use.** Already points at Apple's standard EULA, which Apple
  permits apps to use as-is. Only replace it if custom terms are written.
- **Opening those links.** The app has no URL-opening dependency, so the
  paywall currently shows the URL in a dialog with a *Copy link* action
  instead of opening a browser. Before submitting, add `url_launcher` to
  `pubspec.yaml` and replace `_openLegal` in
  `lib/features/paywall/paywall_screen.dart` with a real
  `launchUrl(..., mode: LaunchMode.externalApplication)`. App Review expects
  a tap to reach a working page.
- **Subscription metadata in App Store Connect.** The app's *description*
  must also state the subscription title, length, price and that it
  auto-renews, and must link the privacy policy and the EULA. The in-app
  disclosure is already generated from the fetched product
  (`SubscriptionPlan.renewalDisclosure`).
