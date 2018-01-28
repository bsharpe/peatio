require 'spec_helper'

describe AMQPQueue do
  let(:config) {
      {
        connect:   { host: '127.0.0.1' },
        exchange:  { testx: { name: 'testx', type: 'fanout' } },
        queue:     { testq: { name: 'testq', durable: true },
                     testd: { name: 'testd'} },
        binding:   {
          test:    { queue: 'testq', exchange: 'testx' },
          testd:   { queue: 'testd' },
          default: { queue: 'testq' }
        }
      }.with_indifferent_access
  }

  let(:default_exchange) { OpenStruct.new(id: 'default exchange') }
  let(:channel) { OpenStruct.new(default_exchange: default_exchange) }

  before do
    allow(AMQPConfig).to receive(:data).and_return(config)

    allow(AMQPQueue).to receive(:publish).and_call_original
    allow(AMQPQueue).to receive(:exchanges).and_return({default: default_exchange})
    allow(AMQPQueue).to receive(:channel).and_return(channel)
  end

  it "should instantiate exchange use exchange config" do
    expect(channel).to receive(:fanout).with('testx')
    AMQPQueue.exchange(:testx)
  end

  it "should publish message on selected exchange" do
    exchange = OpenStruct.new(id: 'test exchange')
    expect(channel).to receive(:fanout).with('testx').and_return(exchange)
    expect(exchange).to receive(:publish).with(JSON.dump(data: 'hello'), {})
    AMQPQueue.publish(:testx, data: 'hello')
  end

  it "should publish message on default exchange" do
    expect(default_exchange).to receive(:publish).with(JSON.dump(data: 'hello', locale: I18n.locale), routing_key: 'testd')
    AMQPQueue.enqueue(:testd, data: 'hello')
  end

end
