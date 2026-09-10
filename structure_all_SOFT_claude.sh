#!/bin/bash
# Deal Collector - Automatyczne tworzenie struktury projektu
# Uruchom: bash structure_all.sh

echo "🎮 Tworzenie Deal Collector..."

# Tworzenie struktury folderów
mkdir -p scrapers frontend
echo "📁 Foldery utworzone"

# requirements.txt
cat > requirements.txt << 'EOF'
fastapi==0.104.1
uvicorn[standard]==0.24.0
aiohttp==3.9.1
beautifulsoup4==4.12.2
lxml==4.9.3
requests==2.31.0
EOF

# scrapers/__init__.py
cat > scrapers/__init__.py << 'EOF'
# Pusty plik __init__.py aby scrapers był uznany za moduł Python
EOF

# scrapers/base_scraper.py
cat > scrapers/base_scraper.py << 'EOF'
from abc import ABC, abstractmethod
from dataclasses import dataclass, asdict
from typing import List, Optional
from datetime import datetime
import hashlib

@dataclass
class Deal:
    title: str
    url: str
    price: str
    original_price: str
    category: str
    source: str
    description: Optional[str] = None
    image_url: Optional[str] = None
    valid_until: Optional[str] = None
    rating: Optional[str] = None
    id: Optional[str] = None
    scraped_at: Optional[str] = None

    def __post_init__(self):
        if not self.id:
            content = f"{self.title}{self.url}{self.source}"
            self.id = hashlib.md5(content.encode()).hexdigest()[:12]
        if not self.scraped_at:
            self.scraped_at = datetime.now().isoformat()

    def to_dict(self) -> dict:
        return asdict(self)

class BaseScraper(ABC):
    def __init__(self, name: str, base_url: str):
        self.name = name
        self.base_url = base_url
        self.headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'}

    @abstractmethod
    async def scrape(self) -> List[Deal]:
        pass

    def clean_price(self, price_text: str) -> str:
        if not price_text or any(word in price_text.lower() for word in ['free', 'darmowa', '0']):
            return "Free"
        return price_text.strip()

    def clean_title(self, title: str) -> str:
        return title.strip()[:200] if title else "Unknown"

    def is_valid_deal(self, deal: Deal) -> bool:
        return bool(deal.title and deal.url and deal.source)
EOF

# scrapers/steamdb_scraper.py
cat > scrapers/steamdb_scraper.py << 'EOF'
import aiohttp
from bs4 import BeautifulSoup
from typing import List
from .base_scraper import BaseScraper, Deal

class SteamDBScraper(BaseScraper):
    def __init__(self):
        super().__init__("SteamDB", "https://steamdb.info")
        self.free_games_url = "https://steamdb.info/upcoming/free/"

    async def scrape(self) -> List[Deal]:
        deals = []
        try:
            async with aiohttp.ClientSession(headers=self.headers) as session:
                async with session.get(self.free_games_url) as response:
                    if response.status == 200:
                        html = await response.text()
                        deals = self._parse_steamdb_page(html)
        except Exception as e:
            print(f"SteamDB error: {e}")
        return deals

    def _parse_steamdb_page(self, html: str) -> List[Deal]:
        deals = []
        soup = BeautifulSoup(html, 'html.parser')
        table = soup.find('table')

        if table:
            for row in table.find_all('tr')[1:15]:  # Max 15 gier
                try:
                    cells = row.find_all(['td', 'th'])
                    if len(cells) < 3:
                        continue

                    title_cell = cells[0]
                    title_link = title_cell.find('a')
                    title = self.clean_title(title_link.get_text(strip=True) if title_link else "Unknown")

                    url = title_link.get('href') if title_link else ""
                    if url and not url.startswith('http'):
                        url = f"https://steamdb.info{url}"

                    deals.append(Deal(
                        title=title,
                        url=url or "https://store.steampowered.com/",
                        price="Free",
                        original_price="Unknown",
                        category="Games",
                        source="SteamDB",
                        description="Free Steam game"
                    ))
                except:
                    continue
        return deals
EOF

# scrapers/epic_scraper.py
cat > scrapers/epic_scraper.py << 'EOF'
import aiohttp
import json
from typing import List
from .base_scraper import BaseScraper, Deal

