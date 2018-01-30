# == Schema Information
#
# Table name: fund_sources
#
#  id         :integer          not null, primary key
#  owner_id   :integer
#  currency   :integer
#  extra      :string(255)
#  uid        :string(255)
#  is_locked  :boolean          default(FALSE)
#  created_at :datetime
#  updated_at :datetime
#  deleted_at :datetime
#  owner_type :string(255)
#
# Indexes
#
#  index_fund_sources_on_owner_type_and_owner_id  (owner_type,owner_id) UNIQUE
#

class FundSource < ApplicationRecord
  include HasCurrencies

  attr_accessor :name

  paranoid

  belongs_to :owner, polymorphic: true, optional: true

  before_validation :normalize
  validates_presence_of :uid, :extra

  def label
    if currency_obj.try :coin?
      "#{uid} (#{extra})"
    else
      [I18n.t("banks.#{extra}"), "****#{uid[-4..-1]}"].join('#')
    end
  end

  def as_json(options = {})
    super(options).merge({label: label})
  end

  def normalize
    self.uid = self.uid&.squish
  end
end
