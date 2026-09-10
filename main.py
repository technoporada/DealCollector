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
