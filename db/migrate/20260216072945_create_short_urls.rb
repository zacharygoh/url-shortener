class CreateShortUrls < ActiveRecord::Migration[7.2]
  def change
    create_table :short_urls do |t|
      # Note: short_code is nullable on create because it's set in after_create callback from id
      # This avoids race conditions with database sequence
      t.string :short_code, limit: 15, null: true
      t.text :target_url, null: false
      t.string :title, limit: 500
      t.integer :click_count, default: 0, null: false
      t.boolean :is_active, default: true, null: false
      t.datetime :expires_at

      t.timestamps
    end

    add_index :short_urls, :short_code, unique: true
    add_index :short_urls, :created_at
  end
end
