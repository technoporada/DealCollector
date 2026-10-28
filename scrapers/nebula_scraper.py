import aiohttp
from typing import List
from .base_scraper import BaseScraper, Deal


class NebulaScraper(BaseScraper):
    def __init__(self):
        super().__init__("NEBULA CDN", "https://cdn.jsdelivr.net")
        self.api_url = "https://cdn.jsdelivr.net/gh/GoatTech-42/NEBULA-CDN@main/games.json"
        self.cdn_base = "https://cdn.jsdelivr.net/gh/GoatTech-42/NEBULA-CDN@main"

    async def scrape(self) -> List[Deal]:
        deals = []
        try:
            async with aiohttp.ClientSession(headers=self.headers) as session:
                async with session.get(self.api_url) as response:
                    if response.status == 200:
                        data = await response.json()
                        games = data.get("games", [])
                        deals = self._parse(games)
        except Exception as e:
            print(f"NEBULA error: {e}")
        return deals

    def _parse(self, games: list) -> List[Deal]:
        deals = []
        for game in games[:30]:
            try:
                name = game.get("name", "")
                slug = game.get("slug", "")
                category = game.get("category", "")
                tags = game.get("tags", [])
                file_path = game.get("file", "")

                if not name or not slug:
                    continue

                url = f"{self.cdn_base}/{file_path}" if file_path else ""

                deals.append(Deal(
                    title=self.clean_title(name),
                    url=url,
                    price="Free",
                    original_price="Browser game",
                    category=category if category else "Browser",
                    source="NEBULA CDN",
                    description=f"Tags: {', '.join(tags[:5])}" if tags else "HTML5 browser game",
                ))
            except Exception:
                continue
        return deals
