require "spec_helper"

describe "routes for trade", type: :routing do

  it "routes /markets/xxxyyy to the trade controller" do
    expect(Market).to receive(:find_by_id).with('xxxyyy').and_return(
      Market.new(id: 'xxxyyy', base_unit: 'xxx', quote_unit: 'yyy')
    )
    expect(get "/markets/xxxyyy").to be_routable
  end

  it "does NOT route /markets/yyyxxx" do
    expect(Market).to receive(:find_by_id).with('yyyxxx').and_return(nil)
    expect( get "/markets/yyyxxx" ).not_to be_routable
  end

end
