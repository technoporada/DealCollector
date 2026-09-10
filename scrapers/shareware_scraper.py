import aiohttp
from bs4 import BeautifulSoup
from typing import List
from .base_scraper import BaseScraper, Deal

class SharewareScraper(BaseScraper):
    def __init__(self):
        super().__init__("SharewareOnSale", "https://sharewareonsale.com")
        self.base_url = "https://sharewareonsale.com"

    async def scrape(self) -> List[Deal]:
        deals = []
        try:
            async with aiohttp.ClientSession(headers=self.headers) as session:
                async with session.get(self.base_url) as response:
                    if response.status == 200:
                        html = await response.text()
                        deals = self._parse_shareware_page(html)
        except Exception as e:
            print(f"Shareware error: {e}")
        return deals

    def _parse_shareware_page(self, html: str) -> List[Deal]:
        deals = []
        soup = BeautifulSoup(html, 'html.parser')

        # Szukamy ofert na stronie głównej
        offers = soup.find_all(['div', 'article'], class_=lambda x: x and ('offer' in str(x).lower() or 'deal' in str(x).lower()))[:6]

        for offer in offers:
            try:
                title_elem = offer.find(['a', 'h2', 'h3'])
                if not title_elem:
                    continue

                title = self.clean_title(title_elem.get_text(strip=True))
                url = title_elem.get('href', '')
                if url and not url.startswith('http'):
                    url = f"{self.base_url}{url}"

                # Próba znalezienia ceny
                price_elem = offer.find(text=lambda x: x and ('free' in x.lower() or '$0' in x))
                price = "Free" if price_elem else "Special Offer"

                deals.append(Deal(
                    title=title,
                    url=url or self.base_url,
                    price=price,
                    original_price="Unknown",
                    category="Software",
                    source="SharewareOnSale",
                    description="Software giveaway"
                ))
            except:
                continue
        return deals
