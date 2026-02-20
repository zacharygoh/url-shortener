# app/models/short_url.rb
class ShortUrl < ApplicationRecord
  has_many :click_events, dependent: :destroy

  validates :target_url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }
  validates :short_code, uniqueness: true, allow_nil: true, length: { maximum: 15 }

  after_create :assign_short_code_from_id

  scope :active, -> { where(is_active: true).where("expires_at IS NULL OR expires_at > ?", Time.current) }

  private

  # Assign short_code from database id to avoid race conditions
  # This ensures the short_code is always unique since it's derived from the auto-increment ID
  def assign_short_code_from_id
    update_column(:short_code, ShortCode.encode(id))
  end
end
