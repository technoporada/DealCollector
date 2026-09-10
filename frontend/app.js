class DealCollector {
    constructor() {
        this.deals = [];
        this.favorites = [];
        this.currentView = 'all';
        this.currentFilter = '';
        this.init();
    }

    init() {
        this.bindEvents();
        this.loadDeals();
        this.loadStats();
    }

    bindEvents() {
        document.getElementById('scrape-btn').addEventListener('click', () => this.scrapeDeals());
        document.getElementById('favorites-btn').addEventListener('click', () => this.showFavorites());
        document.getElementById('all-deals-btn').addEventListener('click', () => this.showAllDeals());
        document.getElementById('category-filter').addEventListener('change', (e) => {
            this.currentFilter = e.target.value;
            this.renderDeals();
        });
    }

    async loadDeals() {
        this.showLoading(true);
        try {
            const response = await fetch('/api/deals');
            const data = await response.json();
            this.deals = data.deals || [];
            this.renderDeals();
        } catch (error) {
            this.showToast('Błąd ładowania', 'error');
        } finally {
            this.showLoading(false);
        }
    }

    async loadStats() {
        try {
            const response = await fetch('/api/stats');
            const data = await response.json();
            document.getElementById('deals-count').textContent = `${data.total_deals} ofert`;
            const lastUpdate = data.last_update !== 'Never' ? new Date(data.last_update).toLocaleString('pl-PL') : 'Nigdy';
            document.getElementById('last-update').textContent = `${lastUpdate}`;
        } catch (error) {
            console.error('Stats error:', error);
        }
    }

    async scrapeDeals() {
        const btn = document.getElementById('scrape-btn');
        btn.textContent = '🔄 Scrapowanie...';
        btn.disabled = true;

        try {
            const response = await fetch('/api/scrape', { method: 'POST' });
            const data = await response.json();
            if (data.status === 'success') {
                this.showToast(`Znaleziono ${data.total_deals} ofert`, 'success');
                await this.loadDeals();
                await this.loadStats();
            }
        } catch (error) {
            this.showToast('Błąd scrapowania', 'error');
        } finally {
            btn.textContent = '🔄 Odśwież';
            btn.disabled = false;
        }
    }

    async showFavorites() {
        this.currentView = 'favorites';
        this.showLoading(true);
        try {
            const response = await fetch('/api/favorites');
            const data = await response.json();
            this.deals = data.deals || [];
            this.renderDeals();
            document.getElementById('favorites-btn').classList.add('btn-primary');
            document.getElementById('favorites-btn').classList.remove('btn-secondary');
            document.getElementById('all-deals-btn').classList.add('btn-secondary');
            document.getElementById('all-deals-btn').classList.remove('btn-primary');
        } catch (error) {
            this.showToast('Błąd ulubionych', 'error');
        } finally {
            this.showLoading(false);
        }
    }

    async showAllDeals() {
        this.currentView = 'all';
        document.getElementById('all-deals-btn').classList.add('btn-primary');
        document.getElementById('all-deals-btn').classList.remove('btn-secondary');
        document.getElementById('favorites-btn').classList.add('btn-secondary');
        document.getElementById('favorites-btn').classList.remove('btn-primary');
        await this.loadDeals();
    }

    renderDeals() {
        const container = document.getElementById('deals-container');
        let dealsToShow = this.deals;

        if (this.currentFilter) {
            dealsToShow = dealsToShow.filter(deal => deal.category.toLowerCase().includes(this.currentFilter.toLowerCase()));
        }

        if (dealsToShow.length === 0) {
            container.innerHTML = '<div style="grid-column: 1 / -1; text-align: center; padding: 60px;"><h3>Brak ofert</h3><p>Spróbuj odświeżyć dane.</p></div>';
            return;
        }

        container.innerHTML = dealsToShow.map(deal => this.createDealCard(deal)).join('');
        container.querySelectorAll('.favorite-btn').forEach(btn => {
            btn.addEventListener('click', (e) => {
                e.preventDefault();
                this.toggleFavorite(btn.dataset.dealId, btn);
            });
        });
    }

    createDealCard(deal) {
        const isFavorited = this.favorites.includes(deal.id);
        const scrapedDate = deal.scraped_at ? new Date(deal.scraped_at).toLocaleDateString('pl-PL') : '';

        return `
            <div class="deal-card ${isFavorited ? 'favorited' : ''}">
                <div class="deal-header">
                    <h3 class="deal-title">${this.escapeHtml(deal.title)}</h3>
                    <button class="favorite-btn ${isFavorited ? 'favorited' : ''}" data-deal-id="${deal.id}">
                        ${isFavorited ? '⭐' : '☆'}
                    </button>
                </div>
                <div class="deal-info">
                    <div class="price-info">
                        <span class="current-price">${this.escapeHtml(deal.price)}</span>
                        ${deal.original_price && deal.original_price !== deal.price ? `<span class="original-price">${this.escapeHtml(deal.original_price)}</span>` : ''}
                    </div>
                    <div class="deal-meta">
                        <span class="category-badge">${this.escapeHtml(deal.category)}</span>
                        <span class="source-badge">${this.escapeHtml(deal.source)}</span>
                    </div>
                    ${deal.description ? `<div class="deal-description">${this.escapeHtml(deal.description)}</div>` : ''}
                </div>
                <div class="deal-footer">
                    <a href="${deal.url}" target="_blank" rel="noopener" class="deal-link">🔗 Zobacz</a>
                    ${scrapedDate ? `<span class="deal-time">${scrapedDate}</span>` : ''}
                </div>
            </div>
        `;
    }

    async toggleFavorite(dealId, buttonElement) {
        const isFavorited = buttonElement.classList.contains('favorited');
        try {
            const method = isFavorited ? 'DELETE' : 'POST';
            const response = await fetch(`/api/favorites/${dealId}`, { method });
            if (response.ok) {
                if (isFavorited) {
                    buttonElement.classList.remove('favorited');
                    buttonElement.textContent = '☆';
                    this.favorites = this.favorites.filter(id => id !== dealId);
                    buttonElement.closest('.deal-card').classList.remove('favorited');
                    if (this.currentView === 'favorites') {
                        buttonElement.closest('.deal-card').style.display = 'none';
                    }
                } else {
                    buttonElement.classList.add('favorited');
                    buttonElement.textContent = '⭐';
                    this.favorites.push(dealId);
                    buttonElement.closest('.deal-card').classList.add('favorited');
                }
                this.showToast(isFavorited ? 'Usunięto' : 'Dodano', 'success');
            }
        } catch (error) {
            this.showToast('Błąd', 'error');
        }
    }

    showLoading(show) {
        const loading = document.getElementById('loading');
        const container = document.getElementById('deals-container');
        if (show) {
            loading.style.display = 'block';
            container.style.display = 'none';
        } else {
            loading.style.display = 'none';
            container.style.display = 'grid';
        }
    }

    showToast(message, type = 'info') {
        const container = document.getElementById('toast-container');
        const toast = document.createElement('div');
        toast.className = `toast ${type}`;
        toast.textContent = message;
        container.appendChild(toast);
        setTimeout(() => toast.classList.add('show'), 100);
        setTimeout(() => {
            toast.classList.remove('show');
            setTimeout(() => container.removeChild(toast), 300);
        }, 3000);
    }

    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }
}

document.addEventListener('DOMContentLoaded', () => {
    new DealCollector();
});
