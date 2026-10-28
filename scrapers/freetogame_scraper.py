import aiohttp
from typing import List
from .base_scraper import BaseScraper, Deal


class FreeToGameScraper(BaseScraper):
    def __init__(self):
        super().__init__("FreeToGame", "https://www.freetogame.com")
        self.api_url = "https://www.freetogame.com/api/games"

    async def scrape(self) -> List[Deal]:
        deals = []
        try:
            async with aiohttp.ClientSession(headers=self.headers) as session:
                async with session.get(self.api_url) as response:
                    if response.status == 200:
                        data = await response.json()
                        deals = self._parse(data)
        except Exception as e:
            print(f"FreeToGame error: {e}")
        return deals

    def _parse(self, data: list) -> List[Deal]:
        deals = []
        for item in data[:30]:
            try:
                title = item.get("title", "")
                url = item.get("game_url", "")
                platform = item.get("platform", "")
                genre = item.get("genre", "")
                developer = item.get("developer", "")
                thumbnail = item.get("thumbnail", "")
                release_date = item.get("release_date", "")

                if not title or not url:
                    continue

                deals.append(Deal(
                    title=self.clean_title(title),
                    url=url,
                    price="Free",
                    original_price="Free-to-play",
                    category=genre if genre else "Games",
                    source="FreeToGame",
                    description=f"{platform} | {developer}" if developer else platform,
                    image_url=thumbnail if thumbnail else None,
                    valid_until=release_date if release_date else None,
                ))
            except Exception:
                continue
        return deals
