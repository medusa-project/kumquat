Rails.application.routes.draw do
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  concern :publishable do
    patch 'publish'
    patch 'unpublish'
  end

  root 'landing#index'

  match '/auth/:provider/callback', to: 'sessions#create', via: [:get, :post],
        as: :auth # used by omniauth
  resources :collections, only: [:index, :show] do
    resources :items, only: :index
  end
  resources :favorites, only: :index
  resources :items, only: [:create, :destroy, :index, :show] do
    match '/access-master', to: 'items#access_master_bytestream', via: 'get',
          as: :access_master_bytestream
    match '/preservation-master', to: 'items#preservation_master_bytestream',
          via: 'get', as: :preservation_master_bytestream
  end
  match '/oai-pmh', to: 'oai_pmh#index', via: %w(get post), as: 'oai_pmh'
  match '/search', to: 'items#search', via: 'post'
  match '/signin', to: 'sessions#new', via: 'get'
  match '/signout', to: 'sessions#destroy', via: 'delete'

  namespace :admin do
    root 'dashboard#index'

    resources :available_elements, except: :show, path: 'elements'
    match '/elements/schema', to: 'available_elements#schema', via: 'get'
    match '/collections/refresh', to: 'collections#refresh', via: 'patch',
          as: 'collections_refresh'
    resources :collections, except: [:new, :create, :delete] do
      match '/items/search', to: 'items#search', via: %w(get post),
            as: 'items_search'
      resources :items, concerns: :publishable
      match '/items/ingest', to: 'items#ingest', via: 'post'
    end
    resources :element_defs, only: [:create, :update, :destroy, :edit]
    resources :metadata_profiles, path: 'metadata-profiles' do
      match '/clone', to: 'metadata_profiles#clone', via: 'patch', as: 'clone'
    end
    match '/metadata-profiles/import', to: 'metadata_profiles#import',
          via: 'post', as: 'metadata_profile_import'
    resources :roles, param: :key
    match '/server', to: 'server#index', via: 'get'
    match '/server/image-server-status', to: 'server#image_server_status',
          via: 'get', as: 'server_image_server_status'
    match '/server/search-server-status', to: 'server#search_server_status',
          via: 'get', as: 'server_search_server_status'
    match '/settings', to: 'settings#index', via: 'get'
    match '/settings', to: 'settings#update', via: 'patch'
    match '/tasks', to: 'tasks#index', via: 'get'
    resources :users, param: :username do
      match '/enable', to: 'users#enable', via: 'patch', as: 'enable'
      match '/disable', to: 'users#disable', via: 'patch', as: 'disable'
      match '/roles', to: 'users#change_roles', via: 'patch', as: 'change_roles'
    end
  end
end
