Ssv01::Application.routes.draw do

  get "agency/load"

  get "agency/check"

  root :to => 'maintenance#index'

  # check following notation to achieve same result
  #resources :publishers do
  #  resources :magazines do
  #    resources :photos
  #  end
  #end

  namespace :testing do
    match ":agency_id/sales/" => "sales#list", :via => :get
    match ":agency_id/sales/list" => "sales#list", :via => :get
    match ":agency_id/sales/search" => "sales#search", :via => :get

    match ":agency_id/sales/:object_id" => "object#index", :via => :get
    match ":agency_id/sales/:object_id/summary" => "object#summary", :via => :get
    match ":agency_id/sales/:object_id/details" => "object#details", :via => :get
    match ":agency_id/sales/:object_id/location" => "object#location", :via => :get
    match ":agency_id/sales/:object_id/pictures" => "object#pictures", :via => :get
    match ":agency_id/sales/:object_id/videos" => "object#videos", :via => :get

    match ":agency_id/rentals/" => "rentals#list", :via => :get
    match ":agency_id/rentals/list" => "rentals#list", :via => :get
    match ":agency_id/rentals/search" => "rentals#search", :via => :get

    match ":agency_id/rentals/:object_id" => "object#index", :via => :get
    match ":agency_id/rentals/:object_id/summary" => "object#summary", :via => :get
    match ":agency_id/rentals/:object_id/details" => "object#details", :via => :get
    match ":agency_id/rentals/:object_id/location" => "object#location", :via => :get
    match ":agency_id/rentals/:object_id/pictures" => "object#pictures", :via => :get
    match ":agency_id/rentals/:object_id/videos" => "object#videos", :via => :get
    match ":agency_id/rentals/:object_id/pricing" => "object#pricing", :via => :get
    match ":agency_id/rentals/:object_id/availability" => "object#availability", :via => :get
  end

  namespace :hub do
    match "/:agency_id/sales" => "sales#index", :via => :get
    match "/:agency_id/sales/index" => "sales#index", :via => :get
    match "/:agency_id/sales/create" => "sales#create", :via => :get
    match "/:agency_id/sales/edit" => "sales#edit", :via => :get
    match "/:agency_id/sales/delete" => "sales#delete", :via => :get
    match "/:agency_id/sales/save" => "sales#save", :via => :post
    match "/:agency_id/sales/trends" => "sales#trends", :via => :get
    match "/:agency_id/sales/objects/" => "object#index", :via => :get

    match "/:agency_id/sales/test" => "sales#test", :via => :get
  end

  # routes for administration namespace
  namespace :admin do
    resources :languages
    resources :agency_users
    resources :agencies

    # agencies module extensions. Sub routing
    match '/agencies/:id/infos' => "agency_infos#show", :method => :get
    match '/agencies/:id/infos/show' => "agency_infos#show", :method => :get
    match '/agencies/:id/infos/edit' => "agency_infos#edit", :method => :get
    match '/agencies/:id/infos/delete' => "agency_infos#delete", :method => :get
    match '/agencies/:id/infos/update' => "agency_infos#update", :method => :post
    match '/agencies/:id/infos/fetch' => "agency_infos#fetch", :method => :get

    # geo manager module
    get "geo_manager/list"
    get "geo_manager/show"
    get "geo_manager/edit"
    get "geo_manager/create"
    get "geo_manager/index"

    # home controller
    get "home/index"
    get "home/home"

    # connection controller
    match "/connection/" => "connection#index"
    match "/connection/index" => "connection#index"
    match "/connection/login" => "connection#login", :method => :post
    match "/connection/logout" => "connection#logout"
  end

  # api namespace ...
  namespace :api do
    get "/documentation/index"
    get "/documentation/list"
    get "/documentation/resources"
    get "/documentation/streams"
  end

  # routes for account
  get "api/account/list"
  scope :module => "api" do
    match "api/account/summary" => "account#summary"
    match "api/account/summary/:id" => "account#summary"
    match "api/account/:id/summary" => "account#summary"

    match "api/account/view" => "account#view"
    match "api/account/:id/view" => "account#view"
    match "api/account/view/:id" => "account#view"

    match "api/account/languages" => "account#languages"
    match "api/account/:id/languages" => "account#languages"
    match "api/account/languages/:id" => "account#languages"

    match "api/account/kind" => "account#kind"
    match "api/account/:id/kind" => "account#kind"
    match "api/account/kind/:id" => "account#kind"

    match "api/account/trends" => "account#trends"
    match "api/account/:id/trends" => "account#trends"
    match "api/account/trends/:id" => "account#trends"
  end

  # routes for public pages
  scope :module => "pub" do
    match "index" => "index#index"
    match "index/index" => "index#index"
  end

  # routes for help module ...
  namespace :help do
    get "/configuration"
    get "/languages"
    get "/documents/privacy"
    get "/documents/term_of_service"
    get "/documents/tos"
    get "/documents/term_of_use"
    get "/documents/tou"
  end

  get "account/list"
  get "account/summary"
  get "account/view"
  get "account/languages"
  get "account/kind"
  get "account/trends"
  get "account/index"
  get "account/show"
  get "account/edit"

  #get "rentals/list"
  #get "rentals/search"
  #get "rentals/object_summary"
  #get "rentals/object_details"
  #get "rentals/object_pictures"
  #get "rentals/object_location"
  #get "rentals/object_pricing"
  #get "rentals/object_video"
  #get "rentals/object_availability"

  #get "sales/list"
  #get "sales/search"
  #get "sales/object_summary"
  #get "sales/object_details"
  #get "sales/object_location"
  #get "sales/object_pictures"
  #get "sales/object_video"

  get "oauth/authorize"
  get "oauth/request_token"
  get "oauth/access_token"
  get "oauth/authenticate"

  get "register/signup"

  get "connection/login"
  get "connection/logout"

  get "maintenance/index"
  get "maintenance/home"
  get "maintenance/about"
  get "maintenance/contact"

  match "/about" => 'maintenance#about'
  match "/contact" => "maintenance#contact"

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
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

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
