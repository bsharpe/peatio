require 'rails_helper'

RSpec.describe Private::SettingsController, type: :controller do
  let(:member) { create :member }
  before { session[:member_id] = member.id }

  describe 'GET /index' do
    before { get :index }

    it { should respond_with :ok }
    it { should render_template(:index) }
  end
end
