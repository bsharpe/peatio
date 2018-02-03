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
# Indexes
#
#  index_comments_on_created_at  (created_at)
#

# Read about factories at https://github.com/thoughtbot/factory_Bot

FactoryBot.define do
  factory :comment do
    sequence(:content) { |n| "Content #{n}" }
    ticket
    author
  end

end
