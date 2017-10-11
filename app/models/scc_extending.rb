class SccExtending < ActiveRecord::Base
  belongs_to :scc_product
  belongs_to :scc_extension, class_name: :SccProduct
end
