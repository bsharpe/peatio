# == Schema Information
#
# Table name: partial_trees
#
#  id         :integer          not null, primary key
#  proof_id   :integer          not null
#  account_id :integer          not null
#  json       :text(65535)      not null
#  created_at :datetime
#  updated_at :datetime
#  sum        :string(255)
#

# Read about factories at https://github.com/thoughtbot/factory_Bot

FactoryBot.define do
  factory :partial_tree do
    json "MyText"
    proof_id 1
    account
  end
end
