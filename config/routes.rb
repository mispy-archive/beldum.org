BeldumOrg::Application.routes.draw do
  root :to => "main#index"
  get 'test' => 'main#test'
  get "synergy" => "synergy#index"
  get "combos" => "combos#index"
  get "todo" => "todo#index"
end
