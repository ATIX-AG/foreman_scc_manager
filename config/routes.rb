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
end
