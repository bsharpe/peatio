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

class Account < ApplicationRecord
  include Wisper::ActiveRecord::Publisher

  include HasCurrencies

  FIX = :fix
  UNKNOWN = :unknown
  STRIKE_ADD = :strike_add
  STRIKE_SUB = :strike_sub
  STRIKE_FEE = :strike_fee
  STRIKE_UNLOCK = :strike_unlock
  ORDER_CANCEL = :order_cancel
  ORDER_SUBMIT = :order_submit
  ORDER_FULLFILLED = :order_fullfilled
  WITHDRAW_LOCK = :withdraw_lock
  WITHDRAW_UNLOCK = :withdraw_unlock
  DEPOSIT = :deposit
  WITHDRAW = :withdraw
  ZERO = 0.to_d

  OPS = {:unlock_funds => 1, :lock_funds => 2, :plus_funds => 3, :sub_funds => 4, :unlock_and_subtract_funds => 5}

  belongs_to :member, optional: true
  has_many :payment_addresses
  has_many :partial_trees
  has_many :versions, class_name: AccountVersion.name

  # Suppose to use has_one here, but I want to store
  # relationship at account side. (Daniel)
  belongs_to :default_withdraw_fund_source, class_name: FundSource.name, optional: true

  validates_numericality_of :balance, :locked, greater_than_or_equal_to: ZERO

  scope :enabled, -> { where("currency in (?)", Currency.ids) }
  scope :locked_sum,  -> (currency) { with_currency(currency).sum(:locked) }
  scope :balance_sum, -> (currency) { with_currency(currency).sum(:balance) }

  def payment_address
    self.payment_addresses.last || self.payment_addresses.create(currency: self.currency)
  end

  def amount
    self.balance + self.locked
  end

  def verify
    self.versions.sum('balance + locked') == self.amount
  end

  def as_json(options = {})
    super(options).merge({
      # check if there is a useable address, but don't touch it to create the address now.
      "deposit_address" => payment_addresses.empty? ? "" : payment_address.deposit_address,
      "name_text" => currency_obj.name_text,
      "default_withdraw_fund_source_id" => default_withdraw_fund_source_id
    })
  end

end
