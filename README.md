# DealCollector

[![CI](https://github.com/technoporada/DealCollector/actions/workflows/ci.yml/badge.svg)](https://github.com/technoporada/DealCollector/actions)
[![Python 3.10+](https://img.shields.io/badge/python-3.10+-blue.svg)](https://python.org)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.104+-009688.svg)](https://fastapi.tiangolo.com)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

**Free games and software collector — Steam, Epic, GOG, SharewareOnSale.**

Dashboard with favorites, auto-refresh, and category filtering. Zero accounts needed.

> **Keywords:** `free-games` `steam` `epic-games` `gog` `deal-collector` `fastapi` `python` `scraping`

---

## Features

| Source | What it finds |
|--------|--------------|
| **SteamDB** | Free games on Steam |
| **Epic Games** | Weekly free games |
| **GOG** | DRM-free free games |
| **SharewareOnSale** | Free software deals |

- Favorites system
- Category filtering
- Auto-refresh
- JSON database (local)

## Quick Start

```bash
git clone https://github.com/technoporada/DealCollector.git
cd DealCollector

python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt

python main.py
# → http://127.0.0.1:8000
```

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/deals` | GET | All deals (optional `?category=`) |
| `/api/deals` | GET | Filter by category |
| `/api/favorites` | GET | Favorite deals |
| `/api/favorites/{id}` | POST | Add to favorites |
| `/api/favorites/{id}` | DELETE | Remove from favorites |
| `/api/scrape` | POST | Trigger scraping |
| `/api/stats` | GET | Dashboard stats |

## Project Structure

```
DealCollector/
├── main.py              # FastAPI server
├── requirements.txt
├── scrapers/
│   ├── base_scraper.py  # Base scraper class
│   ├── steamdb_scraper.py
│   ├── epic_scraper.py
│   ├── gog_scraper.py
│   └── shareware_scraper.py
└── frontend/
    ├── index.html
    ├── style.css
    └── app.js
```

## Tech Stack

- **Backend:** FastAPI + uvicorn
- **Scraping:** aiohttp + BeautifulSoup4
- **Frontend:** Vanilla JS + CSS
- **Database:** JSON (local)

## License

MIT

## Author

**technoporada** — [github.com/technoporada](https://github.com/technoporada)
