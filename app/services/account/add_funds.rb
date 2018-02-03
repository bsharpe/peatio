class Account
  class AddFunds < Account::BaseOperation
    before do
      context.fee    ||= ZERO
      context.locked ||= ZERO
    end

    def call
      amount = context.amount

      if !amount.positive? || context.fee > amount
        context.fail!(message: "cannot add funds (amount: #{amount})")
      end

      create_record_of_change(:plus_funds, amount)
    end
  end
end