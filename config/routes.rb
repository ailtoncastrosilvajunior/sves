Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root "inicio#index"
  resource :session, only: %i[new create destroy]
  resource :palavra_passe, only: %i[edit update]
  resource :alterar_senha, only: %i[edit update], controller: "alterar_senhas"
  get  "cadastro-servo", to: "publico/cadastro_servos#new", as: :cadastro_servo
  post "cadastro-servo", to: "publico/cadastro_servos#create"
  get "equipes", to: "contexto#equipes", as: :equipes_em_curso
  resources :edicoes do
    member do
      patch :marcar_em_curso
      post :importar_casais_csv
      get :impressao_equipe_cenaculos, to: "impressao_equipe_cenaculos#show"
    end
    resources :equipes do
      resources :vinculos, controller: :equipes_servos, only: %i[create destroy] do
        collection do
          post :lote
          delete :destroy_lote
        end
      end
    end
    resources :casais, only: %i[index new create]
    resources :reunioes_cenaculo, controller: "edicao_reunioes_cenaculos", except: %i[show] do
      collection do
        get :novo_lote
        post :criar_lote
      end
    end
    resources :cenaculos do
      member do
        get "reunioes_cenaculo", to: "cenaculo_reuniao_presencas#index", as: :reunioes_cenaculo
        get "reunioes_cenaculo/:reuniao_id/presencas", to: "cenaculo_reuniao_presencas#edit", as: :edit_reuniao_presencas
        patch "reunioes_cenaculo/:reuniao_id/presencas", to: "cenaculo_reuniao_presencas#update", as: :update_reuniao_presencas
      end
      resources :cenaculo_casais, path: "membros_casais", only: %i[create destroy]
      resources :cenaculo_servos, path: "pastores", only: %i[create destroy]
    end
    get "cenaculos_distribuicao_sugestao", to: "sugestao_distribuicao_cenaculos#new",
        as: :distribuicao_cenaculos_sugestao
    post "cenaculos_distribuicao_sugestao", to: "sugestao_distribuicao_cenaculos#create",
         as: :distribuicao_cenaculos_sugestao_envio
  end
  resources :servos do
    member do
      post :liberar_acesso
      post :redefinir_senha_participante
    end
    collection do
      post :liberar_acesso_lote
    end
  end

  resources :materiais_apoio do
    collection do
      get :todos
    end

    member do
      get :baixar
    end
  end
end
