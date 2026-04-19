# Prehrajto Scraper

Rails 7 aplikácia spájajúca tri hlavné funkcie:

- **Prehrajto scraper** – vyhľadávanie videí na [prehrajto.cz](https://prehrajto.cz),
  extrakcia priameho video zdroja a ukladanie obľúbených položiek.
- **Flight watchdogy** – sledovanie cien letov cez **Ryanair** a **Wizzair**
  s históriou cien, normalizáciou do EUR a e-mailovou notifikáciou pri zmene ceny.
- **Video stabilizer** – upload videí, dvojfázová stabilizácia cez `ffmpeg` + `vidstab`
  a download výsledku so zachovaným dátumom nahratia.

---

## 🧱 Tech stack

- Ruby 3.3.6, Rails 7.0
- PostgreSQL 14
- Redis 7 + Sidekiq + `sidekiq-cron`
- Active Storage (disk service, namontovaný volume v produkcii)
- Devise (autentifikácia + admin flag)
- Importmap + Stimulus + Turbo, Bootstrap views pre Kaminari
- Python 3 (`ryanair-py`) ako externý helper pre Ryanair API
- `ffmpeg` s `libvidstab` pre stabilizáciu videí
- I18n: `sk` (default), `en`

---

## 🧰 Predpoklady

- [Docker](https://www.docker.com/) + [Docker Compose](https://docs.docker.com/compose/)

---

## 📦 Setup

### 1. Naklonuj repozitár

```bash
git clone https://github.com/xPalo/prehrajto-scraper.git
cd prehrajto-scraper
```

### 2. Priprav `.env` súbory

#### `.env.development`
```env
RAILS_ENV=development
DATABASE_URL=postgres://postgres:password@db:5432/prehrajto_scraper
REDIS_URL=redis://redis:6379/0
```

#### `.env.production`
```env
RAILS_ENV=production
DATABASE_URL=postgres://postgres:password@db:5432/prehrajto_scraper
REDIS_URL=redis://redis:6379/0
SECRET_KEY_BASE=<vygenerovaný_secret>
GMAIL_USERNAME=<gmail-adresa-pre-notifikácie>
GMAIL_PASSWORD=<app-password>
# Voliteľné – override Wizzair API verzie ak pokazia backend:
# WIZZAIR_API_VERSION=28.6.0
```

Vygeneruj nový `SECRET_KEY_BASE`:
```bash
docker-compose -f docker-compose.production.yml run --rm backend bin/rails secret
```

---

## 🚀 Spustenie

### ✅ Development

```bash
docker-compose -f docker-compose.development.yml up --build
```

Aplikácia beží na [http://localhost:8080](http://localhost:8080).

### ✅ Production

```bash
docker-compose -f docker-compose.production.yml up --build -d
```

Produkčný compose spúšťa päť služieb: `db`, `redis`, `backend`, `sidekiq`
(queues `default`, `mailers`) a `sidekiq_video` (queue `video_processing`,
concurrency 1, aby sa ffmpeg behy neprelínali).

Zastavenie:
```bash
docker-compose -f docker-compose.production.yml down
```

---

## 🛠 Užitočné príkazy

### Rails konzola
```bash
docker-compose -f docker-compose.development.yml exec backend bin/rails console
```

### Zastaviť kontajnery aj s volume
```bash
docker-compose -f docker-compose.development.yml down -v
```

### Sidekiq web UI
V produkcii dostupný na `/sidekiq` pre používateľov s `is_admin = true`.

### Ručné spustenie watchdog behu
```bash
docker-compose -f docker-compose.production.yml exec backend \
  bin/rails runner "WatchdogRunnerJob.perform_now"
```

---

## 🧩 Funkčné moduly

### Prehrajto vyhľadávanie (`HomeController#prehrajto`)
- GET formulár zvláda `search_url` (zoznam výsledkov) aj `movie_url`
  (priamy video zdroj extrahovaný z HTML detailu).
- Výsledky môžu byť zoradené podľa title/size/duration (asc/desc).

### Obľúbené (`FavsController`)
- CRUD nad modelom `Fav`, scope-ovaný na prihláseného usera.
- `new` akcia vie predvyplniť video zdroj rovnakou extrakciou ako homepage.

### Flight watchdog (`WatchdogsController`, `WatchdogRunnerJob`)
- Každý watchdog má: `from_airport`, voliteľne `to_airport` + `to_country`,
  `date_watch_from/to`, voliteľne `departure_time_from/to`, `max_price`, `is_active`.
- Cron `*/15 * * * *` cez `sidekiq-cron` spúšťa `WatchdogRunnerWorker`,
  ten enqueuuje `WatchdogRunnerJob`.
- Letenky sú paralelne načítané cez `RyanairFlightFetcher`
  (Python subproces `pyservice/ryanair_fetch.py`) a `WizzairFlightFetcher`
  (priame volanie Wizzair `timetable` endpointu).
- Wizzair ceny sú normalizované do EUR cez `CurrencyConverter`
  (Frankfurter API, cache 12 h). Ryanair ceny chodia už v EUR.
- Ak `watchdog.can_analyze_price?` (presný dátum + konkrétne letisko),
  najnižšia aktuálna cena sa zapíše do `price_history`
  (`[{x: ISO8601, y: price}]`, TTL `KEEP_PRICE_HISTORY_FOR_MONTHS = 3`).
- E-mail (`RaincheckMailer#watchdog_email`) sa pošle **iba ak sa cena zmenila**
  od posledného behu a zároveň existujú lety pod `max_price`.
- Watchdog s `date_watch_to < today` sa po behu deaktivuje.

### Video stabilizer (`VideosController`, `VideoStabilizeJob`)
- Upload jedného alebo viacerých videí naraz (`original_videos[]`),
  s progress barom. K uploadu posiela klient pole `recorded_ats` (JSON),
  aby sa dátum nahratia zachoval, keď chýba v metadátach.
- Validácia: max 500 MB, whitelisted MIME typy.
- Job beží na queue `video_processing` (concurrency 1):
  1. Ffprobe získa `duration` a `creation_time`.
  2. `ffmpeg -vf vidstabdetect` (pass 1) vyrobí `transforms.trf`.
  3. `ffmpeg -vf vidstabtransform` (pass 2) s `libx264 crf=18`, zachovanými metadátami
     a `creation_time` nastaveným späť na originálny dátum.
- Stavový stroj: `pending → processing → completed|failed`,
  chyba sa ukladá do `error_message`.
- `videos#show` odpovedá aj JSONom (polling pre progress UI),
  `videos#download` servíruje stabilizovaný súbor cez `send_file`
  s `Last-Modified` z `recorded_at`.

### Admin
- `User.is_admin?` odomyká `/sidekiq` mountpoint (`config/routes.rb`).

### I18n a téma
- Jazyk sa prepína cez `/lang/:locale`, ukladá sa do cookie `lang`.
- Tmavá téma sa prepína cez cookie `theme=dark` (čítané v `ApplicationController#set_theme`).

---

## 🗂 Štruktúra kódu

```
app/
├── controllers/   # home, favs, watchdogs, videos, users
├── jobs/          # VideoStabilizeJob, WatchdogRunnerJob, WatchdogRunnerWorker
├── mailers/       # RaincheckMailer
├── models/        # User (Devise), Fav, Watchdog, Video
└── services/      # RyanairFlightFetcher, WizzairFlightFetcher,
                   # RyanairAirportLoader, CurrencyConverter
config/
├── initializers/sidekiq.rb   # sidekiq-cron schedule
└── sidekiq.yml               # queues: default, mailers, video_processing
pyservice/
└── ryanair_fetch.py          # CLI wrapper nad `ryanair-py`
```

---

## 🧪 Testy

Rails default test suite (`bin/rails test`), Capybara + Selenium v `test/system`.