class EpicScraper(BaseScraper):
    def __init__(self):
        super().__init__("Epic Games", "https://store.epicgames.com")
        self.api_url = "https://store-site-backend-static.ak.epicgames.com/freeGamesPromotions"

    async def scrape(self) -> List[Deal]:
        deals = []
        try:
            async with aiohttp.ClientSession(headers=self.headers) as session:
                async with session.get(self.api_url) as response:
                    if response.status == 200:
                        data = await response.json()
                        deals = self._parse_epic_data(data)
        except Exception as e:
            print(f"Epic error: {e}")
        return deals

    def _parse_epic_data(self, data: dict) -> List[Deal]:
        deals = []
        try:
            games = data.get('data', {}).get('Catalog', {}).get('searchStore', {}).get('elements', [])

            for game in games[:10]:  # Max 10 gier
                if game.get('price', {}).get('totalPrice', {}).get('discountPrice', 0) == 0:
                    title = game.get('title', 'Unknown')
                    url = f"https://store.epicgames.com/p/{game.get('catalogNs', {}).get('mappings', [{}])[0].get('pageSlug', '')}"

                    deals.append(Deal(
                        title=self.clean_title(title),
                        url=url,
                        price="Free",
                        original_price=f"${game.get('price', {}).get('totalPrice', {}).get('originalPrice', 0)/100:.2f}",
                        category="Games",
                        source="Epic Games",
                        description=game.get('description', '')[:200]
                    ))
        except:
            pass
        return deals
EOF

# scrapers/gog_scraper.py
cat > scrapers/gog_scraper.py << 'EOF'
import aiohttp
from bs4 import BeautifulSoup
from typing import List
from .base_scraper import BaseScraper, Deal

class GOGScraper(BaseScraper):
    def __init__(self):
        super().__init__("GOG", "https://www.gog.com")
        self.free_url = "https://www.gog.com/games?price=free"

    async def scrape(self) -> List[Deal]:
        deals = []
        try:
            async with aiohttp.ClientSession(headers=self.headers) as session:
                async with session.get(self.free_url) as response:
                    if response.status == 200:
                        html = await response.text()
                        deals = self._parse_gog_page(html)
        except Exception as e:
            print(f"GOG error: {e}")
        return deals

    def _parse_gog_page(self, html: str) -> List[Deal]:
        deals = []
        soup = BeautifulSoup(html, 'html.parser')

        # GOG używa różnych selektorów
        games = soup.find_all(['div', 'article'], class_=lambda x: x and 'product' in x.lower())[:8]

        for game in games:
            try:
                title_elem = game.find(['a', 'h3'], class_=lambda x: x and 'title' in str(x).lower())
                if not title_elem:
                    continue

                title = self.clean_title(title_elem.get_text(strip=True))
                url = title_elem.get('href', '')
                if url and not url.startswith('http'):
                    url = f"https://www.gog.com{url}"

                deals.append(Deal(
                    title=title,
                    url=url,
                    price="Free",
                    original_price="Unknown",
                    category="Games",
                    source="GOG",
                    description="DRM-free game"
                ))
            except:
                continue
        return deals
EOF

# scrapers/shareware_scraper.py
cat > scrapers/shareware_scraper.py << 'EOF'
import aiohttp
from bs4 import BeautifulSoup
from typing import List
from .base_scraper import BaseScraper, Deal

class SharewareScraper(BaseScraper):
    def __init__(self):
        super().__init__("SharewareOnSale", "https://sharewareonsale.com")
        self.base_url = "https://sharewareonsale.com"

    async def scrape(self) -> List[Deal]:
        deals = []
        try:
            async with aiohttp.ClientSession(headers=self.headers) as session:
                async with session.get(self.base_url) as response:
                    if response.status == 200:
                        html = await response.text()
                        deals = self._parse_shareware_page(html)
        except Exception as e:
            print(f"Shareware error: {e}")
        return deals

    def _parse_shareware_page(self, html: str) -> List[Deal]:
        deals = []
        soup = BeautifulSoup(html, 'html.parser')

        # Szukamy ofert na stronie głównej
        offers = soup.find_all(['div', 'article'], class_=lambda x: x and ('offer' in str(x).lower() or 'deal' in str(x).lower()))[:6]

        for offer in offers:
            try:
                title_elem = offer.find(['a', 'h2', 'h3'])
                if not title_elem:
                    continue

                title = self.clean_title(title_elem.get_text(strip=True))
                url = title_elem.get('href', '')
                if url and not url.startswith('http'):
                    url = f"{self.base_url}{url}"

                # Próba znalezienia ceny
                price_elem = offer.find(text=lambda x: x and ('free' in x.lower() or '$0' in x))
                price = "Free" if price_elem else "Special Offer"

                deals.append(Deal(
                    title=title,
                    url=url or self.base_url,
                    price=price,
                    original_price="Unknown",
                    category="Software",
                    source="SharewareOnSale",
                    description="Software giveaway"
                ))
            except:
                continue
        return deals
