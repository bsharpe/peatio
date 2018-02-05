# == Schema Information
#
# Table name: orders
#
#  id             :integer          not null, primary key
#  bid            :integer
#  ask            :integer
#  currency       :integer
#  price          :decimal(32, 16)
#  volume         :decimal(32, 16)
#  origin_volume  :decimal(32, 16)
#  state          :integer
#  done_at        :datetime
#  type           :string(8)
#  member_id      :integer
#  created_at     :datetime
#  updated_at     :datetime
#  sn             :string(255)
#  source         :string(255)      not null
#  ord_type       :string(10)
#  locked         :decimal(32, 16)
#  origin_locked  :decimal(32, 16)
#  funds_received :decimal(32, 16)  default(0.0)
#  trades_count   :integer          default(0)
#
# Indexes
#
#  index_orders_on_currency_and_state   (currency,state)
#  index_orders_on_member_id            (member_id)
#  index_orders_on_member_id_and_state  (member_id,state)
#  index_orders_on_state                (state)
#

class Order < ApplicationRecord
  include Wisper::ActiveRecord::Publisher
  include AASM

  ## -- ATTRIBUTES
  attr_accessor :total

  enumerize :bid, in: Currency.enumerize
  enumerize :ask, in: Currency.enumerize
  enumerize :currency, in: Market.enumerize, scope: true

  ORD_TYPES = %w(market limit).freeze
  enumerize :ord_type, in: ORD_TYPES, scope: true

  SOURCES = %w(Web APIv2 debug).freeze
  enumerize :source, in: SOURCES, scope: true

  ## -- VALIDATIONS
  before_validation :fix_number_precision, on: :create

  validates_presence_of :ord_type, :volume, :origin_volume, :locked, :origin_locked
  validates_numericality_of :origin_volume, :greater_than => 0

  validates_numericality_of :price, greater_than: 0, allow_nil: false, if: -> { ord_type == 'limit' }
  validate :market_order_validations, if: -> { ord_type == 'market' }

  enum state: {:waiting => 100, :done => 200, :canceled => 0}
  aasm column: :state, enum: true do
    state :waiting, initial: true
    state :done
    state :canceled

    event :done do
      transitions from: :waiting, to: :done
      after :unlock_funds
    end

    event :cancel do
      transitions from: :waiting, to: :canceled
    end
  end

  ## -- RELATIONSHIPS
  belongs_to :member, optional: true

  ## -- SCOPES
  scope :active, -> { where(state: :waiting) }
  scope :position, -> { group("price").pluck(:price, 'sum(volume)') }
  scope :best_price, ->(currency) { where(ord_type: 'limit').active.with_currency(currency).matching_rule.position }

  ## — INSTANCE METHODS
  def label
    "%d/$%s/%s" % [id, price.to_s('F'), volume.to_s('F')]
  end

  def funds_used
    origin_locked - locked
  end

  def fee
    config[kind.to_sym]["fee"]
  end

  def market
    @_market ||= Market.find(currency)
  end
  alias :config :market

  ## FIXME: Remove this
  def to_matching_attributes
    { id: id,
      market: market,
      type: type[-3, 3].downcase.to_sym,
      ord_type: ord_type,
      volume: volume,
      price: price,
      locked: locked,
      timestamp: created_at.to_i
    }
  end

  def strike(trade)
    puts "DEPRECATED".yellow
    asdf
  end

  def kind
    type.underscore[-3, 3]
  end

  def self.head(currency)
    active.with_currency(currency.downcase).matching_rule.first
  end

  def at
    created_at.to_i
  end

  def fix_number_precision
    self.price = config.fix_number_precision(:bid, price.to_d) if price

    if volume
      self.volume = config.fix_number_precision(:ask, volume.to_d)
      self.origin_volume = origin_volume.present? ? config.fix_number_precision(:ask, origin_volume.to_d) : volume
    end
  end

  private

  def unlock_funds
    Account::UnlockFunds.(account: self.hold_account, amount: self.locked, reason: Account::ORDER_CANCEL, reference: self)
  end

  def market_order_validations
    errors.add(:price, 'must not be present') if price.present?
  end

  FUSE = '0.9'.to_d
  def estimate_required_funds(price_levels)
    required_funds = Account::ZERO
    expected_volume = volume

    start_from, _ = price_levels.first
    filled_at     = start_from

    until expected_volume.zero? || price_levels.empty?
      level_price, level_volume = price_levels.shift
      filled_at = level_price

      v = [expected_volume, level_volume].min
      required_funds += yield level_price, v
      expected_volume -= v
    end

    raise OrderBookError::TooShallow, "Market is not deep enough" unless expected_volume.zero?
    raise OrderBookError::VolumeTooLarge, "Volume too large" if (filled_at-start_from).abs/start_from > FUSE

    required_funds
  end

end
