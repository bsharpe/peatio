require 'spec_helper'

describe DepositChannel do

  context "#sort" do
    let(:dc1) { DepositChannel.new }
    let(:dc2) { DepositChannel.new }

    it "sort DepositChannel" do
      allow(dc1).to receive(:sort_order).and_return 1
      allow(dc2).to receive(:sort_order).and_return 2
      expect([dc2, dc1].sort.first.sort_order).to eq(1)
    end
  end

end
