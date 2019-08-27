Rails.application.routes.draw do
  resources :scc_accounts do
    collection do
      put 'test_connection'
      get 'auto_complete_search'
    end
    member do
      put 'sync'
      put 'bulk_subscribe'
    end
  end
  resources :scc_products, only: %i[index show] do
    member do
      put 'subscribe'
      put 'unsubscribe'
    end
  end
  
  namespace :api, :defaults => { :format => 'json' } do
    scope '(:apiv)', :module => :v2,
                       :defaults => { :apiv => 'v2' },
                       :apiv => /v1|v2/,
                       :constraints => ApiConstraints.new(:version => 2, :default => true) do
      resources :scc_accounts do
        collection do
          put 'test_connection'
          get 'auto_complete_search'
        end
        member do
          put 'sync'
          put 'bulk_subscribe'
        end
        constraints(:scc_account_id => /[^\/]+/) do
          resources :scc_products, only: %i[index show] do
            member do
              put 'subscribe'
            end
          end
        end
      end
    end
  end
end

