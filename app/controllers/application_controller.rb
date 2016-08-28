class ApplicationController < ActionController::Base
  require 'blockchain'
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  attr_accessor :viewname
  helper_method :current_user
  helper_method :current_order
  helper_method :has_order?
  helper_method :username
  helper_method :receber_pagamento
  helper_method :moeda
  helper_method :buy
  def current_user 
    @current_user ||= Usuario.find(session[:user_id]) if session[:user_id] 
  end
  def require_user 
    redirect_to '/login' unless current_user 
  end
  
  def require_logout
    redirect_to '/' if current_user
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

  def has_order?
    !!(
      session[:order_id] &&
      @current_order = Shoppe::Order.includes(:order_items => :ordered_item).find_by_id(session[:order_id])
    )
  end
  def buy(permalink)
        # @product = Produto.find_by(params[:id])
        puts params[:permalink]
        puts 'AQUI EXECUTA A FUNÇÃO DE SALVAR ITEM NA ONDA'
         @product = Shoppe::Product.root.find_by_permalink!(permalink)
         current_order.order_items.add_item(@product, 1)
         @messages = "Product has been added successfuly!"
         redirect_to product_path(@product.permalink)
  end
end
