class Account
  class UnlockFunds < Account::BaseOperation
    before do
      context.fee ||= ZERO
    end

    def call
      amount = context.amount
      account = context.account

      balance_delta = amount
      locked_delta  = ZERO - amount

      if !amount.positive? || amount > account.locked
        context.fail!(message: "cannot unlock funds (amount: #{amount})")
      end

      create_record_of_change(:unlock_funds, balance_delta, locked_delta)
    end
  end
end