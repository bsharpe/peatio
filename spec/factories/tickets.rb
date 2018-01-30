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

# Read about factories at https://github.com/thoughtbot/factory_Bot

FactoryBot.define do
  factory :ticket do
    author
    sequence(:title)   { |c| "Title #{c}" }
    sequence(:content) { |n| "Content #{n}" }
  end
end
