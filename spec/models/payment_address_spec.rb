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

require 'spec_helper'

describe PaymentAddress do

  context ".create" do
    it "generate address after commit" do
      expect(AMQPQueue).to receive(:enqueue)
        .with(:deposit_coin_address, {payment_address_id: 1, currency: 'btc'}, {persistent: true})

      address = PaymentAddress.create(currency: :btc)
      expect(address).to be_valid
      address.run_callbacks(:commit)
    end
  end

end
