# frozen_string_literal: true

object @scc_product
extends 'api/v2/scc_products/base'
attributes :organization_id, :organization_name, :scc_account_id, :name, :arch, :friendly_name, :description,
  :product_id
