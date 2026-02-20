require 'rails_helper'

RSpec.describe ShortUrls::CreatorService do
  describe '#call' do
    context 'with valid URL' do
      before do
        stub_request(:get, 'https://example.com')
          .to_return(body: '<html><head><title>Example</title></head></html>')
        stub_request(:get, 'https://example.com/')
          .to_return(body: '<html><head><title>Example</title></head></html>')
      end

      it 'creates a short URL' do
        service = described_class.new(target_url: 'https://example.com')

        expect { service.call }.to change(ShortUrl, :count).by(1)
      end

      it 'returns success with short_url' do
        service = described_class.new(target_url: 'https://example.com')
        result = service.call

        expect(result[:success]).to be true
        expect(result[:short_url]).to be_a(ShortUrl)
        expect(result[:short_url].target_url).to eq('https://example.com')
      end

      it 'normalizes URL by adding https scheme' do
        service = described_class.new(target_url: 'example.com')
        result = service.call

        expect(result[:short_url].target_url).to start_with('https://')
      end

      it 'normalizes URL by lowercasing host' do
        stub_request(:get, 'https://example.com/Path')
          .to_return(body: '<html><head><title>Path</title></head></html>')
        service = described_class.new(target_url: 'https://EXAMPLE.COM/Path')
        result = service.call

        expect(result[:short_url].target_url).to include('example.com')
      end

      it 'removes trailing slash from path' do
        stub_request(:get, 'https://example.com/path')
          .to_return(body: '<html><head><title>Path</title></head></html>')
        service = described_class.new(target_url: 'https://example.com/path/')
        result = service.call

        expect(result[:short_url].target_url).to eq('https://example.com/path')
      end
    end

    context 'with invalid URL' do
      it 'returns failure for blank URL' do
        service = described_class.new(target_url: '')
        result = service.call

        expect(result[:success]).to be false
        expect(result[:errors]).to be_present
      end

      it 'returns failure for malformed URL' do
        service = described_class.new(target_url: 'not a url')
        result = service.call

        expect(result[:success]).to be false
      end
    end

    context 'with private/internal URLs (SSRF protection)' do
      it 'rejects localhost' do
        service = described_class.new(target_url: 'http://localhost:3000')
        result = service.call

        expect(result[:success]).to be false
        expect(result[:errors]).to include(/Private or internal URLs/)
      end

      it 'rejects 127.0.0.1' do
        service = described_class.new(target_url: 'http://127.0.0.1')
        result = service.call

        expect(result[:success]).to be false
      end

      it 'rejects 10.x private network' do
        service = described_class.new(target_url: 'http://10.0.0.1')
        result = service.call

        expect(result[:success]).to be false
      end

      it 'rejects 192.168.x private network' do
        service = described_class.new(target_url: 'http://192.168.1.1')
        result = service.call

        expect(result[:success]).to be false
      end

      it 'rejects 169.254.x link-local' do
        service = described_class.new(target_url: 'http://169.254.169.254')
        result = service.call

        expect(result[:success]).to be false
      end

      it 'rejects 172.16-31.x private network' do
        service = described_class.new(target_url: 'http://172.16.0.1')
        result = service.call

        expect(result[:success]).to be false
      end

      it 'accepts public IP' do
        stub_request(:get, 'http://8.8.8.8')
          .to_return(body: '<html><head><title>DNS</title></head></html>')
        service = described_class.new(target_url: 'http://8.8.8.8')
        result = service.call

        expect(result[:success]).to be true
      end
    end

    context 'title fetching' do
      it 'fetches and sets title from URL' do
        stub_request(:get, 'https://example.com')
          .to_return(body: '<html><head><title>Example Title</title></head></html>')

        service = described_class.new(target_url: 'https://example.com')
        result = service.call

        expect(result[:short_url].title).to eq('Example Title')
      end

      it 'handles title fetch failure gracefully' do
        stub_request(:get, 'https://example.com').to_timeout

        service = described_class.new(target_url: 'https://example.com')
        result = service.call

        expect(result[:success]).to be true
        expect(result[:short_url].title).to be_nil
      end
    end
  end
end
