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

require 'rails_helper'

RSpec.describe PaymentTransaction do
  it "expect state transfer" do
    tx = create(:payment_transaction, deposit: create(:deposit))
    allow(tx).to receive(:refresh_confirmations)

    allow(tx).to receive(:min_confirm?).and_return(false)
    allow(tx).to receive(:max_confirm?).and_return(false)

    expect(tx.unconfirm?).to eq(true)
    expect(tx.check).to eq(false)
    expect(tx.check).to eq(false)
    expect(tx.check).to eq(false)
    expect(tx.unconfirm?).to eq(true)

    allow(tx).to receive(:min_confirm?).and_return(true)
    allow(tx).to receive(:max_confirm?).and_return(false)

    expect(tx.check).to eq(true)
    expect(tx.confirming?).to eq(true)

    allow(tx).to receive(:min_confirm?).and_return(false)
    allow(tx).to receive(:max_confirm?).and_return(true)

    expect(tx.check).to eq(true)
    expect(tx.confirmed?).to eq(true)
    expect(tx.check).to eq(true)
  end

end
