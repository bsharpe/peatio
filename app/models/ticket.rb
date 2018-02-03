# == Schema Information
#
# Table name: tickets
#
#  id         :integer          not null, primary key
#  title      :string(255)
#  content    :text(65535)
#  aasm_state :string(255)
#  author_id  :integer
#  created_at :datetime
#  updated_at :datetime
#
# Indexes
#
#  index_tickets_on_created_at  (created_at)
#

class Ticket < ApplicationRecord
  include AASM
  acts_as_readable on: :created_at

  after_commit :send_notification, on: [:create]

  validates_with TicketValidator

  has_many :comments
  belongs_to :author, class_name: Member.name, foreign_key: :author_id

  scope :open, -> { where(aasm_state: :open) }
  scope :close, -> { where(aasm_state: :closed) }

  aasm whiny_transitions: false, requires_lock: true do
    state :open
    state :closed

    event :close do
      transitions from: :open, to: :closed
    end

    event :reopen do
      transitions from: :closed, to: :open
    end
  end

  def title_for_display(n = 60)
    title.blank? ? content.truncate(n) : title.truncate(n)
  end

  private

  def send_notification
    TicketMailer.author_notification(self).deliver
    TicketMailer.admin_notification(self).deliver
  end

end
