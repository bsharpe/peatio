# == Schema Information
#
# Table name: deposits
#
#  id                     :integer          not null, primary key
#  account_id             :integer
#  member_id              :integer
#  currency               :integer
#  amount                 :decimal(32, 16)
#  fee                    :decimal(32, 16)
#  fund_uid               :string(255)
#  fund_extra             :string(255)
#  txid                   :string(255)
#  state                  :integer
#  aasm_state             :string(255)
#  created_at             :datetime
#  updated_at             :datetime
#  done_at                :datetime
#  confirmations          :string(255)
#  type                   :string(255)
#  payment_transaction_id :integer
#  txout                  :integer
#
# Indexes
#
#  index_deposits_on_txid_and_txout  (txid,txout)
#

FactoryBot.define do
  factory :deposit do
    member { create(:member) }
    account { member.get_account(currency) }
    currency { 'btc' }
    fund_uid { Faker::Lorem.characters }
    fund_extra { Faker::Lorem.characters }
    amount { (100..10000).to_a.sample.to_d }
    txid { Faker::Lorem.characters(16) }
  end
end
