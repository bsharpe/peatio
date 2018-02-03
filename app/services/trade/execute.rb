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
      ActiveRecord::Base.transaction do
        ask = context.trade.ask.lock!
        bid = context.trade.bid.lock!

        bid.strike(context.trade)
        ask.strike(context.trade)
      end
    end
  end
end