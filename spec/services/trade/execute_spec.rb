require 'rails_helper'

RSpec.describe Trade::Execute, type: :service do

  let(:alice)  { create(:member, :billionaire) }
  let(:bob)    { create(:member, :billionaire) }
  let(:price)  { 10 }
  let(:volume) { 5 }
  let(:market) { Market.find('btceur') }

  context "Bounds Checking" do
    let(:ask) { build_stubbed(:order_ask, price: price, volume: volume, member: alice) }
    let(:bid) { build_stubbed(:order_bid, price: price, volume: volume, member: bob ) }

    let(:trade) { build_stubbed(:trade, ask: ask, bid: bid, price: price, volume: volume) }

    it "should not accept a bad volume" do
      bid.volume = 3
      context = described_class.(trade: trade)

      expect(context.failure?).to eq(true)
      expect(context.error).to be_present
    end

    it "should not accept a bid price lower than ask price" do
      bid.price -= 1
      context = described_class.(trade: trade)

      expect(context.failure?).to eq(true)
      expect(context.error).to be_present
    end

    it "should not accept an ask price higher than bid price" do
      ask.price += 1
      context = described_class.(trade: trade)

      expect(context.failure?).to eq(true)
      expect(context.error).to be_present
    end

    it "should not accept an ask in a different market" do
      ask.currency = :eur
      context = described_class.(trade: trade)

      expect(context.failure?).to eq(true)
      expect(context.error).to be_present
    end
  end

  context "Actual Execution" do
    let(:ask) { create(:order_ask, price: price, volume: volume, member: alice) }
    let(:bid) { create(:order_bid, price: price, volume: volume, member: bob) }

    let(:trade) { create(:trade, ask: ask, bid: bid, price: price, volume: volume) }

    it "should set trend to down" do
      allow(market).to receive(:latest_price).and_return(11.to_d)
      trade = described_class.(ask: ask, bid: bid, price: price, volume: volume).trade

      expect(trade.trend).to eq 'down'
    end

    it "should set trade used funds" do
      allow(market).to receive(:latest_price).and_return(11.to_d)
      trade = described_class.(ask: ask, bid: bid, price: price, volume: volume).trade
      expect(trade.funds).to eq price*volume
    end

    it "should increase order's trades count" do
      described_class.(ask: ask, bid: bid, price: price, volume: volume)
      expect(Order.find(ask.id).trades_count).to eq 1
      expect(Order.find(bid.id).trades_count).to eq 1
    end

    it "should mark both orders as done" do
      described_class.(ask: ask, bid: bid, price: price, volume: volume)

      expect(Order.find(ask.id).state).to eq Order::STATE_DONE
      expect(Order.find(bid.id).state).to eq Order::STATE_DONE
    end

    # it "should publish trade through amqp" do
    #   allow(AMQPQueue).to receive(:publish)
    #   described_class.(ask: ask, bid: bid, price: price, volume: volume)
    # end
  end

  context "partial ask execution" do
    let(:ask) { create(:order_ask, price: price, volume: 7.to_d, member: alice) }
    let(:bid) { create(:order_bid, price: price, volume: 5.to_d, member: bob) }

    it "should set bid to done only" do
      described_class.(ask: ask, bid: bid, price: price, volume: volume)

      expect(ask.reload.state).to_not eq Order::STATE_DONE
      expect(bid.reload.state).to eq Order::STATE_DONE
    end
  end

  context "partial bid execution" do
    let(:ask) { create(:order_ask, price: price, volume: 5.to_d, member: alice) }
    let(:bid) { create(:order_bid, price: price, volume: 7.to_d, member: bob) }

    it "should set ask to done only" do
      described_class.(ask: ask, bid: bid, price: price, volume: volume)

      expect(ask.reload.state).to eq Order::STATE_DONE
      expect(bid.reload.state).to_not eq Order::STATE_DONE
    end
  end

  context "partially filled market order whose locked fund run out" do
    let(:ask) { create(:order_ask, price: '2.0'.to_d, volume: '3.0'.to_d, member: alice) }
    let(:bid) { create(:order_bid, price: nil, ord_type: 'market', volume: '2.0'.to_d, locked: '3.0'.to_d, member: bob) }

    it "should cancel the market order" do
      described_class.( ask: ask, bid: bid, price: 2, volume: 1.5, funds: 3.0 )

      expect(bid.reload.state).to eq Order::STATE_CANCELED
    end
  end

  context "unlock not used funds" do
    let(:ask) { create(:order_ask, price: 9, volume: 7, member: alice) }
    let(:bid) { create(:order_bid, price: 10, volume: 5, member: bob) }

    it "should unlock funds not used by bid order" do
      expect {
        described_class.(ask: ask, bid: bid, price: price, volume: volume)
      }.to change{bid.hold_account.locked}.by(-(price * volume))
    end

    it "should save unused amount in order locked attribute" do
      described_class.(ask: ask, bid: bid, price: price, volume: volume)

      expect(bid.reload.locked).to eq (price * volume) - ((price - 1) * volume)
    end
  end

  # context "execution fail" do
  #   let(:ask) { ::Matching::LimitOrder.new create(:order_ask, price: price, volume: volume, member: alice).to_matching_attributes }
  #   let(:bid) { ::Matching::LimitOrder.new create(:order_bid, price: price, volume: volume, member: bob).to_matching_attributes }
  #
  #   it "should not create trade" do
  #     # set locked funds to 0 so strike will fail
  #     account = alice.account(:btc)
  #     account.update(locked: ZERO)
  #
  #     executor = Matching::Executor.new(
  #       market_id:    market.id,
  #       ask_id:       ask.id,
  #       bid_id:       bid.id,
  #       strike_price: price,
  #       volume:       volume,
  #       funds:        (price*volume)
  #     )
  #     expect do
  #       executor.execute!
  #     end.not_to change(Trade, :count)
  #   end
  # end

end
