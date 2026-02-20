# frozen_string_literal: true

require "rails_helper"

RSpec.describe GeoIpService do
  subject(:service) { described_class.new }

  describe "#lookup" do
    it "returns default_location for blank IP" do
      expect(service.lookup("")).to eq(country_code: nil, country_name: nil, region: nil, city: nil)
      expect(service.lookup(nil)).to eq(country_code: nil, country_name: nil, region: nil, city: nil)
    end

    it "returns default_location for private IPs" do
      %w[127.0.0.1 10.0.0.1 192.168.1.1 172.16.0.1 169.254.1.1].each do |ip|
        expect(service.lookup(ip)).to eq(country_code: nil, country_name: nil, region: nil, city: nil)
      end
    end

    it "returns default_location when no row matches" do
      # Table empty or no range covers this IP
      result = service.lookup("8.8.8.8")
      expect(result[:country_code]).to be_nil
      expect(result[:city]).to be_nil
    end

    context "when ip_geo_ranges has a matching row" do
      # 8.8.8.8 as integer = 134744072
      let(:ip_int) { IPAddr.new("8.8.8.8").to_i }

      before do
        IpGeoRange.insert_all([ {
          ip_from: ip_int,
          ip_to: ip_int,
          country_code: "US",
          country_name: "United States",
          region: "California",
          city: "Mountain View"
        } ])
      end

      it "returns country_code and city from the range" do
        result = service.lookup("8.8.8.8")
        expect(result[:country_code]).to eq("US")
        expect(result[:country_name]).to eq("United States")
        expect(result[:region]).to eq("California")
        expect(result[:city]).to eq("Mountain View")
      end
    end

    it "returns default_location for invalid IP" do
      result = service.lookup("not-an-ip")
      expect(result).to eq(country_code: nil, country_name: nil, region: nil, city: nil)
    end
  end
end
