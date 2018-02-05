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

        if order.state == Order::STATE_WAITING
          ActiveRecord::Base.transaction do
            order.state = Order::STATE_CANCELED
            account.unlock_funds(order.locked, reason: Account::ORDER_CANCEL, ref: order)
            order.save!
          end
        else
          raise CancelOrderError, "Only active order can be canceled. id: #{order.id}, state: #{order.state}"
        end

    end
  end
end
