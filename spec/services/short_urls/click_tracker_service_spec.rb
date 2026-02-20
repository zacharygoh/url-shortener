require 'rails_helper'

RSpec.describe ShortUrls::ClickTrackerService do
  let(:short_url) { create(:short_url) }

  describe '#call' do
    it 'increments click count' do
      service = described_class.new(
        short_url: short_url,
        ip: '8.8.8.8',
        user_agent: 'Mozilla/5.0',
        referrer: 'https://google.com'
      )

      expect { service.call }.to change { short_url.reload.click_count }.by(1)
    end

    it 'creates a click event record' do
      service = described_class.new(
        short_url: short_url,
        ip: '8.8.8.8',
        user_agent: 'Mozilla/5.0',
        referrer: 'https://google.com'
      )

      expect { service.call }.to change(ClickEvent, :count).by(1)
    end

    it 'records IP address' do
      service = described_class.new(
        short_url: short_url,
        ip: '8.8.8.8',
        user_agent: 'Mozilla/5.0',
        referrer: 'https://google.com'
      )

      service.call
      click_event = ClickEvent.last

      expect(click_event.ip_address.to_s).to eq('8.8.8.8')
    end

    it 'records user agent and referrer' do
      service = described_class.new(
        short_url: short_url,
        ip: '8.8.8.8',
        user_agent: 'Mozilla/5.0 Chrome',
        referrer: 'https://google.com'
      )

      service.call
      click_event = ClickEvent.last

      expect(click_event.user_agent).to eq('Mozilla/5.0 Chrome')
      expect(click_event.referrer).to eq('https://google.com')
    end

    it 'calls GeoIpService for location data' do
      geo_service = instance_double(GeoIpService)
      allow(GeoIpService).to receive(:new).and_return(geo_service)
      allow(geo_service).to receive(:lookup).with('8.8.8.8')
        .and_return({ country_code: 'US', city: 'Mountain View' })

      service = described_class.new(
        short_url: short_url,
        ip: '8.8.8.8',
        user_agent: 'Mozilla/5.0',
        referrer: nil
      )

      service.call
      click_event = ClickEvent.last

      expect(click_event.country_code).to eq('US')
      expect(click_event.city).to eq('Mountain View')
    end

    it 'returns success' do
      service = described_class.new(
        short_url: short_url,
        ip: '8.8.8.8',
        user_agent: 'Mozilla/5.0',
        referrer: nil
      )

      result = service.call

      expect(result[:success]).to be true
    end

    it 'handles errors gracefully' do
      allow(short_url).to receive(:increment!).and_raise(StandardError.new('DB error'))

      service = described_class.new(
        short_url: short_url,
        ip: '8.8.8.8',
        user_agent: 'Mozilla/5.0',
        referrer: nil
      )

      result = service.call

      expect(result[:success]).to be false
      expect(result[:error]).to be_present
    end
  end
end
