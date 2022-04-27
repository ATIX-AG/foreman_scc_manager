module ForemanSccManager
  module FixturesSupport
    FIXTURE_CLASSES = {
      scc_accounts: ::SccAccount,
      scc_products: ::SccProduct,
      scc_repositories: ::SccRepository,
      katello_root_repositories: ::Katello::RootRepository,
      scc_katello_repositories: SccKatelloRepository
    }.freeze

    def self.set_fixture_classes(test_class)
      FIXTURE_CLASSES.each { |k, v| test_class.set_fixture_class(k => v) }
    end
  end
end
