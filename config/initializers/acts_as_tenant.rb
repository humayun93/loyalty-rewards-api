# Configuration for acts_as_tenant
# https://github.com/ErwinM/acts_as_tenant

ActsAsTenant.configure do |config|
  # When set to true, an error will be raised if a tenant is not provided when accessing a model that is scoped by tenant
  config.require_tenant = true
end
