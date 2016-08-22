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
      redirect_to(:action => 'home')
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
  #https://www.sitepoint.com/rails-userpassword-authentication-from-scratch-part-ii/
end
