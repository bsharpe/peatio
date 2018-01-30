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

require 'rails_helper'

RSpec.describe FundSource do

  context '#label' do
    context 'for btc' do
      let(:fund_source) { build(:btc_fund_source) }
      subject { fund_source }

      its(:label) { should eq("#{fund_source.uid} (bitcoin)") }
    end

    context 'bank' do
      let(:fund_source) { build(:eur_fund_source) }
      subject { fund_source }

      its(:label) { should eq('Bank of China#****1234') }
    end
  end

end
