# frozen_string_literal: true

class SccHostProduct < ApplicationRecord
  belongs_to :scc_facet, inverse_of: :scc_host_products
  belongs_to :scc_product
  belongs_to :task, class_name: 'ForemanTasks::Task::DynflowTask', optional: true

  PENDING = 'pending'
  ACTIVE = 'active'
  FAILED = 'failed'
  STATUSES = [PENDING, ACTIVE, FAILED].freeze

  validates :scc_product_id, uniqueness: { scope: :scc_facet_id }
  validates :status, inclusion: { in: STATUSES, allow_blank: false }

  scope :active, -> { where(status: ACTIVE) }
  scope :failed, -> { where(status: FAILED) }
  scope :pending, -> { where(status: PENDING) }

  scoped_search on: :status, complete_value: true
  scoped_search on: :name, relation: :scc_product, rename: :product_name, complete_value: true

  def humanized_status
    case status
    when PENDING then _('Pending')
    when ACTIVE then _('Active')
    when FAILED then _('Failed')
    end
  end
end
