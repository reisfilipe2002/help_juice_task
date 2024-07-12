require 'rails_helper'

RSpec.describe SearchQuery, type: :model do
  describe '.log_search' do
    let(:ip_address) { '192.168.1.1' }

    context 'when starting a new search' do
      it 'creates a new search query' do
        expect {
          SearchQuery.log_search(ip_address, 'new search')
        }.to change(SearchQuery, :count).by(1)
      end
    end

    context 'when updating an existing search' do
      before do
        SearchQuery.log_search(ip_address, 'initial')
      end

      it 'updates the existing search query' do
        expect {
          SearchQuery.log_search(ip_address, 'initial search')
        }.not_to change(SearchQuery, :count)
      end

      it 'updates the query text' do
        SearchQuery.log_search(ip_address, 'initial search')
        expect(SearchQuery.last.query).to eq('initial search')
      end
    end
  end

  describe '.is_new_search?' do
    let(:ip_address) { '192.168.1.1' }
    let(:current_time) { Time.current }

    it 'returns true for nil last_query' do
      expect(SearchQuery.is_new_search?(nil, 'new query', current_time)).to be true
    end

    it 'returns true for significant backspacing' do
      last_query = SearchQuery.create(query: 'long initial query', ip_address: ip_address, last_key_press_at: current_time - 1.second)
      expect(SearchQuery.is_new_search?(last_query, 'long', current_time)).to be true
    end

    it 'returns false for continuing the same query' do
      last_query = SearchQuery.create(query: 'initial', ip_address: ip_address, last_key_press_at: current_time - 1.second)
      expect(SearchQuery.is_new_search?(last_query, 'initial query', current_time)).to be false
    end
  end

  describe '.is_search_complete?' do
    let(:ip_address) { '192.168.1.1' }
    let(:current_time) { Time.current }

    it 'returns true when query ends with a space' do
      last_query = SearchQuery.create(query: 'complete', ip_address: ip_address, last_key_press_at: current_time - 1.second)
      expect(SearchQuery.is_search_complete?(last_query, 'complete ', current_time)).to be true
    end

    it 'returns true when query ends with punctuation' do
      last_query = SearchQuery.create(query: 'complete', ip_address: ip_address, last_key_press_at: current_time - 1.second)
      expect(SearchQuery.is_search_complete?(last_query, 'complete?', current_time)).to be true
    end

    it 'returns false for frequent backspacing' do
      last_query = SearchQuery.create(query: 'initial query', ip_address: ip_address, last_key_press_at: current_time - 1.second)
      expect(SearchQuery.is_search_complete?(last_query, 'initial', current_time)).to be false
    end
  end

  describe '.is_frequent_backspacing?' do
    let(:ip_address) { '192.168.1.1' }
    let(:current_time) { Time.current }

    it 'returns true for rapid deletion of characters' do
      last_query = SearchQuery.create(query: 'initial query', ip_address: ip_address, last_key_press_at: current_time - 0.5.seconds)
      expect(SearchQuery.is_frequent_backspacing?(last_query, 'initial', current_time)).to be true
    end

    it 'returns false for slow deletion of characters' do
      last_query = SearchQuery.create(query: 'initial query', ip_address: ip_address, last_key_press_at: current_time - 3.seconds)
      expect(SearchQuery.is_frequent_backspacing?(last_query, 'initial', current_time)).to be false
    end

    it 'returns false when adding characters' do
      last_query = SearchQuery.create(query: 'initial', ip_address: ip_address, last_key_press_at: current_time - 0.5.seconds)
      expect(SearchQuery.is_frequent_backspacing?(last_query, 'initial query', current_time)).to be false
    end
  end

  describe '.popular_searches' do
    before do
      3.times { SearchQuery.create(query: 'popular search', ip_address: '192.168.1.1') }
      2.times { SearchQuery.create(query: 'less popular', ip_address: '192.168.1.2') }
      SearchQuery.create(query: 'unique', ip_address: '192.168.1.3')
    end

    it 'returns the correct number of popular searches' do
      expect(SearchQuery.popular_searches(2).count).to eq(2)
    end

    it 'orders searches by popularity' do
      popular = SearchQuery.popular_searches(2)
      expect(popular.keys).to eq(['popular search', 'less popular'])
    end

    it 'includes the correct counts' do
      popular = SearchQuery.popular_searches
      expect(popular['popular search']).to eq(3)
      expect(popular['less popular']).to eq(2)
      expect(popular['unique']).to eq(1)
    end
  end
end