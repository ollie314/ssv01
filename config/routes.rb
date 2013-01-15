Ssv01::Application.routes.draw do

  root :to => 'maintenance#index'

  # routes for administration namespace
  namespace :admin do
    resources :languages
  end

  get "api/documentation/index"
  get "api/documentation/list"
  get "api/documentation/resources"
  get "api/documentation/streams"

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

  get "help/configuration"
  get "help/languages"
  get "help/privacy"
  get "help/term_of_service"
  get "help/tos"
  get "help/term_of_use"
  get "help/tou"

  get "account/list"
  get "account/summary"
  get "account/view"
  get "account/languages"
  get "account/kind"
  get "account/trends"

  get "rentals/list"
  get "rentals/search"
  get "rentals/object_summary"
  get "rentals/object_details"
  get "rentals/object_pictures"
  get "rentals/object_location"
  get "rentals/object_pricing"
  get "rentals/object_video"
  get "rentals/object_availability"

  get "sales/list"
  get "sales/search"
  get "sales/object_summary"
  get "sales/object_details"
  get "sales/object_location"
  get "sales/object_pictures"
  get "sales/object_video"

  get "oauth/authorize"
  get "oauth/request_token"
  get "oauth/access_token"
  get "oauth/authenticate"

  get "register/signup"

  get "account/index"
  get "account/show"
  get "account/edit"

  get "connection/login"
  get "connection/logout"

  get "maintenance/index"
  get "maintenance/home"

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