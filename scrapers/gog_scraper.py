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
