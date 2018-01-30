class Account
  class LockFunds < Account::BaseOperation
    before do
      context.fee ||= ZERO
    end

    def call
      amount = context.amount

      balance_delta = ZERO - amount
      locked_delta  = amount

      if !amount.positive? || amount > context.account.balance
        context.fail!( message: "cannot lock funds (amount: #{amount})")
      end

      create_record_of_change(:lock_funds, balance_delta, locked_delta)
    end
  end
end