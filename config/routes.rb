Rails.application.routes.draw do
  match '/payments/payment', :to => 'payments#payment', :as => 'paymentspayment', :via => [:get]
  match '/payments/relay_response', :to => 'payments#relay_response', :as => 'payments_relay_response', :via => [:post]
  match '/payments/receipt', :to => 'payments#receipt', :as => 'payments_receipt', :via => [:get]
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  get '/get_accept' => 'payments#get_an_accept_payment_page'
  get '/subscribe' => 'payments#create_Subscription'
end
