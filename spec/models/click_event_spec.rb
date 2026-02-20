require 'rails_helper'

RSpec.describe ClickEvent, type: :model do
  describe 'associations' do
    it { should belong_to(:short_url) }
  end

  describe 'validations' do
    it { should validate_presence_of(:clicked_at) }
  end

  describe 'scopes' do
    describe '.recent' do
      let(:short_url) { create(:short_url) }

      it 'returns recent clicks ordered by clicked_at desc' do
        old_click = create(:click_event, short_url: short_url, clicked_at: 2.days.ago)
        new_click = create(:click_event, short_url: short_url, clicked_at: 1.day.ago)
        newest_click = create(:click_event, short_url: short_url, clicked_at: 1.hour.ago)

        recent = ClickEvent.recent
        expect(recent.first).to eq(newest_click)
        expect(recent.second).to eq(new_click)
      end

      it 'limits to 10 records' do
        short_url = create(:short_url)
        15.times { create(:click_event, short_url: short_url) }

        expect(ClickEvent.recent.count).to eq(10)
      end
    end

    describe '.by_country' do
      let(:short_url) { create(:short_url) }

      it 'filters by country code' do
        us_click = create(:click_event, short_url: short_url, country_code: 'US')
        sg_click = create(:click_event, short_url: short_url, country_code: 'SG')

        expect(ClickEvent.by_country('US')).to contain_exactly(us_click)
      end
    end
  end
end
