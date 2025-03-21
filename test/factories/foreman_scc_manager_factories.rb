FactoryBot.define do
  factory :scc_host_credentials, class: 'SccHostCredentials' do
    sequence(:scc_login) { |n| "test_login_#{n}" }
    sequence(:scc_password) { |n| "test_password_#{n}" }
  end
end
