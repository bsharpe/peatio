# == Schema Information
#
# Table name: comments
#
#  id         :integer          not null, primary key
#  content    :text(65535)
#  author_id  :integer
#  ticket_id  :integer
#  created_at :datetime
#  updated_at :datetime
#

class Comment < ApplicationRecord
  include Wisper::ActiveRecord::Publisher

  acts_as_readable on: :created_at

  belongs_to :ticket
  belongs_to :author, class_name: Member.name, foreign_key: :author_id

  validates :content, presence: true
end
