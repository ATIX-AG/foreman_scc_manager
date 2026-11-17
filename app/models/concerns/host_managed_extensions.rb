module HostManagedExtensions
  extend ActiveSupport::Concern

  included do
    delegate :scc_host_credentials, :scc_host_products, :scc_products,
      to: :scc_facet, allow_nil: true

    scoped_search on: :id, relation: :scc_facet, rename: :scc_registered, only_explicit: true
  end
end
