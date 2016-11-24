class SessionsController < ApplicationController
  
  before_action :require_logout, only: [:login,:login_attempt]
  
  def login
    #Login Form
  end
  def login_attempt
    @authorized_user = Usuario.authenticate(params[:username_or_email],params[:login_password])
    if @authorized_user
      if @authorized_user.email_confirmed == true
        session[:user_id] = @authorized_user.id
        @messages = "Wow Welcome again, you logged in as #{@authorized_user.username}"
        redirect_to :controller => 'sessions', :action =>'home', :id => session[:user_id]
      else
        @messages = "Email não confirmado, ainda. Por favor, confira sua caixa de entrada ou caixa de SPAM em busca do email de confirmação."
        render "login"
      end
    else
      @messages = "Email/Username ou senha inválidos."
      flash[:color]= "invalid"
      render "login"	 
    end
  end
  def destroy 
    session[:user_id] = nil
    current_order.destroy
    session[:order_id] = nil
    @messages = "logout"
    redirect_to '/' 
  end
  def home
      params[:featured] = "1"
      @destaques = Shoppe::Product.root.ordered
      @destaques = @destaques.group_by(&:product_category)
      count = 0
      @dstqn = Array.new
      @dstqi = Array.new
      @destaques.each do |h|
        h[1].each do |g|
          if g.featured == true
            count = count + 1
            @dstqn.append(g.name)
            @dstqi.append(g.in_the_box)
          end
        end
      end
      @total_btc = limite_compra_btc
      @atual = Usuario.find(params[:id])
    unless session[:user_id] == @atual.id
      @messages = "ERRO! Você não pode acessar esta página"
      render 'sessions/loginerror'
      return
    end
  end
  def submit #FUNÇÃO DE CONFIRMAÇÃO DE PAGAMENTO FUNCIONAL
       endereco = Pagamento.find_by(address: params[:id])
       url_r = 'https://block.io/api/v2/get_address_balance/?api_key=ac35-6ff5-e103-d1c3&addresses=' + endereco.address.to_s #verifique infos sobre a carteira
       uri_r = URI(url_r)
       response_r = Net::HTTP.get(uri_r)
       hash_r = JSON.parse(response_r)
       hash_2 = hash_r["data"]["balances"].to_s.split(',')                      #criar hash com informações necessárias
       pending = hash_2[4].to_s.split("=>")                                     #isolar volume pendente
       @saldo_pendente = pending[1].sub(/["]/, '')
       @saldo_conta_consultada = hash_2[3].to_s                                 #isolar volume confirmado
       splited = @saldo_conta_consultada.split("=>")                            #Isolar Saldo em número
       b = splited[1].sub(/["]/, '')                                            #
       a = BigDecimal.new(b,9)                                                  #Transformando em decimal o saldo atual
       pending_dec = BigDecimal.new(@saldo_pendente,9)                          #Transformando em decimal o saldo pendente (a receber)
       
       #Volume do pedido é igual ou inferior ao volume atual?
       update = Pagamento.find_by(address: endereco.address)
       if BigDecimal(endereco.volume) <= a
          update = Pagamento.find_by(address: endereco.address)
          update.status = 'accepted'
          update.save
          @messages = 'Transação aceita. Você aparentemente enviou pelo menos o valor necessário para essa transação. Pode verificar o status de envio na sua página de detalhes'
       elsif pending_dec > 0
         update.status = 'waiting confirmation'
         update.save
         @messages = 'Transação ainda não aprovada. Porém com volume pendente, é preciso esperar confirmações da rede, tente novamente em alguns instantes. Valor pendente: ' + String(pending_dec) + moeda(hash_r["data"]["network"])
       else
         @messages = 'Transação ainda não aprovada. Verifique se você enviou as moedas para o endereço correto'
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
  def setting
    @user = Usuario.find_by_id(session[:id])
    puts @user
  end
end
