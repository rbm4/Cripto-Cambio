class Sesssion < ActiveRecord::Base
    def home
        @atual = Usuario.find(params[session[:user_id]])
    unless session[:user_id] == @atual.id
      @messages = "Você não pode acessar esta página"
      redirect_to '/loginerror'
      return
    end
    end
end