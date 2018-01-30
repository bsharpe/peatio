# == Schema Information
#
# Table name: api_tokens
#
#  id                    :integer          not null, primary key
#  member_id             :integer          not null
#  access_key            :string(50)       not null
#  secret_key            :string(50)       not null
#  created_at            :datetime
#  updated_at            :datetime
#  trusted_ip_list       :string(255)
#  label                 :string(255)
#  oauth_access_token_id :integer
#  expire_at             :datetime
#  scopes                :string(255)
#  deleted_at            :datetime
#
# Indexes
#
#  index_api_tokens_on_access_key  (access_key) UNIQUE
#  index_api_tokens_on_secret_key  (secret_key) UNIQUE
#

class APIToken < ApplicationRecord
  paranoid
  has_secure_token :access_key
  has_secure_token :secret_key

  ## -- ATTRIBUTES
  serialize :trusted_ip_list

  ## -- RELATIONSHIPS
  belongs_to :member
  belongs_to :oauth_access_token, class_name: Doorkeeper::AccessToken.name, dependent: :destroy, optional: true

  ## -- SCOPES
  scope :user_requested,  -> { where(oauth_access_token_id: nil) }
  scope :oauth_requested, -> { where.not(oauth_access_token_id: nil) }

  ## — CLASS METHODS
  def self.from_oauth_token(token)
    return nil unless token&.token&.present?
    access_key, secret_key = token.token.split(':')
    self.find_by_access_key(access_key)
  end

  ## — INSTANCE METHODS
  def to_oauth_token
    [access_key, secret_key].join(':')
  end

  def expired?
    expire_at.to_f < Time.current.to_f
  end

  def in_scopes?(ary)
    return true if ary.blank?
    return true if self[:scopes] == 'all'
    (ary & scopes).present?
  end

  def allow_ip?(ip)
    trusted_ip_list.blank? || trusted_ip_list.include?(ip)
  end

  def ip_whitelist=(list)
    self.trusted_ip_list = list.split(/,\s*/)
  end

  def ip_whitelist
    trusted_ip_list.try(:join, ',')
  end

  def scopes
    self[:scopes] ? self[:scopes].split(/\s+/) : []
  end

end
