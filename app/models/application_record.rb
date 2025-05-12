class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  # Don't set acts_as_tenant at this level
  # Instead, add it explicitly to each model that should be scoped by tenant
  # Example:
  #   class SomeModel < ApplicationRecord
  #     acts_as_tenant(:client)
  #   end
end
