class Account
  class SubFunds < Account::BaseOperation
    before do
      context.fee ||= ZERO
    end

    def call
      amount = context.amount

      if !amount.positive? || amount > context.account.balance
        context.fail!(message: "cannot subtract funds (amount: #{amount})")
      end

      create_record_of_change(:sub_funds, ZERO - amount)
    end
  end
end