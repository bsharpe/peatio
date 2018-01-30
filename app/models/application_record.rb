class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
  extend Enumerize
  include Ensurance
end
