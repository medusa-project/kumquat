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

  # Error routes that work in conjunction with
  # config.exceptions_app = self.routes.
  match '/404', to: 'errors#not_found', via: :all
  match '/500', to: 'errors#internal_server_error', via: :all

  # Intercept CONTENTdm reference URLs for redirection.
  match '/cdm/ref/collection/:alias/:pointer',
        to: 'contentdm#redirect_to_dls_item', via: :all
  # Intercept CONTENTdm single-item URLs for redirection.
  match '/cdm/singleitem/collection/:alias/id/:pointer',
        to: 'contentdm#redirect_to_dls_item', via: :all
  # Intercept CONTENTdm compound object URLs for redirection.
  match '/cdm/compoundobject/collection/:alias/id/:pointer',
        to: 'contentdm#redirect_to_dls_item', via: :all
  # Intercept CONTENTdm collection pages for redirection.
  match '/cdm/landingpage/collection/:alias',
        to: 'contentdm#redirect_to_dls_collection', via: :all

  match '/auth/:provider/callback', to: 'sessions#create', via: [:get, :post],
        as: :auth # used by omniauth
  resources :collections, only: [:index, :show] do
    resources :items, only: :index
  end
  resources :favorites, only: :index
  resources :items, only: [:create, :destroy, :index, :show] do
    match '/access-master', to: 'items#access_master_bytestream', via: 'get',
          as: :access_master_bytestream
    match '/files', to: 'items#files', via: 'get', as: :files
    match '/pages', to: 'items#pages', via: 'get', as: :pages
    match '/preservation-master', to: 'items#preservation_master_bytestream',
          via: 'get', as: :preservation_master_bytestream
    # IIIF Presentation API 2.1 routes
    match '/annotation/:name', to: 'items#annotation', via: 'get',
          as: 'iiif_annotation'
    match '/canvas/:name', to: 'items#canvas', via: 'get', as: 'iiif_canvas'
    match '/manifest', to: 'items#manifest', via: 'get', as: 'iiif_manifest'
    match '/sequence/:name', to: 'items#sequence', via: 'get',
          as: 'iiif_sequence'
  end
  match '/oai-pmh', to: 'oai_pmh#index', via: %w(get post), as: 'oai_pmh'
  match '/search', to: 'items#search', via: 'post'
  match '/signin', to: 'sessions#new', via: 'get'
  match '/signout', to: 'sessions#destroy', via: 'delete'

  namespace :admin do
    root 'dashboard#index'

    resources :elements, except: :show, path: 'elements'
    match '/elements/import', to: 'elements#import', via: 'post',
          as: 'elements_import'
    match '/elements/schema', to: 'elements#schema', via: 'get'
    match '/collections/sync', to: 'collections#sync', via: 'patch',
          as: 'collections_sync'
    resources :collections, except: [:new, :create, :delete] do
      match '/items/search', to: 'items#search', via: %w(get post),
            as: 'items_search'
      resources :items, concerns: :publishable
      match '/items/import', to: 'items#import', via: 'post'
      match '/items/batch-change-metadata', to: 'items#batch_change_metadata',
            via: 'post'
      match '/items/migrate-metadata', to: 'items#migrate_metadata', via: 'post'
      match '/items/replace-metadata', to: 'items#replace_metadata', via: 'post'
      match '/items/sync', to: 'items#sync', via: 'post'
    end
    resources :metadata_profile_elements,
              only: [:create, :update, :destroy, :edit]
    resources :metadata_profiles, path: 'metadata-profiles' do
      match '/clone', to: 'metadata_profiles#clone', via: 'patch', as: 'clone'
      match '/delete-elements', to: 'metadata_profiles#delete_elements',
            via: 'post', as: 'delete_elements'
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
    resources :vocabulary_terms, except: :index, path: 'vocabulary-terms'
    resources :vocabularies do
      match '/delete-vocabulary-terms',
            to: 'vocabularies#delete_vocabulary_terms',
            via: 'post', as: 'delete_vocabulary_terms'
      match '/terms', to: 'vocabularies#terms', via: 'get'
    end
    match '/vocabularies/import', to: 'vocabularies#import', via: 'post',
          as: 'vocabulary_import'
  end
end
