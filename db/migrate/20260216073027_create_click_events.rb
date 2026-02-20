class CreateClickEvents < ActiveRecord::Migration[7.2]
  def change
    create_table :click_events do |t|
      t.references :short_url, null: false, foreign_key: { on_delete: :cascade }
      t.inet :ip_address
      t.string :country_code, limit: 2
      t.string :city, limit: 100
      t.text :user_agent
      t.text :referrer
      t.datetime :clicked_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }

      t.timestamps
    end

    add_index :click_events, [:short_url_id, :clicked_at], order: { clicked_at: :desc }
    add_index :click_events, :country_code, where: 'country_code IS NOT NULL'
  end
end
