# CLAUDE.md

Guidance for Claude Code when working in this repository.

## What this app is

Rails 7.0 monolith in Slovak with three loosely coupled features:

1. **Prehrajto scraper** — searches `prehrajto.cz` via HTTParty + Nokogiri,
   parses result tiles, and extracts direct video URLs from the `var sources`
   block on detail pages (`HomeController`, `FavsController#new`).
2. **Flight watchdog** — Sidekiq-cron job compares live Ryanair + Wizzair
   prices against saved `Watchdog` records and emails the user when the
   cheapest flight changes.
3. **Video stabilizer** — Active Storage uploads that get stabilized by a
   two-pass `ffmpeg` + `libvidstab` pipeline in a dedicated Sidekiq queue.

All three live behind Devise auth (`User.is_admin?` gates `/sidekiq`).

## Stack

- Ruby 3.3.6, Rails 7.0.3, PostgreSQL 14, Redis 7
- Sidekiq + `sidekiq-cron` (Active Job adapter is `:sidekiq`)
- Active Storage with the local disk service (`storage/`) — in production
  the `video_storage` volume is mounted into both the `backend` and
  `sidekiq_video` containers so the stabilizer and the Rails process share it
- Devise, Kaminari (with Bootstrap 5 views), Turbo + Stimulus via importmap
- Python helper `pyservice/ryanair_fetch.py` (pip package `ryanair-py`)
- External HTTP: Wizzair `be.wizzair.com` timetable API,
  Frankfurter FX (`api.frankfurter.dev`), Ryanair airports API

## Runtime topology

- `backend` — Puma on `:8080`
- `sidekiq` — queues `default`, `mailers`, concurrency 5
- `sidekiq_video` — queue `video_processing`, **concurrency 1** (ffmpeg is
  CPU heavy; do not raise this without checking the host)
- Cron schedule lives in `config/initializers/sidekiq.rb`
  (`*/15 * * * *` → `WatchdogRunnerWorker` → `WatchdogRunnerJob`)

Queues are declared in `config/sidekiq.yml`. If you add a new queue, update
`sidekiq.yml` **and** the production compose command args, otherwise jobs
silently pile up.

## Feature-specific notes

### Watchdogs

- `Watchdog#can_analyze_price?` is the gate for writing to `price_history`:
  it requires `date_watch_from == date_watch_to` **and** a concrete
  `to_airport`. Open-ended searches never produce a chart-able series.
- `price_history` is a JSON array of `{"x" => iso8601, "y" => price}` points,
  sorted ascending, pruned to `KEEP_PRICE_HISTORY_FOR_MONTHS = 3`.
- Emails only send when `price_changed` is true *and* there's at least one
  flight under `max_price`. A watchdog whose `date_watch_to` has passed is
  deactivated at the end of the run.
- `RyanairFlightFetcher` shells out to Python via `cmd.shelljoin` and
  parses stdout as JSON — if the Python process prints anything non-JSON
  (warning, traceback), the fetch silently returns `[]`. Check Rails logs.
- `WizzairFlightFetcher` talks to `be.wizzair.com/{version}/Api/search/timetable`.
  The API version is discovered from `wizzair.com/en-gb/` (`discover_version`)
  and cached for 6 h under `wizzair_api_version`; a 404 or 5xx response
  invalidates the cache so the next call re-discovers. `API_VERSION_DEFAULT`
  is the fallback only when discovery fails. **All Wizzair prices are
  converted to EUR** via `CurrencyConverter.to_eur` before returning —
  Ryanair prices are assumed already EUR. Keep this invariant when adding
  providers, otherwise the sort/compare against `max_price` breaks.
- `CurrencyConverter` caches FX rates for 6 h under `fx_<CCY>_to_eur`. On
  any HTTP failure it returns `nil` and the flight is skipped.

### Video stabilizer

- `VideoStabilizeJob` early-returns unless `video.pending?`, so re-enqueues
  are safe.
- Two-pass ffmpeg (`vidstabdetect` → `vidstabtransform`) with `crf=18`,
  `-preset slow`. Metadata (including `creation_time`) is forwarded; if the
  source had `creation_time`, the output file's mtime is reset to it so
  downloads show the correct date.
- `recorded_at` is filled from client-side JS (`recorded_ats[]` param on
  upload) when ffprobe can't find `creation_time`. The download action
  uses whichever is present for the `Last-Modified` header.
- `VideosController#create` accepts a single file or an array
  (`original_videos[]`) and enqueues one job per saved record. Redirect
  target depends on how many videos were uploaded / failed.

### Prehrajto extraction

`HomeController#prehrajto` and `FavsController#new` both slice the raw HTML
between `var sources` and `var tracks` and pull the first quoted string.
If prehrajto.cz changes that markup, both places break together — update
them together.

## Conventions that aren't obvious from the code

- **Locale default is `:sk`.** Copy in controllers/flash/mailers is Slovak.
  When adding user-facing strings, add keys to both `config/locales/sk.yml`
  and `config/locales/en.yml`.
- **Timezone is pinned to `Europe/Bratislava`** with
  `config.active_record.default_timezone = :local` and
  `time_zone_aware_attributes = false`. Dates in watchdogs are compared
  with `Date.current`, not `Time.zone.today` — keep it that way.
- **Production has hardcoded host fallbacks** (`PRODUCTION_URL`,
  `default_url_options` in `ApplicationController`). If the deployment
  target moves off `62.65.160.178:46580`, update `ApplicationController`
  **and** the CORS allowlist in `config/application.rb`.
- **Authorization is ad-hoc**: each controller has its own
  `authorize_user` before_action comparing `current_user.id` against the
  owner and falling back to `is_admin?`. There is no Pundit/CanCan — keep
  the same pattern when adding owner-scoped resources.
- **No service-object base class.** `app/services/*` are plain Ruby classes
  with class methods; state (if any) lives in `Rails.cache` with explicit
  keys and TTLs.
- **Sidekiq admin mount is behind `authenticate :user, ->(u) { u.is_admin? }`**
  in `routes.rb` — don't expose it more broadly.

## Working with the codebase

- Schema changes: add a migration under `db/migrate/`; the existing files
  use `ActiveRecord::Migration[7.0]`. `db/schema.rb` is checked in.
- When adding a cron entry, put it in `Sidekiq::Cron::Job.load_from_hash!`
  inside the sidekiq initializer (not in a separate YAML).
- Background jobs that need file I/O from Active Storage must run on
  `sidekiq_video` (or whichever container has the `video_storage` volume
  mounted); the mailer/default sidekiq container does **not** have it.
- The `bin/docker-entrypoint` script runs `bin/rails db:prepare` before the
  server starts — migrations apply on container boot, no manual step needed.

## Things to avoid

- Don't raise `sidekiq_video` concurrency above 1 unless you also cap
  ffmpeg threads — the host will thrash.
- Don't add a provider to the watchdog runner without converting prices to
  EUR first; the sort and `max_price` filter assume a single currency.
- Don't call `RyanairFlightFetcher` in a request cycle — it shells out to
  Python and takes seconds. It belongs in a job.
- Don't add code that relies on the prehrajto.cz markup outside the two
  existing extraction sites — if you need it in a third place, extract a
  service first.
