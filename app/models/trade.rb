# == Schema Information
#
# Table name: trades
#
#  id            :integer          not null, primary key
#  price         :decimal(32, 16)
#  volume        :decimal(32, 16)
#  ask_id        :integer
#  bid_id        :integer
#  trend         :integer
#  currency      :integer
#  created_at    :datetime
#  updated_at    :datetime
#  ask_member_id :integer
#  bid_member_id :integer
#  funds         :decimal(32, 16)
#
# Indexes
#
#  index_trades_on_ask_id         (ask_id)
#  index_trades_on_ask_member_id  (ask_member_id)
#  index_trades_on_bid_id         (bid_id)
#  index_trades_on_bid_member_id  (bid_member_id)
#  index_trades_on_created_at     (created_at)
#  index_trades_on_currency       (currency)
#

class Trade < ApplicationRecord
  extend ActiveHash::Associations::ActiveRecordExtensions

  enumerize :trend, in: {:up => 1, :down => 0}
  enumerize :currency, in: Market.enumerize, scope: true

  belongs_to :market, class_name: Market.name, foreign_key: :currency
  belongs_to :ask, class_name: OrderAsk.name, foreign_key: :ask_id
  belongs_to :bid, class_name: OrderBid.name, foreign_key: :bid_id

  belongs_to :ask_member, class_name: Member.name, foreign_key: :ask_member_id
  belongs_to :bid_member, class_name: Member.name, foreign_key: :bid_member_id

  before_validation :setup_ids

  validates_presence_of :price, :volume, :funds

  scope :h24, -> { where("created_at > ?", 24.hours.ago) }

  attr_accessor :side

  alias_method :sn, :id

  class << self
    def latest_price(currency)
      with_currency(currency).order(id: :desc).first.try(:price) || ZERO
    end

    def filter(market, timestamp, from, to, limit, order)
      trades = with_currency(market).order(order)
      trades = trades.limit(limit) if limit.present?
      trades = trades.where('created_at <= ?', timestamp) if timestamp.present?
      trades = trades.where('id > ?', from) if from.present?
      trades = trades.where('id < ?', to) if to.present?
      trades
    end

    def for_member(currency, member, options={})
      trades = filter(currency, options[:time_to], options[:from], options[:to], options[:limit], options[:order]).where("ask_member_id = ? or bid_member_id = ?", member.id, member.id)
      trades.each do |trade|
        trade.side = trade.ask_member_id == member.id ? 'ask' : 'bid'
      end
    end
  end

  def trigger_notify
    # ask.member.notify 'trade', for_notify('ask')
    # bid.member.notify 'trade', for_notify('bid')
  end

  def check_trade?
    return :ask_price_too_high   if ask.ord_type == 'limit' && ask.price > self.price
    return :bid_price_too_low    if bid.ord_type == 'limit' && bid.price < self.price
    return :mismatched_currency  if ask.currency != bid.currency
    return :volume_too_low       if !(self.funds > ZERO && [ask.volume, bid.volume].min >= self.volume)
  end

  # def for_notify(kind=nil)
  #   {
  #     id:     id,
  #     kind:   kind || side,
  #     at:     created_at.to_i,
  #     price:  price.to_s  || ZERO,
  #     volume: volume.to_s || ZERO,
  #     market: currency
  #   }
  # end
  #
  # def for_global
  #   {
  #     tid:    id,
  #     type:   trend == 'down' ? 'sell' : 'buy',
  #     date:   created_at.to_i,
  #     price:  price.to_s || ZERO,
  #     amount: volume.to_s || ZERO
  #   }
  # end

  def setup_ids
    self.ask_member_id ||= self.ask.member_id
    self.bid_member_id ||= self.bid.member_id
  end
end