EOF

# main.py
cat > main.py << 'EOF'
from fastapi import FastAPI, HTTPException
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
import json
import asyncio
from datetime import datetime
from scrapers.steamdb_scraper import SteamDBScraper
from scrapers.epic_scraper import EpicScraper
from scrapers.gog_scraper import GOGScraper
from scrapers.shareware_scraper import SharewareScraper
from scrapers.base_scraper import Deal
import uvicorn

app = FastAPI(title="Deal Collector", version="1.0.0")
app.mount("/static", StaticFiles(directory="frontend"), name="static")

DB_FILE = "deals.json"

def load_deals():
    try:
        with open(DB_FILE, 'r', encoding='utf-8') as f:
            return json.load(f)
    except FileNotFoundError:
        return {"deals": [], "favorites": []}

def save_deals(data):
    with open(DB_FILE, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

@app.get("/")
async def root():
    return FileResponse("frontend/index.html")

@app.get("/api/deals")
async def get_deals(category: str = None):
    data = load_deals()
    deals = data["deals"]
    if category:
        deals = [deal for deal in deals if deal.get("category", "").lower() == category.lower()]
    return {"deals": deals, "count": len(deals)}

@app.get("/api/favorites")
async def get_favorites():
    data = load_deals()
    favorites = data.get("favorites", [])
    favorite_deals = [deal for deal in data["deals"] if deal["id"] in favorites]
    return {"deals": favorite_deals, "count": len(favorite_deals)}

@app.post("/api/favorites/{deal_id}")
async def add_to_favorites(deal_id: str):
    data = load_deals()
    if "favorites" not in data:
        data["favorites"] = []
    if deal_id not in data["favorites"]:
        data["favorites"].append(deal_id)
        save_deals(data)
    return {"status": "added", "deal_id": deal_id}

@app.delete("/api/favorites/{deal_id}")
async def remove_from_favorites(deal_id: str):
    data = load_deals()
    if "favorites" not in data:
        data["favorites"] = []
    if deal_id in data["favorites"]:
        data["favorites"].remove(deal_id)
        save_deals(data)
    return {"status": "removed", "deal_id": deal_id}

@app.post("/api/scrape")
async def scrape_deals():
    try:
        scrapers = [
            SteamDBScraper(),
            EpicScraper(),
            GOGScraper(),
            SharewareScraper()
        ]

        all_deals = []
        for scraper in scrapers:
            print(f"Scrapowanie {scraper.name}...")
            deals = await scraper.scrape()
            all_deals.extend([deal.to_dict() for deal in deals])

        data = load_deals()
        data["deals"] = all_deals
        data["last_update"] = datetime.now().isoformat()
        save_deals(data)

        return {
            "status": "success",
            "total_deals": len(all_deals),
            "timestamp": datetime.now().isoformat()
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/stats")
async def get_stats():
    data = load_deals()
    deals = data.get("deals", [])

    categories = {}
    for deal in deals:
        cat = deal.get("category", "unknown")
        categories[cat] = categories.get(cat, 0) + 1

    return {
        "total_deals": len(deals),
        "favorites_count": len(data.get("favorites", [])),
        "categories": categories,
        "last_update": data.get("last_update", "Never")
    }

if __name__ == "__main__":
    uvicorn.run(app, host="127.0.0.1", port=8000, reload=True)
EOF

# frontend/index.html
cat > frontend/index.html << 'EOF'
<!DOCTYPE html>
<html lang="pl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Deal Collector</title>
    <link rel="stylesheet" href="/static/style.css">
</head>
<body>
    <div class="container">
        <header class="header">
            <h1>🎮 Deal Collector</h1>
            <p>Steam, Epic, GOG, SharewareOnSale</p>
            <div class="controls">
                <button id="scrape-btn" class="btn btn-primary">🔄 Odśwież</button>
                <button id="favorites-btn" class="btn btn-secondary">⭐ Ulubione</button>
                <button id="all-deals-btn" class="btn btn-secondary">📋 Wszystkie</button>
            </div>
        </header>

        <div class="filters">
            <select id="category-filter">
                <option value="">Wszystkie</option>
                <option value="games">Gry</option>
                <option value="software">Programy</option>
            </select>
            <div class="stats" id="stats">
                <span id="deals-count">0 ofert</span>
                <span id="last-update">Nigdy</span>
            </div>
        </div>

        <main class="main">
            <div id="loading" class="loading" style="display: none;">
                <div class="spinner"></div>
                <p>Ładowanie...</p>
            </div>
            <div id="deals-container" class="deals-container"></div>
        </main>
    </div>
    <div id="toast-container" class="toast-container"></div>
    <script src="/static/app.js"></script>
</body>
</html>
EOF

# frontend/style.css (skrócona wersja)
cat > frontend/style.css << 'EOF'
* { margin: 0; padding: 0; box-sizing: border-box; }
body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; color: #333; }
.container { max-width: 1200px; margin: 0 auto; padding: 20px; }
.header { text-align: center; margin-bottom: 30px; background: rgba(255, 255, 255, 0.95); padding: 30px; border-radius: 15px; box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1); }
.header h1 { font-size: 2.5em; margin-bottom: 10px; color: #4a5568; }
.header p { color: #718096; font-size: 1.1em; margin-bottom: 20px; }
.controls { display: flex; justify-content: center; gap: 15px; flex-wrap: wrap; }
.btn { padding: 12px 24px; border: none; border-radius: 8px; cursor: pointer; font-weight: 600; transition: all 0.3s ease; font-size: 14px; }
.btn-primary { background: #4299e1; color: white; }
.btn-primary:hover { background: #3182ce; transform: translateY(-2px); }
.btn-secondary { background: #e2e8f0; color: #4a5568; }
.btn-secondary:hover { background: #cbd5e0; }
.filters { display: flex; align-items: center; justify-content: space-between; background: rgba(255, 255, 255, 0.9); padding: 15px 20px; border-radius: 10px; margin-bottom: 20px; box-shadow: 0 4px 16px rgba(0, 0, 0, 0.1); flex-wrap: wrap; gap: 15px; }
#category-filter { padding: 8px 12px; border: 2px solid #e2e8f0; border-radius: 6px; font-size: 14px; }
.stats { display: flex; gap: 20px; font-size: 14px; color: #718096; }
.loading { text-align: center; padding: 60px; }
.spinner { width: 50px; height: 50px; border: 4px solid #f3f3f3; border-top: 4px solid #4299e1; border-radius: 50%; animation: spin 1s linear infinite; margin: 0 auto 20px; }
@keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }
.deals-container { display: grid; grid-template-columns: repeat(auto-fill, minmax(350px, 1fr)); gap: 25px; margin-top: 20px; }
.deal-card { background: rgba(255, 255, 255, 0.95); border-radius: 12px; padding: 20px; box-shadow: 0 6px 24px rgba(0, 0, 0, 0.1); transition: all 0.3s ease; border: 2px solid transparent; }
.deal-card:hover { transform: translateY(-5px); box-shadow: 0 12px 32px rgba(0, 0, 0, 0.15); border-color: #4299e1; }
.deal-card.favorited { border-color: #f6ad55; background: rgba(255, 235, 59, 0.05); }
.deal-header { display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 15px; }
.deal-title { font-size: 1.2em; font-weight: 700; color: #2d3748; flex: 1; margin-right: 10px; line-height: 1.3; }
.favorite-btn { background: none; border: none; font-size: 1.5em; cursor: pointer; transition: all 0.2s ease; padding: 5px; border-radius: 50%; }
.favorite-btn:hover { background: rgba(0, 0, 0, 0.05); transform: scale(1.1); }
.favorite-btn.favorited { color: #f6ad55; }
.deal-info { margin-bottom: 15px; }
.price-info { display: flex; align-items: center; gap: 10px; margin-bottom: 10px; }
.current-price { font-size: 1.3em; font-weight: 700; color: #38a169; }
.original-price { color: #a0aec0; text-decoration: line-through; font-size: 0.9em; }
.deal-meta { display: flex; gap: 15px; font-size: 0.85em; color: #718096; margin-bottom: 10px; }
.category-badge { background: #edf2f7; padding: 4px 8px; border-radius: 4px; font-weight: 600; color: #4a5568; }
.source-badge { background: #e6fffa; padding: 4px 8px; border-radius: 4px; color: #319795; font-weight: 600; }
.deal-description { color: #4a5568; font-size: 0.9em; line-height: 1.4; margin-bottom: 15px; }
.deal-footer { display: flex; justify-content: space-between; align-items: center; }
.deal-link { padding: 8px 16px; background: #4299e1; color: white; text-decoration: none; border-radius: 6px; font-weight: 600; transition: all 0.2s ease; font-size: 14px; }
.deal-link:hover { background: #3182ce; transform: translateY(-1px); }
.deal-time { font-size: 0.8em; color: #a0aec0; }
.toast-container { position: fixed; top: 20px; right: 20px; z-index: 1000; }
.toast { background: #4299e1; color: white; padding: 15px 20px; border-radius: 8px; margin-bottom: 10px; box-shadow: 0 4px 16px rgba(0, 0, 0, 0.2); opacity: 0; transform: translateX(100%); transition: all 0.3s ease; }
.toast.show { opacity: 1; transform: translateX(0); }
.toast.success { background: #38a169; }
.toast.error { background: #e53e3e; }
@media (max-width: 768px) { .container { padding: 15px; } .deals-container { grid-template-columns: 1fr; gap: 15px; } .filters { flex-direction: column; align-items: stretch; } .controls { flex-direction: column; } .header h1 { font-size: 2em; } }
EOF

# frontend/app.js (skrócona wersja)
cat > frontend/app.js << 'EOF'
class DealCollector {
    constructor() {
        this.deals = [];
        this.favorites = [];
        this.currentView = 'all';
        this.currentFilter = '';
        this.init();
    }

    init() {
        this.bindEvents();
        this.loadDeals();
        this.loadStats();
    }

    bindEvents() {
        document.getElementById('scrape-btn').addEventListener('click', () => this.scrapeDeals());
        document.getElementById('favorites-btn').addEventListener('click', () => this.showFavorites());
        document.getElementById('all-deals-btn').addEventListener('click', () => this.showAllDeals());
        document.getElementById('category-filter').addEventListener('change', (e) => {
            this.currentFilter = e.target.value;
            this.renderDeals();
        });
    }

    async loadDeals() {
        this.showLoading(true);
        try {
            const response = await fetch('/api/deals');
            const data = await response.json();
            this.deals = data.deals || [];
            this.renderDeals();
        } catch (error) {
            this.showToast('Błąd ładowania', 'error');
        } finally {
            this.showLoading(false);
        }
    }

    async loadStats() {
        try {
            const response = await fetch('/api/stats');
            const data = await response.json();
            document.getElementById('deals-count').textContent = `${data.total_deals} ofert`;
            const lastUpdate = data.last_update !== 'Never' ? new Date(data.last_update).toLocaleString('pl-PL') : 'Nigdy';
            document.getElementById('last-update').textContent = `${lastUpdate}`;
        } catch (error) {
            console.error('Stats error:', error);
        }
    }

    async scrapeDeals() {
        const btn = document.getElementById('scrape-btn');
        btn.textContent = '🔄 Scrapowanie...';
        btn.disabled = true;

        try {
            const response = await fetch('/api/scrape', { method: 'POST' });
            const data = await response.json();
            if (data.status === 'success') {
                this.showToast(`Znaleziono ${data.total_deals} ofert`, 'success');
                await this.loadDeals();
                await this.loadStats();
            }
        } catch (error) {
            this.showToast('Błąd scrapowania', 'error');
        } finally {
            btn.textContent = '🔄 Odśwież';
            btn.disabled = false;
        }
    }

    async showFavorites() {
        this.currentView = 'favorites';
        this.showLoading(true);
        try {
            const response = await fetch('/api/favorites');
            const data = await response.json();
            this.deals = data.deals || [];
            this.renderDeals();
            document.getElementById('favorites-btn').classList.add('btn-primary');
            document.getElementById('favorites-btn').classList.remove('btn-secondary');
            document.getElementById('all-deals-btn').classList.add('btn-secondary');
            document.getElementById('all-deals-btn').classList.remove('btn-primary');
        } catch (error) {
            this.showToast('Błąd ulubionych', 'error');
        } finally {
            this.showLoading(false);
        }
    }

    async showAllDeals() {
        this.currentView = 'all';
        document.getElementById('all-deals-btn').classList.add('btn-primary');
        document.getElementById('all-deals-btn').classList.remove('btn-secondary');
        document.getElementById('favorites-btn').classList.add('btn-secondary');
        document.getElementById('favorites-btn').classList.remove('btn-primary');
        await this.loadDeals();
    }

    renderDeals() {
        const container = document.getElementById('deals-container');
        let dealsToShow = this.deals;

        if (this.currentFilter) {
            dealsToShow = dealsToShow.filter(deal => deal.category.toLowerCase().includes(this.currentFilter.toLowerCase()));
        }

        if (dealsToShow.length === 0) {
            container.innerHTML = '<div style="grid-column: 1 / -1; text-align: center; padding: 60px;"><h3>Brak ofert</h3><p>Spróbuj odświeżyć dane.</p></div>';
            return;
        }

        container.innerHTML = dealsToShow.map(deal => this.createDealCard(deal)).join('');
        container.querySelectorAll('.favorite-btn').forEach(btn => {
            btn.addEventListener('click', (e) => {
                e.preventDefault();
                this.toggleFavorite(btn.dataset.dealId, btn);
            });
        });
    }

    createDealCard(deal) {
        const isFavorited = this.favorites.includes(deal.id);
        const scrapedDate = deal.scraped_at ? new Date(deal.scraped_at).toLocaleDateString('pl-PL') : '';

        return `
            <div class="deal-card ${isFavorited ? 'favorited' : ''}">
                <div class="deal-header">
                    <h3 class="deal-title">${this.escapeHtml(deal.title)}</h3>
                    <button class="favorite-btn ${isFavorited ? 'favorited' : ''}" data-deal-id="${deal.id}">
                        ${isFavorited ? '⭐' : '☆'}
                    </button>
                </div>
                <div class="deal-info">
                    <div class="price-info">
                        <span class="current-price">${this.escapeHtml(deal.price)}</span>
                        ${deal.original_price && deal.original_price !== deal.price ? `<span class="original-price">${this.escapeHtml(deal.original_price)}</span>` : ''}
                    </div>
                    <div class="deal-meta">
                        <span class="category-badge">${this.escapeHtml(deal.category)}</span>
                        <span class="source-badge">${this.escapeHtml(deal.source)}</span>
                    </div>
                    ${deal.description ? `<div class="deal-description">${this.escapeHtml(deal.description)}</div>` : ''}
                </div>
                <div class="deal-footer">
                    <a href="${deal.url}" target="_blank" rel="noopener" class="deal-link">🔗 Zobacz</a>
                    ${scrapedDate ? `<span class="deal-time">${scrapedDate}</span>` : ''}
                </div>
            </div>
        `;
    }

    async toggleFavorite(dealId, buttonElement) {
        const isFavorited = buttonElement.classList.contains('favorited');
        try {
            const method = isFavorited ? 'DELETE' : 'POST';
            const response = await fetch(`/api/favorites/${dealId}`, { method });
            if (response.ok) {
                if (isFavorited) {
                    buttonElement.classList.remove('favorited');
                    buttonElement.textContent = '☆';
                    this.favorites = this.favorites.filter(id => id !== dealId);
                    buttonElement.closest('.deal-card').classList.remove('favorited');
                    if (this.currentView === 'favorites') {
                        buttonElement.closest('.deal-card').style.display = 'none';
                    }
                } else {
                    buttonElement.classList.add('favorited');
                    buttonElement.textContent = '⭐';
                    this.favorites.push(dealId);
                    buttonElement.closest('.deal-card').classList.add('favorited');
                }
                this.showToast(isFavorited ? 'Usunięto' : 'Dodano', 'success');
            }
        } catch (error) {
            this.showToast('Błąd', 'error');
        }
    }

    showLoading(show) {
        const loading = document.getElementById('loading');
        const container = document.getElementById('deals-container');
        if (show) {
            loading.style.display = 'block';
            container.style.display = 'none';
        } else {
            loading.style.display = 'none';
            container.style.display = 'grid';
        }
    }

    showToast(message, type = 'info') {
        const container = document.getElementById('toast-container');
        const toast = document.createElement('div');
        toast.className = `toast ${type}`;
        toast.textContent = message;
        container.appendChild(toast);
        setTimeout(() => toast.classList.add('show'), 100);
        setTimeout(() => {
            toast.classList.remove('show');
            setTimeout(() => container.removeChild(toast), 300);
        }, 3000);
    }

    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }
}

document.addEventListener('DOMContentLoaded', () => {
    new DealCollector();
});
EOF

# README.md
cat > README.md << 'EOF'
# 🎮 Deal Collector

Automatyczny kolektor darmowych gier i programów z Steam, Epic, GOG i SharewareOnSale.

## 🚀 Instalacja (dla laików)

### 1. Pobierz i uruchom skrypt
```bash
curl -O https://raw.githubusercontent.com/your-repo/structure_all.sh
bash structure_all.sh
```

LUB skopiuj zawartość pliku `structure_all.sh` do nowego pliku i uruchom:
```bash
bash structure_all.sh
```

### 2. Zainstaluj Python (jeśli nie masz)
- Windows: https://www.python.org/downloads/
- Mac: `brew install python`
- Linux: `sudo apt install python3 python3-pip`

### 3. Uruchom projekt
```bash
pip install -r requirements.txt
python main.py
```

### 4. Otwórz przeglądarkę
Wejdź na: `http://127.0.0.1:8000`

## ✨ Co robi ten projekt?

- **Automatycznie zbiera** darmowe gry ze Steam, Epic, GOG
- **Znajduje** darmowe programy z SharewareOnSale
- **Pokazuje** wszystko w ładnym dashboardzie
- **Zapisuje** ulubione oferty
- **Działa offline** - wszystko na Twoim komputerze

## 🎯 Źródła danych

✅ **Steam** (via SteamDB) - darmowe gry
✅ **Epic Games** - cotygodniowe darmówki
✅ **GOG** - darmowe gry DRM-free
✅ **SharewareOnSale** - darmowe programy

## 🔧 Jak używać?

1. **Kliknij "🔄 Odśwież"** - pobiera najnowsze oferty
2. **Filtruj** po kategorii (Gry/Programy)
3. **Dodawaj do ulubionych** ⭐
4. **Klikaj "🔗 Zobacz"** - przechodzi do oferty

## 📁 Co powstanie po uruchomieniu?

```
deal-collector/
├── main.py              # Serwer
├── requirements.txt     # Biblioteki Python
├── deals.json          # Twoja baza danych
├── scrapers/           # Moduły zbierające dane
└── frontend/          # Strona internetowa
```

## ⚠️ Ważne!

- **Nie publikuj** tego w internecie - to tylko do użytku lokalnego
- **Szanuj** regulaminy stron (nie spamuj odświeżaniem)
- **Backup** `deals.json` jeśli chcesz zachować ulubione

## 🆘 Problemy?

**Nie działa scrapowanie?**
- Sprawdź internet
- Niektóre strony mogą czasowo blokować

**Nie otwiera się strona?**
- Sprawdź czy port 8000 jest wolny
- Spróbuj inny port w `main.py`

**Email do testów:** `arek.softcollector@outlook.com`
EOF

echo ""
echo "📦 GOTOWE!"
echo ""
echo "Aby uruchomić projekt:"
echo "1. pip install -r requirements.txt"
echo "2. python main.py"
echo "3. Otwórz: http://127.0.0.1:8000"
echo "4. uvicorn main:app --reload""
echo ""
echo "Zawiera scrapers dla:"
echo "✅ SteamDB (darmowe gry Steam)"
echo "✅ Epic Games (cotygodniowe darmówki)"
echo "✅ GOG (darmowe gry DRM-free)"
echo "✅ SharewareOnSale (darmowe programy)"
echo ""
echo "🎮 Miłego kolekcjonowania!"
