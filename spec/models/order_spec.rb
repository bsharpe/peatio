# == Schema Information
#
# Table name: orders
#
#  id             :integer          not null, primary key
#  bid            :integer
#  ask            :integer
#  currency       :integer
#  price          :decimal(32, 16)
#  volume         :decimal(32, 16)
#  origin_volume  :decimal(32, 16)
#  state          :integer
#  done_at        :datetime
#  type           :string(8)
#  member_id      :integer
#  created_at     :datetime
#  updated_at     :datetime
#  sn             :string(255)
#  source         :string(255)      not null
#  ord_type       :string(10)
#  locked         :decimal(32, 16)
#  origin_locked  :decimal(32, 16)
#  funds_received :decimal(32, 16)  default(0.0)
#  trades_count   :integer          default(0)
#
# Indexes
#
#  index_orders_on_currency_and_state   (currency,state)
#  index_orders_on_member_id            (member_id)
#  index_orders_on_member_id_and_state  (member_id,state)
#  index_orders_on_state                (state)
#

require 'rails_helper'

RSpec.describe Order, 'validations' do
  # it { should validate_presence_of(:ord_type) }
  # it { should validate_presence_of(:volume) }
  # it { should validate_presence_of(:origin_volume) }
  # it { should validate_presence_of(:locked) }
  # it { should validate_presence_of(:origin_locked) }

  context "limit order" do
    it "should make sure price is present" do
      order = Order.new(currency: 'btceur', price: nil, ord_type: 'limit')
      expect(order).to_not be_valid
      expect(order.errors[:price]).to eq ["is not a number"]
    end

    it "should make sure price is greater than zero" do
      order = Order.new(currency: 'btceur', price: '0.0'.to_d, ord_type: 'limit')
      expect(order).to_not be_valid
      expect(order.errors[:price]).to eq ["must be greater than 0"]
    end
  end

  context "market order" do
    it "should make sure price is not present" do
      order = Order.new(currency: 'btceur', price: '0.0'.to_d, ord_type: 'market')
      expect(order).to_not be_valid
      expect(order.errors[:price]).to eq ['must not be present']
    end
  end
end

RSpec.describe Order, "#fix_number_precision" do
  let(:order_bid) { create(:order_bid, currency: 'btceur', price: '12.326'.to_d, volume: '123.123456789') }
  let(:order_ask) { create(:order_ask, currency: 'btceur', price: '12.326'.to_d, volume: '123.123456789') }
  it { expect(order_bid.price).to be_d '12.32' }
  it { expect(order_bid.volume).to be_d '123.1234' }
  it { expect(order_bid.origin_volume).to be_d '123.1234' }
  it { expect(order_ask.price).to be_d '12.32' }
  it { expect(order_ask.volume).to be_d '123.1234' }
  it { expect(order_ask.origin_volume).to be_d '123.1234' }
end

