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

module Deposits
  class Crypto < ::Deposit
    validates_presence_of :payment_transaction_id
    validates_uniqueness_of :payment_transaction_id
    belongs_to :payment_transaction
    validates_uniqueness_of :txout, scope: :txid

    def channel
      @channel ||= DepositChannel.find_by_key(self.class.name.demodulize.underscore)
    end

    def min_confirm?(confirmations)
      update_confirmations(confirmations)
      confirmations >= channel.min_confirm && confirmations < channel.max_confirm
    end

    def max_confirm?(confirmations)
      update_confirmations(confirmations)
      confirmations >= channel.max_confirm
    end

    def update_confirmations(confirmations)
      if !self.new_record? && self.confirmations.to_s != confirmations.to_s
        self.update_attribute(:confirmations, confirmations.to_s)
      end
    end

    def blockchain_url
      currency_obj.blockchain_url(txid)
    end

    def as_json(options = {})
      super(options).merge({
        txid: txid.blank? ? "" : txid[0..29],
        confirmations: payment_transaction.nil? ? 0 : payment_transaction.confirmations,
        blockchain_url: blockchain_url
      })
    end

  end
end
