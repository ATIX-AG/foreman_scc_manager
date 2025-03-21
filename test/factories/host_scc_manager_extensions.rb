FactoryBot.modify do
  factory :host do
    trait :with_scc_host_credentials do
      after(:create) do |host|
        FactoryBot.create(:scc_host_credentials, host: host)
      end
    end
  end
end
