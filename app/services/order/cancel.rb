class Order
  class Cancel
    include Interactor
    include Interactor::Contracts

    expects do
      required(:order).filled
    end

    before do
      context.order = Order.ensure(context.order)
    end

    def call
        account = context.order.hold_account

        if order.state == Order::WAIT
          ActiveRecord::Base.transaction do
            order.state = Order::CANCEL
            account.unlock_funds(order.locked, reason: Account::ORDER_CANCEL, ref: order)
            order.save!
        else
          raise CancelOrderError, "Only active order can be cancelled. id: #{order.id}, state: #{order.state}"
        end

    end
  end
end
