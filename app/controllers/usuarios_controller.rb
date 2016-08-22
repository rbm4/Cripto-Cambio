class UsuariosController < ApplicationController
  require 'digest/sha1'
  def new
    @usuario = Usuario.new
  end
  def create
    @usuario = Usuario.new(usuario_params)
    @usuario.username.downcase!
    @usuario.email.downcase!
    if @usuario.save
      flash[:notice] = 'Você efetuou o registro com sucesso.'
      flash[:color] = 'valid'
    else 
      flash[:notice] = 'Formulário inválido.'
      flash[:color] = 'invalid'
    end
    #encrypted_password= Digest::SHA1.hexdigest(password)
    @usuario.encrypted_password = Digest::SHA1.hexdigest(@usuario.password)
    @usuario.save
    render 'new'
  end
  private
  def usuario_params
    params.require(:usuario).permit(:username,:email, :password, :password_confirmation)
  end
end
