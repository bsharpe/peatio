require 'spec_helper'

module APIv2
  class Mount

    get "/null" do
      ''
    end

    get "/broken" do
      raise Error, code: 2014310, text: 'MtGox bankrupt'
    end

  end
end

describe APIv2::Mount, type: :api do

  it "should use auth and attack middleware" do
    expect(APIv2::Mount.middleware).to eq [[APIv2::Auth::Middleware], [Rack::Attack]]
  end

  it "should allow 3rd party ajax call" do
    get "/api/v2/null"
    assert_successful
    expect(response.headers['Access-Control-Allow-Origin']).to eq '*'
  end

  context "handle exception on request processing" do
    it "should render json error message" do
      get "/api/v2/broken"
      expect(response.code).to eq '400'
      expect(json_data).to eq ({'error' => {'code' => 2014310, 'message' => "MtGox bankrupt"}})
    end
  end

  context "handle exception on request routing" do
    it "should render json error message" do
      get "/api/v2/non/exist"
      expect(response.code).to eq '404'
      expect(response.body).to eq "Not Found"
    end
  end

end
