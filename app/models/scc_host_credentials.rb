# frozen_string_literal: true

class SccHostCredentials < ApplicationRecord
  include Encryptable

  self.table_name = 'scc_host_credentials'

  encrypts :scc_password

  belongs_to :host, class_name: '::Host::Managed'
  validates :host, { presence: true, uniqueness: true }
end
