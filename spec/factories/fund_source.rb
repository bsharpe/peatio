FactoryBot.define do
  factory :fund_source do
    extra 'bitcoin'
    uid { Faker::Bitcoin.address }
    is_locked false
    currency 'btc'

    trait :eur do
      extra 'bank of euros'
      uid { SecureRandom.hex(10) }
      currency 'eur'
    end

    factory :eur_fund_source, traits: [:eur]
    factory :btc_fund_source
  end
end

