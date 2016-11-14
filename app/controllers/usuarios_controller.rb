class UsuariosController < ApplicationController
  require 'digest/sha1'
  before_action :require_user, only: [:contato, :mail, :my_ticket, :open_tickets]
  
  def new
    @usuario = Usuario.new
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
      render 'open_tickets'
    end
    if params['commit'] == "Não"
      @ticket.status = 'aguardando resposta do usuário'
      render 'usuarios/myticket'
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
    if @usuario.save
      @logged = 'Você efetuou o registro com sucesso. Guarde suas informações com segurança, nós não divulgamos nem solicitamos informações.'
      flash[:color] = 'valid'
      @usuario.encrypted_password = Digest::SHA1.hexdigest(@usuario.password)
      @customer.save
      @usuario.save
      render 'sessions/login'
    else 
      @logged = 'Formulário inválido.'
      render 'new'
      flash[:color] = 'invalid'
    end
    #encrypted_password= Digest::SHA1.hexdigest(password)
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
  private
  def usuario_params
    params.require(:usuario).permit(:username,:email, :password, :password_confirmation, :first_name, :last_name)
  end
end
