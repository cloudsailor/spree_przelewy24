Spree::Core::Engine.routes.draw do
  # Add your extension routes here
  namespace :gateway do
    post '/przelewy24/comeback/:gateway_id/:order_id' => 'przelewy24#comeback', :as => :przelewy24_comeback
  end
end
