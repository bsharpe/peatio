class Account
  class BaseOperation
    include Interactor
    include Interactor::Contracts
    include Wisper::Publisher

    expects do
      required(:account).filled
      required(:amount).filled
      required(:reason).filled
      optional(:fee)
      optional(:reference)
    end

    on_breach do |breaches|
      context.fail!(breaches)
    end

    protected

    def create_record_of_change(operation, balance_delta, locked_delta = 0)
      puts "Account[#{context.account.id}] balance[#{context.account.balance}] locked[#{context.account.locked}]".green
      puts "%25s Account[#{context.account.id}] Amt[#{context.amount}] Locked[#{context.locked}] Fee[#{context.fee}]".yellow % self.class.name.split('::').last
      account = context.account
      account.transaction do
        account.balance += balance_delta
        account.locked  += locked_delta

        attributes = { operation: operation,
                       fee: context.fee || ZERO,
                       reason: context.reason || Account::UNKNOWN,
                       amount: context.account.total_amount,
                       currency: context.account.currency.to_sym,
                       member_id: context.account.member_id,
                       locked: locked_delta,
                       balance: balance_delta,
                     }
        attributes[:modifiable] = context.reference if context.reference.is_a?(ApplicationRecord)

        v = context.account.versions.build(attributes)
        if !v.valid?
          ap v.errors.full_messages
        end

        if !account.save
          ap account.errors.full_messages
          context.fail!(message: "Cannot save Account")
        else
          broadcast(operation, account.versions.last)
        end

        puts "Account[#{context.account.id}] balance[#{context.account.balance}] locked[#{context.account.locked}]".green
        puts
      end
    end
  end
end