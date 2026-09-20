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
        games = data.get('data', {}).get('Catalog', {}).get('searchStore', {}).get('elements', [])

        for game in games[:10]:
            try:
                total_price = game.get('price', {}).get('totalPrice', {})
                discount = total_price.get('discountPrice', -1)
                if discount != 0:
                    continue

                title = game.get('title', 'Unknown')
                mappings = game.get('catalogNs', {}).get('mappings', [])
                slug = mappings[0].get('pageSlug', '') if mappings else ''
                url = f"https://store.epicgames.com/p/{slug}" if slug else ""

                original = total_price.get('originalPrice', 0)
                original_str = f"${original / 100:.2f}" if original > 0 else "Unknown"

                deals.append(Deal(
                    title=self.clean_title(title),
                    url=url,
                    price="Free",
                    original_price=original_str,
                    category="Games",
                    source="Epic Games",
                    description=game.get('description', '')[:200] if game.get('description') else ""
                ))
            except Exception:
                continue
        return deals
