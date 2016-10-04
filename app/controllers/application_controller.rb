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
  helper_method :itens_string
  helper_method :params_post
  helper_method :userphone
  after_filter :cors_set_access_control_headers
  helper_method :wich_status
  helper_method :brl_btc
 
  def brl_btc(value)
    convert_url = 'https://blockchain.info/tobtc?currency=BRL&value=' + value.to_s
    convert_uri = URI(convert_url)
    response_convert = Net::HTTP.get(convert_uri)
    puts response_convert
    result = BigDecimal(response_convert).mult(0.75,7) 
    puts result
    result
  end
  def wich_status(x)
    if x == '1'
      # 	Aguardando pagamento: o comprador iniciou a transação, mas até o momento o PagSeguro não recebeu nenhuma informação sobre o pagamento.
    end
    if x == '2'
      # Em análise: o comprador optou por pagar com um cartão de crédito e o PagSeguro está analisando o risco da transação. 
    end
    if x == '3'
      # Paga: a transação foi paga pelo comprador e o PagSeguro já recebeu uma confirmação da instituição financeira responsável pelo processamento. 
      return '3'
    end
    if x == '4'
      # Disponível: a transação foi paga e chegou ao final de seu prazo de liberação sem ter sido retornada e sem que haja nenhuma disputa aberta. 
    end
    if x == '5'
      # Em disputa: o comprador, dentro do prazo de liberação da transação, abriu uma disputa. 
    end
    if x == '6'
      # Devolvida: o valor da transação foi devolvido para o comprador. 
    end
    if x == '7'
      # Cancelada: a transação foi cancelada sem ter sido finalizada. 
    end
    if x == '8'
      # Debitado: o valor da transação foi devolvido para o comprador. 
    end
    if x == '9'
      # Retenção temporária: o comprador contestou o pagamento junto à operadora do cartão de crédito ou abriu uma demanda judicial ou administrativa (Procon). 
    end
    
    
  end
  def cors_set_access_control_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'POST'
    headers['Access-Control-Allow-Headers'] = '*'
    headers['Access-Control-Request-Method'] = 'pgseguro'
    headers['Access-Control-Max-Age'] = "1728000"
  end
  def params_post
    result = "'email' => 'ricardo.malafaia1994@gmail.com', 'token' => '95112EE828D94278BD394E91C4388F20', "
    itens = ""
    order = Shoppe::Order.find(current_order.id)
    order.order_items.each do |item|
      id = id + 1
      itens = itens + '"itemId' + id.to_s + '" => "' + id.to_s + '", ' + '"itemDescription"' + id.to_s + '" => "' + (item.ordered_item.full_name).to_s + '", ' + '"itemAmount' + id.to_s + '" => "' + (item.sub_total).to_s + '", '  + '"itemQuantity' + id.to_s + '" => "' + (item.quantity).to_s + '", '
    end
    result = result + itens + "'reference' => 'REF1234', 'senderName' => '" + username.to_s + "', 'senderEmail' => '" + useremail.to_s + "', 'shippingAddressStreet' =>  '" + params["pagamento"]["rua"].to_s + "',  'shippingAddressNumber' =>  '" + params["pagamento"]["numero"] + "' , 'shippingAddressComplement' => '" + params["pagamento"]["complemento"] + "', 'shippingAddressDistrict' => '" + params["pagamento"]["bairro"] + "', 'shippingAddressPostalCode' => '"+ params["pagamento"]["postcode"] + "', 'shippingAddressCity' => '" + params["pagamento"]["cidade"] + "', 'shippingAddressState' => '" + params["pagamento"]["estado"] +"', 'shippingAddressCountry' => '" + params["pagamento"]["pais"] + "'"
    puts result
    result
  end
  def itens_string
    id = 0
    string = ""
    order = Shoppe::Order.find(current_order.id)
    order.order_items.each do |item|
      id = id + 1
      string = string + '\&itemId' + id.to_s + '=' + id.to_s + '\&itemDescription' + id.to_s + '=' + (item.ordered_item.full_name).to_s + '&itemAmount' + id.to_s + '=' + (item.sub_total).to_s + '\&itemQuantity' + id.to_s + '=' + (item.quantity).to_s 
    end
    string
  end
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
