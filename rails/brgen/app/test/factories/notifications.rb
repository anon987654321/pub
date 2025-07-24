FactoryBot.define do
  factory :notification do
    user { nil }
    message { "MyText" }
    notification_type { "MyString" }
    read_at { "2025-07-21 23:05:15" }
  end
end
