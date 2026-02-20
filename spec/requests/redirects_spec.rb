require 'rails_helper'

RSpec.describe 'Redirects', type: :request do
  describe 'GET /:short_code' do
    let!(:short_url) { create(:short_url, target_url: 'https://example.com') }

    it 'redirects to target URL' do
      get "/#{short_url.short_code}"

      expect(response).to have_http_status(:found)
      expect(response).to redirect_to('https://example.com')
    end

    it 'enqueues click tracking job' do
      expect {
        get "/#{short_url.short_code}"
      }.to change { Sidekiq::Job.jobs.size }.by(1)
      expect(Sidekiq::Job.jobs.last['args'].to_s).to include('TrackClickJob')
    end

    it 'returns 404 for non-existent code' do
      get '/nonexistent'

      expect(response).to have_http_status(:not_found)
    end

    it 'returns 404 for inactive URLs' do
      inactive_url = create(:short_url, :inactive)

      get "/#{inactive_url.short_code}"

      expect(response).to have_http_status(:not_found)
    end

    it 'returns 404 for expired URLs' do
      expired_url = create(:short_url, :expired)

      get "/#{expired_url.short_code}"

      expect(response).to have_http_status(:not_found)
    end

    context 'with Redis caching' do
      it 'caches the redirect' do
        # First request
        get "/#{short_url.short_code}"

        # Check cache
        cache_key = "short_url:#{short_url.short_code}"
        cached_data = REDIS.get(cache_key)

        expect(cached_data).to be_present
      end

      it 'uses cache on subsequent requests' do
        # Warm cache
        get "/#{short_url.short_code}"

        # Change target URL
        short_url.update(target_url: 'https://changed.com')

        # Second request should use cache
        get "/#{short_url.short_code}"

        # Should still redirect to original URL (cached)
        expect(response).to redirect_to('https://example.com')
      end
    end
  end
end
