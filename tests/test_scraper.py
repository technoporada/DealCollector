import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'scrapers'))

import pytest
from base_scraper import Deal, BaseScraper


def test_deal_creation():
    deal = Deal(
        title="Test Game",
        url="https://example.com",
        price="Free",
        original_price="$29.99",
        category="games",
        source="test"
    )
    assert deal.title == "Test Game"
    assert deal.price == "Free"
    assert deal.id is not None
    assert deal.scraped_at is not None


def dealeal_auto_id():
    d1 = Deal(title="Game", url="https://a.com", price="Free", original_price="$10", category="games", source="test")
    d2 = Deal(title="Game", url="https://a.com", price="Free", original_price="$10", category="games", source="test")
    assert d1.id == d2.id


def test_deal_different_ids():
    d1 = Deal(title="Game A", url="https://a.com", price="Free", original_price="$10", category="games", source="test")
    d2 = Deal(title="Game B", url="https://b.com", price="Free", original_price="$10", category="games", source="test")
    assert d1.id != d2.id


def test_deal_to_dict():
    deal = Deal(title="Test", url="https://example.com", price="Free", original_price="$0", category="games", source="test")
    d = deal.to_dict()
    assert isinstance(d, dict)
    assert d["title"] == "Test"
    assert "id" in d


def test_clean_price_free():
    class DummyScraper(BaseScraper):
        async def scrape(self): return []
    s = DummyScraper("test", "http://test.com")
    assert s.clean_price("Free") == "Free"
    assert s.clean_price("0") == "Free"
    assert s.clean_price("") == "Free"
    assert s.clean_price("$19.99") == "$19.99"


def test_clean_title():
    class DummyScraper(BaseScraper):
        async def scrape(self): return []
    s = DummyScraper("test", "http://test.com")
    assert s.clean_title("  Game  ") == "Game"
    assert s.clean_title("") == "Unknown"
    assert s.clean_title(None) == "Unknown"


def test_is_valid_deal():
    class DummyScraper(BaseScraper):
        async def scrape(self): return []
    s = DummyScraper("test", "http://test.com")
    valid = Deal(title="Game", url="https://example.com", price="Free", original_price="$0", category="games", source="test")
    invalid = Deal(title="", url="https://example.com", price="Free", original_price="$0", category="games", source="test")
    assert s.is_valid_deal(valid) is True
    assert s.is_valid_deal(invalid) is False
