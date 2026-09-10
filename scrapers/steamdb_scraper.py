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
