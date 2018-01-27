# == Schema Information
#
# Table name: documents
#
#  id         :integer          not null, primary key
#  key        :string(255)
#  title      :string(255)
#  body       :text(65535)
#  is_auth    :boolean
#  created_at :datetime
#  updated_at :datetime
#  desc       :text(65535)
#  keywords   :text(65535)
#

# Read about factories at https://github.com/thoughtbot/factory_Bot

FactoryBot.define do
  factory :document do
  end
end
