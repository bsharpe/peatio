require 'rails_helper'

RSpec.describe APIv2::Orders, type: :api do

  let(:member) { create(:member) }
  let(:token)  { create(:api_token, member: member) }

  describe "GET /api/v2/orders" do
    before do
      create(:order_bid, currency: 'btceur', price: '11'.to_d, volume: '123.123456789', member: member)
      create(:order_bid, currency: 'btceur', price: '12'.to_d, volume: '123.123456789', member: member, state: Order::STATE_CANCELED)
      create(:order_ask, currency: 'btceur', price: '13'.to_d, volume: '123.123456789', member: member)
      create(:order_ask, currency: 'btceur', price: '14'.to_d, volume: '123.123456789', member: member, state: Order::STATE_DONE)
    end

    it "should require authentication" do
      get "/api/v2/orders", market: 'btceur'
      expect(response.code).to eq '401'
    end

    it "should validate market param" do
      signed_get '/api/v2/orders', params: {market: 'mtgox'}, token: token
      expect(response.code).to eq '400'
      expect(json_data).to eq ({"error" => {"code" => 1001,"message" => "market does not have a valid value"}})
    end

    it "should validate state param" do
      signed_get '/api/v2/orders', params: {market: 'btceur', state: 'test'}, token: token
      expect(response.code).to eq '400'
      expect(json_data).to eq ({"error" => {"code" => 1001,"message" => "state does not have a valid value"}})
    end

    it "should return active orders by default" do
      signed_get '/api/v2/orders', params: {market: 'btceur'}, token: token
      assert_successful
      expect(json_data.size).to eq 2
    end

    it "should return complete orders" do
      signed_get '/api/v2/orders', params: {market: 'btceur', state: Order::STATE_DONE}, token: token
      assert_successful
      expect(json_data.first['state']).to eq Order::STATE_DONE
    end

    it "should return paginated orders" do
      signed_get '/api/v2/orders', params: {market: 'btceur', limit: 1, page: 1}, token: token
      assert_successful
      expect(json_data.first['price']).to eq '11.0'
      reset_json_object

      signed_get '/api/v2/orders', params: {market: 'btceur', limit: 1, page: 2}, token: token
      assert_successful
      expect(json_data.first['price']).to eq '13.0'
    end

    it "should sort orders" do
      signed_get '/api/v2/orders', params: {market: 'btceur', order_by: 'asc'}, token: token
      assert_successful
      expect(json_data[0]['id']).to be < json_data[1]['id']
      reset_json_object

      signed_get '/api/v2/orders', params: {market: 'btceur', order_by: 'desc'}, token: token
      assert_successful
      expect(json_data[0]['id']).to be > json_data[1]['id']
    end

  end

  describe "GET /api/v2/order" do
    let(:order)  { create(:order_bid, currency: 'btceur', price: '12.326'.to_d, volume: '3.14', origin_volume: '12.13', member: member, trades_count: 1) }
    let!(:trade) { create(:trade, bid: order) }

    it "should get specified order" do
      signed_get "/api/v2/order", params: {id: order.id}, token: token
      assert_successful

      result = json_data
      expect(result['id']).to eq order.id
      expect(result['executed_volume']).to eq '8.99'
    end

    it "should include related trades" do
      signed_get "/api/v2/order", params: {id: order.id}, token: token

      expect(json_data['trades_count']).to eq 1
      expect(json_data['trades']).to have(1).trade
      expect(json_data['trades'].first['id']).to eq trade.id
      expect(json_data['trades'].first['side']).to eq 'buy'
    end

    it "should get 404 error when order doesn't exist" do
      signed_get "/api/v2/order", params: {id: 99999}, token: token
      expect(response.code).to eq '404'
    end
  end

  describe "POST /api/v2/orders/multi" do
    before do
      member.account(:btc).update_attributes(balance: 100)
      member.account(:eur).update_attributes(balance: 100000)
    end

    it "should create a sell order and a buy order" do
      params = {
        market: 'btceur',
        orders: [
          {side: 'sell', volume: '12.13', price: '2014'},
          {side: 'buy',  volume: '17.31', price: '2005'}
        ]
      }

      expect {
        signed_post '/api/v2/orders/multi', token: token, params: params
        assert_successful

        expect(json_data).to have(2).orders
        expect(json_data.first['side']).to eq 'sell'
        expect(json_data.first['volume']).to eq '12.13'
        expect(json_data.last['side']).to eq 'buy'
        expect(json_data.last['volume']).to eq '17.31'
      }.to change(Order, :count).by(2)
    end

    it "should create nothing on error" do
      params = {
        market: 'btceur',
        orders: [
          {side: 'sell', volume: '12.13', price: '2014'},
          {side: 'buy',  volume: '17.31', price: 'test'} # <- invalid price
        ]
      }

      expect {
        expect(AMQPQueue).to receive(:enqueue).exactly(0).times

        signed_post '/api/v2/orders/multi', token: token, params: params
        expect(response.code).to eq '400'
        expect(response.body).to eq '{"error":{"code":2002,"message":"Failed to create order. Reason: Validation failed: Price must be greater than 0"}}'
      }.not_to change(Order, :count)
    end
  end

  describe "POST /api/v2/orders" do
    it "should create a sell order" do
      member.account(:btc).update_attributes(balance: 100)

      expect {
        signed_post '/api/v2/orders', token: token, params: {market: 'btceur', side: 'sell', volume: '12.13', price: '2014'}
        assert_successful
        expect(json_data['id']).to eq OrderAsk.last.id
      }.to change(OrderAsk, :count).by(1)
    end

    it "should create a buy order" do
      member.account(:eur).update_attributes(balance: 100000)

      expect {
        signed_post '/api/v2/orders', token: token, params: {market: 'btceur', side: 'buy', volume: '12.13', price: '2014'}
        assert_successful
        expect(json_data['id']).to eq OrderBid.last.id
      }.to change(OrderBid, :count).by(1)
    end

    it "should set order source to APIv2" do
      member.account(:eur).update_attributes(balance: 100000)
      signed_post '/api/v2/orders', token: token, params: {market: 'btceur', side: 'buy', volume: '12.13', price: '2014'}
      expect(OrderBid.last.source).to eq 'APIv2'
    end

    it "should return cannot lock funds error" do
      expect {
        signed_post '/api/v2/orders', params: {market: 'btceur', side: 'sell', volume: '12.13', price: '2014'}
        expect(response.code).to eq '400'
        expect(response.body).to eq '{"error":{"code":2002,"message":"Failed to create order. Reason: cannot lock funds (amount: 12.13)"}}'
      }.not_to change(OrderAsk, :count)
    end

    it "should give a number as volume parameter" do
      signed_post '/api/v2/orders', params: {market: 'btceur', side: 'sell', volume: 'test', price: '2014'}
      expect(response.code).to eq '400'
      expect(response.body).to eq '{"error":{"code":2002,"message":"Failed to create order. Reason: Validation failed: Volume must be greater than 0"}}'
    end

    it "should give a number as price parameter" do
      signed_post '/api/v2/orders', params: {market: 'btceur', side: 'sell', volume: '12.13', price: 'test'}
      expect(response.code).to eq '400'
      expect(response.body).to eq '{"error":{"code":2002,"message":"Failed to create order. Reason: Validation failed: Price must be greater than 0"}}'
    end
  end

  describe "POST /api/v2/order/delete" do
    let!(:order)  { create(:order_bid, currency: 'btceur', price: '12.326'.to_d, volume: '3.14', origin_volume: '12.13', locked: '20.1082', origin_locked: '38.0882', member: member) }

    context "succesful" do
      before do
        member.account(:eur).update_attributes(locked: order.price*order.volume)
      end

      it "should cancel specified order" do
        expect(AMQPQueue).to receive(:enqueue).with(:matching, action: 'cancel', order: order.to_matching_attributes)
        expect {
          signed_post "/api/v2/order/delete", params: {id: order.id}, token: token
          assert_successful
          expect(json_data['id']).to eq order.id
        }.not_to change(Order, :count)
      end
    end

    context "failed" do
      it "should return order not found error" do
        signed_post "/api/v2/order/delete", params: {id: '0'}, token: token
        expect(response.code).to eq '400'
        expect(json_data['error']['code']).to eq 2003
      end
    end

  end

  describe "POST /api/v2/orders/clear" do

    before do
      create(:order_ask, currency: 'btceur', price: '12.326', volume: '3.14', origin_volume: '12.13', member: member)
      create(:order_bid, currency: 'btceur', price: '12.326', volume: '3.14', origin_volume: '12.13', member: member)

      member.account(:btc).update_attributes(locked: '5')
      member.account(:eur).update_attributes(locked: '50')
    end

    it "should cancel all my orders" do
      member.orders.each do |o|
        expect(AMQPQueue).to receive(:enqueue).with(:matching, action: 'cancel', order: o.to_matching_attributes)
      end

      expect {
        signed_post "/api/v2/orders/clear", token: token
        assert_successful

        expect(json_data).to have(2).orders
      }.not_to change(Order, :count)
    end

    it "should cancel all my asks" do
      member.orders.where(type: 'OrderAsk').each do |o|
        expect(AMQPQueue).to receive(:enqueue).with(:matching, action: 'cancel', order: o.to_matching_attributes)
      end

      expect {
        signed_post "/api/v2/orders/clear", token: token, params: {side: 'sell'}
        assert_successful

        expect(json_data).to have(1).orders
        expect(json_data.first['id']).to eq member.orders.where(type: 'OrderAsk').first.id
      }.not_to change(Order, :count)
    end

  end
end
