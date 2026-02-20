# app/models/click_event.rb
class ClickEvent < ApplicationRecord
  belongs_to :short_url

  validates :clicked_at, presence: true

  scope :recent, -> { order(clicked_at: :desc).limit(10) }
  scope :by_country, ->(country_code) { where(country_code: country_code) }
end
