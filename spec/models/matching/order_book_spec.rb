require 'rails_helper'

RSpec.describe Matching::OrderBook do

  context "#find" do
    subject { Matching::OrderBook.new('btceur', :ask) }

    it "should find specific order" do
      o1 = build_stubbed(:order_ask, price: 1)
      o2 = build_stubbed(:order_ask, price: 1)
      subject.add o1
      subject.add o2

      expect(subject.find(o1).id).to eq o1.id
      expect(subject.find(o2).id).to eq o2.id
    end
  end

  context "#add" do
    subject { Matching::OrderBook.new('btceur', :ask) }

    it "should reject invalid order whose volume is zero" do
      expect {
        subject.add build_stubbed(:order_ask,  volume: '0.0'.to_d)
      }.to raise_error(::Matching::InvalidOrderError)
    end

    it "should add market order" do
      subject.add build_stubbed(:order_ask)

      o1 = build_stubbed(:order_ask, ord_type: :market)
      o2 = build_stubbed(:order_ask, ord_type: :market)
      o3 = build_stubbed(:order_ask, ord_type: :market)
      subject.add o1
      subject.add o2
      subject.add o3

      expect(subject.market_orders).to eq [o1, o2, o3]
    end

    it "should create price level for order with new price" do
      order = build_stubbed(:order_ask)
      subject.add order
      expect(subject.limit_orders.keys.first).to eq order.price
      expect(subject.limit_orders.values.first).to eq [order]
    end

    it "should add order with same price to same price level" do
      o1 = build_stubbed(:order_ask)
      o2 = build_stubbed(:order_ask,  price: o1.price)
      subject.add o1
      subject.add o2

      expect(subject.limit_orders.keys).to have(1).price_level
      expect(subject.limit_orders.values.first).to eq [o1, o2]
    end

    it "should broadcast add event" do
      order = build_stubbed(:order_ask)

      expect(AMQPQueue).to receive(:enqueue).with(:slave_book, {action: 'new', market: 'btceur', side: :ask}, {persistent: false})
      expect(AMQPQueue).to receive(:enqueue).with(:slave_book, {action: 'add', order: order.attributes}, {persistent: false})
      subject.add order
    end

    it "should not broadcast add event" do
      order = build_stubbed(:order_ask)

      expect(AMQPQueue).to receive(:enqueue).with(:slave_book, {action: 'add', order: order.attributes}, {persistent: false}).never
      Matching::OrderBook.new('btceur', :ask, broadcast: false).add order
    end
  end

  context "#remove" do
    subject { Matching::OrderBook.new('btceur', :ask) }

    it "should remove market order" do
      subject.add build_stubbed(:order_ask)
      order = build_stubbed(:order_ask, ord_type: :market)
      subject.add order
      subject.remove order
      expect(subject.market_orders).to be_empty
    end

    it "should remove limit order" do
      o1 = build_stubbed(:order_ask, price: 1)
      o2 = build_stubbed(:order_ask, price: 1)
      subject.add o1
      subject.add o2
      subject.remove o1
      expect(subject.limit_orders.values.first).to have(1).order
    end

    it "should remove price level if its only limit order removed" do
      order = build_stubbed(:order_ask)
      subject.add(order)
      subject.remove(order)
      expect(subject.limit_orders).to be_empty
    end

    it "should return nil if order is not found" do
      order = build_stubbed(:order_ask)
      expect(subject.remove(order)).to be_nil
    end

    # TODO: Not sure what this is really testing
    it "should return order in book" do
      # create an order
      o1 = build_stubbed(:order_ask, price: 1)
      # make a copy
      o2 = o1.dup
      o2.id = o1.id
      # change the volume on the original order
      o1.volume = '12345'.to_d
      # add the original to the order book
      subject.add o1
      # try and remove the duplicate order
      o = subject.remove o2

      expect(o.volume).to eq '12345'.to_d
    end
  end

  context "#best_limit_price" do
    it "should return highest bid price" do
      book = Matching::OrderBook.new('btceur', :bid)
      o1   = build_stubbed(:order_bid,  price: '1.0'.to_d)
      o2   = build_stubbed(:order_bid,  price: '2.0'.to_d)
      book.add o1
      book.add o2

      expect(book.best_limit_price).to eq o2.price
    end

    it "should return lowest ask price" do
      book = Matching::OrderBook.new('btceur', :ask)
      o1   = build_stubbed(:order_ask, price: 1)
      o2   = build_stubbed(:order_ask,  price: '2.0'.to_d)
      book.add o1
      book.add o2

      expect(book.best_limit_price).to eq o1.price
    end

    it "should return nil if there's no limit order" do
      book = Matching::OrderBook.new('btceur', :ask)
      expect(book.best_limit_price).to be_nil
    end
  end

  context "#top" do
    it "should return market order if there's any market order" do
      book = Matching::OrderBook.new('btceur', :ask)
      o1 = build_stubbed(:order_ask)
      o2 = build_stubbed(:order_ask, ord_type: :market)
      book.add o1
      book.add o2

      expect(book.top).to eq o2
    end

    it "should return nil for empty book" do
      book = Matching::OrderBook.new('btceur', :ask)
      expect(book.top).to be_nil
    end

    it "should find ask order with lowest price" do
      book = Matching::OrderBook.new('btceur', :ask)
      o1 = build_stubbed(:order_ask, price: 1)
      o2 = build_stubbed(:order_ask,  price: '2.0'.to_d)
      book.add o1
      book.add o2

      expect(book.top).to eq o1
    end

    it "should find bid order with highest price" do
      book = Matching::OrderBook.new('btceur', :bid)
      o1 = build_stubbed(:order_bid,  price: '1.0'.to_d)
      o2 = build_stubbed(:order_bid,  price: '2.0'.to_d)
      book.add o1
      book.add o2

      expect(book.top).to eq o2
    end

    it "should favor earlier order if orders have same price" do
      book = Matching::OrderBook.new('btceur', :ask)
      o1 = build_stubbed(:order_ask, price: 1)
      o2 = build_stubbed(:order_ask, price: 1)
      book.add o1
      book.add o2

      expect(book.top).to eq o1
    end
  end

  context "#fill_top" do
    subject { Matching::OrderBook.new('btceur', :ask) }

    it "should raise error if there is no top order" do
      expect { subject.fill_top '1.0'.to_d, '1.0'.to_d, '1.0'.to_d }.to raise_error(OrderBookError::NoTop)
    end

    it "should complete fill the top market order" do
      subject.add build_stubbed(:order_ask,  volume: '1.0'.to_d)
      subject.add create(:matching_market_order, type: :ask, volume: '1.0'.to_d)
      subject.fill_top '1.0'.to_d, '1.0'.to_d, '1.0'.to_d
      expect(subject.market_orders).to be_empty
      expect(subject.limit_orders).to have(1).order
    end

    it "should partial fill the top market order" do
      subject.add build_stubbed(:order_ask,  volume: '1.0'.to_d)
      subject.add create(:matching_market_order, type: :ask, volume: '1.0'.to_d)
      subject.fill_top '1.0'.to_d, '0.6'.to_d, '0.6'.to_d
      expect(subject.market_orders.first.volume).to eq '0.4'.to_d
      expect(subject.limit_orders).to have(1).order
    end

    it "should remove the price level if top order is the only order in level" do
      subject.add build_stubbed(:order_ask,  volume: '1.0'.to_d)
      subject.fill_top '1.0'.to_d, '1.0'.to_d, '1.0'.to_d
      expect(subject.limit_orders).to be_empty
    end

    it "should remove order from level" do
      subject.add build_stubbed(:order_ask,  volume: '1.0'.to_d)
      subject.add build_stubbed(:order_ask,  volume: '1.0'.to_d)
      subject.fill_top '1.0'.to_d, '1.0'.to_d, '1.0'.to_d
      expect(subject.limit_orders.values.first).to have(1).order
    end

    it "should fill top order with volume" do
      subject.add build_stubbed(:order_ask,  volume: '2.0'.to_d)
      subject.fill_top '1.0'.to_d, '0.5'.to_d, '0.5'.to_d
      expect(subject.top.volume).to eq '1.5'.to_d
    end
  end

end
