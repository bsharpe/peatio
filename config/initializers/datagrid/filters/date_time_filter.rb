class Datagrid::Filters::DateTimeFilter < Datagrid::Filters::BaseFilter
  def parse(value)
    value = value.utc if value.respond_to?(:utc)
    value.is_a?(String) ? value : value.to_s(:db)
  end
end


