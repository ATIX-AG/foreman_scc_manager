module ForemanSccManager
  module FixturesSupport
    FIXTURE_CLASSES = {
      scc_accounts: ForemanSccManager::SccAccount,
      scc_products: ForemanSccManager::SccProduct
    }.freeze

    def self.set_fixture_classes(test_class)
      FIXTURE_CLASSES.each { |k, v| test_class.set_fixture_class(k => v) }
    end
  end
end
