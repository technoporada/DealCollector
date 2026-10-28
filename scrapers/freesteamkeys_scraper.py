import aiohttp
from typing import List
from .base_scraper import BaseScraper, Deal


class FreeSteamKeysScraper(BaseScraper):
    def __init__(self):
        super().__init__("FreeSteamKeys", "https://www.freesteamkeys.com")
        self.api_url = "https://www.freesteamkeys.com/api/giveaways"

    async def scrape(self) -> List[Deal]:
        deals = []
        try:
            async with aiohttp.ClientSession(headers=self.headers) as session:
                async with session.get(self.api_url) as response:
                    if response.status == 200:
                        data = await response.json()
                        deals = self._parse(data)
        except Exception as e:
            print(f"FreeSteamKeys error: {e}")
        return deals

    def _parse(self, data: list) -> List[Deal]:
        deals = []
        for item in data[:30]:
            try:
                title = item.get("title", "")
                url = item.get("giveaway_url", "") or item.get("url", "")
                giveaway_type = item.get("type", "")
                trust = item.get("trust_score", 0)
                image = item.get("image", "") or item.get("thumbnail", "")

                if not title or not url:
                    continue

                trust_label = {1: "Trusted", 2: "Unofficial", 3: "Unknown"}.get(trust, "Unknown")

                deals.append(Deal(
                    title=self.clean_title(title),
                    url=url,
                    price="Free",
                    original_price="Unknown",
                    category=giveaway_type if giveaway_type else "Games",
                    source="FreeSteamKeys",
                    description=f"Trust: {trust_label}",
                    image_url=image if image else None,
                ))
            except Exception:
                continue
        return deals
