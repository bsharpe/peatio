require 'rails_helper'

RSpec.describe Matching::Engine do

  let(:market) { Market.find('btceur') }
  let(:price)  { 10.to_d }
  let(:volume) { 5.to_d }
  let(:ask)    { create(:matching_limit_order, type: :ask, price: price, volume: volume)}
  let(:bid)    { create(:matching_limit_order, type: :bid, price: price, volume: volume)}

  let(:orderbook) { Matching::OrderBookManager.new('btceur', broadcast: false) }
  subject         { Matching::Engine.new(market, mode: :run) }
  before          { allow(subject).to receive(:orderbook).and_return(orderbook) }

  context "submit market order" do
    let!(:bid)  { create(:matching_limit_order, type: :bid, price: '0.1'.to_d, volume: '0.1'.to_d) }
    let!(:ask1) { create(:matching_limit_order, type: :ask, price: '1.0'.to_d, volume: '1.0'.to_d) }
    let!(:ask2) { create(:matching_limit_order, type: :ask, price: '2.0'.to_d, volume: '1.0'.to_d) }
    let!(:ask3) { create(:matching_limit_order, type: :ask, price: '3.0'.to_d, volume: '1.0'.to_d) }

    it "should fill the market order completely" do
      mo = create(:matching_market_order, type: :bid, locked: '6.0'.to_d, volume: '2.4'.to_d)

      expect(AMQPQueue).to receive(:enqueue).with(:trade_executor, {market_id: market.id, ask_id: ask1.id, bid_id: mo.id, strike_price: ask1.price, volume: ask1.volume, funds: '1.0'.to_d}, anything)
      expect(AMQPQueue).to receive(:enqueue).with(:trade_executor, {market_id: market.id, ask_id: ask2.id, bid_id: mo.id, strike_price: ask2.price, volume: ask2.volume, funds: '2.0'.to_d}, anything)
      expect(AMQPQueue).to receive(:enqueue).with(:trade_executor, {market_id: market.id, ask_id: ask3.id, bid_id: mo.id, strike_price: ask3.price, volume: '0.4'.to_d, funds: '1.2'.to_d}, anything)

      subject.submit bid
      subject.submit ask1
      subject.submit ask2
      subject.submit ask3
      subject.submit mo

      expect(subject.ask_orders.limit_orders).to have(1).price_level
      expect(subject.ask_orders.limit_orders.values.first).to eq [ask3]
      expect(ask3.volume).to eq '0.6'.to_d

      expect(subject.bid_orders.market_orders).to be_empty
    end

    it "should fill the market order partially and cancel it" do
      mo = create(:matching_market_order, type: :bid, locked: '6.0'.to_d, volume: '2.4'.to_d)

      expect(AMQPQueue).to receive(:enqueue).with(:trade_executor, {market_id: market.id, ask_id: ask1.id, bid_id: mo.id, strike_price: ask1.price, volume: ask1.volume, funds: '1.0'.to_d}, anything)
      expect(AMQPQueue).to receive(:enqueue).with(:trade_executor, {market_id: market.id, ask_id: ask2.id, bid_id: mo.id, strike_price: ask2.price, volume: ask2.volume, funds: '2.0'.to_d}, anything)
      expect(AMQPQueue).to receive(:enqueue).with(:order_processor, hash_including(action: 'cancel', order: hash_including(id: mo.id)), anything)

      subject.submit bid
      subject.submit ask1
      subject.submit ask2
      subject.submit mo

      expect(subject.ask_orders.limit_orders).to be_empty
      expect(subject.bid_orders.market_orders).to be_empty
    end

    it "should partially fill then cancel the market order if locked funds run out" do
      mo = create(:matching_market_order, type: :bid, locked: '2.5'.to_d, volume: '2'.to_d)

      expect(AMQPQueue).to receive(:enqueue).with(:trade_executor, {market_id: market.id, ask_id: ask1.id, bid_id: mo.id, strike_price: ask1.price, volume: ask1.volume, funds: '1.0'.to_d}, anything)
      expect(AMQPQueue).to receive(:enqueue).with(:trade_executor, {market_id: market.id, ask_id: ask2.id, bid_id: mo.id, strike_price: ask2.price, volume: '0.75'.to_d, funds: '1.5'.to_d}, anything)

      subject.submit bid
      subject.submit ask1
      subject.submit ask2
      subject.submit ask3
      subject.submit mo

      expect(subject.ask_orders.limit_orders).to have(2).price_level
      expect(ask2.volume).to eq '0.25'.to_d
      expect(ask3.volume).to eq '1.0'.to_d

      expect(subject.bid_orders.market_orders).to be_empty
    end
  end

  context "submit limit order" do
    context "fully match incoming order" do
      it "should execute trade" do
        expect(AMQPQueue).to receive(:enqueue)
        .with(:trade_executor, {market_id: market.id, ask_id: ask.id, bid_id: bid.id, strike_price: price, volume: volume, funds: '50.0'.to_d}, anything)

        subject.submit(ask)
        subject.submit(bid)

        expect(subject.ask_orders.limit_orders).to be_empty
        expect(subject.bid_orders.limit_orders).to be_empty
      end
    end

    context "partial match incoming order" do
      let(:ask) { create(:matching_limit_order, type: :ask, price: price, volume: 3.to_d)}

      it "should execute trade" do
        expect(AMQPQueue).to receive(:enqueue)
          .with(:trade_executor, {market_id: market.id, ask_id: ask.id, bid_id: bid.id, strike_price: price, volume: 3.to_d, funds: '30.0'.to_d}, anything)

        subject.submit(ask)
        subject.submit(bid)

        expect(subject.ask_orders.limit_orders).to be_empty
        expect(subject.bid_orders.limit_orders).to_not be_empty

        expect(AMQPQueue).to receive(:enqueue)
          .with(:order_processor, {action: 'cancel', order: bid.attributes}, anything)
        subject.cancel(bid)
        expect(subject.bid_orders.limit_orders).to be_empty
      end
    end

    context "match order with many counter orders" do
      let(:bid)    { create(:matching_limit_order, type: :bid, price: price, volume: 10.to_d)}

      let(:asks) do
        [nil,nil,nil].map do
          create(:matching_limit_order, type: :ask, price: price, volume: 3.to_d)
        end
      end

      it "should execute trade" do
        expect(AMQPQueue).to receive(:enqueue).exactly(asks.size).times

        asks.each {|ask| subject.submit(ask) }
        subject.submit(bid)

        expect(subject.ask_orders.limit_orders).to be_empty
        expect(subject.bid_orders.limit_orders).to_not be_empty
      end
    end

    context "fully match order after some cancellatons" do
      let(:bid)      { create(:matching_limit_order, type: :bid, price: price,   volume: 10.to_d)}
      let(:low_ask)  { create(:matching_limit_order, type: :ask, price: price-1, volume: 3.to_d) }
      let(:high_ask) { create(:matching_limit_order, type: :ask, price: price,   volume: 3.to_d) }

      it "should match bid with high ask" do
        subject.submit(low_ask) # low ask enters first
        subject.submit(high_ask)
        subject.cancel(low_ask) # but it's canceled

        expect(AMQPQueue).to receive(:enqueue)
        .with(:trade_executor, {market_id: market.id, ask_id: high_ask.id, bid_id: bid.id, strike_price: high_ask.price, volume: high_ask.volume, funds: '30.0'.to_d}, anything)
        subject.submit(bid)

        expect(subject.ask_orders.limit_orders).to be_empty
        expect(subject.bid_orders.limit_orders).to_not be_empty
      end
    end
  end

  context "#cancel" do
    it "should cancel order" do
      subject.submit(ask)
      subject.cancel(ask)
      expect(subject.ask_orders.limit_orders).to be_empty

      subject.submit(bid)
      subject.cancel(bid)
      expect(subject.bid_orders.limit_orders).to be_empty
    end
  end

  context "float number edge cases" do
    it "should add up used funds to locked funds" do
      order = create(:order_bid, price: '3662.05', volume: '0.62')
      bid  = create(:matching_limit_order, order.to_matching_attributes)

      ask1 = create(:matching_limit_order, type: :ask, price: '3658.28'.to_d, volume: '0.0129'.to_d)
      ask2 = create(:matching_limit_order, type: :ask, price: '3661.72'.to_d, volume: '0.26'.to_d)
      ask3 = create(:matching_limit_order, type: :ask, price: '3659.00'.to_d, volume: '0.2945'.to_d)
      ask4 = create(:matching_limit_order, type: :ask, price: '3661.68'.to_d, volume: '0.0526'.to_d)

      used_funds = 0
      allow(subject).to receive(:publish) do |order, counter_order, trade|
        price, volume, funds = trade
        used_funds += funds
      end

      subject.submit bid
      subject.submit ask1
      subject.submit ask2
      subject.submit ask3
      subject.submit ask4

      expect(used_funds).to eq  order.compute_locked
    end
  end

  context "dryrun" do
    subject { Matching::Engine.new(market, mode: :dryrun) }

    it "should not publish matched trades" do
      expect(AMQPQueue).to receive(:enqueue).never

      subject.submit(ask)
      subject.submit(bid)

      expect(subject.ask_orders.limit_orders).to be_empty
      expect(subject.bid_orders.limit_orders).to be_empty

      expect(subject.queue).to have(1).trade
      expect(subject.queue.first).to eq [:trade_executor, {market_id: market.id, ask_id: ask.id, bid_id: bid.id, strike_price: price, volume: volume, funds: '50.0'.to_d}, {persistent: false}]
    end
  end

end
