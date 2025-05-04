# Prehrajto Scraper

---
## 🧰 Predpoklady

- [Docker](https://www.docker.com/)
- [Docker Compose](https://docs.docker.com/compose/)

---
## 📦 Setup

### 1. Naklonuj repozitár

```bash
git clone https://github.com/tvoj-username/prehrajto-scraper.git
cd prehrajto-scraper
```

### 2. Priprav si `.env` súbory

Vytvor súbory s environment premennými pre rôzne prostredia:

#### `.env.development`
```env
RAILS_ENV=development
DATABASE_URL=postgres://postgres:password@db:5432/prehrajto_scraper
```

#### `.env.production`
```env
RAILS_ENV=production
DATABASE_URL=postgres://postgres:password@db:5432/prehrajto_scraper
SECRET_KEY_BASE=<vygenerovaný_secret>
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

Aplikácia bude bežať na: [http://localhost:8080](http://localhost:8080)

---

### ✅ Production

Pre build a spustenie v pozadí:

```bash
docker-compose -f docker-compose.production.yml up --build -d
```

Zastavenie produkcie:

```bash
docker-compose -f docker-compose.production.yml down
```

---

## 🛠 Užítočné príkazy

### Zastaviť a odstrániť kontajnery a volume:
```bash
docker-compose -f docker-compose.development.yml down -v
```

### Spustiť Rails konzolu:
```bash
docker-compose -f docker-compose.development.yml exec backend bin/rails console
```

---
