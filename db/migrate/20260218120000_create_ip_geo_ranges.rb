# frozen_string_literal: true

class CreateIpGeoRanges < ActiveRecord::Migration[7.2]
  def change
    create_table :ip_geo_ranges do |t|
      t.bigint :ip_from, null: false
      t.bigint :ip_to, null: false
      t.string :country_code, limit: 2
      t.string :country_name, limit: 100
      t.string :region, limit: 100
      t.string :city, limit: 100
    end

    add_index :ip_geo_ranges, [:ip_from, :ip_to], name: "index_ip_geo_ranges_on_ip_from_ip_to"
  end
end
