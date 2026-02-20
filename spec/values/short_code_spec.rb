require 'rails_helper'

RSpec.describe ShortCode do
  describe '.encode' do
    it 'encodes 0 to first character' do
      expect(ShortCode.encode(0)).to eq('0')
    end

    it 'encodes 1 to second character' do
      expect(ShortCode.encode(1)).to eq('1')
    end

    it 'encodes 62 to "10"' do
      expect(ShortCode.encode(62)).to eq('10')
    end

    it 'encodes large numbers correctly' do
      expect(ShortCode.encode(1_000_000)).to eq('4c92')
    end

    it 'produces codes under MAX_LENGTH for reasonable IDs' do
      code = ShortCode.encode(1_000_000_000)
      expect(code.length).to be <= ShortCode::MAX_LENGTH
    end
  end

  describe '.decode' do
    it 'decodes "0" to 0' do
      expect(ShortCode.decode('0')).to eq(0)
    end

    it 'decodes "1" to 1' do
      expect(ShortCode.decode('1')).to eq(1)
    end

    it 'decodes "10" to 62' do
      expect(ShortCode.decode('10')).to eq(62)
    end

    it 'is inverse of encode' do
      [ 1, 100, 1000, 100_000, 1_000_000 ].each do |id|
        encoded = ShortCode.encode(id)
        expect(ShortCode.decode(encoded)).to eq(id)
      end
    end

    it 'handles empty string' do
      expect(ShortCode.decode('')).to eq(0)
    end

    it 'handles nil' do
      expect(ShortCode.decode(nil)).to eq(0)
    end
  end

  describe '.valid_format?' do
    it 'accepts alphanumeric codes' do
      expect(ShortCode.valid_format?('abc123')).to be true
      expect(ShortCode.valid_format?('XYZ')).to be true
      expect(ShortCode.valid_format?('123')).to be true
    end

    it 'rejects codes exceeding MAX_LENGTH' do
      long_code = 'a' * (ShortCode::MAX_LENGTH + 1)
      expect(ShortCode.valid_format?(long_code)).to be false
    end

    it 'rejects codes with special characters' do
      expect(ShortCode.valid_format?('abc-123')).to be false
      expect(ShortCode.valid_format?('abc_123')).to be false
      expect(ShortCode.valid_format?('abc.123')).to be false
    end

    it 'rejects blank codes' do
      expect(ShortCode.valid_format?('')).to be false
      expect(ShortCode.valid_format?(nil)).to be false
    end
  end
end
