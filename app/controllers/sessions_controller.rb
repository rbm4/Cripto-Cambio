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
      @messages = "Você não pode acessar esta página"
      redirect_to '/loginerror'
      return
    end
  end
  def loginerror
  end
  def index
  end
  #https://www.sitepoint.com/rails-userpassword-authentication-from-scratch-part-ii/
end
