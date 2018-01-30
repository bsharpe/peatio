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

require 'rails_helper'

RSpec.describe Deposit do
  it 'should compute fee' do
    deposit = build_stubbed(:deposit, amount: 100)
    expect(deposit.fee).to eql 0
    expect(deposit.amount).to eql 100
  end

  context 'when deposit fee 10%' do
    before do
      allow_any_instance_of(Deposit).to receive(:calc_fee).and_return([777, 10])
    end

    it 'should compute fee' do
      deposit = build_stubbed(:deposit, amount: 777)
      expect(deposit.fee).to eql(10)
      expect(deposit.amount).to eql(777)
    end
  end
end
