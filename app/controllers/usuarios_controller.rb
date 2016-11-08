class UsuariosController < ApplicationController
  require 'digest/sha1'
  before_action :require_user, only: [:contato, :mail]
  
  def new
    @usuario = Usuario.new
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
    nome_user = params['name']
    email_user = params['email']
    titulo = params['subject']
    mensagem = params['message']
    
    @messages = 'Sua mensagem foi enviada com sucesso!'
    render 'sessions/loginerror'
  end
  private
  def usuario_params
    params.require(:usuario).permit(:username,:email, :password, :password_confirmation, :first_name, :last_name)
  end
end
