# == Schema Information
#
# Table name: payment_transactions
#
#  id            :integer          not null, primary key
#  txid          :string(255)
#  amount        :decimal(32, 16)
#  confirmations :integer
#  address       :string(255)
#  state         :integer
#  aasm_state    :string(255)
#  created_at    :datetime
#  updated_at    :datetime
#  receive_at    :datetime
#  dont_at       :datetime
#  currency      :integer
#  type          :string(60)
#  txout         :integer
#
# Indexes
#
#  index_payment_transactions_on_txid_and_txout  (txid,txout)
#  index_payment_transactions_on_type            (type)
#

FactoryBot.define do
  factory :payment_transaction do
    txid { Faker::Lorem.characters(16) }
    txout 0
    currency { 'btc' }
    amount { 10.to_d }
    payment_address
  end
end
