module HostManagedExtensions
  extend ActiveSupport::Concern

  included do
    has_one :scc_host_credentials, class_name: 'SccHostCredentials',
      inverse_of: :host, foreign_key: :host_id, dependent: :destroy
  end
end
