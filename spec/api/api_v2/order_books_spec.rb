require 'spec_helper'

describe APIv2::OrderBooks, type: :api do

  describe "GET /api/v2/order_book" do
    before do
      5.times { create(:order_bid) }
      5.times { create(:order_ask) }
    end

    it "should return ask and bid orders on specified market" do
      get '/api/v2/order_book', market: 'btceur'
      assert_successful

      expect(json_data['asks'].size).to eq 5
      expect(json_data['bids'].size).to eq 5
    end

    it "should return limited asks and bids" do
      get '/api/v2/order_book', market: 'btceur', asks_limit: 1, bids_limit: 1
      assert_successful

      expect(json_data['asks'].size).to eq 1
      expect(json_data['bids'].size).to eq 1
    end
  end

  describe "GET /api/v2/depth" do
    let(:asks) { [['100', '2.0'], ['120', '1.0']] }
    let(:bids) { [['90', '3.0'], ['50', '1.0']] }

    before do
      global = OpenStruct.new(id: "global", asks: asks, bids: bids)
      allow(Global).to receive(:[]).and_return(global)
    end

    it "should sort asks and bids from highest to lowest" do
      get '/api/v2/depth', market: 'btceur'
      assert_successful

      expect(json_data['asks']).to eq asks.reverse
      expect(json_data['bids']).to eq bids
    end
  end

end
