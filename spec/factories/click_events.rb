FactoryBot.define do
  factory :click_event do
    association :short_url
    ip_address { "#{rand(1..255)}.#{rand(1..255)}.#{rand(1..255)}.#{rand(1..255)}" }
    country_code { %w[US SG JP UK CA].sample }
    city { %w[New\ York Singapore Tokyo London Toronto].sample }
    user_agent { "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)" }
    referrer { "https://www.google.com" }
    clicked_at { Time.current }
  end
end
