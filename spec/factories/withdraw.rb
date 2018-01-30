FactoryBot.define do
  factory :satoshi_withdraw, class: Withdraws::Satoshi do
    member
    sum 10
    currency :btc

    account do
      member.get_account(:btc).tap do |a|
        a.balance = 50
        a.save(validate: false)

        a.versions.create!(
          member: a.member,
          balance: a.balance,
          amount: a.balance,
          locked: 0,
          fee: 0,
          currency: a.currency,
          fun: Account::OPS[:plus_funds]
          )
      end
    end

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

    account do
      member.get_account(:eur).tap do |a|
        a.balance = 50000
        a.save(validate: false)

        a.versions.create!(
          member: a.member,
          balance: a.balance,
          amount: a.balance,
          locked: 0,
          fee: 0,
          currency: a.currency,
          fun: Account::OPS[:plus_funds]
          )
      end
    end

    after(:build) do |x|
      x.fund_source ||= build(:eur_fund_source, owner: x)
      x.account&.save!
    end
  end
end
