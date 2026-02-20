require 'rails_helper'

RSpec.describe ShortUrl, type: :model do
  describe 'associations' do
    it { should have_many(:click_events).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:target_url) }

    it 'validates URL format' do
      short_url = ShortUrl.new(target_url: 'not-a-url')
      expect(short_url).not_to be_valid
      expect(short_url.errors[:target_url]).to be_present
    end

    it 'accepts valid HTTP URLs' do
      short_url = ShortUrl.new(target_url: 'http://example.com')
      short_url.valid?
      expect(short_url.errors[:target_url]).to be_empty
    end

    it 'accepts valid HTTPS URLs' do
      short_url = ShortUrl.new(target_url: 'https://example.com')
      short_url.valid?
      expect(short_url.errors[:target_url]).to be_empty
    end

    it 'validates short_code uniqueness' do
      existing = create(:short_url)
      existing.update_column(:short_code, 'abc123')
      duplicate = build(:short_url, short_code: 'abc123')
      expect(duplicate).not_to be_valid
    end

    it 'validates short_code length' do
      short_url = build(:short_url)
      short_url.short_code = 'a' * 16
      expect(short_url).not_to be_valid
    end
  end

  describe 'callbacks' do
    it 'assigns short_code from id after creation' do
      short_url = create(:short_url, short_code: nil)
      expect(short_url.reload.short_code).to eq(ShortCode.encode(short_url.id))
    end
  end

  describe 'scopes' do
    describe '.active' do
      let!(:active_url) { create(:short_url, is_active: true, expires_at: nil) }
      let!(:inactive_url) { create(:short_url, is_active: false) }
      let!(:expired_url) { create(:short_url, is_active: true, expires_at: 1.day.ago) }
      let!(:not_expired_url) { create(:short_url, is_active: true, expires_at: 1.day.from_now) }

      it 'returns only active and non-expired URLs' do
        expect(ShortUrl.active).to contain_exactly(active_url, not_expired_url)
      end
    end
  end
end