RSpec.describe Order, "#done" do
  let(:ask_fee) { '0.003'.to_d }
  let(:bid_fee) { '0.001'.to_d }
  let(:order) { order_bid }
  let(:order_bid) { create(:order_bid, price: "1.2".to_d, volume: "10.0".to_d) }
  let(:order_ask) { create(:order_ask, price: "1.2".to_d, volume: "10.0".to_d) }
  let(:hold_account) { create(:account, member_id: 1, locked: "100.0".to_d, balance: "0.0".to_d) }
  let(:expect_account) { create(:account, member_id: 2, locked: "0.0".to_d, balance: "0.0".to_d) }

  before do
    allow(order_bid).to receive(:hold_account).and_return(hold_account)
    allow(order_bid).to receive(:expect_account).and_return(expect_account)
    allow(order_ask).to receive(:hold_account).and_return(hold_account)
    allow(order_ask).to receive(:expect_account).and_return(expect_account)
    allow_any_instance_of(OrderBid).to receive(:fee).and_return(bid_fee)
    allow_any_instance_of(OrderAsk).to receive(:fee).and_return(ask_fee)
  end

  shared_examples "trade done" do
    before do
      hold_account.reload
      expect_account.reload
    end

    it "order_bid done" do
      trade = build_stubbed(:trade, volume: strike_volume, price: strike_price)

      expect(::Account::UnlockAndSubtractFunds).to receive(:call).with(
        account: hold_account,
        amount: strike_volume * strike_price,
        locked: strike_volume * strike_price,
        reason: Account::STRIKE_SUB,
        reference: trade).and_call_original

      expect(::Account::AddFunds).to receive(:call).with(
        account: expect_account,
        amount: strike_volume - (strike_volume * bid_fee),
        reason: Account::STRIKE_ADD,
        fee: (strike_volume * bid_fee),
        reference: trade).and_call_original

      order_bid.strike(trade)
    end

    it "order_ask done" do
      trade = build_stubbed(:trade, volume: strike_volume, price: strike_price)

      expect(::Account::UnlockAndSubtractFunds).to receive(:call).with(
        account: hold_account,
        amount: strike_volume, locked: strike_volume,
        reason: Account::STRIKE_SUB,
        reference: trade).and_call_original

      expect(::Account::AddFunds).to receive(:call).with(
        account: expect_account,
        amount: (strike_volume * strike_price) - (strike_volume * strike_price * ask_fee),
        reason: Account::STRIKE_ADD,
        fee: (strike_volume * strike_price) * ask_fee,
        reference: trade).and_call_original

      order_ask.strike(trade)
    end
  end

  describe Order do
    describe "#state" do
      it "should be keep wait state" do
        expect do
          order.strike(build_stubbed(:trade, volume: "5.0", price: "0.8"))
        end.not_to change{ order.state }
      end

      it "should be change to done state" do
        expect do
          order.strike(build_stubbed(:trade, volume: "10.0", price:  "1.2"))
        end.to change{ order.state }.from(Order::WAIT).to(Order::DONE)
      end
    end

    describe "#volume" do
      it "should be change volume" do
        expect do
          order.strike(build_stubbed(:trade, volume: "4.0", price:  "1.2"))
        end.to change{ order.volume }.from("10.0".to_d).to("6.0".to_d)
      end

      it "should be don't change origin volume" do
        expect do
          order.strike(build_stubbed(:trade, volume: "4.0", price:  "1.2"))
        end.not_to change{ order.origin_volume }
      end
    end

    describe "#trades_count" do
      it "should increase trades count" do
        expect do
          order.strike(build_stubbed(:trade, volume: "4.0", price:  "1.2"))
        end.to change{ order.trades_count }.from(0).to(1)
      end
    end

    describe "#done" do
      context "trade done volume 5.0 with price 0.8" do
        let(:strike_price) { "0.8".to_d }
        let(:strike_volume) { "5.0".to_d }
        it_behaves_like "trade done"
      end

      context "trade done volume 3.1 with price 0.7" do
        let(:strike_price) { "0.7".to_d }
        let(:strike_volume) { "3.1".to_d }
        it_behaves_like "trade done"
      end

      context "trade done volume 10.0 with price 0.8" do
        let(:strike_price)  { "0.8".to_d }
        let(:strike_volume) { "10.0".to_d }

        it "should unlock not used funds" do
          trade = build_stubbed(:trade, volume: strike_volume, price: strike_price)

          expect(::Account::UnlockAndSubtractFunds).to receive(:call).with(
            account: hold_account,
            amount: strike_volume * strike_price,
            locked: strike_volume * strike_price,
            reason: Account::STRIKE_SUB,
            reference: trade).and_call_original

          expect(::Account::AddFunds).to receive(:call).with(
            account: expect_account,
            amount: strike_volume - (strike_volume * bid_fee),
            reason: Account::STRIKE_ADD,
            fee: (strike_volume * bid_fee),
            reference: trade).and_call_original

          expect(::Account::UnlockFunds).to receive(:call).with(
            account: hold_account,
            amount: strike_volume * (order.price - strike_price),
            reason: Account::ORDER_FULLFILLED,
            reference: trade).and_call_original

          order_bid.strike(trade)
        end
      end
    end
  end
