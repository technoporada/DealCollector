import aiohttp
from bs4 import BeautifulSoup
from typing import List
from .base_scraper import BaseScraper, Deal


class ItchIOScraper(BaseScraper):
    def __init__(self):
        super().__init__("itch.io", "https://itch.io")
        self.free_url = "https://itch.io/games/free"

    async def scrape(self) -> List[Deal]:
        deals = []
        try:
            async with aiohttp.ClientSession(headers=self.headers) as session:
                async with session.get(self.free_url) as response:
                    if response.status == 200:
                        html = await response.text()
                        deals = self._parse(html)
        except Exception as e:
            print(f"itch.io error: {e}")
        return deals

    def _parse(self, html: str) -> List[Deal]:
        deals = []
        soup = BeautifulSoup(html, "html.parser")
        games = soup.select(".game_cell")

        for game in games[:20]:
            try:
                title_el = game.select_one(".title")
                link_el = game.select_one("a.game_link")
                author_el = game.select_one(".game_author")
                platform_el = game.select_one(".web_flag")

                if not title_el or not link_el:
                    continue

                title = title_el.get_text(strip=True)
                url = link_el.get("href", "")
                author = author_el.get_text(strip=True) if author_el else ""
                is_web = platform_el is not None

                platforms = "Web" if is_web else "Download"

                deals.append(Deal(
                    title=self.clean_title(title),
                    url=url,
                    price="Free",
                    original_price="Unknown",
                    category="Games",
                    source="itch.io",
                    description=f"By {author} | {platforms}" if author else platforms,
                ))
            except Exception:
                continue
        return deals
