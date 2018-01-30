FactoryBot.define do
  factory :account do
    locked  0
    balance 100
    currency :eur

    factory :account_btc do
      currency :btc
    end
  end
end

