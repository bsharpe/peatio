class Order
  class Strike
    include Interactor
    include Interactor::Contracts

    expects do
      required(:order).filled
      required(:trade).filled
    end

    before do
      unless context.order.waiting?
        context.fail!(error: "Cannot strike on CANCELLED or DONE order. id: #{context.order.id}, state: #{context.order.state.to_s.upcase}")
      end
    end

    def call
      order = context.order
      trade = context.trade

      real_sub  = order.subtract_funds(trade)
      add       = order.add_funds(trade)
      real_fee  = add * order.fee.to_d
      real_add  = add - real_fee

      result = Account::UnlockAndSubtractFunds.call(
        account: order.hold_account,
        amount: real_sub,
        locked: real_sub,
        reason: Account::STRIKE_SUB,
        reference: trade
        )
      context.fail!(result.error) unless result.success?

      result = Account::AddFunds.call(
        account: order.expect_account,
        amount: real_add,
        fee: real_fee,
        reason: Account::STRIKE_ADD,
        reference: trade
        )
      context.fail!(result.error) unless result.success?

      order.volume         -= trade.volume
      order.locked         -= real_sub
      order.funds_received += add
      order.trades_count   += 1

      if order.volume.zero?
        order.done!

        # unlock unused funds
        if order.locked.positive?
          Account::UnlockFunds.call(
            account: order.hold_account,
            amount: order.locked,
            reason: Account::ORDER_FULLFILLED,
            reference: trade)
        end
      elsif order.ord_type == 'market' && order.locked.zero?
        # partially filled market order has run out its locked fund
        order.cancel!
      end

      order.save!
    end
  end
end