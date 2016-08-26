class SessionsController < ApplicationController
  
  before_action :require_logout, only: [:login,:login_attempt]
  
  def login
    #Login Form
  end
  def login_attempt
    @authorized_user = Usuario.authenticate(params[:username_or_email],params[:login_password])
    if @authorized_user
      session[:user_id] = @authorized_user.id
      @messages = "Wow Welcome again, you logged in as #{@authorized_user.username}"
      redirect_to :controller => 'sessions', :action =>'home', :id => session[:user_id]
    else
      @messages = "Invalid Username or Password"
      flash[:color]= "invalid"
      render "login"	
    end
  end
  def destroy 
    session[:user_id] = nil 
    @messages = "logout"
    redirect_to '/' 
  end
  def home
      @atual = Usuario.find(params[:id])
    unless session[:user_id] == @atual.id
      @messages = "ERRO! Você não pode acessar esta página"
      render 'sessions/loginerror'
      return
    end
  end
  def submit
       endereco = Pagamento.find_by(address: params[:id])
       url_r = 'https://block.io/api/v2/get_address_balance/?api_key=ac35-6ff5-e103-d1c3&addresses=' + endereco.address.to_s
       uri_r = URI(url_r)
       response_r = Net::HTTP.get(uri_r)
       hash_r = JSON.parse(response_r)
       puts hash_r["data"].to_s
       puts hash_r["data"]["network"]
       hash_2 = hash_r["data"]["balances"].to_s.split(',')
       @saldo_conta_consultada = hash_2[3].to_s 
       @saldo_conta_consultada = @saldo_conta_consultada[/\d/].to_r #satoshi
       puts @saldo_conta_consultada
       puts endereco.volume.to_r
       if endereco.volume.to_r >= @saldo_conta_consultada 
          update = Pagamento.find_by(address: endereco.address)
          update.status = 'accepted'
          update.save
          @messages = 'Transação aceita. Você aparentemente enviou pelo menos o valor necessário para essa transação. Pode verificar o status de envio na sua página de detalhes'
       else
         @messages = 'Transação ainda não aprovada. Verifique se você enviou as moedas para o endereço correto.'
       end
  end
  def detalhes
    @pagamentos = Pagamento.all
  end
  def loginerror
  end
  def index
  end
  def endereco_params
        params.require(:pagamento).permit(:address, :volume)
  end
  #https://www.sitepoint.com/rails-userpassword-authentication-from-scratch-part-ii/
end