end

RSpec.describe Order, "#head" do
  let(:currency) { :btceur }

  describe OrderAsk do
    it "price priority" do
      foo = create(:order_ask, price: "1.0".to_d, created_at: 2.second.ago)
      create(:order_ask, price: "1.1".to_d, created_at: 1.second.ago)
      expect(OrderAsk.head(currency)).to eql foo
    end

    it "time priority" do
      foo = create(:order_ask, price: "1.0".to_d, created_at: 2.second.ago)
      create(:order_ask, price: "1.0".to_d, created_at: 1.second.ago)
      expect(OrderAsk.head(currency)).to eql foo
    end
  end

  describe OrderBid do
    it "price priority" do
      foo = create(:order_bid, price: "1.1".to_d, created_at: 2.second.ago)
      create(:order_bid, price: "1.0".to_d, created_at: 1.second.ago)
      expect(OrderBid.head(currency)).to eql foo
    end

    it "time priority" do
      foo = create(:order_bid, price: "1.0".to_d, created_at: 2.second.ago)
      create(:order_bid, price: "1.0".to_d, created_at: 1.second.ago)
      expect(OrderBid.head(currency)).to eql foo
    end
  end
end

RSpec.describe Order, "#kind" do
  it "should be ask for ask order" do
    expect(OrderAsk.new.kind).to eq 'ask'
  end

  it "should be bid for bid order" do
    expect(OrderBid.new.kind).to eq 'bid'
  end
end

RSpec.describe Order, "related accounts" do
  let(:alice)  { who_is_billionaire }
  let(:bob)    { who_is_billionaire }

  context OrderAsk do
    it "should hold btc and expect eur" do
      ask = create(:order_ask, member: alice)
      expect(ask.hold_account).to eq alice.get_account(:btc)
      expect(ask.expect_account).to eq alice.get_account(:eur)
    end
  end

  context OrderBid do
    it "should hold eur and expect btc" do
      bid = create(:order_bid, member: bob)
      expect(bid.hold_account).to eq bob.get_account(:eur)
      expect(bid.expect_account).to eq bob.get_account(:btc)
    end
  end
end

RSpec.describe Order, "#avg_price" do
  it "should be zero if not filled yet" do
    expect(OrderAsk.new(locked: '1.0', origin_locked: '1.0', volume: '1.0', origin_volume: '1.0', funds_received: '0').avg_price).to eq '0'.to_d
    expect(OrderBid.new(locked: '1.0', origin_locked: '1.0', volume: '1.0', origin_volume: '1.0', funds_received: '0').avg_price).to eq '0'.to_d
  end

  it "should calculate average price of bid order" do
    expect(OrderBid.new(currency: 'btceur', locked: '10.0', origin_locked: '20.0', volume: '1.0', origin_volume: '3.0', funds_received: '2.0').avg_price).to eq '5'.to_d
  end

  it "should calculate average price of ask order" do
    expect(OrderAsk.new(currency: 'btceur', locked: '1.0', origin_locked: '2.0', volume: '1.0', origin_volume: '2.0', funds_received: '10.0').avg_price).to eq '10'.to_d
  end
end

RSpec.describe Order, "#estimate_required_funds" do
  let(:price_levels) do
    [ ['1.0'.to_d, '10.0'.to_d],
      ['2.0'.to_d, '20.0'.to_d],
      ['3.0'.to_d, '30.0'.to_d] ]
  end

  before do
    global = Global.new('btceur')
    allow(global).to receive(:asks).and_return(price_levels)
    allow(Global).to receive(:[]).and_return(global)
  end
end

RSpec.describe Order, "#strike" do
  it "should raise error if order has been cancelled" do
    order = Order.new(state: Order::CANCEL)
    expect { order.strike(build_stubbed(:trade)) }.to raise_error(OrderError)
  end
end
