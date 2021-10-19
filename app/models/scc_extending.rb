# frozen_string_literal: true

class SccExtending < ApplicationRecord
  belongs_to :scc_product, inverse_of: :scc_extendings
  belongs_to :scc_extension, class_name: :SccProduct, inverse_of: :inverse_scc_extendings
end
