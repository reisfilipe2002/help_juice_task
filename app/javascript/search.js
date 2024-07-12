document.addEventListener('DOMContentLoaded', () => {
    const searchInput = document.getElementById('search-input');
    const searchResults = document.getElementById('search-results');
    const popularSearches = document.getElementById('popular-searches');
    let typingTimer;
    const typingInterval = 300; 

    searchInput.addEventListener('input', () => {
        clearTimeout(typingTimer);
        typingTimer = setTimeout(() => {
            const query = searchInput.value.trim();
            if (query.length > 0) {
                performSearch(query);
                logSearch(query);
            } else {
                searchResults.innerHTML = '';
            }
        }, typingInterval);
    });

    function performSearch(query) {
        fetch(`/search?query=${encodeURIComponent(query)}`)
            .then(response => response.json())
            .then(data => {
                searchResults.innerHTML = data.articles.map(article => `
                    <div>
                        <h3>${article.title}</h3>
                        <p>${article.content}</p>
                    </div>
                `).join('');
            });
    }

    function logSearch(query) {
        fetch(`/log_search?query=${encodeURIComponent(query)}`);
    }

    function updatePopularSearches() {
        fetch('/analytics')
            .then(response => response.json())
            .then(data => {
                popularSearches.innerHTML = data.popular_searches.map(item => `
                    <li>${item.query} (${item.count})</li>
                `).join('');
            });
    }

    setInterval(updatePopularSearches, 30000);
    updatePopularSearches(); 
});
