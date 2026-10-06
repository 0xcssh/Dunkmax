# App Marketing Context — Dunk It

> Foundation doc for all ASO / marketing skills. Created 2026-10-02 from the
> competitor + keyword research of the same day (iTunes Search/Lookup API,
> Apple search autocomplete in 9 storefronts, competitor review feeds).
> Update whenever positioning, pricing, or goals change.

## App Overview

- **App Name (store):** `Dunk It` + keyword suffix — see Current ASO State. The
  repo/package is still called `dunkmax`, but **"DunkMax" is taken on the App
  Store** by the reference app (id6757568089, "DunkMax: Vertical Jump
  Trainer") and the name must not be used anywhere public (duplicate-name
  rejection + Guideline 4.1 copycat risk).
- **App ID (Apple):** TBD (bundle id `com.awdia.dunkmax`)
- **Category:** Health & Fitness (primary) — candidate; Sports as secondary.
  The reference app uses Sports / Health & Fitness.
- **Platform:** iOS (iPhone + iPad — Flutter's default device family is 1,2,
  so 13" iPad screenshots are required)
- **Price Model:** Free download, subscription (yearly + weekly, 3-day trial,
  RevenueCat). Price TBD. Reference: DunkMax $59.99/yr + $7.99/wk; Jump AI
  $59.99/yr; How2Jump $19.99–59.99/yr.
- **Launch Date:** not yet launched
- **Current Version:** pre-1.0

## Value Proposition

- **Problem:** Players who want to dunk don't know their real vertical, how far
  they are from the rim, or what to train — and every jump app in the store is
  accused of inflated, made-up numbers (the #1 complaint across all competitor
  reviews: "says 41 inches, it's closer to 20").
- **Target Audience:** 14–25, basketball players (and secondarily volleyball
  players) who can almost touch/ just touch the rim and want their first dunk;
  train at home or in a gym, 2–5 days a week. Self-film with a phone.
- **Unique Differentiator:**
  - **Measured, not guessed** — vertical from flight time (h = g·t²/8) with
    on-device body tracking; when a clip can't be measured the app says why
    instead of inventing a number.
  - **4 form scores from the same pass** (Bounce, Power, Control, Form) +
    one-foot / two-foot takeoff detection + a written breakdown with tips
    mapped to the weakest score.
  - **Personal dunk gap** — height/reach → inches to dunk (one- vs two-hand).
  - **A real periodised plan** — 3 programs by level, rest days, progressive
    overload, deloads, home-equipment substitutions.
  - **Free analysis before the paywall**, units follow the region (cm / in),
    clips never leave the phone.
- **Elevator Pitch:** Film one jump, get your real vertical and how far you are
  from dunking — then follow the plan that closes the gap.

## Competitors

| App | App ID | Strengths | Weaknesses |
|-----|--------|-----------|------------|
| DunkMax: Vertical Jump Trainer | 6757568089 | Exact feature match, 4.76★ (692 US), ships often, AI chat coach | Accuracy complaints ("kids reading 40 inches"), hard paywall after quiz, SE layout bug, no FR/IT/BR/JP store metadata, iPhone-only |
| Jump AI: Jump Higher, Faster | 6748652914 | Category leader 4.73★ (1,482), 9 price tiers | Inconsistent readings (20→70 cm), crashes, no unit switch |
| How2Jump: Jump Higher, Faster | 6755148059 | "Jump higher in 60 days", skeleton overlay in screenshots | Small (151 ratings), workout bugs |
| My Jump Lab | 1554077178 | Scientific authority, 12 languages, strong ES/BR | Lab tool, not a dunk coach; light UI |
| Vertical Jump for Basketball | 1632125411 | Exact-match title | Stale (2025), absurd readings (756") |
| HomeCourt (adjacent) | 1258520424 | 14.9k ratings, basketball brand | Not jump-focused, stale since 2022 |
| New 2026 entrants | — | Hang Time (same flight-time method, localised everywhere), PlyoMetricAI, Dunk AI, Dunk Labs… | 0–10 ratings — the niche is filling fast |

## Current ASO State

Pre-launch — no listing. Working proposals (see the listing doc once validated):
- **Title:** `Dunk It: Vertical Jump Trainer` (30/30)
- **Subtitle:** `Measure Your Vert, Jump Higher` (30/30)
- **Primary keywords:** vertical jump, jump higher, vertical jump test/measure,
  vertical jump trainer/workout, jump training, plyometrics, basketball
  training, dunk (only inside phrases — "dunk" alone is game-dominated)
- **Rating:** n/a
- **Screenshots:** pipeline built — real screens captured by
  `tool/store_screenshots/capture_test.dart`, composed into marketing frames.
  Rules: no ratings, no user counts, no "top X %", "estimated vertical"
  wording, small subscription notice (Guideline 2.3.2).

## Goals

1. **Ship a listing that converts** — first 3 screenshots carry the pitch
   (≈60 % of visitors never scroll past them).
2. **Rank top 10 for "vertical jump trainer / test / workout" in the US** —
   weak fields (#1 results with 0 ratings).
3. **Own the non-English stores** — FR/BR/IT/JP have no localised competitor
   metadata; localise en-US, fr-FR, es-MX, es-ES, pt-BR, de-DE, it first.

## Resources

- **Budget:** $0 at launch — organic + ASO.
- **Team:** solo developer, Windows only (CI builds iOS).
- **Tools:** App Store Connect analytics, RevenueCat.
- **Constraints:** no fabricated social proof (project rule); app UI is en + fr
  only, so other locales get localised metadata + captions over English UI.

## Markets

- **Primary:** United States (also serves GB/CA/AU), France
- **Secondary:** Mexico + Spain (es-MX also indexes on the US store), Brazil
  ("impulsão", volleyball angle), Germany ("Sprungkraft"), Italy
- **Later:** Japan (垂直跳び / ジャンプ力), Korea (서전트 점프) — need a real UI
- **Languages shipped in-app:** en, fr
