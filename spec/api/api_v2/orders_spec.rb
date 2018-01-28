require 'spec_helper'

describe APIv2::Orders, type: :controller do

  let(:member) { create(:member) }
  let(:token)  { create(:api_token, member: member) }

  describe "GET /api/v2/orders" do
    before do
      create(:order_bid, currency: 'btceur', price: '11'.to_d, volume: '123.123456789', member: member)
      create(:order_bid, currency: 'btceur', price: '12'.to_d, volume: '123.123456789', member: member, state: Order::CANCEL)
      create(:order_ask, currency: 'btceur', price: '13'.to_d, volume: '123.123456789', member: member)
      create(:order_ask, currency: 'btceur', price: '14'.to_d, volume: '123.123456789', member: member, state: Order::DONE)
    end

    it "should require authentication" do
      get "/api/v2/orders", market: 'btceur'
      expect(response.code).to eq '401'
    end

    it "should validate market param" do
      signed_get '/api/v2/orders', params: {market: 'mtgox'}, token: token
      expect(response.code).to eq '400'
      expect(JSON.parse(response.body)).to eq ({"error" => {"code" => 1001,"message" => "market does not have a valid value"}})
    end

    it "should validate state param" do
      signed_get '/api/v2/orders', params: {market: 'btceur', state: 'test'}, token: token
      expect(response.code).to eq '400'
      expect(JSON.parse(response.body)).to eq ({"error" => {"code" => 1001,"message" => "state does not have a valid value"}})
    end

    it "should return active orders by default" do
      signed_get '/api/v2/orders', params: {market: 'btceur'}, token: token
      response.should be_success
      expect(JSON.parse(response.body).size).to eq 2
    end

    it "should return complete orders" do
      signed_get '/api/v2/orders', params: {market: 'btceur', state: Order::DONE}, token: token
      response.should be_success
      expect(JSON.parse(response.body).first['state']).to eq Order::DONE
    end

    it "should return paginated orders" do
      signed_get '/api/v2/orders', params: {market: 'btceur', limit: 1, page: 1}, token: token
      response.should be_success
      expect(JSON.parse(response.body).first['price']).to eq '11.0'

      signed_get '/api/v2/orders', params: {market: 'btceur', limit: 1, page: 2}, token: token
      response.should be_success
      expect(JSON.parse(response.body).first['price']).to eq '13.0'
    end

    it "should sort orders" do
      signed_get '/api/v2/orders', params: {market: 'btceur', order_by: 'asc'}, token: token
      response.should be_success
      orders = JSON.parse(response.body)
      orders[0]['id'].should < orders[1]['id']

      signed_get '/api/v2/orders', params: {market: 'btceur', order_by: 'desc'}, token: token
      response.should be_success
      orders = JSON.parse(response.body)
      orders[0]['id'].should > orders[1]['id']
    end

  end

  describe "GET /api/v2/order" do
    let(:order)  { create(:order_bid, currency: 'btceur', price: '12.326'.to_d, volume: '3.14', origin_volume: '12.13', member: member, trades_count: 1) }
    let!(:trade) { create(:trade, bid: order) }

    it "should get specified order" do
      signed_get "/api/v2/order", params: {id: order.id}, token: token
      response.should be_success

      result = JSON.parse(response.body)
      expect(result['id']).to eq order.id
      expect(result['executed_volume']).to eq '8.99'
    end

    it "should include related trades" do
      signed_get "/api/v2/order", params: {id: order.id}, token: token

      result = JSON.parse(response.body)
      expect(result['trades_count']).to eq 1
      result['trades'].should have(1).trade
      expect(result['trades'].first['id']).to eq trade.id
      expect(result['trades'].first['side']).to eq 'buy'
    end

    it "should get 404 error when order doesn't exist" do
      signed_get "/api/v2/order", params: {id: 99999}, token: token
      expect(response.code).to eq '404'
    end
  end

  describe "POST /api/v2/orders/multi" do
    before do
      member.get_account(:btc).update_attributes(balance: 100)
      member.get_account(:eur).update_attributes(balance: 100000)
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
        response.should be_success

        result = JSON.parse(response.body)
        result.should have(2).orders
        expect(result.first['side']).to eq 'sell'
        expect(result.first['volume']).to eq '12.13'
        expect(result.last['side']).to eq 'buy'
        expect(result.last['volume']).to eq '17.31'
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
        AMQPQueue.expects(:enqueue).times(0)
        signed_post '/api/v2/orders/multi', token: token, params: params
        expect(response.code).to eq '400'
        expect(response.body).to eq '{"error":{"code":2002,"message":"Failed to create order. Reason: Validation failed: Price must be greater than 0"}}'
      }.not_to change(Order, :count)
    end
  end

  describe "POST /api/v2/orders" do
    it "should create a sell order" do
      member.get_account(:btc).update_attributes(balance: 100)

      expect {
        signed_post '/api/v2/orders', token: token, params: {market: 'btceur', side: 'sell', volume: '12.13', price: '2014'}
        response.should be_success
        expect(JSON.parse(response.body)['id']).to eq OrderAsk.last.id
      }.to change(OrderAsk, :count).by(1)
    end

    it "should create a buy order" do
      member.get_account(:eur).update_attributes(balance: 100000)

      expect {
        signed_post '/api/v2/orders', token: token, params: {market: 'btceur', side: 'buy', volume: '12.13', price: '2014'}
        response.should be_success
        expect(JSON.parse(response.body)['id']).to eq OrderBid.last.id
      }.to change(OrderBid, :count).by(1)
    end

    it "should set order source to APIv2" do
      member.get_account(:eur).update_attributes(balance: 100000)
      signed_post '/api/v2/orders', token: token, params: {market: 'btceur', side: 'buy', volume: '12.13', price: '2014'}
      expect(OrderBid.last.source).to eq 'APIv2'
    end

    it "should return cannot lock funds error" do
      expect {
        signed_post '/api/v2/orders', params: {market: 'btceur', side: 'sell', volume: '12.13', price: '2014'}
        expect(response.code).to eq '400'
        expect(response.body).to eq '{"error":{"code":2002,"message":"Failed to create order. Reason: cannot lock funds (amount: 12.13)"}}'
      }.not_to change(OrderAsk, :count).by(1)
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
        member.get_account(:eur).update_attributes(locked: order.price*order.volume)
      end

      it "should cancel specified order" do
        AMQPQueue.expects(:enqueue).with(:matching, action: 'cancel', order: order.to_matching_attributes)
        expect {
          signed_post "/api/v2/order/delete", params: {id: order.id}, token: token
          response.should be_success
          expect(JSON.parse(response.body)['id']).to eq order.id
        }.not_to change(Order, :count)
      end
    end

    context "failed" do
      it "should return order not found error" do
        signed_post "/api/v2/order/delete", params: {id: '0'}, token: token
        expect(response.code).to eq '400'
        expect(JSON.parse(response.body)['error']['code']).to eq 2003
      end
    end

  end

  describe "POST /api/v2/orders/clear" do

    before do
      create(:order_ask, currency: 'btceur', price: '12.326', volume: '3.14', origin_volume: '12.13', member: member)
      create(:order_bid, currency: 'btceur', price: '12.326', volume: '3.14', origin_volume: '12.13', member: member)

      member.get_account(:btc).update_attributes(locked: '5')
      member.get_account(:eur).update_attributes(locked: '50')
    end

    it "should cancel all my orders" do
      member.orders.each do |o|
        AMQPQueue.expects(:enqueue).with(:matching, action: 'cancel', order: o.to_matching_attributes)
      end

      expect {
        signed_post "/api/v2/orders/clear", token: token
        response.should be_success

        result = JSON.parse(response.body)
        result.should have(2).orders
      }.not_to change(Order, :count)
    end

    it "should cancel all my asks" do
      member.orders.where(type: 'OrderAsk').each do |o|
        AMQPQueue.expects(:enqueue).with(:matching, action: 'cancel', order: o.to_matching_attributes)
      end

      expect {
        signed_post "/api/v2/orders/clear", token: token, params: {side: 'sell'}
        response.should be_success

        result = JSON.parse(response.body)
        result.should have(1).orders
        expect(result.first['id']).to eq member.orders.where(type: 'OrderAsk').first.id
      }.not_to change(Order, :count)
    end

  end
end
