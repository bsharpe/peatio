module Matching
  class ExecuteOrder
    include Interactor
    include Interactor::Contracts

    expects do
      required(:ask).filled
      required(:bid).filled
      required(:price).filled
      required(:volume).filled
      optional(:funds)
    end

    before do
      context.price = context.price.to_d
      context.volume = context.volume.to_d
      context.funds ||= (context.price * context.volume)
      context.funds = context.funds.to_d
      context.ask = OrderAsk.ensure(context.ask)
      context.bid = OrderBid.ensure(context.bid)
      context.market = Market.find(context.ask.market)
    end

    def call
      raise RuntimeError, "Mismatched Markets #{markets}" unless context.ask.market == context.bid.market

      ActiveRecord::Base.transaction do
        ask = context.ask.lock!
        bid = context.bid.lock!

        unless valid?
          raise TradeExecutionError.new({ask: ask, bid: bid, price: context.price, volume: context.volume, funds: context.funds})
        end

        context.trade = Trade.create!(
          ask_id: ask.id, ask_member_id: ask.member_id,
          bid_id: bid.id, bid_member_id: bid.member_id,
          price: context.price,
          volume: context.volume,
          funds: context.funds,
          currency: context.market.id.to_sym,
          trend: trend
          )

        bid.strike(context.trade)
        ask.strike(context.trade)
      end
    end

    def trend
      (context.price >= context.market.latest_price) ? 'up' : 'down'
    end

    def valid?
      return false if context.ask.ord_type == 'limit' && context.ask.price > context.price
      return false if context.bid.ord_type == 'limit' && context.bid.price < context.price
      context.funds > ZERO && [context.ask.volume, context.bid.volume].min >= context.volume
    end

  end
end