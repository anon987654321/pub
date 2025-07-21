FactoryBot.define do
  factory :direct_message do
    sender_id { 1 }
    recipient_id { 1 }
    content { "MyText" }
    read_at { "2025-07-21 23:05:29" }
  end
end
