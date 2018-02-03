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

class Withdraw < ApplicationRecord
  include Wisper::ActiveRecord::Publisher

  STATES = [:submitting, :submitted, :rejected, :accepted, :suspect, :processing,
            :done, :canceled, :almost_done, :failed].freeze
  COMPLETED_STATES = [:done, :rejected, :canceled, :almost_done, :failed].freeze

  include AASM
  include HasCurrencies

  has_paper_trail on: [:update, :destroy]

  enumerize :aasm_state, in: STATES, scope: true

  belongs_to :member
  belongs_to :account
  has_many :account_versions, as: :modifiable
  has_one  :fund_source, as: :owner

  delegate :balance, to: :account, prefix: true
  delegate :key_text, to: :channel, prefix: true
  delegate :id, to: :channel, prefix: true
  delegate :name, to: :member, prefix: true
  delegate :coin?, :fiat?, to: :currency_obj

  before_validation :normalize
  after_create :generate_serial_number

  validates_with WithdrawBlacklistValidator

  validates :currency, presence: true

  validates :fee,    numericality: {greater_than_or_equal_to: 0}, presence: true
  validates :amount, numericality: {greater_than: 0}, presence: true

  validates :sum,  numericality: {greater_than: 0}, on: :create, presence: true
  validates :txid, uniqueness: true, allow_nil: true, on: :update

  validate :ensure_account_balance, on: :create

  scope :completed, -> { where( aasm_state: COMPLETED_STATES ) }
  scope :not_completed, -> { where.not( aasm_state: COMPLETED_STATES ) }

  alias_attribute :withdraw_id, :sn
  alias_attribute :full_name, :member_name

  aasm whiny_transitions: false, requires_lock: true do
    state :submitting,  initial: true
    state :submitted
    state :canceled
    state :accepted
    state :suspect
    state :rejected
    state :processing
    state :almost_done
    state :done
    state :failed

    event :submit do
      transitions from: :submitting, to: :submitted
      after [:lock_funds, :send_email]
    end

    event :cancel do
      transitions from: [:submitting, :submitted, :accepted], to: :canceled
      after [:after_cancel, :send_email]
    end

    event :mark_suspect do
      transitions from: :submitted, to: :suspect
      after :send_email
    end

    event :accept do
      transitions from: :submitted, to: :accepted
    end

    event :reject do
      transitions from: [:submitted, :accepted, :processing], to: :rejected
      after [:unlock_funds, :send_email]
    end

    event :process, after_commit: [:send_coins!, :send_email] do
      transitions from: :accepted, to: :processing
    end

    event :call_rpc do
      transitions from: :processing, to: :almost_done
    end

    event :succeed do
      transitions from: [:processing, :almost_done], to: :done

      before [:set_txid, :unlock_and_sub_funds]
      after  [:send_email, :send_sms]
    end

    event :fail do
      transitions from: :processing, to: :failed
      after :send_email
    end
  end

  ## — CLASS METHODS
  def self.channel
    WithdrawChannel.find_by_key(name.demodulize.underscore)
  end

  def self.resource_name
    name.demodulize.underscore.pluralize
  end

  ## — INSTANCE METHODS
  def channel
    self.class.channel
  end

  def channel_name
    channel.key
  end

  def cancelable?
    submitting? || submitted? || accepted?
  end

  def quick?
    sum <= currency_obj.quick_withdraw_max
  end

  def audit!
    with_lock do
      if account.verify
        accept
        process if quick?
      else
        mark_suspect
      end

      save!
    end
  end

  def fund_uid
    self.fund_source&.uid
  end

  def fund_extra
    self.fund_source&.extra
  end

  def generate_serial_number
    self.sn ||= begin
      id_part = sprintf('%06d', id)
      date_part = created_at.localtime.strftime('%y%m%d%H%M')
      sn = "#{date_part}#{id_part}"
      self.update_column(:sn, sn)
      sn
    end
  end

  # protected

  def after_cancel
    unlock_funds unless aasm.from_state == :submitting
  end

  def lock_funds
    Account::LockFunds.(account: account, amount: sum, reason: Account::WITHDRAW_LOCK, reference: self)
  end

  def unlock_funds
    Account::UnlockFunds.(account: account, amount: sum, reason: Account::WITHDRAW_UNLOCK, reference: self)
  end

  def unlock_and_sub_funds
    Account::UnlockAndSubtractFunds.(account: account, amount: sum, locked: sum, fee: fee, reason: Account::WITHDRAW, reference: self)
  end

  def set_txid
    self.txid = @sn unless coin?
  end

  def send_email
    broadcast(:send_email, self)
  end

  def send_sms
    return true unless member.sms_two_factor.activated?
    broadcast(:send_sms, self)
  end

  def send_coins!
    AMQPQueue.enqueue(:withdraw_coin, id: id) if coin?
  end

  def ensure_account_balance
    if sum.nil? || sum > account&.balance.to_f
      errors.add :base, -> { I18n.t('activerecord.errors.models.withdraw.account_balance_is_poor') }
    end
  end

  def fix_precision
    if sum && currency_obj&.precision
      self.sum = sum.round(currency_obj.precision, BigDecimal::ROUND_DOWN)
    end
  end

  def set_fee
    self.fee = self.sum / 500.0
  end

  def calc_fee
    self.sum ||= 0.0
    set_fee
    self.amount = self.sum - self.fee
  end

  def set_account
    self.account = member&.account(currency)
  end

  def normalize
    fix_precision
    calc_fee
    set_account
    true
  end


end
