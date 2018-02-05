require 'rails_helper'

RSpec.describe APIv2::Deposits, type: :api do

  let(:member) { create(:member) }
  let(:other_member) { create(:member) }
  let(:token)  { create(:api_token, member: member) }

  describe "GET /api/v2/deposits" do

    before do
      create(:deposit, member: member, currency: 'btc')
      create(:deposit, member: member, currency: 'eur')
      create(:deposit, member: member, currency: 'eur', txid: 1, amount: 520)
      create(:deposit, member: member, currency: 'btc', created_at: 2.day.ago,  txid: 'test', amount: 111)
      create(:deposit, member: other_member, currency: 'eur', txid: 10)
    end

    it "should require deposits authentication" do
      get '/api/v2/deposits', token: token
      expect(response.code).to eq('401')
    end

    it "login deposits" do
      signed_get '/api/v2/deposits', token: token
      assert_successful
    end

    it "deposits num" do
      signed_get '/api/v2/deposits', token: token
      expect(json_data.size).to eq 3
    end

    it "should return limited deposits" do
      signed_get '/api/v2/deposits', params: {limit: 1}, token: token
      expect(json_data.size).to eq 1
    end

    it "should filter deposits by state" do
      signed_get '/api/v2/deposits', params: {state: 'canceled'}, token: token
      expect(json_data.size).to eq 0
      reset_json_object
      d = create(:deposit, member: member, currency: 'btc')
      d.submit!
      signed_get '/api/v2/deposits', params: {state: 'submitted'}, token: token

      expect(json_data.size).to eq 1
      expect(json_data.first['txid']).to eq d.txid
    end

    it "deposits currency eur" do
      signed_get '/api/v2/deposits', params: {currency: 'eur'}, token: token
      expect(json_data).to have(2).deposits
      expect(json_data.all? {|d| d['currency'] == 'eur' }).to eq(true)
    end

    it "should return 404 if txid not exist" do
      signed_get '/api/v2/deposit', params: {txid: 5}, token: token
      expect(response.code).to eq '404'
    end

    it "should return 404 if txid not belongs_to you " do
      signed_get '/api/v2/deposit', params: {txid: 10}, token: token
      expect(response.code).to eq '404'
    end

    it "should ok txid if exist" do
      signed_get '/api/v2/deposit', params: {txid: 1}, token: token

      expect(response.code).to eq '200'
      expect(json_data['amount']).to eq '520.0'
    end

    it "should return deposit no time limit " do
      signed_get '/api/v2/deposit', params: {txid: 'test'}, token: token

      expect(response.code).to eq '200'
      expect(json_data['amount']).to eq '111.0'
    end
  end
end
