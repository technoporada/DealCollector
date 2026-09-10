# 🎮 Deal Collector

**Automatyczny kolektor darmowych gier i programów**

Pobiera oferty ze Steam, Epic, GOG i SharewareOnSale. Dashboard w przeglądarce.

## 🚀 Instalacja

```bash
# 1. Zainstaluj zależności
pip install -r requirements.txt

# 2. Uruchom serwer
python main.py

# 3. Otwórz przeglądarkę
# http://127.0.0.1:8000
```

## ✨ Funkcje

- 🎮 **Steam** - darmowe gry (via SteamDB)
- 🔵 **Epic Games** - cotygodniowe darmówki
- 🟣 **GOG** - darmowe gry DRM-free
- 📦 **SharewareOnSale** - darmowe programy
- ⭐ **Ulubione** - zapisz oferty
- 🔄 **Auto-refresh** - odświeżaj co X minut

## 📁 Struktura

```
DealCollector/
├── main.py              # FastAPI server
├── requirements.txt     # Zależności
├── scrapers/            # Moduły scrapujące
│   ├── steamdb_scraper.py
│   ├── epic_scraper.py
│   ├── gog_scraper.py
│   └── shareware_scraper.py
└── frontend/            # Dashboard HTML/CSS/JS
    ├── index.html
    ├── style.css
    └── app.js
```

## 🛠️ Tech Stack

- **Backend**: FastAPI + Python
- **Scraping**: aiohttp + BeautifulSoup
- **Frontend**: Vanilla JS + CSS
- **Baza**: JSON (lokalnie)

## ⚠️ Uwagi

- Tylko do użytku lokalnego
- Nie spamuj odświeżaniem
- Szanuj regulaminy serwisów

## 📜 Licencja

MIT

---

*"Darmowe gry są dobre gry"* 🎮
