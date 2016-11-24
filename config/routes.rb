Rails.application.routes.draw do
  mount Shoppe::Engine => "/shoppe"
  post '/coinpay' => 'notifications#coinpay'
  get '/tickets' => 'usuarios#open_tickets'
  get '/yesno' => 'usuarios#open_tickets'
  post '/yesno' => 'usuarios#my_ticket'
  post '/ticketawnser' => 'usuarios#resposta'
  get 'sessions/login'
  post '/ticket' => 'admin#open_tckt'
  post '/mailto' => 'usuarios#mail'
  post '/submit_tckt' => 'admin#resposta'
  get '/home' => 'sessions#home'
  get '/loginerror' => 'sessions#loginerror'
  get '/contato' => 'usuarios#contato'
  get 'sessions/profile'
  get '/store' => 'store#store'
  post 'submit' => 'sessions#submit'
  post 'list' => 'produtos#list_all_payment'
  get '/detalhes' => 'sessions#detalhes'
  post '/create_handler' => 'produtos#finalizar_compra'
  post '/create_handlerps' => 'produtos#finalizar_compra_pagseguro'
  get 'sessions/setting'
  get 'login' => 'sessions#login'
  get 'login_attempt' => 'sessions#login_attempt'
  post 'login_attempt' => 'sessions#login_attempt'
  get 'logout' => 'sessions#destroy'
  root 'sessions#index'
  get '/register' => 'usuarios#new'
  get '/create' => 'usuarios#new'
  post '/create' => 'usuarios#create'
  get '/charte' => 'sensores#charte'
  get '/chamados' => 'sensores#smart'
  post "/store" => "store#show", as: "product"
  post "/show" => "store#buy", as: "buy"
  get "basket", to: "orders#show"
  delete "basket", to: "orders#destroy"
  match "/confirmation", to: "usuarios#confirm_email", via: [:get, :post]
  match "checkout", to: "orders#checkout", as: "checkout", via: [:get, :patch]
  match "checkout/pay", to: "orders#payment", as: "checkout_payment", via: [:get, :post]
  match "checkout/confirm", to: "orders#confirmation", as: "checkout_confirmation", via: [:get, :post]
  get "/admin" => "admin#home"
  match "/payment" => "admin#orders", via: [:get, :post]
  match "/finish" => "admin#finish", via: [:get, :post]
  post '/finalizar' => 'admin#finalizar'
  get '/howto' => 'sessions#howto'
  post '/history' => "admin#history"
  post '/volm' => 'admin#take'
  post '/confirmation' => 'notifications#balance_change'
  get '/promote' => 'admin#promo'
  get '/demote' => 'admin#demo'
  get '/msgs' => 'admin#all_tickets'
  get '/msgall' => 'notifications#msgall'
  get '/setting' => 'sessions#setting'
  post '/blckrntf' => 'notifications#bitcoin'
  get '/blckrntf' => 'notifications#msg'
  post '/pgseguro' => 'notifications#pgseguro'
  get '/checkoutps' => 'orders#checkoutpgseguro'
  post '/calc' => 'application#calcular_metodos'
  get '/paypal' => 'notifications#paypal'
  post '/paypal' => 'notifications#paypal'
  post '/paypalnip' => 'notifications#paypalnip'
  
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  #root 'index.html'

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
end
