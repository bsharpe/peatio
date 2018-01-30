# == Schema Information
#
# Table name: accounts
#
#  id                              :integer          not null, primary key
#  member_id                       :integer
#  currency                        :integer
#  balance                         :decimal(32, 16)  default(0.0)
#  locked                          :decimal(32, 16)
#  created_at                      :datetime
#  updated_at                      :datetime
#  in                              :decimal(32, 16)
#  out                             :decimal(32, 16)
#  default_withdraw_fund_source_id :integer
#
# Indexes
#
#  index_accounts_on_member_id               (member_id)
#  index_accounts_on_member_id_and_currency  (member_id,currency) UNIQUE
#

require 'rails_helper'

RSpec.describe Account, type: :model do
  subject { create(:account, locked: 10, balance: 10) }

  # it { expect(subject.amount).to eq(20) }
  # it { expect(subject.sub_funds(1.0).balance).to eq(9.0) }
  # it { expect(subject.plus_funds(1.0).balance).to eq(11.0) }
  # it { expect(subject.unlock_funds(1.0).locked).to eq(9.0) }
  # it { expect(subject.unlock_funds(1.0).balance).to eq(11.0) }
  # it { expect(subject.lock_funds(1.0).locked).to eq(11.0) }
  # it { expect(subject.lock_funds(1.0).balance).to eq(9.0) }
  #
  # it { expect(subject.unlock_and_sub_funds(1.0, locked: 1.0).balance).to eq(10) }
  # it { expect(subject.unlock_and_sub_funds(1.0, locked: 1.0).locked).to eq(9) }
  #
  # it { expect(subject.sub_funds(0.1).balance).to eq(9.9) }
  # it { expect(subject.plus_funds(0.1).balance).to eq(10.1) }
  # it { expect(subject.unlock_funds(0.1).locked).to eq(9.9) }
  # it { expect(subject.unlock_funds(0.1).balance).to eq(10.1) }
  # it { expect(subject.lock_funds(0.1).locked).to eq(10.1) }
  # it { expect(subject.lock_funds(0.1).balance).to eq(9.9) }
  #
  # it { expect(subject.unlock_and_sub_funds(0.1, locked: 1.0).balance).to eq(10.9) }
  # it { expect(subject.unlock_and_sub_funds(0.1, locked: 1.0).locked).to eq(9) }
  #
  # it { expect(subject.sub_funds(10).balance).to eq(0.0) }
  # it { expect(subject.plus_funds(10).balance).to eq(20.0) }
  # it { expect(subject.unlock_funds(10).locked).to eq(0.0) }
  # it { expect(subject.unlock_funds(10).balance).to eq(20.0) }
  # it { expect(subject.lock_funds(10).locked).to eq(20.0) }
  # it { expect(subject.lock_funds(10).balance).to eq(0.0) }
  #
  # it { expect{subject.sub_funds(11.0)}.to raise_error(AccountError) }
  # it { expect{subject.lock_funds(11.0)}.to raise_error(AccountError) }
  # it { expect{subject.unlock_funds(11.0)}.to raise_error(AccountError) }
  #
  # it { expect{subject.unlock_and_sub_funds(1.1, locked: 1.0)}.to raise_error(AccountError) }
  #
  # it { expect{subject.sub_funds(-1.0)}.to raise_error(AccountError) }
  # it { expect{subject.plus_funds(-1.0)}.to raise_error(AccountError) }
  # it { expect{subject.lock_funds(-1.0)}.to raise_error(AccountError) }
  # it { expect{subject.unlock_funds(-1.0)}.to raise_error(AccountError) }
  # it { expect{subject.sub_funds(0)}.to raise_error(AccountError) }
  # it { expect{subject.plus_funds(0)}.to raise_error(AccountError) }
  # it { expect{subject.lock_funds(0)}.to raise_error(AccountError) }
  # it { expect{subject.unlock_funds(0)}.to raise_error(AccountError) }

  describe "basic functions" do
    let(:account) { create :account }

    it "should add funds" do
      expect {
        context = Account::AddFunds.call(account: account, amount: 10, reason: Account::DEPOSIT)
        expect(context.success?).to eq(true)
      }.to change{account.balance}.by(10)
    end

    it "should NOT add NEGATIVE funds" do
      context = Account::AddFunds.call(account: account, amount: -10, fee: 0.1, reason: Account::DEPOSIT)
      expect(context.success?).to eq(false)
    end

    it "should add funds with a FEE" do
      expect {
        context = Account::AddFunds.call(account: account, amount: 10, fee: 0.1, reason: Account::DEPOSIT)
        expect(context.success?).to eq(true)
      }.to change{account.balance}.by(10)
    end

    it "should subtract funds" do
      context = Account::SubFunds.call(account: account, amount: 10, reason: Account::WITHDRAW)
      expect(context.success?).to eq(true)
    end

    it "should NOT subtract NEGATIVE funds" do
      context = Account::SubFunds.call(account: account, amount: -1, reason: Account::WITHDRAW)
      expect(context.success?).to eq(false)
    end

    it "should NOT subtract funds we don't have" do
      context = Account::SubFunds.call(account: account, amount: 10_000, reason: Account::WITHDRAW)
      expect(context.success?).to eq(false)
    end

    it "should lock funds" do
      context = Account::LockFunds.call(account: account, amount: 10, reason: Account::WITHDRAW_LOCK)
      expect(context.success?).to eq(true)
    end

    it "should NOT lock funds we don't have" do
      context = Account::LockFunds.call(account: account, amount: 30_000, reason: Account::WITHDRAW_LOCK)
      expect(context.success?).to eq(false)
    end

    it "should NOT lock NEGATIVE funds" do
      context = Account::LockFunds.call(account: account, amount: -1, reason: Account::WITHDRAW_LOCK)
      expect(context.success?).to eq(false)
    end

    it "should unlock funds" do
      context = Account::LockFunds.call(account: account, amount: 10, reason: Account::WITHDRAW_LOCK)
      context = Account::UnlockFunds.call(account: account, amount: 10, reason: Account::WITHDRAW_UNLOCK)
      expect(context.success?).to eq(true)
    end

    it "should NOT unlock funds if none are locked" do
      context = Account::UnlockFunds.call(account: account, amount: 10, reason: Account::WITHDRAW_UNLOCK)
      expect(context.success?).to eq(false)
    end

    it "should unlock and subtract funds" do
      context = Account::LockFunds.call(account: account, amount: 10, reason: Account::WITHDRAW_LOCK)
      context = Account::UnlockAndSubtractFunds.call(account: account, amount: 10, locked: 10, fee: 1, reason: Account::WITHDRAW_UNLOCK)
      expect(context.success?).to eq(true)
    end


  end

  it "expect to set reason" do
    subject.plus_funds(1.0)
    expect(subject.versions.last.reason.to_sym).to eql Account::UNKNOWN
  end

  it "expect to set ref" do
    ref = double(id: 1)

    subject.plus_funds(1.0, ref: ref)

    expect(subject.versions.last.modifiable_id).to eq(1)
  end

  describe "double operation" do
    let(:amount) { 10 }
    let(:account) { create(:account) }

    it "expect double operation funds" do
      expect do
        Account::AddFunds.call(account: account, amount: amount, reason: Account::STRIKE_ADD)
        Account::SubFunds.call(account: account, amount: amount, reason: Account::STRIKE_FEE)
      end.to_not change{account.balance}
    end

    it "expect double operation funds to add versions" do
      expect do
        Account::AddFunds.call(account: account, amount: amount, reason: Account::STRIKE_ADD)
        Account::SubFunds.call(account: account, amount: amount, reason: Account::STRIKE_FEE)
      end.to change{account.reload.versions.size}.from(0).to(2)
    end
  end

  describe "#payment_address" do
    it { expect(subject.payment_address).not_to be_nil }
    it { expect(subject.payment_address).to be_is_a(PaymentAddress) }
  end

  describe "#versions" do
    let(:account) { create(:account) }

    context 'when account add funds' do
      before do
        Account::AddFunds.(account: account, amount: 10, reason: Account::DEPOSIT)
      end

      it { expect( account.versions.last.reason.withdraw?).to eq(true) }
      it { expect( account.versions.last.locked).to eq(0) }
      it { expect( account.versions.last.balance).to eq(10) }
      it { expect( account.versions.last.amount).to eq(110) }
      it { expect( account.versions.last.fee).to eq(0) }
      it { expect( account.versions.last.fun).to eq 'plus_funds' }
    end

    context 'when account add funds with fee' do
      subject { account.plus_funds(10, fee: 1, reason: Account::WITHDRAW).versions.last }

      it { expect(subject.reason.withdraw?).to eq(true) }
      it { expect(subject.locked).to eq(0) }
      it { expect(subject.balance).to eq(10) }
      it { expect(subject.amount).to eq(110) }
      it { expect(subject.fee).to eq(1) }
      it { expect(subject.fun).to eq 'plus_funds' }
    end

    context 'when account sub funds' do
      subject { account.sub_funds(10, reason: Account::WITHDRAW).versions.last }
      it { expect(subject.reason.withdraw?).to eq(true) }
      it { expect(subject.locked).to eq(0) }
      it { expect(subject.balance).to eq(-10) }
      it { expect(subject.amount).to eq(90) }
      it { expect(subject.fee).to eq(0) }
      it { expect(subject.fun).to eq 'sub_funds' }
    end

    context 'when account sub funds with fee' do
      subject { account.sub_funds(10, fee: 1, reason: Account::WITHDRAW).versions.last }
      it { expect(subject.reason.withdraw?).to eq(true) }
      it { expect(subject.locked).to eq(0) }
      it { expect(subject.balance).to eq(-10) }
      it { expect(subject.amount).to eq(90) }
      it { expect(subject.fee).to eq(1) }
      it { expect(subject.fun).to eq 'sub_funds' }
    end

    context 'when account lock funds' do
      subject { account.lock_funds(10, reason: Account::WITHDRAW).versions.last }
      it { expect(subject.reason.withdraw?).to eq(true) }
      it { expect(subject.locked).to eq(10) }
      it { expect(subject.balance).to eq(-10) }
      it { expect(subject.amount).to eq(100.0) }
    end

    context 'when account unlock funds' do
      let(:account) { create(:account, locked: 10) }
      subject { account.unlock_funds(10, reason: Account::WITHDRAW).versions.last }
      it { expect(subject.reason.withdraw?).to eq(true) }
      it { expect(subject.locked).to eq(-10) }
      it { expect(subject.balance).to eq(10) }
      it { expect(subject.amount).to eq(110) }
    end

    context 'when account unlock and sub funds' do
      let(:account) { create(:account, balance: 10, locked: 10) }
      subject { account.unlock_and_sub_funds(10, locked: 10, reason: Account::WITHDRAW).versions.last }
      it { expect(subject.reason.withdraw?).to eq(true) }
      it { expect(subject.locked).to eq(-10) }
      it { expect(subject.balance).to eq(0) }
      it { expect(subject.amount).to be_d 10 }
      it { expect(subject.fee).to eq(0) }
      it { expect(subject.fun).to eq 'unlock_and_sub_funds' }
    end

    context 'when account unlock and sub funds with fee' do
      let(:account) { create(:account, balance: 10, locked: 10) }
      subject { account.unlock_and_sub_funds(10, fee: 1, locked: 10, reason: Account::WITHDRAW).versions.last }
      it { expect(subject.reason.withdraw?).to eq(true) }
      it { expect(subject.locked).to eq(-10) }
      it { expect(subject.balance).to eq(0) }
      it { expect(subject.amount).to be_d 10 }
      it { expect(subject.fee).to eq(1) }
      it { expect(subject.fun).to eq 'unlock_and_sub_funds' }
    end
  end

  describe "#verify" do
    let(:member) { create(:member) }
    let(:account) { create(:account, locked: 0.0, balance: 0) }

    context "account without any account versions" do
      it "returns true" do
        expect(account.verify).to eq(true)
      end

      it "returns false when account changed without versions" do
        allow(account).to receive(:member).and_return(member)
        account.update_attribute(:balance, 5000)
        expect(account.verify).to eq(false)
      end
    end

    context "account with account versions" do
      before do
        account.plus_funds(100.0)
        account.sub_funds(1.0)
        account.plus_funds(12.0)
        account.lock_funds(12.0)
        account.unlock_funds(1.0)
        account.lock_funds(1.0)
        account.lock_funds(1.0)
      end

      it "returns true" do
        expect(account.verify).to eq(true)
      end

      it "returns false when account balance doesn't match versions" do
        allow(account).to receive(:member).and_return(member)
        account.update_attribute(:balance, 5000)
        expect(account.verify).to eq(false)
      end

      it "returns false when account versions were changed" do
        account.versions.load.sample.update_attribute(:amount, 50.to_d)
        expect(account.verify).to eq(false)
      end
    end
  end

  describe "#change_balance_and_locked" do
    it "should update balance and locked funds in memory" do
      subject.change_balance_and_locked -10, 10
      expect(subject.balance).to eq(0)
      expect(subject.locked).to eq(20)
    end

    it "should update balance and locked funds in db" do
      subject.change_balance_and_locked -10, 10
      subject.reload
      expect(subject.balance).to eq(0)
      expect(subject.locked).to eq(20)
    end
  end

  describe "after callback" do
    it "should create account version associated to account change" do
      expect {
        subject.unlock_and_sub_funds(1.0, locked: 2.0)
      }.to change(AccountVersion, :count).by(1)

      v = AccountVersion.last

      expect(v.member_id).to eq subject.member_id
      expect(v.account).to eq subject
      expect(v.fun).to eq 'unlock_and_sub_funds'
      expect(v.reason).to eq 'unknown'
      expect(v.amount).to eq subject.amount
      expect(v.balance).to eq 1.0
      expect(v.locked).to eq -2.0
    end

    it "should retry the whole transaction on stale object error" do
      subject.update(balance: subject.balance + 3, locked: subject.locked - 8)

      expect {
        expect {
          ActiveRecord::Base.transaction do
            create(:order_ask) # any other statements should be executed
            subject.unlock_and_sub_funds(1.0, locked: 2.0)
          end
        }.to change(OrderAsk, :count).by(1)
      }.to change(AccountVersion, :count).by(1)

      v = AccountVersion.last
      expect(v.amount).to eq 14.0
      expect(v.balance).to eq 1.0
      expect(v.locked).to eq -2.0
    end
  end

  describe "concurrent lock_funds" do
    it "should raise error on the second lock_funds" do
      account1 = Account.find subject.id
      account2 = Account.find subject.id

      expect(subject.reload.balance).to eq BigDecimal.new('10')

      expect do
        ActiveRecord::Base.transaction do
          account1.lock_funds 8, reason: Account::ORDER_SUBMIT
        end
        ActiveRecord::Base.transaction do
          account2.lock_funds 8, reason: Account::ORDER_SUBMIT
        end
      end.to raise_error(ActiveRecord::RecordInvalid)

      expect(subject.reload.balance).to eq BigDecimal.new('2')
    end
  end

  describe ".enabled" do
    let!(:account1) { create(:account, currency: Currency.first.code,   member: nil)}
    let!(:account2) { create(:account, currency: Currency.last.code,    member: nil)}
    let!(:account3) { create(:account, currency: Currency.all[1].code,  member: nil)}
    before do
      allow(Currency).to receive(:ids).and_return([Currency.first.id, Currency.last.id])
    end

    it "should only return the accoutns with currency enabled" do
      expect(Account.enabled.to_a).to eq [account1, account2]
    end

  end

end
