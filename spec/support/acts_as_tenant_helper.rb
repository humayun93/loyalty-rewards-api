# Safely set ActsAsTenant.current_tenant for tests without relying on headers
module ActsAsTenantHelper
  def with_tenant(tenant)
    ActsAsTenant.with_tenant(tenant) do
      yield
    end
  end
end
 