module JSONHelper
  def rdata
    response
  end

  def rdata_code
    code = 0
    code = rdata.code if rdata.respond_to?(:code)
    code = rdata.status if rdata.respond_to?(:status)
    code
  end

  def get_json_object
    @_json_object ||= begin
      d = {}
      if rdata.body.present?
        begin
          d = JSON.parse(rdata.body)
        rescue JSON::ParserError
          d = rdata.body
        end
        d = d.with_indifferent_access if d.is_a?(Hash)
      end
      d
    end if rdata.body.present?
  end
  alias :json_data :get_json_object

  def assert_successful
    if !(200..299).cover?(rdata_code.to_i)
      ap rdata_code
      ap json_data if rdata.body.present?
    end
    expect(rdata_code.to_i).to be_in(200..299)
  end

  def assert_unsuccessful
    expect(rdata_code.to_i).to_not be_in(200..299)
  end

  def reset_json_object
    @_json_object = nil
  end
end

RSpec.configure do |config|
  config.include JSONHelper, type: :controller

  config.before(:each, type: :controller) do
    reset_json_object
  end

  config.include JSONHelper, type: :api
  config.before(:each, type: :api) do
    reset_json_object
  end

end
