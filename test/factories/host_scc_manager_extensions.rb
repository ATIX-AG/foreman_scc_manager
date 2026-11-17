FactoryBot.modify do
  factory :host do
    trait :with_scc_host_credentials do
      after(:create) do |host|
        facet = host.create_scc_facet
        FactoryBot.create(:scc_host_credentials, scc_facet: facet)
      end
    end
  end
end
