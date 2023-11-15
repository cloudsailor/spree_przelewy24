Spree::Core::Engine.routes.draw do
  # Add your extension routes here
  namespace :gateway do
    get '/przelewy24/complete/:gateway_id/:order_id' => 'przelewy24#complete', :as => :przelewy24_complete
    get '/przelewy24/:gateway_id/:order_id' => 'przelewy24#show', :as => :przelewy24
    get '/przelewy24/error/:gateway_id/:order_id' => 'przelewy24#error', :as => :przelewy24_error
    post '/przelewy24/error/:gateway_id/:order_id' => 'przelewy24#error', :as => :post_przelewy24_error
    post '/przelewy24/comeback/:gateway_id/:order_id' => 'przelewy24#comeback', :as => :przelewy24_comeback
  end
end
