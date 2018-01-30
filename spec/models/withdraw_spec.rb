# == Schema Information
#
# Table name: withdraws
#
#  id         :integer          not null, primary key
#  sn         :string(255)
#  account_id :integer
#  member_id  :integer
#  currency   :integer
#  amount     :decimal(32, 16)
#  fee        :decimal(32, 16)
#  fund_uid   :string(255)
#  fund_extra :string(255)
#  created_at :datetime
#  updated_at :datetime
#  done_at    :datetime
#  txid       :string(255)
#  aasm_state :string(255)
#  sum        :decimal(32, 16)  default(0.0), not null
#  type       :string(255)
#

require 'rails_helper'

RSpec.describe Withdraw do

  context '#fix_precision' do
    it "should round down to max precision" do
      withdraw = create(:satoshi_withdraw, sum: '0.123456789')
      expect(withdraw.sum).to eq '0.12345678'.to_d
    end
  end

  context 'fund source' do
    it "should strip trailing spaces in fund_uid" do
      fund_source = create(:btc_fund_source, uid: 'test   ')
      @withdraw = create(:satoshi_withdraw, fund_source: fund_source)
      expect(@withdraw.fund_uid).to eq 'test'
    end
  end

  context 'bank withdraw' do
    describe "#audit!" do
      subject { create(:bank_withdraw) { |bw| bw.submit! } }

      it "should accept withdraw with clean history" do
        subject.audit!
        expect(subject).to be_accepted
      end

      it "should mark withdraw with suspicious history" do
        subject.account.versions.delete_all
        subject.audit!
        expect(subject).to be_suspect
      end

      it "should approve quick withdraw directly" do
        subject.update_attributes sum: 5
        subject.audit!
        expect(subject).to be_processing
      end
    end
  end

  context 'coin withdraw' do
    describe '#audit!' do
      subject { create(:satoshi_withdraw) { |sw| sw.submit! } }

      it "should be rejected if address is invalid" do
        allow(CoinRPC).to receive(:[]).and_return(double('rpc', validateaddress: {isvalid: false}))
        subject.audit!
        expect(subject).to be_rejected
      end

      it "should be rejected if address belongs to hot wallet" do
        allow(CoinRPC).to receive(:[]).and_return(double('rpc', validateaddress: {isvalid: true, ismine: true}))
        subject.audit!
        expect(subject).to be_rejected
      end

      it "should accept withdraw with clean history" do
        allow(CoinRPC).to receive(:[]).and_return(double('rpc', validateaddress: {isvalid: true}))
        subject.audit!
        expect(subject).to be_accepted
      end

      it "should mark withdraw with suspicious history" do
        allow(CoinRPC).to receive(:[]).and_return(double('rpc', validateaddress: {isvalid: true}))
        subject.account.versions.delete_all
        subject.audit!
        expect(subject).to be_suspect
      end

      it "should approve quick withdraw directly" do
        allow(CoinRPC).to receive(:[]).and_return(double('rpc', validateaddress: {isvalid: true}))
        subject.update_attributes sum: '0.099'
        subject.audit!
        expect(subject).to be_processing
      end
    end

    describe 'sn' do
      before do
        Timecop.freeze(Time.local(2013,10,7,18,18,18))
        @withdraw = create(:satoshi_withdraw, id: 1)
      end

      after do
        Timecop.return
      end

      it "generate right sn" do
        expect(@withdraw.sn).to eq('1310071818000001')
      end

      it 'alias withdraw_id to sn' do
        expect(@withdraw.withdraw_id).to eq('1310071818000001')
      end
    end

    describe 'account id assignment' do
      subject { build :satoshi_withdraw, account_id: 999 }

      it "don't accept account id from outside" do
        subject.save
        expect(subject.account_id).to eq(subject.member.get_account(subject.currency).id)
      end
    end
  end

  context 'Worker::WithdrawCoin#process' do
    subject { create(:satoshi_withdraw) }
    before do
      @rpc = double()
      allow(@rpc).to receive(:getbalance).and_return(50000)
      allow(@rpc).to receive(:sendtoaddress).and_return('12345')
      allow(@rpc).to receive(:settxfee).and_return(true)

      @broken_rpc = double()
      allow(@broken_rpc).to receive(:getbalance).and_return(5)

      subject.submit
      subject.accept
      subject.process
      subject.save!
    end

    it 'transitions to :almost_done after calling rpc but getting Exception' do
      allow(CoinRPC).to receive(:[]).and_return(@broken_rpc)

      expect { Worker::WithdrawCoin.new.process({id: subject.id}, {}, {}) }.to raise_error(Account::BalanceError)

      expect(subject.reload.almost_done?).to eq(true)
    end

    it 'transitions to :done after calling rpc' do
      allow(CoinRPC).to receive(:[]).and_return(@rpc)

      expect { Worker::WithdrawCoin.new.process({id: subject.id}, {}, {}) }.to change{subject.account.reload.amount}.by(-subject.sum)

      subject.reload
      expect(subject.done?).to eq(true)
      expect(subject.txid).to eq('12345')
    end

    it 'does not send coins again if previous attempt failed' do
      allow(CoinRPC).to receive(:[]).and_return(@broken_rpc)
      begin
        Worker::WithdrawCoin.new.process({id: subject.id}, {}, {})
      rescue Account::BalanceError
        # ignore failure
      end
      allow(CoinRPC).to receive(:[]).and_return(double())

      expect {
        Worker::WithdrawCoin.new.process({id: subject.id}, {}, {})
      }.to_not change{ subject.account.reload.amount }

      expect(subject.reload.almost_done?).to eq(true)
    end
  end

  context 'aasm_state' do
    let(:bank_withdraw) { create(:bank_withdraw, sum: 1000) }

    it 'initializes with state :submitting' do
      expect(bank_withdraw.submitting?).to eq(true)
    end

    it 'transitions to :submitted after calling #submit!' do
      bank_withdraw.submit!
      expect(bank_withdraw.submitted?).to eq(true)
      account = bank_withdraw.account
      expect(bank_withdraw.sum).to eq(account.locked)
      expect(bank_withdraw.sum).to eq(account.versions.last.locked)
    end

    it 'transitions to :rejected after calling #reject!' do
      bank_withdraw.submit!
      bank_withdraw.accept!
      bank_withdraw.reject!

      expect(bank_withdraw.rejected?).to eq(true)
    end

    context :process do
      before do
        bank_withdraw.submit!
        bank_withdraw.accept!
      end

      it 'transitions to :processing after calling #process! when withdrawing fiat currency' do
        allow(bank_withdraw).to receive(:coin?).and_return(false)

        bank_withdraw.process!

        expect(bank_withdraw.processing?).to eq(true)
      end

      it 'transitions to :failed after calling #fail! when withdrawing fiat currency' do
        allow(bank_withdraw).to receive(:coin?).and_return(false)

        bank_withdraw.process!

        expect { bank_withdraw.fail! }.to_not change{bank_withdraw.account.amount}

        expect(bank_withdraw.failed?).to eq(true)
      end

      it 'transitions to :processing after calling #process!' do
        expect(bank_withdraw).to receive(:send_coins!)
        expect(bank_withdraw).to receive(:send_email)

        bank_withdraw.process!

        expect(bank_withdraw.processing?).to eq(true)
      end
    end

    context :cancel do
      it 'transitions to :canceled after calling #cancel!' do
        bank_withdraw.cancel!

        expect(bank_withdraw.canceled?).to eq(true)
        expect(bank_withdraw.account.locked).to eq 0
      end

      it 'transitions from :submitted to :canceled after calling #cancel!' do
        bank_withdraw.submit!
        bank_withdraw.cancel!

        expect(bank_withdraw.canceled?).to eq(true)
        expect(bank_withdraw.account.locked).to eq 0
      end

      it 'transitions from :accepted to :canceled after calling #cancel!' do
        bank_withdraw.submit!
        bank_withdraw.accept!
        bank_withdraw.cancel!

        expect(bank_withdraw.canceled?).to eq(true)
        expect(bank_withdraw.account.locked).to eq 0
      end
    end
  end

  context "#quick?" do
    subject(:withdraw) { build(:satoshi_withdraw) }

    it "returns false if currency doesn't set quick withdraw max" do
      expect(withdraw).to_not be_quick
    end

    it "returns false if exceeds quick withdraw amount" do
      allow(withdraw.currency_obj).to receive(:quick_withdraw_max).and_return(withdraw.sum-1)
      expect(withdraw).to_not be_quick
    end

    it "returns true" do
      allow(withdraw.currency_obj).to receive(:quick_withdraw_max).and_return(withdraw.sum+1)
      expect(withdraw).to be_quick
    end
  end

end

