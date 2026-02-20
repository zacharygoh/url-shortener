class CreatePriceCaches < ActiveRecord::Migration[7.2]
  def change
    create_table :price_caches do |t|
      t.string :network, limit: 50, null: false
      t.string :token_address, limit: 66, null: false
      # Use decimal for financial precision (never float/double for money)
      t.decimal :usd_price, precision: 30, scale: 18, null: false
      t.datetime :fetched_at, null: false
      t.datetime :expires_at, null: false
      t.text :source_url

      t.timestamps
    end

    # Unique constraint on network + token_address combination
    add_index :price_caches, [ :network, :token_address ], unique: true
    add_index :price_caches, :expires_at
  end
end
