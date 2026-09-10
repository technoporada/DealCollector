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
