FactoryBot.define do
  factory :satoshi_withdraw, class: Withdraws::Satoshi do
    member
    sum 10
    currency :btc

    account {
      account = member.account(:btc)
      Account::AddFunds.(account: account, amount: 50, reason: Account::DEPOSIT)
      account
    }

    after(:build) do |x|
      # allow(x).to receive(:validate_address).and_return(true)
      x.fund_source ||= build(:btc_fund_source, owner: x)
      x.account&.save!
    end
  end

  factory :bank_withdraw, class: Withdraws::Bank do
    member
    currency :eur
    sum 1000

    account {
      account = member.account(:eur)
      Account::AddFunds.(account: account, amount: 50_000, reason: Account::DEPOSIT)
      account
    }

    after(:build) do |x|
      x.fund_source ||= build(:eur_fund_source, owner: x)
      x.account&.save!
    end
  end
end
