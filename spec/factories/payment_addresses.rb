# == Schema Information
#
# Table name: payment_addresses
#
#  id         :integer          not null, primary key
#  account_id :integer
#  address    :string(255)
#  created_at :datetime
#  updated_at :datetime
#  currency   :integer
#

# Read about factories at https://github.com/thoughtbot/factory_Bot

FactoryBot.define do
  factory :payment_address do
    address "FakeAddress"
    account { create(:member).account(:eur) }
    currency :eur

    trait :btc_address do
      address { Faker::Bitcoin.address }
      account { create(:member).account(:btc) }
      currency :btc
    end

    factory :btc_payment_address, traits: [:btc_address]
  end
end
