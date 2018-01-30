require 'rails_helper'

RSpec.describe Private::FundsController, type: :controller do

  context "Verified user with two factor" do
    let(:member) { create(:member, :activated, :verified, :app_two_factor_activated) }
    before { session[:member_id] = member.id }

    before do
      get :index
    end

    it { expect(response).not_to redirect_to(settings_path) }
    it { expect(member.two_factors).to be_activated }
  end

  context "Verified user without two factor auth" do
    let(:member) { create(:member, :activated, :verified) }
    before { session[:member_id] = member.id }

    before do
      get :index
    end

    it { expect(member.two_factors).not_to be_activated }
    it { expect(response).to redirect_to(settings_path) }
  end

end
