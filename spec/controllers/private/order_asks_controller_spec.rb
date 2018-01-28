require 'spec_helper'

describe Private::OrderAsksController do

  let(:member) do
    create(:member).tap {|m|
      m.get_account('btc').update_attributes(balance: '20')
    }
  end

  let(:market) { Market.find('btceur') }
  let(:params) do
    { market_id: market.id,
      market:    market.id,
      ask:       market.base_unit,
      bid:       market.quote_unit,
      order_ask: { ord_type: 'limit', origin_volume: '12.13', price: '2014.47' }
    }
  end

  context 'POST :create' do
    it "should create a sell order" do
      expect {
        post :create, params, {member_id: member.id}
        assert_successful
        expect(response.body).to eq '{"result":true,"message":"Success"}'
      }.to change(OrderAsk, :count).by(1)
    end

    it "should set order source to Web" do
      post :create, params, {member_id: member.id}
      expect(assigns(:order).source).to eq 'Web'
    end
  end

  context 'POST :clear' do
    it "should cancel all my asks in current market" do
      o1 = create(:order_ask, member: member, currency: market)
      o2 = create(:order_ask, member: member, currency: Market.find(:ptsbtc))
      member.should have(2).orders

      post :clear, {market_id: market.id}, {member_id: member.id}
      assert_successful
      expect(assigns(:orders).size).to eq 1
      expect(assigns(:orders).first).to eq o1
    end
  end

end
