class Account
  class UnlockAndSubtractFunds < Account::BaseOperation
    before do
      context.fee    ||= ZERO
      context.locked ||= ZERO
    end

    def call
      account = context.account
      amount = context.amount
      locked = context.locked

      if !amount.positive? || (amount > locked)
        context.fail!(error: "cannot unlock and subtract funds (amount: #{amount})")
      end
      if locked.negative? || (locked > account.locked)
        context.fail!(error: "invalid lock amount (amount: #{amount}, locked: #{locked}, account.locked: #{account.locked})")
      end

      balance_delta = locked - amount
      locked_delta  = ZERO - locked

      create_record_of_change(:unlock_and_subtract_funds, balance_delta, locked_delta )
    end
  end
end