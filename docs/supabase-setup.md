# Supabase setup — global leaderboard

The Feed tab's **ALL-TIME VERTICAL** board is backed by Supabase. The app
ships fully functional without it: with no credentials the board shows an
honest "off in this build" card and everything else works offline, so CI, the
web preview and local runs need no secrets.

This document is the owner's checklist. **No credentials are committed to this
repo, ever** — they are passed at build time with `--dart-define`.

What the board stores, and nothing more: a display name, a vertical in inches,
a height in inches, and when the best was set. **No video, no thumbnails, no
free-form text.** That is deliberate — publishing user media would make this a
user-generated-content app, which App Store Guideline 1.2 then requires to
ship content filtering, in-app reporting, user blocking and 24-hour takedown.
Ranking on numbers alone avoids all of it. Do not add media columns.

---

## 1. Create the project

1. Sign in at <https://supabase.com> → **New project**.
2. Pick a region close to the athletes; note the database password (not used
   by the app, but needed for SQL access).
3. Once provisioned, go to **Project Settings → API** and copy:
   - **Project URL** → this is `SUPABASE_URL`
   - **anon / public** key → this is `SUPABASE_ANON_KEY`

The anon key is a publishable client key and is safe to embed in an app
binary *provided RLS is enabled* (step 3). Never ship the `service_role` key.

## 2. Enable anonymous sign-in

The app has no signup flow. Each athlete gets an anonymous identity, which is
what lets them own exactly one row.

**Authentication → Sign In / Providers → Anonymous sign-ins → enable.**

Optionally enable CAPTCHA protection there if the board attracts abuse; the
client currently sends no captcha token, so only turn it on together with a
code change.

## 3. Table, index and RLS

Run this in the **SQL Editor** as one script.

```sql
-- One row per athlete: their best measured vertical.
create table if not exists public.leaderboard_entries (
  athlete_id     uuid primary key references auth.users (id) on delete cascade,
  display_name   text        not null check (char_length(display_name) between 1 and 20),
  vertical_inches int        not null check (vertical_inches between 1 and 60),
  height_inches  int         not null check (height_inches between 36 and 96),
  recorded_at    timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

-- The ranking query: order by vertical desc, then recorded_at asc, limit 50.
create index if not exists leaderboard_entries_rank_idx
  on public.leaderboard_entries (vertical_inches desc, recorded_at asc);

-- Keep updated_at honest.
create or replace function public.touch_leaderboard_entry()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists leaderboard_entries_touch on public.leaderboard_entries;
create trigger leaderboard_entries_touch
  before update on public.leaderboard_entries
  for each row execute function public.touch_leaderboard_entry();

-- ROW LEVEL SECURITY. Without this, the anon key lets anyone rewrite the
-- whole board. This is the single most important step on this page.
alter table public.leaderboard_entries enable row level security;

-- Anyone (signed in or not) may read the board.
create policy "leaderboard is publicly readable"
  on public.leaderboard_entries
  for select
  to anon, authenticated
  using (true);

-- An athlete may create only their own row.
create policy "athletes insert their own row"
  on public.leaderboard_entries
  for insert
  to authenticated
  with check (auth.uid() = athlete_id);

-- An athlete may update only their own row, and may not reassign it.
create policy "athletes update their own row"
  on public.leaderboard_entries
  for update
  to authenticated
  using (auth.uid() = athlete_id)
  with check (auth.uid() = athlete_id);

-- Deliberately no delete policy: nobody can delete rows through the API.
```

Notes on the constraints:

- The `check` bounds mirror `LeaderboardAthlete`'s plausibility bounds
  (name ≤ 20 chars, vertical 1–60", height 36–96"). The client refuses to send
  anything outside them and the client *also* refuses to display anything
  outside them, so a row can never be forged past both.
- `athlete_id` is both the primary key and the FK to `auth.users`, which is
  what makes "one row per athlete" a database guarantee rather than a client
  convention. The client upserts on that key.
- Deleting an auth user cascades their board row away.

### Verifying RLS actually works

In the SQL editor, `set role anon;` then try
`update public.leaderboard_entries set vertical_inches = 60;` — it must affect
0 rows. If it rewrites the board, RLS is not on.

## 4. Build the app with credentials

Two dart-defines, exactly these names (read via `String.fromEnvironment` in
`lib/services/leaderboard_service.dart`):

| Define | Value |
|---|---|
| `SUPABASE_URL` | Project URL, e.g. `https://abcdefgh.supabase.co` |
| `SUPABASE_ANON_KEY` | The **anon / public** key |

Locally:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://abcdefgh.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOi...
```

Omit them and the app runs exactly as before, board locked.

## 5. Wiring them into CI (owner to do — not edited by the agent)

Add the two values as **repository secrets** (`Settings → Secrets and
variables → Actions → New repository secret`):

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

Then edit the **one** step that compiles Dart — in this workflow that is
`Build (CocoaPods install + asset compile, unsigned)`, which runs
`flutter build ios`. The later `xcodebuild archive` step re-packages what that
step produced, so the defines only need to go on the Flutter command:

```yaml
      - name: Build (CocoaPods install + asset compile, unsigned)
        env:
          FLUTTER_XCODE_IPHONEOS_DEPLOYMENT_TARGET: "15.0"
          SUPABASE_URL: ${{ secrets.SUPABASE_URL }}
          SUPABASE_ANON_KEY: ${{ secrets.SUPABASE_ANON_KEY }}
        run: |
          flutter build ios --release --no-codesign \
            --dart-define=SUPABASE_URL=$SUPABASE_URL \
            --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
```

(Only the `env:` block and the `run:` line change; keep the existing comment
and the deployment-target variable.)

Leave `.github/workflows/ci.yml` and `web-preview.yml` **alone**: analyze,
test and the public web preview must keep working with no secrets, and a
public preview build has no business embedding the key.

If a secret is missing at build time the define is an empty string, which the
app treats exactly like "not configured" — the build still succeeds and the
board shows its locked state, rather than shipping a broken network call.

## 6. Rotating or revoking

If the anon key ever needs rotating (Project Settings → API → rotate), update
the GitHub secret and ship a new build. Old builds fall back to the
unavailable board rather than crashing.
