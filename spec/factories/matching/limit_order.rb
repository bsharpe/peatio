FactoryBot.define do
  factory :matching_limit_order, class: Matching::LimitOrder do
    sequence(:id)
    timestamp { Time.current.to_i }
    volume    { rand(10) + 1 }
    type      :bid
    price     { rand(3000) + 3000 }
    market    { Market.find('btceur') }
  end
end