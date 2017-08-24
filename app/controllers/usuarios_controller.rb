class UsuariosController < ApplicationController
  require 'digest/sha1'
  before_action :require_user, only: [:contato, :mail, :my_ticket, :open_tickets, :edit]
  
  def howworks
    #Gráfico de funcionalidade
  end
  def new
    @usuario = Usuario.new
  end
  def edit
    @authorized_user = Usuario.authenticate(params["usuario"]["username_or_email"],params["usuario"]["password"])
   
    if current_user == @authorized_user
      if params["commit"] == "Salvar Informações"
        @authorized_user.first_name = params["usuario"]["first_name"]
        @authorized_user.last_name = params["usuario"]["last_name"]
        @authorized_user.fone = params["usuario"]["fone"]
        @authorized_user.save
        render 'setting'
      end
      if params["commit"] == "Salvar Carteiras"
        @authorized_user.bitcoin = params["usuario"]["bitcoin"]
        @authorized_user.litecoin = params["usuario"]["litecoin"]
        @authorized_user.save
        render 'sessions/setting'
      end
      if params["commit"] == "Salvar Nova senha"
        if params["usuario"]["senha_nova"] == params["usuario"]["senha_confirm"]
          @authorized_user.encrypted_password = Digest::SHA1.hexdigest(params['usuario']["senha_nova"])
          @authorized_user.save
        end
        @messages = 'As senhas não correspondem, tente novamente.<br> <a href="/setting?menu=Segurança">Voltar</a>'
        render 'sessions/loginerror'
      end
    else
      if params["commit"] == "Salvar Informações"
        @messages = 'A senha inserida não corresponde a sua senha.<br> Por favor, tente novamente <a href="/setting?menu=Segurança">Voltar</a>'
        render 'sessions/loginerror'
      elsif params["commit"] == "Salvar Carteiras"
        @messages = 'A senha inserida não corresponde a sua senha.<br> Por favor, tente novamente <a href="/setting?menu=Carteiras">Voltar</a>'
        render 'sessions/loginerror'
      elsif params["commit"] == "Salvar Nova senha"
        @messages = 'A senha inserida não corresponde a sua senha.<br> Por favor, tente novamente <a href="/setting?menu=Segurança">Voltar</a>'
        render 'sessions/loginerror'
      else
        @messages = 'A senha inserida não corresponde a sua senha.<br> Por favor, tente novamente <a href="/setting">Voltar</a>'
        render 'sessions/loginerror'
      end
    end
  end
  def open_tickets
    @tickets = Ticket.all
    if params['method'] == 'post'
      @ticket = Ticket.find(params['id'])
      render 'myticket'
    end
  end
  def my_ticket
    @tickets = Ticket.all
    @ticket = Ticket.find(params['resposta']['id'])
    if params['commit'] == "Sim"
      @ticket.status = 'fechado'
      @ticket.save
    end
    if params['commit'] == "Não"
      @ticket.status = 'aguardando resposta do usuário'
      @ticket.save
    end
    respond_to do | format |  
        format.js {render :layout => false}
    end
  end
  def create
    @customer = Shoppe::Customer.new
    @customer.first_name = params["usuario"]["first_name"]
    @customer.last_name = params["usuario"]["last_name"]
    @customer.email = params["usuario"]["email"]
    @customer.phone = params["usuario"]["fone"]
    @usuario = Usuario.new(usuario_params)
    @usuario.username.downcase!
    @usuario.email.downcase!
    @usuario.fone = @customer.phone
    @usuario.saldo_encrypted = eval("{'BRL' => 0, 'BTC' => 0, 'LTC' => 0, 'DOGE' => 0}").to_s

    if @usuario.save
      @logged = "Você efetuou o registro com sucesso. Guarde suas informações com segurança, nós não divulgamos nem solicitamos informações.\n Por favor, acesse seu email para confirmar o registro."
      flash[:color] = 'valid'
      @usuario.encrypted_password = Digest::SHA1.hexdigest(@usuario.password)
      @usuario.email_confirmed = false
      @customer.save
      confirmar_email(@usuario)
      @usuario.save
      render 'sessions/login'
    else 
      @logged = 'Formulário inválido.'
      render 'new'
      flash[:color] = 'invalid'
    end
  end
  def contato
  end
  def mail
    ticket = Ticket.new
    ticket.user = params['name']
    ticket.title = params['subject']
    ticket.conteudo = params['message']
    ticket.email = params['email']
    ticket.status = 'aberto'
    if ticket.save
      @messages = "Sua mensagem foi enviada com sucesso! Por favor, aguarde para futuro contato.\n Você pode consultar o status do seu ticket na área de 'Inicio' "
      render 'sessions/loginerror'
    else
      @messages = "Algum erro ocorreu. Por favor, tente novamente!"
      render 'sessions/loginerror'
    end
  end
  def resposta
    @ticket = Ticket.find(params['message']['id'])
    @texto = @ticket.conteudo
    @ticket.conteudo << "\n"
    @ticket.conteudo << '------------------------------------------------------------------------------------------------------'
    @ticket.conteudo << "\n"
    @ticket.conteudo << 'Ticket respondido: ' + params['message']['user_name']
    @ticket.conteudo << "\n"
    @ticket.conteudo << params['message']['resposta']
    @ticket.conteudo << "\n"
    @ticket.conteudo << "------------------------------------------------------------------------------------------------------\n"
    @ticket.status = "aberto"
    if @ticket.save
         @messages = "Sua mensagem foi enviada com sucesso! Por favor, aguarde para futuro contato.\n Você pode consultar o status do seu ticket na área de 'Inicio' "
         render 'sessions/loginerror'
    else
         @messages = "Ocorreu algum erro. Tente novamente."
         render 'sessions/loginerror'
    end
  end
  def confirm_email
    user = Usuario.find_by_confirm_token(params[:id])
    if user
      user.email_activate
      user.save
      cpt_transaction_user("#{user.first_name} #{user.last_name}",user.id,user.username,user.email)
      @logged = "Parabéns! Seu email foi confirmado! Faça login para prosseguir."
      render 'sessions/login'
    else
      @logged = "Usuário inexistente."
      render 'sessions/login'
    end
  end
  private
  def usuario_params
    params.require(:usuario).permit(:username,:email, :password, :password_confirmation, :first_name, :last_name)
  end
end
