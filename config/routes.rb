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

  root 'landing#index'

  # Error routes that work in conjunction with
  # config.exceptions_app = self.routes.
  match '/404', to: 'errors#not_found', via: :all
  match '/500', to: 'errors#internal_server_error', via: :all

  ######################### Public website routes ###########################

  resources :agents, only: :show do
    match '/items', to: 'agents#items', via: :get, as: 'items'
  end
  match '/auth/:provider/callback', to: 'sessions#create', via: [:get, :post],
        as: 'auth' # used by omniauth
  resources :binaries, only: :show
  match '/collections/iiif', to: 'collections#iiif_presentation_list',
        via: :get, as: 'collections_iiif_presentation_list'
  resources :collections, only: [:index, :show] do
    match 'items/treedata', to: 'items#tree_data', via: [:get, :post]
    match 'tree', to: 'items#tree', via: :get
    resources :items, only: :index
    # IIIF Presentation API 2.1 routes
    match '/iiif', to: 'collections#iiif_presentation', via: :get,
          as: 'iiif_presentation'
  end
  resources :downloads, only: :show, param: :key do
    match '/file', to: 'downloads#file', via: :get, as: 'file'
  end
  match '/harvest', to: 'harvest#index', via: :get
  resources :items, only: [:index, :show] do
    match '/treedata', to: 'items#item_tree_node', via: [:get, :post]
    match '/binaries/:filename', to: 'items#binary', via: :get, as: 'binary'
    match '/files', to: 'items#files', via: :get, as: 'files'
    # IIIF Presentation API 2.1 routes
    match '/annotation/:name', to: 'items#iiif_image_resource', via: :get,
          as: 'iiif_image_resource'
    match '/canvas/:id', to: 'items#iiif_canvas', via: :get, as: 'iiif_canvas'
    match '/layer/:name', to: 'items#iiif_layer', via: :get, as: 'iiif_layer'
    match '/list/:name', to: 'items#iiif_annotation_list', via: :get,
          as: 'iiif_annotation_list'
    match '/manifest', to: 'items#iiif_manifest', via: :get,
          as: 'iiif_manifest'
    match '/range/:name', to: 'items#iiif_range', via: :get, as: 'iiif_range'
    match '/sequence/:name', to: 'items#iiif_sequence', via: :get,
          as: 'iiif_sequence'
    # Wellcome Library API extension
    match '/xsequence/:name', to: 'items#iiif_media_sequence', via: :get,
          as: 'iiif_media_sequence'
  end
  match '/oai-pmh', to: 'oai_pmh#index', via: %w(get post), as: 'oai_pmh'
  match '/search', to: redirect('/', status: 301), via: :all
  match '/signin', to: 'sessions#new', via: :get
  match '/signout', to: 'sessions#destroy', via: :delete

  ######################### Control Panel routes ###########################

  namespace :admin do
    root 'dashboard#index'

    resources :agents
    resources :agent_relation_types, except: :show,
              path: 'agent-relation-types'
    resources :agent_relations, except: [:index, :show], path: 'agent-relations'
    resources :agent_rules, except: :show, path: 'agent-rules'
    resources :agent_types, except: :show, path: 'agent-types'
    resources :elements, param: :name do
      match '/usages', to: 'elements#usages', via: :get
    end
    match '/elements/import', to: 'elements#import', via: :post,
          as: 'elements_import'
    match '/collections/sync', to: 'collections#sync', via: :patch,
          as: 'collections_sync'
    resources :collections, except: [:new, :create, :delete] do
      resources :item_sets, except: :index do
        match '/all-items', to: 'item_sets#remove_all_items', via: :delete
        match '/items', to: 'item_sets#items', via: :get
        match '/items', to: 'item_sets#remove_items', via: :delete
      end
      match '/items/edit', to: 'items#edit_all', via: :get, as: 'edit_all_items'
      match '/items', to: 'items#destroy_all', via: :delete,
            as: 'destroy_all_items'
      match '/items/update', to: 'items#update_all', via: :post
      match '/items/publish', to: 'items#publish', via: :patch
      match '/items/unpublish', to: 'items#unpublish', via: :patch
      resources :items do
        match '/purge-cached-images', to: 'items#purge_cached_images',
              via: :post
      end
      match '/items/add-items-to-item-set', to: 'items#add_items_to_item_set',
            via: :post
      match '/items/add-query-to-item-set', to: 'items#add_query_to_item_set',
            via: :post
      match '/items/import', to: 'items#import', via: :post
      match '/items/batch-change-metadata', to: 'items#batch_change_metadata',
            via: :post
      match '/items/migrate-metadata', to: 'items#migrate_metadata', via: :post
      match '/items/replace-metadata', to: 'items#replace_metadata', via: :post
      match '/items/sync', to: 'items#sync', via: :post
      match '/purge-cached-images', to: 'collections#purge_cached_images',
            via: :post
      match '/statistics', to: 'collections#statistics', via: :get
    end
    match '/test-images', to: 'test#index', via: :get
    resources :metadata_profile_elements,
              only: [:create, :update, :destroy, :edit]
    resources :metadata_profiles, path: 'metadata-profiles' do
      match '/clone', to: 'metadata_profiles#clone', via: :patch, as: 'clone'
      match '/delete-elements', to: 'metadata_profiles#delete_elements',
            via: :post, as: 'delete_elements'
      match '/reindex-items', to: 'metadata_profiles#reindex_items',
            via: :post, as: 'reindex_items'
    end
    match '/metadata-profiles/import', to: 'metadata_profiles#import',
          via: :post, as: 'metadata_profile_import'
    resources :roles, param: :key
    match '/settings', to: 'settings#index', via: :get
    match '/settings', to: 'settings#update', via: :patch
    match '/statistics', to: 'statistics#index', via: :get
    match '/status', to: 'status#index', via: :get
    resources :tasks
    resources :users, param: :username do
      match '/enable', to: 'users#enable', via: :patch, as: 'enable'
      match '/disable', to: 'users#disable', via: :patch, as: 'disable'
      match '/reset-api-key', to: 'users#reset_api_key', via: :post, as: 'reset_api_key'
      match '/roles', to: 'users#change_roles', via: :patch, as: 'change_roles'
    end
    resources :vocabulary_terms, except: :index, path: 'vocabulary-terms'
    resources :vocabularies do
      match '/delete-vocabulary-terms',
            to: 'vocabularies#delete_vocabulary_terms',
            via: :post, as: 'delete_vocabulary_terms'
      match '/terms', to: 'vocabularies#terms', via: :get
    end
    match '/vocabularies/import', to: 'vocabularies#import', via: :post,
          as: 'vocabulary_import'
  end

  ############################ REST API routes ##############################

  namespace :api do
    root 'landing#index'
    resources :collections, only: [:index, :show, :update] do
      resources :items, only: :index
    end
    resources :items, only: [:index, :show, :destroy]
    match '/items/:id', to: 'items#update', via: :put
  end

  ############# Redirects from images.library.uiuc/illinois.edu #############

  match '/projects/:alias', to: 'collections#show_contentdm', via: :get
  match '/projects/:alias/*glob', to: 'collections#show_contentdm', via: :get

  ######################## CONTENTdm v4/5 redirects #########################

  # Reference URLs
  match '/u',
        to: 'contentdm#v4_reference_url', via: :all
  # Single-item URLs
  match '/cdm4/item_viewer.php',
        to: 'contentdm#v4_item', via: :all
  # Compound object URLs
  match '/cdm4/document.php',
        to: 'contentdm#v4_item', via: :all
  # Collection pages
  match '/cdm4/browse.php',
        to: 'contentdm#v4_collection', via: :all
  # Search results pages
  match '/cdm4/results.php',
        to: 'contentdm#v4_collection_items', via: :all
  match '/cdm4/search.php',
        to: redirect('/', status: 301), via: :all
  # OAI-PMH
  match '/cgi-bin/oai.exe',
        to: redirect('/oai-pmh', status: 301), via: :all
  match '/cgi-bin/oai2.exe',
        to: redirect('/oai-pmh', status: 301), via: :all
  # Admin
  match '/cgi-bin/admin/start.exe',
        to: redirect('/admin', status: 301), via: :all
  # Other pages
  match '/cdm4/about.php',
        to: redirect('/collections', status: 301), via: :all
  match '/cdm4/favorites.php',
        to: redirect('/', status: 301), via: :all
  match '/cdm4/help.php',
        to: redirect('/', status: 301), via: :all

  ######################### CONTENTdm v6 redirects ##########################

  # Reference URLs
  match '/cdm/ref/collection/:alias/:pointer',
        to: 'contentdm#v6_item', via: :all
  match '/cdm/ref/collection/:alias/id/:pointer',
        to: 'contentdm#v6_item', via: :all
  # Single-item URLs
  match '/cdm/singleitem/collection/:alias/id/:pointer',
        to: 'contentdm#v6_item', via: :all
  match '/cdm/singleitem/collection/:alias/id/:pointer/rec/:noop',
        to: 'contentdm#v6_item', via: :all
  # Compound object URLs
  match '/cdm/compoundobject/collection/:alias/id/:pointer',
        to: 'contentdm#v6_item', via: :all
  match '/cdm/compoundobject/collection/:alias/id/:pointer/rec/:noop',
        to: 'contentdm#v6_item', via: :all
  match '/cdm/compoundobject/collection/:alias/id/:pointer/show/:noop1/rec/:noop2',
        to: 'contentdm#v6_item', via: :all
  # Collection pages
  match '/cdm/landingpage/collection/:alias',
        to: 'contentdm#v6_collection', via: :all
  match '/cdm/about/collection/:alias',
        to: 'contentdm#v6_collection', via: :all
  # Search results pages
  match '/cdm/search',
        to: redirect('/items', status: 301), via: :all
  match '/cdm/search/collection/:alias',
        to: 'contentdm#v6_collection_items', via: :all
  match '/cdm/search/collection/:alias/order/:order/ad/:ad',
        to: 'contentdm#v6_collection_items', via: :all
  match '/cdm/search/collection/:alias/searchterm/:term/mode/:mode/page/:page',
        to: 'contentdm#v6_collection_items', via: :all
  match '/cdm/search/collection/:alias/searchterm/:term/mode/:mode/order/:order',
        to: 'contentdm#v6_collection_items', via: :all
  match '/cdm/search/collection/:alias/searchterm/:term/field/:field/mode/:mode/conn/:conn/order/:order',
        to: 'contentdm#v6_collection_items', via: :all
  match '/cdm/search/collection/:alias/searchterm/:term/field/:field/mode/:mode/conn/:conn/order/:order/ad/:ad',
        to: 'contentdm#v6_collection_items', via: :all
  match '/cdm/search/collection/:alias/searchterm/:term/field/:field/mode/:mode/conn/:conn/order/:order/page/:page',
        to: 'contentdm#v6_collection_items', via: :all
  match '/cdm/search/searchterm/:term',
        to: 'contentdm#v6_search_results', via: :all
  match '/cdm/search/searchterm/:term/mode/:mode',
        to: 'contentdm#v6_search_results', via: :all
  match '/cdm/search/searchterm/:term/mode/:mode/page/:page',
        to: 'contentdm#v6_search_results', via: :all
  match '/cdm/search/searchterm/:term/mode/:mode/order/:order',
        to: 'contentdm#v6_search_results', via: :all
  match '/cdm/search/searchterm/:term/mode/:mode/order/:order/ad/:ad',
        to: 'contentdm#v6_search_results', via: :all
  match '/cdm/search/searchterm/:term/mode/:mode/order/:order/ad/:ad/page/:page',
        to: 'contentdm#v6_search_results', via: :all
  match '/cdm/search/searchterm/:term/mode/:mode/order/:order/page/:page',
        to: 'contentdm#v6_search_results', via: :all
  match '/cdm/search/searchterm/:term/order/:order',
        to: 'contentdm#v6_search_results', via: :all
  # Images
  match '/utils/getthumbnail/collection/:alias/id/:pointer',
        to: 'contentdm#v6_thumbnail', via: :all
  # OAI-PMH
  match '/oai/oai.php',
        to: redirect('/oai-pmh', status: 301), via: :all
  # Other pages
  match '/cdm/about',
        to: redirect('/', status: 301), via: :all
  match '/cdm/favorites',
        to: redirect('/', status: 301), via: :all
  # I don't know what this is; maybe used by the Project Client?
  match '/ui/*glob',
        to: 'contentdm#gone', via: :all

  match '*path', to: 'errors#not_found', via: :all

end
