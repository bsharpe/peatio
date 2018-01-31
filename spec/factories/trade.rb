FactoryBot.define do
  factory :trade do
    association :ask, factory: :order_ask
    association :bid, factory: :order_bid
    price   10.0
    volume  1.0
    funds   { price.to_f * volume.to_f }
    currency :btceur
    ask_member { ask.member }
    bid_member { bid.member }
  end
end
