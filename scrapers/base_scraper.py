from abc import ABC, abstractmethod
from dataclasses import dataclass, asdict
from typing import List, Optional
from datetime import datetime
import hashlib

@dataclass
class Deal:
    title: str
    url: str
    price: str
    original_price: str
    category: str
    source: str
    description: Optional[str] = None
    image_url: Optional[str] = None
    valid_until: Optional[str] = None
    rating: Optional[str] = None
    id: Optional[str] = None
    scraped_at: Optional[str] = None

    def __post_init__(self):
        if not self.id:
            content = f"{self.title}{self.url}{self.source}"
            self.id = hashlib.md5(content.encode()).hexdigest()[:12]
        if not self.scraped_at:
            self.scraped_at = datetime.now().isoformat()

    def to_dict(self) -> dict:
        return asdict(self)

class BaseScraper(ABC):
    def __init__(self, name: str, base_url: str):
        self.name = name
        self.base_url = base_url
        self.headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'}

    @abstractmethod
    async def scrape(self) -> List[Deal]:
        pass

    def clean_price(self, price_text: str) -> str:
        if not price_text or any(word in price_text.lower() for word in ['free', 'darmowa', '0']):
            return "Free"
        return price_text.strip()

    def clean_title(self, title: str) -> str:
        return title.strip()[:200] if title else "Unknown"

    def is_valid_deal(self, deal: Deal) -> bool:
        return bool(deal.title and deal.url and deal.source)
