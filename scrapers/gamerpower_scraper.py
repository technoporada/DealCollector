import aiohttp
from typing import List
from .base_scraper import BaseScraper, Deal


class GamerpowerScraper(BaseScraper):
    def __init__(self):
        super().__init__("Gamerpower", "https://www.gamerpower.com")
        self.api_url = "https://www.gamerpower.com/api/giveaways"

    async def scrape(self) -> List[Deal]:
        deals = []
        try:
            async with aiohttp.ClientSession(headers=self.headers) as session:
                async with session.get(self.api_url) as response:
                    if response.status == 200:
                        data = await response.json()
                        deals = self._parse(data)
        except Exception as e:
            print(f"Gamerpower error: {e}")
        return deals

    async def scrape_filtered(self, platform: str = None, game_type: str = None, sort_by: str = None) -> List[Deal]:
        deals = []
        try:
            params = {}
            if platform:
                params["platform"] = platform
            if game_type:
                params["type"] = game_type
            if sort_by:
                params["sort-by"] = sort_by

            async with aiohttp.ClientSession(headers=self.headers) as session:
                async with session.get(self.api_url, params=params) as response:
                    if response.status == 200:
                        data = await response.json()
                        deals = self._parse(data)
        except Exception as e:
            print(f"Gamerpower filtered error: {e}")
        return deals

    async def get_worth(self, platform: str = None, game_type: str = None) -> dict:
        try:
            params = {}
            if platform:
                params["platform"] = platform
            if game_type:
                params["type"] = game_type

            async with aiohttp.ClientSession(headers=self.headers) as session:
                async with session.get("https://www.gamerpower.com/api/worth", params=params) as response:
                    if response.status == 200:
                        return await response.json()
        except Exception:
            pass
        return {}

    def _parse(self, data: list) -> List[Deal]:
        deals = []
        for item in data[:30]:
            try:
                title = item.get("title", "")
                url = item.get("open_giveaway_url", "")
                platform = item.get("platform", "")
                game_type = item.get("type", "")
                worth = item.get("worth", "Free")
                thumbnail = item.get("thumbnail", "")
                end_date = item.get("end_date", "")
                image = item.get("image", "")

                if not title or not url:
                    continue

                deals.append(Deal(
                    title=self.clean_title(title),
                    url=url,
                    price="Free",
                    original_price=worth if worth and worth != "N/A" else "Unknown",
                    category=game_type if game_type else "Games",
                    source="Gamerpower",
                    description=f"{platform} | Ends: {end_date}" if end_date else platform,
                    image_url=image or thumbnail or None,
                    valid_until=end_date if end_date and end_date != "N/A" else None,
                ))
            except Exception:
                continue
        return deals
