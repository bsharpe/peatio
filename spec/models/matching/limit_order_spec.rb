require 'rails_helper'

RSpec.describe Order do

  context "initialize" do
    it "should throw invalid order error for empty attributes" do
      expect(Order.new(type: '', price: '', volume: '').valid?).to eq(false)
    end

    it "should initialize market" do
        expect(build(:order_bid).market).to be_instance_of(Market)
    end
  end

  context "crossed?" do
    it "should cross at lower or equal price for bid order" do
      order = build(:order_bid, price: '10.0'.to_d)
      expect(order.crossed?('9.0'.to_d)).to eq(true)
      expect(order.crossed?('10.0'.to_d)).to eq(true)
      expect(order.crossed?('11.0'.to_d)).to eq(false)
    end

    it "should cross at higher or equal price for ask order" do
      order = build(:order_ask, price: '10.0'.to_d)
      expect(order.crossed?('9.0'.to_d)).to eq(false)
      expect(order.crossed?('10.0'.to_d)).to eq(true)
      expect(order.crossed?('11.0'.to_d)).to eq(true)
    end
  end
end
