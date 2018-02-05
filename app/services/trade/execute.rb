class Trade
  class Execute
    include Interactor
    include Interactor::Contracts

    expects do
      required(:trade).filled
    end

    before do
      trade_error = context.trade.check_trade?
      context.fail!(error: "Invalid Trade: #{trade_error}") if trade_error
    end

    def call
      trade = context.trade

      ActiveRecord::Base.transaction do
        ask = trade.ask.lock!
        bid = trade.bid.lock!

        result = Order::Strike.(order: bid, trade: trade)
        context.fail!(error: "BID: #{result.error}") unless result.success?
        result = Order::Strike.(order: ask, trade: trade)
        context.fail!(error: "ASK: #{result.error}") unless result.success?
      end
    end
  end
end