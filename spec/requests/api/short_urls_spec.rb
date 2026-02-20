require 'rails_helper'

RSpec.describe 'API::ShortUrls', type: :request do
  describe 'POST /api/shorten' do
    context 'with valid URL' do
      before do
        stub_request(:get, 'https://example.com')
          .to_return(body: '<html><head><title>Example</title></head></html>')
      end

      it 'creates a short URL' do
        post '/api/shorten', params: { target_url: 'https://example.com' }, as: :json

        expect(response).to have_http_status(:created)
        expect(json_response['data']).to include('short_url', 'short_code', 'target_url')
      end

      it 'returns short URL with full domain' do
        post '/api/shorten', params: { target_url: 'https://example.com' }, as: :json

        expect(json_response['data']['short_url']).to match(/http.*\/[a-zA-Z0-9]+/)
      end

      it 'returns target URL' do
        post '/api/shorten', params: { target_url: 'https://example.com' }, as: :json

        expect(json_response['data']['target_url']).to eq('https://example.com')
      end

      it 'creates record in database' do
        expect {
          post '/api/shorten', params: { target_url: 'https://example.com' }, as: :json
        }.to change(ShortUrl, :count).by(1)
      end
    end

    context 'with invalid URL' do
      it 'returns unprocessable entity' do
        post '/api/shorten', params: { target_url: 'not-a-url' }, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns error messages' do
        post '/api/shorten', params: { target_url: '' }, as: :json

        expect(json_response['errors']).to be_present
      end
    end

    context 'with private URL (SSRF protection)' do
      it 'rejects localhost' do
        post '/api/shorten', params: { target_url: 'http://localhost:3000' }, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['errors']).to include(/Private or internal/)
      end

      it 'rejects private IPs' do
        post '/api/shorten', params: { target_url: 'http://192.168.1.1' }, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'rate limiting' do
      before do
        stub_request(:get, 'https://example.com')
          .to_return(body: '<html><head><title>Example</title></head></html>')
        # Test uses null_store by default; Rack::Attack needs a real store for throttle to persist
        @previous_rack_attack_store = Rack::Attack.cache.store
        Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
      end

      after do
        Rack::Attack.cache.store = @previous_rack_attack_store
      end

      it 'rate limits after 10 requests' do
        10.times do
          post '/api/shorten', params: { target_url: 'https://example.com' }, as: :json
          expect(response).to have_http_status(:created)
        end

        post '/api/shorten', params: { target_url: 'https://example.com' }, as: :json
        expect(response).to have_http_status(:too_many_requests)
      end
    end
  end

  describe 'GET /api/stats/:short_code' do
    let!(:short_url) { create(:short_url, :with_clicks) }

    it 'returns stats for existing short code' do
      get "/api/stats/#{short_url.short_code}"

      expect(response).to have_http_status(:ok)
      expect(json_response['data']).to include(
        'short_code', 'target_url', 'click_count',
        'clicks_by_country', 'recent_clicks'
      )
    end

    it 'returns click count' do
      get "/api/stats/#{short_url.short_code}"

      expect(json_response['data']['click_count']).to eq(short_url.click_count)
    end

    it 'returns clicks by country' do
      get "/api/stats/#{short_url.short_code}"

      expect(json_response['data']['clicks_by_country']).to be_a(Hash)
    end

    it 'returns recent clicks' do
      get "/api/stats/#{short_url.short_code}"

      expect(json_response['data']['recent_clicks']).to be_an(Array)
    end

    it 'returns 404 for non-existent code' do
      get '/api/stats/nonexistent'

      expect(response).to have_http_status(:not_found)
      expect(json_response['error']).to include('not found')
    end

    it 'does not return stats for inactive URLs' do
      inactive_url = create(:short_url, :inactive)

      get "/api/stats/#{inactive_url.short_code}"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'GET /api/report' do
    let!(:short_urls) { create_list(:short_url, 5, :with_clicks) }

    it 'returns report of short URLs' do
      get '/api/report'

      expect(response).to have_http_status(:ok)
      expect(json_response['data']).to be_an(Array)
    end

    it 'includes short URL data' do
      get '/api/report'

      first_item = json_response['data'].first
      expect(first_item).to include(
        'short_code', 'target_url', 'click_count', 'created_at'
      )
    end

    it 'limits results' do
      create_list(:short_url, 150)

      get '/api/report', params: { limit: 50 }

      expect(json_response['data'].length).to be <= 50
    end

    it 'filters by since date' do
      old_url = create(:short_url, created_at: 10.days.ago)
      new_url = create(:short_url, created_at: 1.day.ago)

      get '/api/report', params: { since: 5.days.ago.iso8601 }

      short_codes = json_response['data'].map { |d| d['short_code'] }
      expect(short_codes).to include(new_url.short_code)
      expect(short_codes).not_to include(old_url.short_code)
    end

    it 'defaults to 7 days when since is not provided' do
      old_url = create(:short_url, created_at: 10.days.ago)
      new_url = create(:short_url, created_at: 1.day.ago)

      get '/api/report'

      short_codes = json_response['data'].map { |d| d['short_code'] }
      expect(short_codes).to include(new_url.short_code)
      expect(short_codes).not_to include(old_url.short_code)
    end
  end

  private

  def json_response
    JSON.parse(response.body)
  end
end
