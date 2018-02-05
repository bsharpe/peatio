FactoryBot.define do
  factory :matching_market_order, class: Matching::MarketOrder do
    sequence(:id)
    timestamp { Time.current.to_i }
    volume    { rand(10) + 1 }
    type
    price     { rand(15000) + 15000 }
    market    { Market.find('btceur') }
  end
end