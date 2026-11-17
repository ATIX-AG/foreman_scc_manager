# frozen_string_literal: true

class SccHostCredentials < ApplicationRecord
  include Encryptable

  self.table_name = 'scc_host_credentials'

  encrypts :scc_password

  belongs_to :scc_facet, inverse_of: :scc_host_credentials
  validates :scc_facet, presence: true, uniqueness: true
end
