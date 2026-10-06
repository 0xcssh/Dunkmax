# App Store listing — Dunk It

Everything on the product page, and how it gets there. Positioning, competitors
and keyword research: [`app-marketing-context.md`](../app-marketing-context.md).

## Name

The store name is **Dunk It**. "DunkMax" is taken by the reference app
(id6757568089) and must never appear publicly. Title pattern: `Dunk It: <keyword>`.

## Metadata — `scripts/listing/build_listing.py`

One Python file holds every locale's name, subtitle, keywords, description,
promo text and what's new. Run it to validate (Apple limits + no word repeated
across title/subtitle/keywords) and to write `scripts/listing/1.0.json`.

| Store locale | Title | Subtitle |
|---|---|---|
| en-US / GB / CA / AU | Dunk It: Vertical Jump Trainer | AI Vert Test & Basketball Plan |
| fr-FR / fr-CA | Dunk It : Détente Verticale | Test de saut et plan basket |
| es-MX | Dunk It: Salto Vertical | Brinca más alto y llega al aro |
| es-ES | Dunk It: Salto Vertical | Salta más alto y llega al aro |
| pt-BR | Dunk It: Treino de Impulsão | Meça seu salto vertical com IA |
| de-DE | Dunk It: Sprungkraft Training | Sprunghöhe messen mit KI |
| it | Dunk It: Salto Verticale | Misura e migliora l'elevazione |

Notes from the research (2026-10-02):
- es-MX metadata is also indexed on the **US** store — a second keyword field there.
- Never "détente" alone in French search terms (relaxation apps); never "dunk"
  alone in English (games). "impulsão" is the Brazilian word, "Sprungkraft" the German.
- ja / ko are worth doing only with a translated UI.

## Screenshots — `tool/store_screenshots/`

1. `capture_test.dart` renders the **real screens** at store resolution
   (iPhone 6.9" 1320x2868, iPad 13" 2064x2752) for three UI variants:
   `en-US` (inches), `en-metric`, `fr`. Demo athlete, demo history — no
   ratings, no other people.
   `STORE_SHOTS_DIR=build/store_screenshots/raw flutter test tool/store_screenshots/capture_test.dart`
2. `compose.py` lays the 8-slide storyboard over them with headless Chrome
   (Anton + Inter), one caption set per language, and writes flattened RGB
   PNGs to `build/store_screenshots/final/<set>/<device>/`.
   `py -3.12 tool/store_screenshots/compose.py` (needs Pillow + Chrome/Edge)
3. `compose.STORE_LOCALES` maps each store locale onto a caption set.

Storyboard (mix of the three validated directions): 1 measured number over the
result · 2 film one jump · 3 the four scores · 4 gap to the rim · 5 plan ·
6 guided sets · 7 progress · 8 dunker closer. Slides 1 and 8 carry the
subscription notice (Guideline 2.3.2); the vertical is always "estimated".

Captions are code: change copy in `compose.CAPTIONS`, re-run, re-upload.

## Pushing it — `.github/workflows/asc-listing.yml`

Manual workflow, Linux runner. Inputs: listing file, `screenshots` (regenerate
in CI and upload; the composed set is also kept as an artifact), `dry_run`
(default on). It targets the app's editable App Store version, creates missing
localizations, and replaces each locale's screenshots per display size.

```
gh workflow run "ASC listing" --ref main -f listing=1.0 -f screenshots=true -f dry_run=true
```

## Blockers before a real (non-dry) push

- **Privacy policy URL** — the descriptions carry `{{PRIVACY_URL}}` and the
  script refuses to write while it does. Publish the page, put the URL in
  `build_listing.py` and `lib/core/legal_urls.dart`.
- **Support URL** — currently the GitHub repo; replace with a real page.
- **Category** (Health & Fitness primary, Sports secondary), age rating, App
  Privacy questionnaire — set once in App Store Connect.
