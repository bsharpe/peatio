require 'rails_helper'

RSpec.describe Admin::MembersController, type: :controller do
  let(:member) { create(:admin_member) }
  before { session[:member_id] = member.id }

end
