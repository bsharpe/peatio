require 'spec_helper'

describe APIv2::Markets, type: :api do

  describe "GET /api/v2/markets" do
    it "should all available markets" do
      get '/api/v2/markets'
      assert_successful
      expect(response.body).to eq '[{"id":"btceur","name":"BTC/EUR"}]'
    end
  end

end
