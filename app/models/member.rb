# == Schema Information
#
# Table name: members
#
#  id           :integer          not null, primary key
#  uid          :string(255)
#  display_name :string(255)
#  email        :string(255)
#  identity_id  :integer
#  created_at   :datetime
#  updated_at   :datetime
#  state        :integer
#  activated    :boolean
#  country_code :integer
#  phone_number :string(255)
#  disabled     :boolean          default(FALSE)
#  api_disabled :boolean          default(FALSE)
#  nickname     :string(255)
#

class Member < ApplicationRecord
  include Wisper::ActiveRecord::Publisher

  has_secure_token :uid
  acts_as_reader

  has_many :orders
  has_many :accounts
  has_many :payment_addresses, through: :accounts
  has_many :trades
  has_many :withdraws
  has_many :fund_sources, as: :owner
  has_many :deposits
  has_many :api_tokens
  has_many :two_factors
  has_many :tickets, foreign_key: :author_id
  has_many :comments, foreign_key: :author_id
  has_many :signup_histories
  has_many :token_activations, class_name: Token::Activation.name

  has_one :id_document, dependent: :destroy

  has_many :authentications, dependent: :destroy

  scope :enabled, -> { where(disabled: false) }

  delegate :activated?, to: :two_factors, prefix: true, allow_nil: true
  delegate :name,       to: :id_document, allow_nil: true
  delegate :full_name,  to: :id_document, allow_nil: true
  delegate :verified?,  to: :id_document, prefix: true, allow_nil: true

  before_validation :sanitize

  validates :display_name, uniqueness: true, allow_blank: true
  validates :email, email: true, uniqueness: true, allow_nil: true

  class << self
    def from_auth(auth_hash)
      locate_auth(auth_hash) || locate_email(auth_hash) || create_from_auth(auth_hash)
    end

    # FIXME: This is sooo bad. Do NOT do this.
    def current
      Thread.current[:user]
    end

    def current=(user)
      Thread.current[:user] = user
    end

    # FIXME: Switch to a real role-management system, like Rolify
    def admins
      Figaro.env.admin.split(',')
    end

    def search(field: nil, term: nil)
      result =
        case field
        when 'email'
          self.where('members.email LIKE ?', "%#{term.downcase.squish}%")
        when 'phone_number'
          self.where('members.phone_number LIKE ?', "%#{term}%")
        when 'name'
          self.joins(:id_document).where('id_documents.name LIKE ?', "%#{term}%")
        when 'wallet_address'
          members = self.joins(:fund_sources).where(fund_sources: { uid: term } )
          if members.empty?
            members = self.joins(:payment_addresses).where(payment_addresses: { address: term } )
          end
          members
        else
          self.all
        end

      result.order(id: :desc)
    end

    private

    def locate_auth(auth_hash)
      Authentication.locate(auth_hash)&.member
    end

    def locate_email(auth_hash)
      auth_email = auth_hash['info']['email']&.downcase&.squish
      return nil if auth_email.blank?
      member = self.find_by_email(auth_email)
      return nil unless member
      member.add_auth(auth_hash)
      member
    end

    def create_from_auth(auth_hash)
      member = Member.new(
        nickname: auth_hash['info']['nickname'],
        activated: false)
      member.add_auth(auth_hash)
      member.save!
      member.update(email: auth_hash['info']['email'])
      member
    end
  end


  def create_auth_for_identity(identity)
    self.authentications.create(provider: :identity, uid: identity.id)
  end

  def trades
    Trade.where('bid_member_id = :id OR ask_member_id = :id', id: id)
  end

  def active!
    update activated: true
  end

  def update_password(password)
    identity.update password: password, password_confirmation: password
    send_password_changed_notification
  end

  def admin?
    @is_admin ||= self.class.admins.include?(self.email)
  end

  def add_auth(auth_hash)
    auth = Authentication.build_auth(auth_hash)
    auth.member = self
    auth.save!
  end

  def trigger(event, data)
    AMQPQueue.enqueue(:pusher_member, {member_id: id, event: event, data: data})
  end

  def notify(event, data)
    ::Pusher["private-#{uid}"].trigger_async event, data
  end

  def to_s
    result = "#{name}"
    result << " <#{email}>" if email
    "#{result} - #{uid}"
  end

  def gravatar
    "//gravatar.com/avatar/#{Digest::MD5.hexdigest(email)}?d=retro"
  end

  def get_account(currency)
    raise RuntimeError, "Unknown Currency(#{currency})" unless Currency.find_by_code(currency)
    self.accounts.with_currency(currency.to_sym).first_or_create
  end

  def identity
    authentication = authentications.for_provider(:identity).first
    authentication ? Identity.find(authentication.uid) : nil
  end

  def auth(name)
    authentications.for_provider(name).first
  end

  def auth_with?(name)
    authentications.for_provider(name).exists?
  end

  def remove_auth(name)
    identity.destroy if name == 'identity'
    auth(name).destroy
  end

  def send_password_changed_notification
    MemberMailer.reset_password_done(self.id).deliver

    if sms_two_factor.activated?
      sms_message = I18n.t('sms.password_changed', email: self.email)
      AMQPQueue.enqueue(:sms_notification, phone: phone_number, message: sms_message)
    end
  end

  def unread_comments
    ticket_ids = self.tickets.open.collect(&:id)
    if ticket_ids.any?
      Comment.where(ticket_id: [ticket_ids].flatten).where.not(author_id: self.id).unread_by(self).to_a
    else
      []
    end
  end

  def app_two_factor
    two_factors.by_type(:app)
  end

  def sms_two_factor
    two_factors.by_type(:sms)
  end

  def as_json(options = {})
    super(options).merge({
      "name" => self.name,
      "app_activated" => self.app_two_factor.activated?,
      "sms_activated" => self.sms_two_factor.activated?,
      "memo" => self.id
    })
  end

  private

  def sanitize
    self.email = self.email&.downcase&.squish
  end

end
