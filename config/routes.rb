Rails.application.routes.draw do
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  root 'pages#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  get 'test' => 'pages#test'

  get '/auth/:provider/callback', to: 'sessions#create'
  delete '/logout', to: 'sessions#destroy', as: :logout
  # post 'games/mock_user_login', to: 'sessions#mock_user_login', as: :mock_user_login # For testing purposes only, remove or comment out later

  get 'games/:name' => 'games#index', as: :game_index
  get 'games/:name/json' => 'games#index_json'
  get 'games/:name/profile' => 'games#profile', as: :game_profile
  get 'games/:name/roster' => 'games#roster', as: :game_roster
  get 'games/:name/roster/json' => 'games#roster_json'
  get 'games/:name/leaderboard' => 'games#leaderboard', as: :game_leaderboard
  get 'games/:name/leaderboard/json' => 'games#leaderboard_json'
  get 'games/:name/assignments' => 'assignments#show', as: :show_assignments
  get 'games/:name/manage' => 'games#manage', as: :game_manage
  get 'games/:name/history' => 'games#history', as: :game_history
  get 'games/:name/history/json' => 'games#history_json'
  get 'games/:name/sponsors' => 'games#sponsors', as: :game_sponsors
  get 'games/:name/sponsors/json' => 'games#sponsors_json'
  get 'games/:name/rules' => 'games#rules', as: :game_rules
  post 'games/:name/generate_assignments' => 'assignments#generate_assignments', as: :generate_assignments
  post 'games/:name/activate_assignments' => 'assignments#activate_assignments', as: :activate_assignments
  post 'games/:name/kill' => 'assignments#kill', as: :kill
  post 'games/:name/manual_reassign' => 'assignments#manual_reassign', as: :manual_reassign
  post 'games/:name/set_public_enemy_mode' => 'games#set_public_enemy_mode', as: :set_public_enemy_mode
  post 'games/:name/reassign_roles' => 'games#reassign_roles', as: :reassign_roles
  post 'games/:name/update_sponsor_points' => 'games#update_sponsor_points', as: :update_sponsor_points
  post 'games/:name/create_note' => 'notes#create', as: :create_note
  post 'games/:name/delete_note' => 'notes#delete', as: :delete_note

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
