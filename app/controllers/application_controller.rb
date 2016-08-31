class ApplicationController < ActionController::Base
  require 'blockchain'
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  attr_accessor :viewname
  helper_method :useremail
  helper_method :current_user
  helper_method :current_order
  helper_method :has_order?
  helper_method :username
  helper_method :receber_pagamento
  helper_method :moeda
  helper_method :buy
  helper_method :convert_bitcoin
  helper_method :is_admin?
  helper_method :archive_wallet
  def current_user 
    @current_user ||= Usuario.find(session[:user_id]) if session[:user_id] 
  end
  def require_user 
    redirect_to '/login' unless current_user 
  end
  
  def require_logout
    redirect_to '/' if current_user
  end
  def useremail
    if @current_user == nil
      current_user
      @current_user.email
    else
      @current_user.email
    end
  end
  def username
    if @current_user == nil
      current_user
      @current_user.username
    else
      @current_user.username
    end
  end
  def moeda(string)
    if string == "BTCTEST"
      return "฿T"
    end
    if string == "LTCTEST"
      return " ŁT"
    end
    if string == "BTC"
      return " ฿"
    end
    if string == "LTC"
      return " Ł"
    end
  end
  private
  def current_order
    @current_order ||= begin
      if has_order?
        @current_order
      else
        order = Shoppe::Order.create(:ip_address => request.ip)
        session[:order_id] = order.id
        order
      end
    end
  end
  def is_admin?
    user = current_user
    if user.salt == 'admin'
      true
    else
      false
    end
  end
  def has_order?
    !!(
      session[:order_id] &&
      @current_order = Shoppe::Order.includes(:order_items => :ordered_item).find_by_id(session[:order_id])
    )
  end
  def convert_bitcoin(valor)
    string = 'https://blockchain.info/tobtc?currency=BRL&value=' + valor.to_s
    uri = URI(string)
    response = Net::HTTP.get(uri)
    response
  end
  def archive_wallet(address)
    url = 'https://block.io/api/v2/archive_addresses/?api_key=ac35-6ff5-e103-d1c3&addresses=' + address
    uri = URI(url)
    response = Net::HTTP.get(uri)
    hash = JSON.parse(response)
    puts hash
  end
end
