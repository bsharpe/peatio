require 'spec_helper'

describe APIv2::Tickers do

  describe "GET /api/v2/tickers" do
    it "returns ticker of all markets" do
      get "/api/v2/tickers"
      assert_successful
      json_data['btceur']['at'].should_not be_nil
      expect(json_data['btceur']['ticker']).to eq({"buy"=>"0.0", "sell"=>"0.0", "low"=>"0.0", "high"=>"0.0", "last"=>"0.0", "vol"=>"0.0"})
    end
  end

  describe "GET /api/v2/tickers/:market" do
    it "should return market tickers" do
      get "/api/v2/tickers/btceur"
      assert_successful
      expect(json_data['ticker']).to eq({"buy"=>"0.0", "sell"=>"0.0", "low"=>"0.0", "high"=>"0.0", "last"=>"0.0", "vol"=>"0.0"})
    end
  end

end
