Spree::Core::Engine.routes.draw do
  # Add your extension routes here
  namespace :gateway do
    get '/przelewy24/complete/:gateway_id/:order_id' => 'przelewy24#complete'
    get '/przelewy24/:gateway_id/:order_id' => 'przelewy24#show'
    get '/przelewy24/error/:gateway_id/:order_id' => 'przelewy24#error'
    post '/przelewy24/error/:gateway_id/:order_id' => 'przelewy24#error'
    post '/przelewy24/comeback/:gateway_id/:order_id' => 'przelewy24#comeback'
  end
end
