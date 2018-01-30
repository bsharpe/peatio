require 'rails_helper'

RSpec.describe APIv2::Entities::Member do

  let(:member) { create(:verified_member) }

  subject { OpenStruct.new(APIv2::Entities::Member.represent(member).serializable_hash) }

  before { allow(Currency).to receive(:codes).and_return(%w(eur btc)) }

  its(:sn)        { should == member.sn }
  its(:name)      { should == member.name }
  its(:email)     { should == member.email }
  its(:activated) { should == true }
  its(:accounts)  { is_expected.to match [{:currency=>"eur", :balance=>"0.0", :locked=>"0.0"}, {:currency=>"btc", :balance=>"0.0", :locked=>"0.0"}] }

end
