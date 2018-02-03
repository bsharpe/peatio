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

class OrderBid < Order

  has_many :trades, foreign_key: :bid_id

  scope :matching_rule, -> { order('price DESC, created_at ASC') }

  def subtract_funds(trade)
    trade.funds
  end

  def add_funds(trade)
    trade.volume
  end

  def hold_account
    member.account(bid)
  end

  def expect_account
    member.account(ask)
  end

  def avg_price
    return ZERO if funds_received.zero?
    config.fix_number_precision(:bid, funds_used / funds_received)
  end

  LOCKING_BUFFER_FACTOR = '1.1'.to_d
  def compute_locked
    case ord_type
    when 'limit'
      price * volume
    when 'market'
      funds = estimate_required_funds(Global[currency].asks) {|k, v| k * v }
      funds * LOCKING_BUFFER_FACTOR
    else
      raise ArgumentError, "Unknown Order Type[#{ord_type}]"
    end
  end

end
