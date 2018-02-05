# == Schema Information
#
# Table name: deposits
#
#  id                     :integer          not null, primary key
#  account_id             :integer
#  member_id              :integer
#  currency               :integer
#  amount                 :decimal(32, 16)
#  fee                    :decimal(32, 16)
#  fund_uid               :string(255)
#  fund_extra             :string(255)
#  txid                   :string(255)
#  state                  :integer
#  aasm_state             :string(255)
#  created_at             :datetime
#  updated_at             :datetime
#  done_at                :datetime
#  confirmations          :string(255)
#  type                   :string(255)
#  payment_transaction_id :integer
#  txout                  :integer
#
# Indexes
#
#  index_deposits_on_txid_and_txout  (txid,txout)
#

class Deposit < ApplicationRecord
  include Wisper::ActiveRecord::Publisher

  STATES = [:submitting, :canceled, :submitted, :rejected, :accepted, :checked, :warning].freeze

  include AASM
  include HasCurrencies

  has_paper_trail on: [:update, :destroy]

  enumerize :aasm_state, in: STATES, scope: true

  alias_attribute :sn, :id

  delegate :name, to: :member, prefix: true
  delegate :id, to: :channel, prefix: true
  delegate :coin?, :fiat?, to: :currency_obj

  belongs_to :member
  belongs_to :account
  has_one :fund_source, as: :owner

  validates_presence_of :amount, :account, :member, :currency
  validates_numericality_of :amount, greater_than: 0

  scope :recent, -> { order(created_at: :desc) }

  aasm :whiny_transitions => false, requires_lock: true do
    state :submitting, initial: true, before_enter: :set_fee # FIXME: This happens *before* db load
    state :canceled
    state :submitted
    state :rejected
    state :accepted
    state :checked
    state :warning

    event :submit do
      transitions from: :submitting, to: :submitted
    end

    event :cancel do
      transitions from: :submitting, to: :canceled
    end

    event :reject do
      transitions from: :submitted, to: :rejected
    end

    event :accept do
      transitions from: :submitted, to: :accepted
      after :do
    end

    event :check do
      transitions from: :accepted, to: :checked
    end

    event :warn do
      transitions from: :accepted, to: :warning
    end
  end

  def txid_desc
    txid
  end

  class << self
    def channel
      DepositChannel.find_by_key(name.demodulize.underscore)
    end

    def resource_name
      name.demodulize.underscore.pluralize
    end

    def params_name
      name.underscore.gsub('/', '_')
    end

    def new_path
      "new_#{params_name}_path"
    end
  end

  def channel
    self.class.channel
  end

  # def update_confirmations(data)
  #   update_column(:confirmations, data)
  # end

  def txid_text
    txid && txid.truncate(40)
  end

  private

  def do
    Account::AddFunds.(account: account, amount: amount, reason: Account::DEPOSIT, reference: self)
  end

  def set_fee
    self.amount = calc_fee.first
    self.fee = calc_fee.last
  end

  def calc_fee
    [amount || 0, 0]
  end
end
