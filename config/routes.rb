Rails.application.routes.draw do
  resources :scc_accounts do
    member do
      put 'sync'
      put 'bulk_subscribe'
    end
  end
  resources :scc_products, only: [:index, :show] do
    member do
      put 'subscribe'
      put 'unsubscribe'
    end
  end
end
