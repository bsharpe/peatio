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

require 'rails_helper'

RSpec.describe PaymentAddress do

  context ".create" do
    it "generate address after commit" do
      member = create(:member)
      address = PaymentAddress.create(currency: :btc, account: member.account(:btc))
      expect(AMQPQueue).to receive(:enqueue)
        .with(:deposit_coin_address, {payment_address_id: address.id, currency: address.currency}, {persistent: true})
      address.gen_address
      expect(address).to be_valid
    end
  end

end
