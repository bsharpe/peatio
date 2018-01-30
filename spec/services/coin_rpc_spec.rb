require 'rails_helper'

RSpec.describe CoinRPC do
  describe '#http_post_request' do
    it 'raises custom error on connection refused' do
      allow_any_instance_of(Net::HTTP).to receive(:request).and_raise(Errno::ECONNREFUSED)

      rpc_client = CoinRPC::BTC.new('http://127.0.0.1:18332')

      expect {
        rpc_client.http_post_request ''
      }.to raise_error(CoinRPC::ConnectionRefusedError)
    end
  end
end
