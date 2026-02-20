require 'rails_helper'

RSpec.describe UrlTitleFetcher do
  let(:fetcher) { described_class.new }

  describe '#fetch' do
    context 'with valid URL' do
      it 'extracts title from HTML' do
        stub_request(:get, 'https://example.com')
          .to_return(body: '<html><head><title>Example Title</title></head></html>')

        title = fetcher.fetch('https://example.com')

        expect(title).to eq('Example Title')
      end

      it 'handles missing title tag' do
        stub_request(:get, 'https://example.com')
          .to_return(body: '<html><head></head></html>')

        title = fetcher.fetch('https://example.com')

        expect(title).to be_nil
      end

      it 'strips whitespace from title' do
        stub_request(:get, 'https://example.com')
          .to_return(body: '<html><head><title>  Example  </title></head></html>')

        title = fetcher.fetch('https://example.com')

        expect(title).to eq('Example')
      end
    end

    context 'with SSRF protection' do
      it 'rejects localhost' do
        title = fetcher.fetch('http://localhost:3000')
        expect(title).to be_nil
      end

      it 'rejects 127.0.0.1' do
        title = fetcher.fetch('http://127.0.0.1')
        expect(title).to be_nil
      end

      it 'rejects 10.x private IPs' do
        title = fetcher.fetch('http://10.0.0.1')
        expect(title).to be_nil
      end

      it 'rejects 192.168.x private IPs' do
        title = fetcher.fetch('http://192.168.1.1')
        expect(title).to be_nil
      end

      it 'rejects 169.254.x link-local IPs' do
        title = fetcher.fetch('http://169.254.169.254')
        expect(title).to be_nil
      end

      it 'rejects 172.16-31.x private IPs' do
        title = fetcher.fetch('http://172.20.0.1')
        expect(title).to be_nil
      end

      it 'accepts public IPs' do
        stub_request(:get, 'http://8.8.8.8')
          .to_return(body: '<html><head><title>Google DNS</title></head></html>')

        title = fetcher.fetch('http://8.8.8.8')
        expect(title).to eq('Google DNS')
      end
    end

    context 'with errors' do
      it 'returns nil on timeout' do
        stub_request(:get, 'https://example.com').to_timeout

        title = fetcher.fetch('https://example.com')

        expect(title).to be_nil
      end

      it 'returns nil on HTTP error' do
        stub_request(:get, 'https://example.com')
          .to_return(status: 500)

        title = fetcher.fetch('https://example.com')

        expect(title).to be_nil
      end

      it 'returns nil for blank URL' do
        title = fetcher.fetch('')
        expect(title).to be_nil
      end

      it 'returns nil for nil URL' do
        title = fetcher.fetch(nil)
        expect(title).to be_nil
      end
    end
  end
end
