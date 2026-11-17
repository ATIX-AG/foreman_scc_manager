class SccFacet < ApplicationRecord
  include Facets::Base

  has_one :scc_host_credentials, class_name: 'SccHostCredentials', inverse_of: :scc_facet, dependent: :destroy
  has_many :scc_host_products, class_name: 'SccHostProduct', inverse_of: :scc_facet, dependent: :destroy
  has_many :scc_products, through: :scc_host_products
end
