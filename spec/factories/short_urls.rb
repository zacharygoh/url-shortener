FactoryBot.define do
  factory :short_url do
    target_url { "https://example.com/#{SecureRandom.hex(8)}" }
    title { "Example Page" }
    is_active { true }
    click_count { 0 }

    trait :inactive do
      is_active { false }
    end

    trait :expired do
      expires_at { 1.day.ago }
    end

    trait :with_clicks do
      after(:create) do |short_url|
        create_list(:click_event, 5, short_url: short_url)
      end
    end
  end
end
