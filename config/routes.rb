GenericApiRails::Engine.routes.draw do
  namespace :generic_api_rails , :path => "/" do
    match '*path' => "base#options", :via => [:options]
  
    namespace "authentication" do 
      get 'facebook' 
      post 'facebook'
      get 'login'
      post 'login'
      get 'signup'
      post 'signup'
    end

    get 'version' => 'misc#version'
    get 'whoami' => 'misc#whoami'

    get ':model' => 'rest#index'
    get ':model/:id' => 'rest#show'
    post ':model' => 'rest#create'
    match ':model/:id' => 'rest#update' , :via => [:post,:put,:patch]
    delete ':model/:id' => 'rest#destroy'
  end
end
