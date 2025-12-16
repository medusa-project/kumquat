Rails.application.routes.draw do
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
  resources :binaries, only: :show do
    match '/object', to: 'binaries#object', via: :get
    match '/stream', to: 'binaries#stream', via: :get
  end

  match '/contact', to: 'website#contact', via: :post
        # constraints: lambda { |request| request.xhr? }

  match '/collections/iiif', to: 'collections#iiif_presentation_list',
        via: :get, as: 'collections_iiif_presentation_list',
        defaults: { format: :json }
  resources :collections, only: [:index, :show] do
    match 'items/treedata', to: 'items#tree_data', via: [:get, :post]
    match 'tree', to: 'items#tree', via: :get
    resources :items, only: :index
    # IIIF Presentation API 2.1 routes
    match '/iiif', to: 'collections#iiif_presentation', via: :get,
          as: 'iiif_presentation', defaults: { format: :json }
  end
  resources :downloads, only: :show, param: :key do
    match '/file', to: 'downloads#file', via: :get, as: 'file'
  end
  match '/health', to: 'health#index', via: :get
  resources :items, only: [:index, :show] do
    match '/treedata', to: 'items#item_tree_node', via: [:get, :post]
    match '/binaries/:filename', to: 'items#binary', via: :get, as: 'binary'
    match '/files', to: 'items#files', via: :get, as: 'files'
    # IIIF Presentation API 2.1 routes
    match '/annotation/:name', to: 'items#iiif_image_resource', via: :get,
          as: 'iiif_image_resource', defaults: { format: :json }
    match '/canvas/:id', to: 'items#iiif_canvas', via: :get, as: 'iiif_canvas',
          defaults: { format: :json }
    match '/layer/:name', to: 'items#iiif_layer', via: :get, as: 'iiif_layer',
          defaults: { format: :json }
    match '/annotation-list/:name', to: 'items#iiif_annotation_list', via: :get,
          as: 'iiif_annotation_list',
          defaults: { format: :json }
    match '/manifest', to: 'items#iiif_manifest', via: :get,
          as: 'iiif_manifest', defaults: { format: :json }
    match '/range/:name', to: 'items#iiif_range', via: :get, as: 'iiif_range',
          defaults: { format: :json }
    match '/sequence/:name', to: 'items#iiif_sequence', via: :get,
          as: 'iiif_sequence', defaults: { format: :json }
    # IIIF Search API routes
    match '/manifest/search', to: 'items#iiif_search', via: :get,
          as: 'iiif_search', defaults: { format: :json }
    # Wellcome Library API extension
    match '/xsequence/:name', to: 'items#iiif_media_sequence', via: :get,
          as: 'iiif_media_sequence', defaults: { format: :json }
  end
  match '/oai-pmh', to: 'oai_pmh#handle', via: %w(get post), as: 'oai_pmh'
  match '/oai-pmh/idhh', to: 'oai_pmh#handle', via: %w(get post), as: 'idhh_oai_pmh'
  match '/oai-pmh/primo', to: 'oai_pmh#handle', via: %w(get post), as: 'primo_oai_pmh'
  match '/search-landing', to: 'search_landing#index', via: :get, as: 'search_landing'
  match '/special-collections-search', to: 'special_collections_search#index', via: :get, as: 'special_collections_search'
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
    resources :binaries, only: :update do
      match '/edit-access', to: 'binaries#edit_access', via: :get
      match '/run-ocr', to: 'binaries#run_ocr', via: :patch
    end
    match '/collections/items', to: 'collections#items', via: :get
    match '/collections/sync', to: 'collections#sync', via: :patch,
          as: 'collections_sync'
    resources :collections, except: [:edit, :new, :create, :delete] do
      match '/edit-access', to: 'collections#edit_access', via: :get,
            constraints: lambda { |request| request.xhr? }
      match '/edit-email-watchers', to: 'collections#edit_email_watchers', via: :get,
            constraints: lambda { |request| request.xhr? }
      match '/edit-info', to: 'collections#edit_info', via: :get,
            constraints: lambda { |request| request.xhr? }
      match '/edit-representation', to: 'collections#edit_representation', via: :get,
            constraints: lambda { |request| request.xhr? }
      member do 
        get :export_permalinks_and_metadata
      end
      resources :item_sets, except: :index do
        match '/all-items', to: 'item_sets#remove_all_items', via: :delete , as: "remove_all_items"
        match '/items', to: 'item_sets#items', via: :get, as: "items"
        match '/items', to: 'item_sets#remove_items', via: :delete, as: "remove_items"
      end
      match '/items/edit', to: 'items#edit_all', via: :get
      match '/items/enable-full-text-search', to: 'items#enable_full_text_search',
            via: :patch
      match '/items/disable-full-text-search', to: 'items#disable_full_text_search',
            via: :patch
      match '/items', to: 'collections#delete_items', via: :delete,
            as: 'delete_items'
      match '/items/publish', to: 'items#publish', via: :patch
      match '/items/run-ocr', to: 'items#run_ocr', via: :patch
      match '/items/unpublish', to: 'items#unpublish', via: :patch
      match '/items/update', to: 'items#update_all', via: :post
      resources :items, except: :edit do
        match '/edit-access', to: 'items#edit_access', via: :get,
              constraints: lambda { |request| request.xhr? }
        match '/edit-info', to: 'items#edit_info', via: :get,
              constraints: lambda { |request| request.xhr? }
        match '/edit-metadata', to: 'items#edit_metadata', via: :get,
              constraints: lambda { |request| request.xhr? }
        match '/edit-representation', to: 'items#edit_representation', via: :get,
              constraints: lambda { |request| request.xhr? }
        match '/publicize-child-binaries', to: 'items#publicize_child_binaries',
              via: :post
        match '/purge-cached-images', to: 'items#purge_cached_images',
              via: :post
        match '/run-ocr', to: 'items#run_ocr', via: :patch
        match '/unpublicize-child-binaries', to: 'items#unpublicize_child_binaries',
              via: :post
      end
      match '/items/add-items-to-item-set', to: 'items#add_items_to_item_set',
            via: :post
      match '/items/add-query-to-item-set', to: 'items#add_query_to_item_set',
            via: :post
      match '/items/import', to: 'items#import', via: :post
      match '/items/import-embedded-file-metadata',
            to: 'items#import_embedded_file_metadata', via: :post
      match '/items/batch-change-metadata', to: 'items#batch_change_metadata',
            via: :post
      match '/items/migrate-metadata', to: 'items#migrate_metadata', via: :post
      match '/items/replace-metadata', to: 'items#replace_metadata', via: :post
      match '/items/sync', to: 'items#sync', via: :post
      match '/purge-cached-images', to: 'collections#purge_cached_images',
            via: :post
      match '/statistics', to: 'collections#statistics', via: :get
      match '/unwatch', to: 'collections#unwatch', via: :patch
      match '/watch', to: 'collections#watch', via: :patch
    end
    resources :elements, param: :name do
      match '/usages', to: 'elements#usages', via: :get
    end
    match '/elements/import', to: 'elements#import', via: :post,
          as: 'elements_import'
    resources :host_groups
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
    match '/settings', to: 'settings#index', via: :get
    match '/settings', to: 'settings#update', via: :patch
    match '/statistics', to: 'statistics#index', via: :get
    resources :tasks
    resources :users, param: :username, except: [:edit, :update] do
      match '/reset-api-key', to: 'users#reset_api_key', via: :post, as: 'reset_api_key'
    end
    resources :vocabularies do
      resources :vocabulary_terms, path: "terms"
      match '/delete-vocabulary-terms',
            to: 'vocabularies#delete_vocabulary_terms',
            via: :post, as: 'delete_vocabulary_terms'
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

  namespace :harvest do
    root 'harvest#index'
    resources :agents, only: :show, defaults: { format: :json }
    resources :collections, only: :show, defaults: { format: :json }
    resources :items, only: :show, defaults: { format: :json }
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
