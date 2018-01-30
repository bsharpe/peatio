require 'rails_helper'

RSpec.describe Private::MarketsController, type: :controller do
  let(:member) { create :member }
  before { session[:member_id] = member.id }

  context "logged in user" do
    describe "GET /markets/btceur" do
      before { get :show, data }

      it { should respond_with :ok }
    end
  end

  context "non-login user" do
    before { session[:member_id] = nil }

    describe "GET /markets/btceur" do
      before { get :show, data }

      it { should respond_with :ok }
      it { expect(assigns(:member)).to be_nil }
    end
  end

  private

  def data
    {
      id: 'btceur',
      market: 'btceur',
      ask: 'btc',
      bid: 'eur'
    }
  end

end
