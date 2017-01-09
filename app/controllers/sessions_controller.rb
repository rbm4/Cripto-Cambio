class SessionsController < ApplicationController
  
  before_action :require_logout, only: [:login,:login_attempt]
  
  def login
    #Login Form
  end
  def senha
    #senha form
  end
 
  def change
    token = params['usuario']['token']
    @user = Usuario.find_by_confirm_token(token)
    if params['usuario']['senha_nova'] == params['usuario']['senha_confirm']
      #senhas conferem
      @user.encrypted_password = Digest::SHA1.hexdigest(params['usuario']['senha_nova'])
      @user.confirm_token = nil
      @user.save
      @messages = "Você reiniciou sua senha. Faça login a seguir: "
    end
    render 'login'
  end
  def recuperar_senha
    @authorized_user = Usuario.find_by_username(params[:username_or_email])
    if @authorized_user == nil
      puts 'email'
      @authorized_user = Usuario.find_by_email(params[:username_or_email])
    end
    if @authorized_user != nil
      puts @authorized_user.username
      @authorized_user.generate_token
      if @authorized_user.save
        string_body = ""
        string_body << "Olá "
        string_body << @authorized_user.first_name.capitalize + " " + @authorized_user.last_name.capitalize
        string_body << "<br>"
        string_body << "Você iniciou um processo de reinicialização de sua senha.<br> Se não foi você, por favor, ignore este email."
        string_body << "\n"
        string_body << ("Confirme a troca de senha clicando no link: <a href='" + ENV["LOCAL_URL"] + "/recover?id=" + @authorized_user.confirm_token.to_s + "'> Confirmar </a>")
    
        from = Email.new(email: 'admin@cptcambio.com')
        subject = 'Mudança de senha - Cptcambio'
        to = Email.new(email: @authorized_user.email)
        content = Content.new(type: 'text/html', value: string_body)
        mail = Mail.new(from, subject, to, content)

        sg = SendGrid::API.new(api_key: ENV['SENDGRID_API_KEY'])
        response = sg.client.mail._("send").post(request_body: mail.to_json)
        puts 'email enviado aqui'
        puts response.status_code
        puts response.body
        puts response.headers
      end
    end
    @messages = 'Se as informações estiverem corretas, um email de recuperação será enviado para o email cadastrado do usuário informado. <br> <a href="/login">Voltar</a>'
    render 'loginerror'
  end
  def recover
    if @user_reset = Usuario.find_by_confirm_token(params[:id])
      @recover = true
      
      @token = @user_reset.confirm_token 
     
      render 'recover'
    end
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
      @total_btc = limite_compra_btc
      @total_ltc = limite_compra_ltc
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
    option = params['menu']
    if option == 'Informações básicas'
      @basicinfo = true
      render 'setting'
    elsif option == 'Carteiras'
      @wallets = true
      render 'setting'
    elsif option == 'Notificações'
      @notifications = true
      render 'setting'
    elsif option == 'Segurança'
      @seguranca = true
      render 'setting'
    else
      @normal = true
      render 'setting'
    end
  end
end
