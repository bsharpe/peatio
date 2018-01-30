# == Schema Information
#
# Table name: documents
#
#  id         :integer          not null, primary key
#  key        :string(255)
#  is_auth    :boolean
#  created_at :datetime
#  updated_at :datetime
#

# Read about factories at https://github.com/thoughtbot/factory_Bot

FactoryBot.define do
  factory :document do
  end
end
